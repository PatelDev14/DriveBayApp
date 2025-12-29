import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct RequestsView: View {
    @Environment(\.dismiss) private var dismiss
    
    let listing: Listing?
    @State private var requests: [Booking] = []
    @State private var isLoading = true
    @State private var isUpdating = false
    @State private var requestToDelete: Booking?
    @State private var showingDeleteAlert = false
    
    private let emailService = EmailService()
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                } else if requests.isEmpty {
                    emptyRequestsView
                } else {
                    List {
                        ForEach(requests) { request in
                            IncomingRequestCard(
                                request: request,
                                isUpdating: isUpdating,
                                onUpdateStatus: { status in
                                    updateStatus(request: request, newStatus: status)
                                },
                                onDelete: {
                                    requestToDelete = request
                                    showingDeleteAlert = true
                                }
                            )
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Incoming Requests")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.white.opacity(0.9))
                        .fontWeight(.semibold)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        fetchRequests()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.headline)
                            .foregroundColor(DriveBayTheme.accent)
                    }
                }
            }
            .onAppear {
                fetchRequests()
            }
            .alert("Remove Request?", isPresented: $showingDeleteAlert, presenting: requestToDelete) { request in
                    Button("Remove", role: .destructive) { // Changed "Delete" to "Remove"
                        deleteRequest(request)
                    }
                    Button("Cancel", role: .cancel) { }
                } message: { request in
                    Text("This will remove the request from your list. The renter (\(request.renterEmail)) will still be able to see the status in their history.")
                }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Empty State (Standardized with Bookings)
    private var emptyRequestsView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(DriveBayTheme.glow.opacity(0.15))
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)
                
                Image(systemName: "tray.and.arrow.down.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DriveBayTheme.accent, .white],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: DriveBayTheme.glow.opacity(0.5), radius: 20)
            }
            
            VStack(spacing: 8) {
                Text("No Requests")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text("New requests for your parking bays will appear here.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 50)
            }
        }
        .padding(.top, 60)
    }

    // MARK: - Logic (Updated with Loading state)
    private func fetchRequests() {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            
            // Update: Added filter for hiddenByOwner
            var query = Firestore.firestore().collection("bookings")
                .whereField("listingOwnerId", isEqualTo: uid)
                .whereField("hiddenByOwner", isEqualTo: false)
            
            if let listing = listing {
                query = query.whereField("listingId", isEqualTo: listing.id ?? "")
            }
            
            // It's good practice to sort by newest first
            query.order(by: "createdAt", descending: true)
                .addSnapshotListener { snapshot, error in
                    isLoading = false
                    if let error = error {
                        print("Error fetching requests: \(error.localizedDescription)")
                        return
                    }
                    withAnimation {
                        self.requests = snapshot?.documents.compactMap { try? $0.data(as: Booking.self) } ?? []
                    }
                }
        }
    
    
    private func updateStatus(request: Booking, newStatus: Booking.BookingStatus) {
        guard let id = request.id else { return }
        isUpdating = true
        Firestore.firestore().collection("bookings").document(id).updateData(["status": newStatus.rawValue]) { error in
            DispatchQueue.main.async {
                self.isUpdating = false
                if error == nil && newStatus == .approved {
                    let dateString = request.requestedDate.formatted(date: .abbreviated, time: .omitted)
                    let ownerEmail = Auth.auth().currentUser?.email ?? ""
                    Task {
                        try? await self.emailService.sendBookingApprovedEmail(to: request.renterEmail, ownerEmail: ownerEmail, address: request.listingAddress, date: dateString, startTime: request.startTime, endTime: request.endTime)
                    }
                }
            }
        }
    }
    
    private func deleteRequest(_ request: Booking) {
        guard let id = request.id else { return }
        
        Firestore.firestore().collection("bookings").document(id).updateData([
            "hiddenByOwner": true,
            "status": Booking.BookingStatus.cancelled.rawValue // Change status to free up the spot
        ]) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Refined Incoming Request Card
private struct IncomingRequestCard: View {
    let request: Booking
    let isUpdating: Bool
    let onUpdateStatus: (Booking.BookingStatus) -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.listingAddress)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.caption2)
                        Text("From: \(request.renterEmail)")
                            .font(.caption)
                    }
                    .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.red.opacity(0.7))
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
            
            HStack {
                HStack(spacing: 12) {
                    Label(request.requestedDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    Label("\(request.startTime) – \(request.endTime)", systemImage: "clock.fill")
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(DriveBayTheme.accent)
                
                Spacer()
                
                StatusBadge(status: request.status)
            }
            
            if request.status == .pending {
                Divider()
                    .background(Color.white.opacity(0.1))
                
                HStack(spacing: 12) {
                    // Approve Button
                    Button {
                        print("DEBUG: Approve pressed for \(request.id ?? "unknown")")
                        onUpdateStatus(.approved)
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Approve")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green.opacity(0.15))
                        .foregroundColor(.green)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain) 
                    .disabled(isUpdating)
                    
                    // Reject Button
                    Button {
                        print("DEBUG: Reject pressed for \(request.id ?? "unknown")")
                        onUpdateStatus(.rejected)
                    } label: {
                        Text("Reject")
                            .font(.system(size: 14, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.05))
                            .foregroundColor(.white.opacity(0.8))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain) // CRITICAL: Prevents tap bleeding
                    .disabled(isUpdating)
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.12), Color.white.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(
                    LinearGradient(
                        colors: [DriveBayTheme.glassBorder.opacity(0.5), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: Booking.BookingStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption2.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(8)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .pending: return Color.orange.opacity(0.2)
        case .approved: return Color.green.opacity(0.2)
        case .rejected: return Color.red.opacity(0.2)
        case .cancelled: return Color.gray.opacity(0.2)
        }
    }
    
    private var foregroundColor: Color {
        switch status {
        case .pending: return .orange
        case .approved: return .green
        case .rejected: return .red
        case .cancelled: return .gray
        }
    }
}

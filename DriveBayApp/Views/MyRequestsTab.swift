import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct RequestsView: View {
    @Environment(\.dismiss) private var dismiss
    
    let listing: Listing?  // Optional: filter by specific listing, or nil for all
    @State private var requests: [Booking] = []
    @State private var isUpdating = false
    
    private let emailService = EmailService()
    
    var body: some View {
        NavigationStack {
            List(requests) { request in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(request.listingAddress)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Renter: \(request.renterEmail)")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        StatusBadge(status: request.status)
                    }
                    
                    HStack {
                        Label(request.requestedDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                            .foregroundColor(.cyan)
                        
                        Spacer()
                        
                        Label("\(request.startTime) – \(request.endTime)", systemImage: "clock.fill")
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .font(.caption)
                    
                    // Approve/Reject buttons only for pending
                    if request.status == .pending {
                        HStack(spacing: 16) {
                            Button("Approve") {
                                updateStatus(request: request, newStatus: .approved)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            .disabled(isUpdating)
                            
                            Button("Reject") {
                                updateStatus(request: request, newStatus: .rejected)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                            .disabled(isUpdating)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.vertical, 8)
            }
            .listStyle(.plain)
            .navigationTitle("Incoming Requests")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { dismiss() }
                        .foregroundColor(.white.opacity(0.9))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        fetchRequests()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                            .foregroundColor(DriveBayTheme.accent)
                    }
                }
            }
            .onAppear {
                fetchRequests()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Fetch Requests (all for current user, or filtered by listing)
    private func fetchRequests() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        var query = Firestore.firestore().collection("bookings")
            .whereField("listingOwnerId", isEqualTo: uid)
        
        // Optional: filter by specific listing
        if let listing = listing {
            query = query.whereField("listingId", isEqualTo: listing.id ?? "")
        }
        
        query.addSnapshotListener { snapshot, error in
            if let error = error {
                print("Fetch requests error: \(error)")
                return
            }
            
            self.requests = snapshot?.documents.compactMap { document in
                try? document.data(as: Booking.self)
            } ?? []
        }
    }
    
//    // MARK: - Update Status + Send Email
    private func updateStatus(request: Booking, newStatus: Booking.BookingStatus) {
        guard let id = request.id else { return }
        isUpdating = true
        
        let db = Firestore.firestore()
        
        db.collection("bookings").document(id).updateData([
            "status": newStatus.rawValue
        ]) { error in
            DispatchQueue.main.async {
                self.isUpdating = false
                
                if let error = error {
                    print("Update failed: \(error)")
                    return
                }
                
                print("Status updated to \(newStatus.displayName)")
                
                // Use the existing emailService instance
                let dateString = request.requestedDate.formatted(date: .abbreviated, time: .omitted)
                let ownerEmail = Auth.auth().currentUser?.email ?? ""
                
                Task {
                    do {
                        if newStatus == .approved {
                            try await self.emailService.sendBookingApprovedEmail(
                                to: request.renterEmail,
                                ownerEmail: ownerEmail,
                                address: request.listingAddress,
                                date: dateString,
                                startTime: request.startTime,
                                endTime: request.endTime
                            )
                        } else if newStatus == .rejected {
                            print("Booking rejected — add rejected email later")
                        }
                    } catch {
                        print("Email send failed: \(error)")
                    }
                }
            }
        }
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
        }
    }
    
    private var foregroundColor: Color {
        switch status {
        case .pending: return .orange
        case .approved: return .green
        case .rejected: return .red
        }
    }
}

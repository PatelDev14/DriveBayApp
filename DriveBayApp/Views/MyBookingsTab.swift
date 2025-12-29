import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MyBookingsTab: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var bookings: [Booking] = []
    @State private var isLoading = true
    @State private var bookingToDelete: Booking?
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // High-end Background Consistency
                AnimatedGradientBackground()
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                } else if bookings.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(bookings) { booking in
                            BookingCard(booking: booking) {
                                bookingToDelete = booking
                                showingDeleteAlert = true
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("My Bookings")
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
            }
            .onAppear {
                fetchMyBookings()
            }
            .alert("Remove from History?", isPresented: $showingDeleteAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Remove", role: .destructive) {
                        if let booking = bookingToDelete {
                            deleteBooking(booking)
                        }
                    }
                } message: {
                    Text("This booking will be removed from your view, but will remain active if it is currently approved.")
                }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Refined Empty State (Consistency with Requests)
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(DriveBayTheme.glow.opacity(0.15))
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)
                
                Image(systemName: "ticket.fill")
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
                Text("No Bookings Yet")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Your approved bookings will appear here once a host accepts your request.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 50)
            }
        }
        .padding(.top, 60)
    }
    
    // MARK: - Logic
    private func fetchMyBookings() {
            guard let uid = Auth.auth().currentUser?.uid else {
                isLoading = false
                return
            }
            
            // Update: We only fetch bookings where hiddenByRenter is false
            Firestore.firestore().collection("bookings")
                .whereField("renterId", isEqualTo: uid)
                .whereField("hiddenByRenter", isEqualTo: false)
                .order(by: "createdAt", descending: true)
                .addSnapshotListener { snapshot, error in
                    isLoading = false
                    if let error = error {
                        print("Error fetching bookings: \(error.localizedDescription)")
                        return
                    }
                    
                    withAnimation {
                        self.bookings = snapshot?.documents.compactMap { try? $0.data(as: Booking.self) } ?? []
                    }
                }
        }
    
    private func deleteBooking(_ booking: Booking) {
        guard let id = booking.id else { return }
        
        Firestore.firestore().collection("bookings").document(id).updateData([
            "hiddenByRenter": true,
            "status": Booking.BookingStatus.cancelled.rawValue // Change status to free up the spot
        ]) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Beautiful Booking Card (Consistency with Requests)
private struct BookingCard: View {
    let booking: Booking
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: Address & Styled Delete Button
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.listingAddress)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if let ownerEmail = booking.ownerEmail {
                        HStack(spacing: 4) {
                            Image(systemName: "person.circle.fill")
                                .font(.caption2)
                            Text("Host: \(ownerEmail)")
                                .font(.caption)
                        }
                        .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                Spacer()
                
                // Matches the Delete Style from Requests Tab
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
            
            // Middle: Metadata & Status Badge
            HStack {
                HStack(spacing: 12) {
                    Label(booking.requestedDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    Label("\(booking.startTime) – \(booking.endTime)", systemImage: "clock.fill")
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(DriveBayTheme.accent)
                
                Spacer()
                
                StatusBadge(status: booking.status)
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Footer: Total Price (Receipt Style)
            HStack {
                Text("Total Payment")
                    .font(.caption)
                    .textCase(.uppercase)
                    .tracking(1)
                    .foregroundColor(.white.opacity(0.4))
                
                Spacer()
                
                Text("$\(String(format: "%.2f", booking.totalPrice ?? 0.0))")
                    .font(.system(.title2, design: .rounded, weight: .heavy))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
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
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

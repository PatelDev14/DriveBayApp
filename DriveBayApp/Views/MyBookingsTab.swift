import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MyBookingsTab: View {
    @Environment(\.dismiss) private var dismiss
    @State private var bookings: [Booking] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView().tint(.white)
                } else if bookings.isEmpty {
                    VStack(spacing: 32) {
                        Image(systemName: "ticket.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(DriveBayTheme.accent)
                            .shadow(color: DriveBayTheme.glow, radius: 30)
                        
                        Text("No Bookings Yet")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Your approved bookings will appear here once a host accepts your request.")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    List(bookings) { booking in
                        BookingRow(booking: booking)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            // CANCEL FEATURE ADDED HERE
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if booking.status == .pending {
                                    Button(role: .destructive) {
                                        cancelBooking(booking)
                                    } label: {
                                        Label("Cancel", systemImage: "xmark.circle.fill")
                                    }
                                }
                            }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("My Bookings")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { dismiss() }
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .onAppear {
                fetchMyBookings()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func fetchMyBookings() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore().collection("bookings")
            .whereField("renterId", isEqualTo: uid)
            .addSnapshotListener { snapshot, error in
                isLoading = false
                if let error = error {
                    print("Error fetching bookings: \(error.localizedDescription)")
                    return
                }
                
                self.bookings = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: Booking.self)
                } ?? []
            }
    }
    
    private func cancelBooking(_ booking: Booking) {
        guard let id = booking.id else { return }
        Firestore.firestore().collection("bookings").document(id).delete()
    }
}

struct BookingRow: View {
    let booking: Booking
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.listingAddress)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Host: \(booking.ownerEmail ?? "DriveBay Host")")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                Spacer()
                StatusBadge(status: booking.status)
            }
            
            HStack {
                Label(booking.requestedDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                Spacer()
                Label("\(booking.startTime) - \(booking.endTime)", systemImage: "clock")
            }
            .font(.caption)
            .foregroundColor(.cyan)
            
            Divider().background(Color.white.opacity(0.2))
            
            HStack {
                Text("Total Price")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                // Safely handle the optional price
                Text("$\(String(format: "%.2f", booking.totalPrice ?? 0.0))")
                    .font(.headline)
                    .foregroundColor(DriveBayTheme.accent)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

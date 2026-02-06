import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MyBookingsTab: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var bookings: [Booking] = []
    @State private var isLoading = true
    @State private var bookingToDelete: Booking?
    @State private var showingDeleteAlert = false
    @State private var bookingToReport: Booking?
    @State private var showingReportForm = false
    
    // NEW: Toggle for History
    @State private var showHistory = false
    
    // NEW: Computed properties to split bookings
    private var activeBookings: [Booking] {
        bookings.filter { $0.requestedDate >= Calendar.current.startOfDay(for: Date()) }
    }
    
    private var pastBookings: [Booking] {
        bookings.filter { $0.requestedDate < Calendar.current.startOfDay(for: Date()) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                } else {
                    VStack {
                        if (showHistory ? pastBookings : activeBookings).isEmpty {
                            emptyStateView(isHistory: showHistory)
                        } else {
                            List {
                                ForEach(showHistory ? pastBookings : activeBookings) { booking in
                                    BookingCard(
                                        booking: booking,
                                        onDelete: {
                                            bookingToDelete = booking
                                            showingDeleteAlert = true
                                        },
                                        onReport: {
                                            bookingToReport = booking
                                            showingReportForm = true
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
                }
            }
            .navigationTitle(showHistory ? "Past Bookings" : "My Bookings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { dismiss() }
                        .foregroundColor(.white.opacity(0.9))
                        .fontWeight(.medium)
                }
                
                // NEW: History Toggle Button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation(.spring()) {
                            showHistory.toggle()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: showHistory ? "clock.arrow.circlepath" : "clock.fill")
                                .font(.system(size: 13, weight: .semibold))
                            
                            Text(showHistory ? "Show Active" : "History")
                                .font(.footnote.weight(.semibold))
                        }
                        .padding(.vertical, 7)
                        .padding(.horizontal, 14)
                        .background(
                            Capsule()
                                .fill(showHistory ? DriveBayTheme.accent : Color.white.opacity(0.12))
                        )
                        .foregroundColor(showHistory ? .black : .white)
                        .shadow(
                            color: showHistory
                                ? DriveBayTheme.accent.opacity(0.5)
                                : Color.black.opacity(0.25),
                            radius: showHistory ? 10 : 6,
                            y: 4
                        )
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
            .sheet(isPresented: $showingReportForm) {
                if let booking = bookingToReport {
                    ReportFormView(booking: booking, asRenter: true)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Updated Empty State
    private func emptyStateView(isHistory: Bool) -> some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(DriveBayTheme.glow.opacity(0.15))
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)
                
                Image(systemName: isHistory ? "archivebox.fill" : "ticket.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(
                        LinearGradient(colors: [DriveBayTheme.accent, .white], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(color: DriveBayTheme.glow.opacity(0.5), radius: 20)
            }
            
            VStack(spacing: 8) {
                Text(isHistory ? "No Past Bookings" : "No Bookings Yet")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text(isHistory ? "You haven't completed any driveway bookings yet." : "Your approved bookings will appear here once a host accepts your request.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 50)
            }
        }
        .padding(.top, 60)
    }
    
    private func fetchMyBookings() {
        guard let uid = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        
        Firestore.firestore().collection("bookings")
            .whereField("renterId", isEqualTo: uid)
            .whereField("hiddenByRenter", isEqualTo: false)
            .order(by: "requestedDate", descending: true)
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
            "status": Booking.BookingStatus.cancelled.rawValue
        ]) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
}




// ... BookingCard remains the same ...
// MARK: - Booking Card (Renter side)
private struct BookingCard: View {
    let booking: Booking
    let onDelete: () -> Void
    let onReport: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // MARK: - Header (Address & Delete)
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
            
            // MARK: - Date, Time & Status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label(booking.requestedDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    Label("\(booking.startTime) – \(booking.endTime)", systemImage: "clock.fill")
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(DriveBayTheme.accent)
                
                Spacer()
                
                StatusBadge(status: booking.status)
            }

            // MARK: - STRIPE PAYMENT BUTTON + REPORT
            VStack(spacing: 12) {
                // 1. Report Issue Button
                if booking.status == .approved {
                    Button(action: {
                        onReport()
                    }) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("Report Issue with Driveway")
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // 2. Complete Payment Button (Bottom position)
                if booking.status == .approved && booking.paymentStatus != "paid" {
                    NavigationLink(destination: PaymentView(booking: booking, totalAmount: booking.totalPrice ?? 25.00)) {
                        HStack {
                            Image(systemName: "creditcard.fill")
                            Text("Complete Payment")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(DriveBayTheme.accent)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                        .shadow(color: DriveBayTheme.glow.opacity(0.3), radius: 10)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else if booking.paymentStatus == "paid" {
                    Label("Paid Successfully", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.bold())
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            // MARK: - Footer (Total Price)
            Divider().background(Color.white.opacity(0.1))
            
            HStack {
                Text("Total Price")
                    .font(.caption)
                    .textCase(.uppercase)
                    .foregroundColor(.white.opacity(0.4))
                
                Spacer()
                
                Text("$\(String(format: "%.2f", booking.totalPrice ?? 0.0))")
                    .font(.system(.title2, design: .rounded, weight: .heavy))
                    .foregroundColor(.green)
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(DriveBayTheme.glassBorder.opacity(0.5), lineWidth: 1)
        )
    }
}

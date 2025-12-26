import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct BookingRequestView: View {
    let listing: Listing
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedDate = Date()
    @State private var startTime = "09:00"
    @State private var endTime = "10:00"
    @State private var isSending = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var existingBookings: [Booking] = []
    @State private var availabilityMessage: String = ""
    
    private let emailService = EmailService()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Driveway Overview
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(DriveBayTheme.accent)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(listing.address)
                                        .font(.title3.bold())
                                        .foregroundColor(.white)
                                    
                                    Text("\(listing.city), \(listing.state)")
                                        .font(.headline)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                Spacer()
                                Text("$\(String(format: "%.2f", listing.rate))/hr")
                                    .font(.title2.bold())
                                    .foregroundColor(.green)
                                    .padding(8)
                                    .background(Color.green.opacity(0.2))
                                    .cornerRadius(12)
                            }
                            
                            HStack {
                                Label(listing.formattedDate, systemImage: "calendar")
                                    .foregroundColor(.cyan)
                                Spacer()
                                Label("\(listing.startTime) – \(listing.endTime)", systemImage: "clock.fill")
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .font(.subheadline.bold())
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(24)
                        
                        // MARK: - Availability Message
                        if !availabilityMessage.isEmpty {
                            Text(availabilityMessage)
                                .font(.caption)
                                .foregroundColor(.yellow.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // MARK: - Request Form
                        VStack(spacing: 24) {
                            DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .padding(10)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(18)
                                .onChange(of: selectedDate) { _ in
                                    loadBookingsAndUpdateAvailability()
                                }
                            
                            HStack(spacing: 16) {
                                ClockPicker(title: "Start Time", selection: $startTime)
                                ClockPicker(title: "End Time", selection: $endTime)
                            }
                        }
                        .padding(.horizontal)
                        
                        if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.callout)
                                .padding(.horizontal)
                        }
                        
                        // MARK: - Send Button
                        Button(action: {
                            if isTimeSlotConflict() {
                                errorMessage = "This time slot overlaps with an existing booking."
                            } else {
                                sendBookingRequest()
                            }
                        }) {
                            HStack {
                                if isSending {
                                    ProgressView().tint(.black)
                                } else {
                                    Text(showSuccess ? "Request Sent!" : "Send Booking Request")
                                        .font(.title3.bold())
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(showSuccess ? Color.green : DriveBayTheme.accent)
                            .foregroundColor(.black)
                            .cornerRadius(20)
                            .shadow(color: (showSuccess ? Color.green : DriveBayTheme.glow).opacity(0.5), radius: 15, y: 8)
                        }
                        .disabled(isSending || showSuccess)
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Request Booking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.white)
                }
            }
            .onAppear {
                selectedDate = listing.date
                loadBookingsAndUpdateAvailability()
            }
        }
    }
    
    // MARK: - Helper Logic
    
    private func isTimeSlotConflict() -> Bool {
        let newStart = Int(startTime.replacingOccurrences(of: ":", with: "")) ?? 0
        let newEnd = Int(endTime.replacingOccurrences(of: ":", with: "")) ?? 0
        
        if newEnd <= newStart { return true }
        
        for existing in existingBookings {
            let existStart = Int(existing.startTime.replacingOccurrences(of: ":", with: "")) ?? 0
            let existEnd = Int(existing.endTime.replacingOccurrences(of: ":", with: "")) ?? 0
            
            if newStart < existEnd && newEnd > existStart {
                return true
            }
        }
        return false
    }

    private func sendBookingRequest() {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "Please log in to book."
            return
        }
        
        isSending = true
        errorMessage = nil
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        let dateString = displayFormatter.string(from: selectedDate)
        
        let newBooking = Booking(
            listingId: listing.id,
            listingAddress: listing.address,
            listingOwnerId: listing.ownerId,
            renterId: user.uid,
            renterEmail: user.email ?? "unknown@drivebay.com",
            status: .pending,
            requestedDate: selectedDate,
            startTime: startTime,
            endTime: endTime,
            createdAt: Timestamp(date: Date())
        )
        
        Task {
            do {
                try Firestore.firestore().collection("bookings").addDocument(from: newBooking)
                
                try await emailService.sendBookingRequestEmail(
                    to: listing.contactEmail,
                    renterEmail: user.email ?? "unknown@drivebay.com",
                    address: listing.address,
                    date: dateString,
                    startTime: startTime,
                    endTime: endTime
                )
                
                await MainActor.run {
                    showSuccess = true
                    isSending = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSending = false
                }
            }
        }
    }

    private func loadBookingsAndUpdateAvailability() {
        let db = Firestore.firestore()
        Task {
            do {
                let startOfDay = Calendar.current.startOfDay(for: selectedDate)
                let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

                let snapshot = try await db.collection("bookings")
                    .whereField("listingId", isEqualTo: listing.id ?? "")
                    .whereField("status", isEqualTo: "approved")
                    .whereField("requestedDate", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
                    .whereField("requestedDate", isLessThan: Timestamp(date: endOfDay))
                    .getDocuments()

                
                let bookings = snapshot.documents.compactMap { try? $0.data(as: Booking.self) }
                
                await MainActor.run {
                    self.existingBookings = bookings
                    if bookings.isEmpty {
                        availabilityMessage = "Fully available on this day!"
                    } else {
                        let times = bookings.map { "\($0.startTime)-\($0.endTime)" }.joined(separator: ", ")
                        availabilityMessage = "Booked slots: \(times)"
                    }
                }
            } catch {
                print("Error loading availability: \(error)")
            }
        }
    }
}

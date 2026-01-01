// PaymentViewModel.swift
import SwiftUI
import StripePaymentSheet
import FirebaseFunctions
import FirebaseAuth
import FirebaseFirestore
import Combine

// Wrapper for SwiftUI sheet/fullScreenCover
struct PaymentSheetWrapper: Identifiable {
    let id = UUID()
    let sheet: PaymentSheet
}

@MainActor
class PaymentViewModel: ObservableObject {
    @Published var paymentWrapper: PaymentSheetWrapper?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var paymentSucceeded = false

    func preparePayment(for booking: Booking, totalAmount: Double) {
        isLoading = true
        errorMessage = nil
        
        // 1. Determine currency based on the specific country field
        // Assuming your booking object has a 'country' property
        let country = booking.country?.lowercased() ?? "united states"
        let selectedCurrency = (country == "canada") ? "cad" : "usd"
        
        let data: [String: Any] = [
            "amount": totalAmount,
            "bookingId": booking.id ?? "unknown",
            "currency": selectedCurrency,
            "customerEmail": Auth.auth().currentUser?.email ?? ""
        ]
        
        Functions.functions().httpsCallable("createPaymentIntent").call(data) { [weak self] result, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Setup failed: \(error.localizedDescription)"
                    return
                }
                
                guard let data = result?.data as? [String: Any],
                      let clientSecret = data["clientSecret"] as? String else {
                    self.errorMessage = "Invalid response from server."
                    return
                }
                
                var config = PaymentSheet.Configuration()
                config.merchantDisplayName = "DriveBay"
                config.style = .alwaysDark
                
                let sheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: config)
                self.paymentWrapper = PaymentSheetWrapper(sheet: sheet)
            }
        }
    }
    
    func handlePaymentResult(_ result: PaymentSheetResult, for booking: Booking) {
        switch result {
        case .completed:
            self.paymentSucceeded = true
            
            // Update Firestore
            updateBookingToPaid(bookingID: booking.id)
            
            // Send email to host
            Task {
                let emailService = EmailService()
                try? await emailService.sendPaymentConfirmationEmail(
                    to: booking.ownerEmail ?? "",
                    renterEmail: Auth.auth().currentUser?.email ?? "unknown@drivebay.com",
                    address: booking.listingAddress,
                    date: booking.requestedDate.formatted(date: .abbreviated, time: .omitted),
                    startTime: booking.startTime,
                    endTime: booking.endTime,
                    amount: booking.totalPrice ?? 0.0
                )
            }
            
        case .canceled:
            print("User cancelled payment")
        case .failed(let error):
            self.errorMessage = "Payment failed: \(error.localizedDescription)"
        }
    }
    
    private func updateBookingToPaid(bookingID: String?) {
        guard let id = bookingID else { return }
        
        Firestore.firestore().collection("bookings").document(id).updateData([
            "paymentStatus": "paid",
            "paidAt": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("Successfully paid on Stripe, but failed to update Firestore: \(error.localizedDescription)")
            } else {
                print("Successfully updated booking \(id) to 'paid' status.")
            }
        }
    }
}

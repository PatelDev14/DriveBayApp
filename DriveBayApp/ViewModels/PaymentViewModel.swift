// PaymentViewModel.swift
import SwiftUI
import StripePaymentSheet
import FirebaseFunctions
import FirebaseAuth
import FirebaseFirestore
import Combine
internal import PassKit

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
        
        Task {
            do {
                // 1. Get Host ID from Firestore
                let snapshot = try await Firestore.firestore()
                    .collection("users")
                    .document(booking.listingOwnerId)
                    .getDocument()
                
                guard let hostStripeID = snapshot.data()?["stripeAccountId"] as? String else {
                    self.isLoading = false
                    self.errorMessage = "Host payout not configured."
                    return
                }

                // 2. Prepare Data (Stripe expects Integers for cents)
                let amountInCents = Int(round(totalAmount * 100))
                let data: [String: Any] = [
                    "amount": amountInCents,
                    "bookingId": booking.id ?? "unknown",
                    "currency": (booking.country?.lowercased() == "canada") ? "cad" : "usd",
                    "destinationAccount": hostStripeID,
                    "applicationFeePercent": 0.25
                ]

                let result = try await Functions.functions().httpsCallable("createPaymentIntent").call(data)
                
                // 4. Extract Secret
                if let resultData = result.data as? [String: Any],
                   let clientSecret = resultData["clientSecret"] as? String {
                    
                    var config = PaymentSheet.Configuration()
                    config.merchantDisplayName = "DriveBay"
                    config.style = .alwaysDark
                    config.applePay = .init(merchantId: "merchant.com.drivebay.app", merchantCountryCode: "CA")
                    
                    self.paymentWrapper = PaymentSheetWrapper(sheet: PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: config))
                }
                
                self.isLoading = false
            }
           catch {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                print("Payment Error: \(error)")
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

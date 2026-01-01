import SwiftUI
import StripePaymentSheet

struct PaymentView: View {
    let booking: Booking
    let totalAmount: Double
    
    @StateObject private var viewModel = PaymentViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()
                    .ignoresSafeArea()
                
                if viewModel.paymentSucceeded {
                    // Success State
                    VStack(spacing: 40) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.3))
                                .frame(width: 180, height: 180)
                                .blur(radius: 40)
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 120))
                                .foregroundColor(.green)
                                .shadow(color: .green.opacity(0.8), radius: 40)
                        }
                        
                        VStack(spacing: 16) {
                            Text("Payment Successful!")
                                .font(.system(size: 40, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Your parking spot is confirmed")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.9))
                            
                            Text("$\(String(format: "%.2f", totalAmount))")
                                .font(.system(size: 56, weight: .black))
                                .foregroundStyle(
                                    LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .shadow(color: .green.opacity(0.6), radius: 20)
                        }
                        
                        Button("Done") {
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(DriveBayTheme.accent)
                        .foregroundColor(.black)
                        .font(.title2.bold())
                        .cornerRadius(24)
                        .shadow(color: DriveBayTheme.glow.opacity(0.8), radius: 20, y: 10)
                        .padding(.horizontal, 40)
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    // Main Screen
                    VStack(spacing: 50) {
                        VStack(spacing: 24) {
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 90))
                                .foregroundStyle(DriveBayTheme.accent)
                                .shadow(color: DriveBayTheme.glow, radius: 40)
                            
                            Text("Complete Your Booking")
                                .font(.system(size: 38, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                Text(booking.listingAddress)
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Text("Total Amount")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text("$\(String(format: "%.2f", totalAmount))")
                                    .font(.system(size: 64, weight: .black))
                                    .foregroundStyle(
                                        LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .shadow(color: .green.opacity(0.6), radius: 30)
                            }
                        }
                        .padding(.top, 60)
                        
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.subheadline)
                                .padding()
                                .background(Color.red.opacity(0.15))
                                .cornerRadius(18)
                                .padding(.horizontal, 40)
                        }
                        
                        Spacer()
                        
                        Button("Proceed to Checkout") {
                            viewModel.preparePayment(for: booking, totalAmount: totalAmount)
                        }
                        .disabled(viewModel.isLoading)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 22)
                        .background(DriveBayTheme.accent)
                        .foregroundColor(.black)
                        .font(.title2.bold())
                        .cornerRadius(28)
                        .shadow(color: DriveBayTheme.glow.opacity(0.9), radius: 25, y: 12)
                        .padding(.horizontal, 40)
                        .overlay(viewModel.isLoading ? ProgressView().tint(.black) : nil)
                    }
                    .padding()
                }
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {  // ← This gives the standard "X"
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .navigationBarTitle("", displayMode: .inline)  // Hides title completely
            }
            .fullScreenCover(item: $viewModel.paymentWrapper) { wrapper in
                PaymentSheetFullScreenView(paymentSheet: wrapper.sheet) { result in
                    viewModel.handlePaymentResult(result, for: booking)
                }
            }
        }
    }

// MARK: - FIXED Full-Screen Stripe Sheet
struct PaymentSheetFullScreenView: UIViewControllerRepresentable {
    let paymentSheet: PaymentSheet
    let completion: (PaymentSheetResult) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .clear
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if uiViewController.presentedViewController == nil {
            DispatchQueue.main.async {
                paymentSheet.present(from: uiViewController) { result in
                    completion(result)
                    uiViewController.dismiss(animated: true)
                }
            }
        }
    }
}

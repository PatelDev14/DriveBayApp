import SwiftUI
import StripePaymentSheet

struct PaymentSheetView: UIViewControllerRepresentable {
    let paymentSheet: PaymentSheet
    let onCompletion: (PaymentSheetResult) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .clear // Make the background transparent
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            if uiViewController.presentedViewController == nil {
                paymentSheet.present(from: uiViewController, completion: onCompletion)
            }
        }
    }
}

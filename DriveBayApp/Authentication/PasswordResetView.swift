import SwiftUI

struct PasswordResetView: View {
    @Environment(\.dismiss) var dismiss // Allows us to close the sheet/view
    @State private var email: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    // Assume you pass your AuthService or access it via environment
    @EnvironmentObject var authService: AuthService

    var body: some View {
        VStack(spacing: 20) {
            Text("Reset Password")
                .font(.title).bold()

            Text("Enter the email address associated with your account. We will send you a password reset link.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Email Input Field
            TextField("Email Address", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
            
            // Send Reset Link Button
            Button("Send Reset Link") {
                Task {
                    await sendPasswordReset()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            // Cancel Button
            Button("Cancel") {
                dismiss() // Close the view
            }
            .padding(.top, 10)
        }
        .padding()
        .alert("Password Reset", isPresented: $showAlert, actions: {}) {
            Text(alertMessage)
        }
    }
    
    // ... Function to call Firebase (defined in Section 2)
    func sendPasswordReset() async {
        // Basic email validation
        guard !email.isEmpty else {
            alertMessage = "Please enter your email address."
            showAlert = true
            return
        }

        do {
            try await authService.sendPasswordReset(email: email)
            
            // Success message
            alertMessage = "A password reset link has been sent to \(email). Please check your inbox."
            showAlert = true
            
            // Dismiss the view after a successful send
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                dismiss()
            }
            
        } catch {
            // Failure message (e.g., email not found, invalid format)
            let nsError = error as NSError
            alertMessage = "Failed to send reset email. \(nsError.localizedDescription)"
            showAlert = true
        }
    }
}

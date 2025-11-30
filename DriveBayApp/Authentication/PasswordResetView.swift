import SwiftUI

struct PasswordResetView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    
    @State private var email: String = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    // Title
                    VStack(spacing: 12) {
                        Image(systemName: "envelope.open.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(DriveBayTheme.accent)
                            .shadow(color: DriveBayTheme.glow, radius: 20, y: 10)

                        Text("Reset Password")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Enter your email and we’ll send you a link to reset your password.")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    // Glass Card
                    GlassCard {
                        VStack(spacing: 24) {
                            // Email Field
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundStyle(DriveBayTheme.accent)
                                TextField("Email Address", text: $email)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            }
                            .padding(18)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .strokeBorder(DriveBayTheme.accent.opacity(0.4), lineWidth: 1.5)
                            )

                            // Send Button — GLOWING
                            Button {
                                Task { await sendPasswordReset() }
                            } label: {
                                Group {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.black)
                                    } else {
                                        Label("Send Reset Link", systemImage: "paperplane.fill")
                                    }
                                }
                                .font(.title3.bold())
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(DriveBayTheme.accent)
                                .cornerRadius(20)
                                .shadow(color: DriveBayTheme.glow, radius: 20, y: 10)
                            }
                            .disabled(isLoading || email.isEmpty)

                            // Cancel Button
                            Button("Cancel") {
                                dismiss()
                            }
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(32)
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
                .padding(.top, 40)
            }
            .navigationBarHidden(true)
            .alert("Password Reset", isPresented: $showAlert) {
                Button("OK") {
                    if alertMessage.contains("sent") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
        .preferredColorScheme(.dark)
    }

    // Your existing function — unchanged
    func sendPasswordReset() async {
        guard !email.isEmpty else {
            alertMessage = "Please enter your email address."
            showAlert = true
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.sendPasswordReset(email: email)
            alertMessage = "A password reset link has been sent to \(email).\nCheck your inbox (and spam folder)."
            showAlert = true
        } catch {
            alertMessage = "Failed to send reset link.\n\(error.localizedDescription)"
            showAlert = true
        }
    }
}

#Preview {
    PasswordResetView()
        .environmentObject(AuthService())
}

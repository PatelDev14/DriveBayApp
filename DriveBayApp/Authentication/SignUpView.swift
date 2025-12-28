import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSecure = true
    @State private var isSecureConfirm = true
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "person.badge.plus.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(DriveBayTheme.accent)
                            .shadow(color: DriveBayTheme.glow, radius: 20, y: 10)
                        
                        Text("Create Account")
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("Join DriveBay and start earning")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(.top, 40)
                    
                    // Glass Card — exact same style as everywhere
                    GlassCard {
                        VStack(spacing: 24) {
                            // Email
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundStyle(DriveBayTheme.accent)
                                TextField("Email", text: $email)
                                    .textContentType(.emailAddress)
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
                            
                            // Password
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(DriveBayTheme.accent)
                                Group {
                                    if isSecure {
                                        SecureField("Password", text: $password)
                                    } else {
                                        TextField("Password", text: $password)
                                    }
                                }
                                .textContentType(.newPassword)
                                
                                Button { withAnimation { isSecure.toggle() } } label: {
                                    Image(systemName: isSecure ? "eye.slash" : "eye")
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                            }
                            .padding(18)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(18)
                            
                            // Confirm Password
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(DriveBayTheme.accent)
                                Group {
                                    if isSecureConfirm {
                                        SecureField("Confirm Password", text: $confirmPassword)
                                    } else {
                                        TextField("Confirm Password", text: $confirmPassword)
                                    }
                                }
                                .textContentType(.newPassword)
                                
                                Button { withAnimation { isSecureConfirm.toggle() } } label: {
                                    Image(systemName: isSecureConfirm ? "eye.slash" : "eye")
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                            }
                            .padding(18)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(18)
                            
                            // Error
                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundStyle(.red.opacity(0.9))
                                    .padding(.horizontal)
                            }
                            
                            // Sign Up Button — GLOWING MASTERPIECE
                            Button(action: signUp) {
                                HStack {
                                    if isLoading {
                                        ProgressView().tint(.black)
                                    } else {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.title2)
                                    }
                                    Text(isLoading ? "Creating Account..." : "Sign Up")
                                        .font(.title3.bold())
                                }
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(DriveBayTheme.accent)
                                .cornerRadius(20)
                                .shadow(color: DriveBayTheme.glow, radius: 20, y: 10)
                            }
                            .disabled(isLoading || email.isEmpty || password.isEmpty || confirmPassword.isEmpty)
                            
                            // Back to Login
                            HStack {
                                Text("Already have an account?")
                                    .foregroundStyle(.white.opacity(0.7))
                                Button("Sign In") {
                                    dismiss()
                                }
                                .foregroundStyle(DriveBayTheme.accent)
                                .fontWeight(.bold)
                            }
                            .font(.callout)
                        }
                        .padding(32)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
    }
    private func signUp() {
        errorMessage = nil
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }
        
        isLoading = true
        Task {
            do {
                try await authService.signUp(email: email, password: password)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
}

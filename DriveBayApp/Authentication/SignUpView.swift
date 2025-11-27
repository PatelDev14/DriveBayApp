// Authentication/SignUpView.swift
import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService // Access the service
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = "" // Crucial state variable
    @State private var isSecure: Bool = true
    @State private var isSecureConfirm: Bool = true // New state for confirm password visibility
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            // Re-using the background from LoginView
            LinearGradient(colors: [Color.blue.opacity(0.9), Color.purple.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            // ... (Add decorative circles or similar background elements if desired)
            
            VStack(spacing: 24) {
                // Title
                VStack(spacing: 8) {
                    Text("Create Account")
                        .font(.largeTitle).bold()
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 4)
                    Text("Join DriveBay to manage your vehicles")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.top, 20)
                
                // Card
                VStack(spacing: 16) {
                    // Email
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill").foregroundStyle(.secondary)
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    .padding(14).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    
                    // Password
                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill").foregroundStyle(.secondary)
                        Group {
                            if isSecure { SecureField("Password", text: $password) }
                            else { TextField("Password", text: $password) }
                        }
                        .textContentType(.newPassword)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        
                        Button(action: { withAnimation(.easeInOut(duration: 0.15)) { isSecure.toggle() } }) {
                            Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill").foregroundStyle(.secondary)
                        }
                    }
                    .padding(14).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    
                    // ⭐️ CONFIRM PASSWORD FIELD (NEW BLOCK)
                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill").foregroundStyle(.secondary)
                        Group {
                            if isSecureConfirm { SecureField("Confirm Password", text: $confirmPassword) }
                            else { TextField("Confirm Password", text: $confirmPassword) }
                        }
                        .textContentType(.newPassword)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        
                        Button(action: { withAnimation(.easeInOut(duration: 0.15)) { isSecureConfirm.toggle() } }) {
                            Image(systemName: isSecureConfirm ? "eye.slash.fill" : "eye.fill").foregroundStyle(.secondary)
                        }
                    }
                    .padding(14).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    // ⭐️ END NEW BLOCK
                    
                    
                    // Error message
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote).foregroundStyle(.red.opacity(0.95))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    // Sign Up button
                    Button(action: signUp) {
                        // ... (Button style similar to LoginView's Sign In button)
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(LinearGradient(colors: [Color.white.opacity(0.95), Color.white.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 12)
                            HStack(spacing: 10) {
                                if isLoading { ProgressView().tint(.black.opacity(0.7)) }
                                else { Image(systemName: "person.badge.plus.fill").font(.title3).foregroundStyle(.black.opacity(0.7)) }
                                Text(isLoading ? "Creating account..." : "Sign Up")
                                    .font(.headline.weight(.bold)).foregroundStyle(.black.opacity(0.75))
                            }.padding(.vertical, 12)
                        }.frame(height: 54)
                    }
                    // Crucial: confirmPassword is now checked for emptiness
                    .disabled(isLoading || email.isEmpty || password.isEmpty || confirmPassword.isEmpty)
                    .padding(.top, 6)
                }
                .padding(20).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.25), radius: 24, x: 0, y: 18)
                .padding(.horizontal)
                
                // Back to Sign In
                HStack(spacing: 6) {
                    Text("Already have an account?")
                        .foregroundStyle(.white.opacity(0.85))
                    Button("Sign In") {
                        dismiss() // Dismisses the view and returns to LoginView
                    }
                    .foregroundStyle(.white).fontWeight(.semibold)
                }
                .font(.footnote).padding(.bottom, 24)
            }
        }
    }
    
    // The signUp function handles validation and calls the service
    private func signUp() {
        errorMessage = nil
        // Basic validation: ensure passwords match, and fields are not empty
        guard password == confirmPassword else {
            withAnimation { errorMessage = "Passwords do not match." }
            return
        }
        
        isLoading = true
        Task {
            do {
                // Call the Firebase AuthService function
                try await authService.signUp(email: email, password: password)
                // On successful sign-up, the user is automatically logged in.
                // The authService listener updates the state, and the app transitions to ContentView.
            } catch {
                withAnimation { errorMessage = error.localizedDescription }
            }
            isLoading = false
        }
    }
}

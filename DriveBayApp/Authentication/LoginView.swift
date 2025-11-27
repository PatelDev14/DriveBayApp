// Authentication/LoginView.swift
import SwiftUI

struct LoginView: View {
    // 1. Access the shared Authentication Service
    @EnvironmentObject var authService: AuthService
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSecure: Bool = true
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var isShowingSignUp: Bool = false
    @State private var showingResetSheet = false
    
    var body: some View {
        // Use NavigationStack to allow potential pushes/sheets for views like Forgot Password
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(colors: [Color.blue.opacity(0.9), Color.purple.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                // Decorative circles (Retained from original code)
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .blur(radius: 40)
                    .frame(width: 280, height: 280)
                    .offset(x: -120, y: -260)
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .blur(radius: 30)
                    .frame(width: 220, height: 220)
                    .offset(x: 160, y: -200)
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .blur(radius: 50)
                    .frame(width: 320, height: 320)
                    .offset(x: 120, y: 280)
                
                VStack(spacing: 24) {
                    // Logo / Title
                    VStack(spacing: 8) {
                        Image(systemName: "car.2.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.white)
                            .font(.system(size: 56))
                            .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 8)
                        Text("DriveBay")
                            .font(.largeTitle).bold()
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 4)
                        Text("Welcome back. Sign in to continue")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .padding(.top, 20)
                    
                    // Card
                    VStack(spacing: 16) {
                        // Email Field
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(.secondary)
                            TextField("Email", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        .padding(14)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        
                        // Password Field
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.secondary)
                            Group {
                                if isSecure {
                                    SecureField("Password", text: $password)
                                } else {
                                    TextField("Password", text: $password)
                                }
                            }
                            .textContentType(.password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            Button(action: { withAnimation(.easeInOut(duration: 0.15)) { isSecure.toggle() } }) {
                                Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(14)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        
                        // Forgot password
                        HStack {
                            Spacer()
                            Button("Forgot password?") {
                                showingResetSheet = true
                            }
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.9))
                                .buttonStyle(.plain)
                        }
                        
                        .sheet(isPresented: $showingResetSheet) {
                                    PasswordResetView()
                                        // Ensure AuthService is available in the environment if you use it
                                        .environmentObject(authService)
                        }
                        
                        // Error message
                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red.opacity(0.95))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        // Sign in button
                        Button(action: signIn) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(LinearGradient(colors: [Color.white.opacity(0.95), Color.white.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 12)
                                HStack(spacing: 10) {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.black.opacity(0.7))
                                    } else {
                                        Image(systemName: "arrow.right.circle.fill").font(.title3)
                                            .foregroundStyle(.black.opacity(0.7))
                                    }
                                    Text(isLoading ? "Signing in..." : "Sign In")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(.black.opacity(0.75))
                                }
                                .padding(.vertical, 12)
                            }
                            .frame(height: 54)
                        }
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        .padding(.top, 6)
                        
                        // Divider and alternative options
                        HStack {
                            Rectangle().fill(Color.white.opacity(0.2)).frame(height: 1)
                            Text("or")
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.8))
                            Rectangle().fill(Color.white.opacity(0.2)).frame(height: 1)
                        }
                        .padding(.vertical, 4)
                        

                        Button(action: { Task { await signInWithApple() } }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "apple.logo")
                                        .font(.system(size: 20, weight: .medium))
                                    Text("Continue with Apple")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    LinearGradient(
                                        colors: [Color.black.opacity(0.5), Color.black.opacity(0.35)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                            }
                            .buttonStyle(.plain)
                    }
                    
                    // ⭐️ NEW: Continue with Google Button
                    Button(action: { Task { await signInWithGoogle() } }) {
                            HStack(spacing: 12) {
//                                Image(systemName: "globe")
                                Image("google_icon")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .font(.system(size: 20, weight: .medium))
                                Text("Continue with Google")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    colors: [Color.black.opacity(0.5), Color.black.opacity(0.35)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                    
                    // Sign up prompt (Updated to trigger a sheet/fullScreenCover)
                    HStack(spacing: 6) {
                            Text("New to DriveBay?")
                                .foregroundStyle(.white.opacity(0.7))
                                .font(.system(size: 14))
                            Button("Create an account") {
                                isShowingSignUp = true
                            }
                            .foregroundStyle(.white)
                            .font(.system(size: 14, weight: .semibold))
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                }
            }
            // 2. Present SignUpView when the button is tapped
            .fullScreenCover(isPresented: $isShowingSignUp) {
                SignUpView()
                    // Crucial: Pass the authService to the new view
                    .environmentObject(authService)
            }
        }
    }
    
    // MARK: - Firebase Authentication Methods

    private func signIn() {
        // Prevent double-tap
        guard !isLoading else { return }
        
        errorMessage = nil
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password"
            return
        }
        
        Task { @MainActor in
            isLoading = true
            defer { isLoading = false } 
            
            do {
                try await authService.signIn(email: email, password: password)
                // Success → AuthService updates isLoggedIn → App switches to ChatView automatically
            } catch {
                print("Login failed: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
        }
    }
    private func signInWithApple() {
        errorMessage = nil
        isLoading = true
        
        // Placeholder for the Sign in with Apple implementation
        Task {
            do {
                try await authService.signInWithApple()
            } catch {
                withAnimation { errorMessage = error.localizedDescription }
            }
            isLoading = false
        }
    }
    
    private func signInWithGoogle() {
        errorMessage = nil
        isLoading = true
        
        Task {
            do {
                try await authService.signInWithGoogle()
            } catch {
                withAnimation {
                    errorMessage = error.localizedDescription
                }
            }
            isLoading = false
        }
    }
    
}

#Preview {
    // You need to provide the environment object for the preview to work
    LoginView()
        .environmentObject(AuthService())
}

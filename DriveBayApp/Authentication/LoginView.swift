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
        NavigationStack {
            ZStack {
                // DriveBay signature background — same as ChatView & MyDriveways
                AnimatedGradientBackground()
                    .ignoresSafeArea()

                VStack(spacing: 28) {
                    // Logo
                    VStack(spacing: 12) {
                        Image(systemName: "car.2.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(DriveBayTheme.accent)
                            .shadow(color: DriveBayTheme.glow, radius: 20, y: 10)

                        Text("DriveBay")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.4), radius: 10)

                        Text("Welcome back")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(.top, 40)

                    // Glass Card — exact same style as driveway cards
                    GlassCard {
                        VStack(spacing: 20) {
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
                            .padding(16)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(16)

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
                                .textContentType(.password)

                                Button {
                                    withAnimation { isSecure.toggle() }
                                } label: {
                                    Image(systemName: isSecure ? "eye.slash" : "eye")
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(16)

                            // Forgot Password
                            Button("Forgot password?") {
                                showingResetSheet = true
                            }
                            .font(.caption.bold())
                            .foregroundStyle(DriveBayTheme.accent)
                            .frame(maxWidth: .infinity, alignment: .trailing)

                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundStyle(.red.opacity(0.9))
                                    .padding(.horizontal)
                            }

                            // Sign In Button — GLOWING ACCENT
                            Button(action: signIn) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "arrow.right.circle.fill")
                                            .font(.title2)
                                    }
                                    Text(isLoading ? "Signing in..." : "Sign In")
                                        .font(.title3.bold())
                                }
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(DriveBayTheme.accent)
                                .cornerRadius(20)
                                .shadow(color: DriveBayTheme.glow, radius: 20, y: 10)
                            }
                            .disabled(isLoading || email.isEmpty || password.isEmpty)

                            // OR Divider
                            HStack {
                                Rectangle().fill(.white.opacity(0.2)).frame(height: 1)
                                Text("or continue with")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                                Rectangle().fill(.white.opacity(0.2)).frame(height: 1)
                            }

                            // Apple + Google Buttons
                            Button { Task { await signInWithApple() } } label: {
                                Label("Continue with Apple", systemImage: "apple.logo")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(Color.white.opacity(0.12))
                                    .cornerRadius(16)
                                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.3)))
                            }

                            Button { Task { await signInWithGoogle() } } label: {
                                HStack {
                                    Image("google_icon")
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                    Text("Continue with Google")
                                        .font(.headline)
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.white.opacity(0.12))
                                .cornerRadius(16)
                                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.3)))
                            }

                            // Sign Up Link
                            HStack {
                                Text("New to DriveBay?")
                                    .foregroundStyle(.white.opacity(0.7))
                                Button("Create account") {
                                    isShowingSignUp = true
                                }
                                .foregroundStyle(DriveBayTheme.accent)
                                .fontWeight(.bold)
                            }
                            .font(.callout)
                        }
                        .padding(24)
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }
            .fullScreenCover(isPresented: $isShowingSignUp) {
                SignUpView()
                    .environmentObject(authService)
            }
            .sheet(isPresented: $showingResetSheet) {
                PasswordResetView()
                    .environmentObject(authService)
            }
        }
        .preferredColorScheme(.dark)
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

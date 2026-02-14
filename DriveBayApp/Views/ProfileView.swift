// Views/ProfileView.swift
import SwiftUI
import FirebaseAuth
import PhotosUI
import FirebaseFirestore
import FirebaseFunctions

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = ProfileViewModel()
    @State private var isEditing = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showDeleteConfirmation = false
    
    let onLogout: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                backgroundGlowOrbs
                
                ScrollView {
                    VStack(spacing: 32) {
                        profileHeader
                        
                        if isEditing {
                            editModeContent
                        } else {
                            summaryModeContent
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                                if isEditing {
                                    withAnimation(.spring()) {
                                        isEditing = false
                                    }
                                } else {
                                    dismiss()
                                }
                            }
                        .foregroundColor(.white.opacity(0.9))
                        .fontWeight(.semibold)
                }
            }
            .onChange(of: selectedPhoto) { handlePhotoSelection($0) }
            .onAppear { onAppearSetup() }
            .alert("Delete Profile?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            try await authService.deleteAccount()
                            onLogout()
                            dismiss()
                        } catch {
                            print("Delete failed: \(error)")
                        }
                    }
                }
            } message: {
                Text("This will permanently delete your account, all listings, bookings, and data. This cannot be undone.")
            }
        }
    }
    
    // MARK: - Subviews
    
    private var backgroundGlowOrbs: some View {
        VStack {
            Circle()
                .fill(DriveBayTheme.glow.opacity(0.15))
                .frame(width: 350)
                .blur(radius: 80)
                .offset(x: -100, y: -100)
            Spacer()
            Circle()
                .fill(DriveBayTheme.accent.opacity(0.1))
                .frame(width: 300)
                .blur(radius: 80)
                .offset(x: 100, y: 100)
        }
        .ignoresSafeArea()
    }
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(DriveBayTheme.glow.opacity(0.3))
                    .frame(width: 140, height: 140)
                    .blur(radius: 30)
                
                if let urlString = viewModel.profileImageUrl,
                   !urlString.isEmpty,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.2)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(DriveBayTheme.accent, lineWidth: 3))
                                .shadow(color: DriveBayTheme.glow, radius: 15)
                        case .failure:
                            fallbackIcon()
                        }
                    }
                    .frame(width: 120, height: 120)
                } else {
                    fallbackIcon()
                }
                
                if isEditing {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                Image(systemName: "camera.fill")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(DriveBayTheme.accent)
                                    .clipShape(Circle())
                                    .shadow(color: DriveBayTheme.glow, radius: 8)
                            }
                        }
                    }
                    .frame(width: 120, height: 120)
                }
            }
            
            VStack(spacing: 4) {
                Text(isEditing ? "Update Profile" : (viewModel.displayName.isEmpty ? "Welcome" : viewModel.displayName))
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
        }
        .padding(.top, 30)
    }
    
    private var editModeContent: some View {
        VStack(spacing: 25) {
            profileSectionLabel("PERSONAL DETAILS")
            
            VStack(spacing: 16) {
                GlassTextField(placeholder: "First Name", text: $viewModel.firstName)
                GlassTextField(placeholder: "Last Name", text: $viewModel.lastName)
                GlassTextField(placeholder: "Phone Number", text: $viewModel.phoneNumber)
                    .keyboardType(.phonePad)
            }
            
            profileSectionLabel("ACCOUNT EMAIL")
            
            HStack(spacing: 15) {
                Image(systemName: "envelope.fill")
                    .foregroundColor(DriveBayTheme.accent.opacity(0.6))
                Text(viewModel.email)
                    .foregroundColor(.white.opacity(0.6))
                    .font(.body)
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(18)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
            
            // Unified button style
            primaryButton(title: "Save Changes", isLoading: viewModel.isSaving) {
                viewModel.saveProfile()
                withAnimation(.spring()) { isEditing = false }
            }
        }
        .padding(.horizontal, 24)
        .transition(.move(edge: .trailing).combined(with: .opacity))
    }
    
    private var summaryModeContent: some View {
        VStack(spacing: 24) {
            VStack(spacing: 20) {
                summaryRow(icon: "envelope.fill", title: "Email", value: viewModel.email)
                if !viewModel.phoneNumber.isEmpty {
                    Divider().background(Color.white.opacity(0.1))
                    summaryRow(icon: "phone.fill", title: "Phone", value: viewModel.phoneNumber)
                }
            }
            .padding(24)
            .background(Color.white.opacity(0.03))
            .cornerRadius(24)
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.1), lineWidth: 1))
            
            // MARK: - Stripe Payout Section (updated buttons)
            VStack(spacing: 12) {
                profileSectionLabel("PAYOUT SETTINGS")
                
                if let stripeID = viewModel.stripeAccountId, !stripeID.isEmpty {
                    if viewModel.isStripeVerified {
                        // Verified state
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                                Text("Payouts Enabled")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                Spacer()
                                Text("Stripe Connected")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.green.opacity(0.3), lineWidth: 1))
                            
                            secondaryButton(title: "Manage Payout Method") {
                                startStripeOnboarding()
                            }
                        }
                    } else {
                        // Incomplete state
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                VStack(alignment: .leading) {
                                    Text("Setup Incomplete")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                    Text("Finish adding info to receive payments")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(16)
                            
                            primaryButton(title: "Continue Registration") {
                                startStripeOnboarding()
                            }
                        }
                    }
                } else {
                    // Not started state
                    primaryButton(title: "Setup Payouts to Earn") {
                        startStripeOnboarding()
                    }
                    .disabled(viewModel.isLoading)
                    .overlay(viewModel.isLoading ? ProgressView().tint(.black) : nil)
                }
            }
            .padding(.bottom, 10)
            
            // MARK: - Action Buttons (unified style)
            VStack(spacing: 16) {
                primaryButton(title: "Edit Profile") {
                    withAnimation(.spring()) { isEditing = true }
                }
                
                dangerButton(title: "Logout", icon: "arrow.right.square") {
                    onLogout()
                }
                
                dangerButton(title: "Delete Profile", icon: "trash.fill") {
                    showDeleteConfirmation = true
                }
            }
        }
        .padding(.horizontal, 24)
        .transition(.move(edge: .leading).combined(with: .opacity))
    }
    
    // MARK: - Unified Button Styles
    
    private func primaryButton(title: String, isLoading: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView().tint(.black)
                } else {
                    Text(title)
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(DriveBayTheme.accent)
            .foregroundColor(.black)
            .cornerRadius(16)
            .shadow(color: DriveBayTheme.glow.opacity(0.4), radius: 10, y: 5)
        }
    }
    
    private func secondaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.08))
                .foregroundColor(DriveBayTheme.accent)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(DriveBayTheme.accent.opacity(0.4), lineWidth: 1)
                )
        }
    }
    
    private func dangerButton(title: String, icon: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.red.opacity(0.15))
            .foregroundColor(.red)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.red.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: .red.opacity(0.3), radius: 10, y: 5)
        }
    }
    
    // MARK: - Other Functions (unchanged)
    
    private func handlePhotoSelection(_ newItem: PhotosPickerItem?) {
        Task {
            guard let newItem else { return }
            do {
                guard let data = try await newItem.loadTransferable(type: Data.self) else {
                    print("Failed to load image data")
                    return
                }
                await viewModel.uploadProfilePhoto(data)
                viewModel.loadProfile()
            } catch {
                print("Photo picker error: \(error)")
            }
        }
    }
    
    private func onAppearSetup() {
        viewModel.loadProfile()
        if let stripeID = viewModel.stripeAccountId, !stripeID.isEmpty {
            viewModel.fetchStripeStatus()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if viewModel.firstName.isEmpty && viewModel.lastName.isEmpty {
                withAnimation { isEditing = true }
            }
        }
    }
    
    func startStripeOnboarding() {
        viewModel.isLoading = true
        
        // FIX: Pass the current stripeAccountId to the function
        let data: [String: Any] = [
            "stripeAccountId": viewModel.stripeAccountId ?? ""
        ]
        
        Functions.functions().httpsCallable("createStripeAccountLink").call(data) { result, error in
            if let error = error {
                print("Stripe Link Error: \(error.localizedDescription)")
                viewModel.isLoading = false
                return
            }
            
            if let data = result?.data as? [String: Any],
               let urlString = data["url"] as? String,
               let stripeID = data["stripeAccountId"] as? String,
               let url = URL(string: urlString) {
                
                // Save the ID immediately so we don't lose it if they close the app
                let uid = Auth.auth().currentUser?.uid ?? ""
                Firestore.firestore().collection("users").document(uid).setData([
                    "stripeAccountId": stripeID
                ], merge: true)
                
                viewModel.stripeAccountId = stripeID
                
                // Open the secure Stripe onboarding page
                UIApplication.shared.open(url)
            }
            viewModel.isLoading = false
        }
    }
    
    // MARK: - Helper Views (unchanged)
    
    private func fallbackIcon() -> some View {
        Image(systemName: "person.crop.circle.fill")
            .font(.system(size: 80))
            .foregroundStyle(LinearGradient(colors: [DriveBayTheme.accent, DriveBayTheme.secondary], startPoint: .topLeading, endPoint: .bottomTrailing))
            .shadow(color: DriveBayTheme.glow.opacity(0.5), radius: 10)
    }
    
    private func profileSectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption2.bold())
            .tracking(1.5)
            .foregroundColor(DriveBayTheme.accent.opacity(0.8))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4)
    }
    
    private func summaryRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(DriveBayTheme.accent)
                .font(.system(size: 18))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.4))
                Text(value)
                    .font(.body)
                    .foregroundColor(.white)
            }
            Spacer()
        }
    }
}

// === STYLED TEXTFIELD (unchanged) ===
private struct GlassTextField: View {
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.25)))
            .padding(18)
            .background(Color.white.opacity(0.06))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.15), .clear, .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .foregroundColor(.white)
            .accentColor(DriveBayTheme.accent)
    }
}

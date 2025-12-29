// Views/ProfileView.swift
import SwiftUI
import FirebaseAuth
import PhotosUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
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
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }
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
            
            Button {
                viewModel.saveProfile()
                withAnimation(.spring()) { isEditing = false }
            } label: {
                if viewModel.isSaving {
                    ProgressView().tint(.white)
                } else {
                    Text("Save Changes")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(DriveBayTheme.accent)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: DriveBayTheme.glow.opacity(0.4), radius: 10, y: 5)
                }
            }
            .padding(.top, 10)
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
            
            VStack(spacing: 16) {
                Button {
                    withAnimation(.spring()) { isEditing = true }
                } label: {
                    Text("Edit Profile")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.08))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(DriveBayTheme.accent.opacity(0.4), lineWidth: 1))
                }
                
                Button(action: onLogout) {
                    Label("Logout", systemImage: "arrow.right.square")
                        .font(.headline)
                        .foregroundColor(.red.opacity(0.8))
                        .padding(.top, 10)
                }
                
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete Profile", systemImage: "trash.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.red.opacity(0.15))
                        .foregroundColor(.red)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.red.opacity(0.5), lineWidth: 1))
                }
            }
        }
        .padding(.horizontal, 24)
        .transition(.move(edge: .leading).combined(with: .opacity))
    }
    
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if viewModel.firstName.isEmpty && viewModel.lastName.isEmpty {
                withAnimation { isEditing = true }
            }
        }
    }
    
    // MARK: - Helper Views
    
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

// === STYLED TEXTFIELD ===
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

// Views/ProfileView.swift
import SwiftUI
import FirebaseAuth
import PhotosUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ProfileViewModel()
    @State private var isEditing = false
    
    let onLogout: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
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
                
                ScrollView {
                    VStack(spacing: 32) {
                        
                        // === HEADER SECTION ===
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(DriveBayTheme.glow.opacity(0.3))
                                    .frame(width: 120, height: 120)
                                    .blur(radius: 20)
                                
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [DriveBayTheme.accent, DriveBayTheme.secondary],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: DriveBayTheme.glow.opacity(0.5), radius: 10)
                            }
                            
                            VStack(spacing: 4) {
                                Text(isEditing ? "Update Profile" : (viewModel.displayName.isEmpty ? "Welcome" : viewModel.displayName))
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.top, 30)

                        if isEditing {
                            // === EDIT MODE ===
                            VStack(spacing: 25) {
                                // Personal Info Section
                                profileSectionLabel("PERSONAL DETAILS")
                                
                                VStack(spacing: 16) {
                                    GlassTextField(placeholder: "First Name", text: $viewModel.firstName)
                                    GlassTextField(placeholder: "Last Name", text: $viewModel.lastName)
                                    GlassTextField(placeholder: "Phone Number", text: $viewModel.phoneNumber)
                                        .keyboardType(.phonePad)
                                }
                                
                                // Email Section (Locked)
                                profileSectionLabel("ACCOUNT EMAIL")
                                
                                HStack(spacing: 15) {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(DriveBayTheme.accent.opacity(0.6))
                                    
                                    Text(viewModel.email) // Pre-populated from ViewModel
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
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                                
                                // Save Button
                                Button(action: {
                                    viewModel.saveProfile()
                                    withAnimation(.spring()) {
                                        isEditing = false
                                    }
                                }) {
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
                            
                        } else {
                            // === SUMMARY MODE ===
                            VStack(spacing: 24) {
                                
                                // Information Card
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
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )

                                // Action Buttons
                                VStack(spacing: 16) {
                                    Button(action: {
                                        withAnimation(.spring()) { isEditing = true }
                                    }) {
                                        Text("Edit Profile")
                                            .font(.headline)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 16)
                                            .background(Color.white.opacity(0.08))
                                            .foregroundColor(.white)
                                            .cornerRadius(16)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(DriveBayTheme.accent.opacity(0.4), lineWidth: 1)
                                            )
                                    }

                                    Button(action: onLogout) {
                                        Label("Logout", systemImage: "arrow.right.square")
                                            .font(.headline)
                                            .foregroundColor(.red.opacity(0.8))
                                            .padding(.top, 10)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            // 💡 THIS TRIGGERS THE PRE-POPULATION
            .onAppear {
                viewModel.loadProfile()
                // Auto-switch to edit mode if name is missing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if viewModel.firstName.isEmpty && viewModel.lastName.isEmpty {
                        withAnimation { isEditing = true }
                    }
                }
            }
        }
    }
    
    // --- HELPER SUBVIEWS ---
    
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

// === OPTIONAL COLOR HELPER ===
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

import SwiftUI
import CoreLocation

// MARK: - DriveBay Theme (copy-paste this if you don’t have it in a separate file yet)
struct DriveBayTheme {
    static let primary   = Color(red: 0.07, green: 0.18, blue: 0.36)
    static let secondary = Color(red: 0.28, green: 0.45, blue: 0.76)
    static let accent    = Color(red: 0.37, green: 0.62, blue: 0.89)
    static let glow      = Color(red: 0.37, green: 0.62, blue: 0.89).opacity(0.6)
    
    static let backgroundGradient = LinearGradient(
        colors: [primary.opacity(0.98), secondary.opacity(0.6), Color.indigo.opacity(0.4)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let glass = Color.white.opacity(0.09)
    static let glassBorder = Color.white.opacity(0.15)
}

enum ButtonStyleType { case filled, outline }

struct ChatView: View {
    //@ObservedObject var chatViewModel: ChatViewModel
    @StateObject private var chatViewModel = ChatViewModel()
    
    @State private var city: String = ""
    @State private var stateProvince: String = ""
    @State private var zipCode: String = ""
    @State private var country: String = ""
    
    @State private var showPermissionModal = false
    
    @State private var selectedProfileTab: ProfileTab = .driveways

    private enum ProfileTab {
        case driveways
        case bookings
    }
    
    var onLogout: () -> Void
    
    @Namespace private var bottomID
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    topBar
                    conversationArea
                    inputPanel
                }
                
                overlays
            }
            .preferredColorScheme(.dark)
            .fullScreenCover(isPresented: $chatViewModel.showMyDriveways) {
                if selectedProfileTab == .driveways {
                    MyDrivewaysTab()
                } else {
                    MyBookingsTab() 
                }
            }
        }
    }
    
    // MARK: - Background (exact same as LoginView)
    private struct AnimatedGradientBackground: View {
        var body: some View {
            DriveBayTheme.backgroundGradient
                .animation(.linear(duration: 40).repeatForever(autoreverses: true), value: UUID())
        }
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DriveBay")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [.white, DriveBayTheme.accent], startPoint: .leading, endPoint: .trailing))
                    Text("Smart Parking • Driveways • Instant")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                Menu {
                    Button {
                        selectedProfileTab = .driveways
                        chatViewModel.showMyDriveways = true
                    } label: {
                        Label("My Driveway", systemImage: "house.fill")
                    }
                    Button {
                        selectedProfileTab = .bookings
                        chatViewModel.showMyDriveways = true
                    } label: {
                        Label("My Bookings", systemImage: "list.bullet.clipboard")
                    }
                    Divider()
                    Button("Logout", systemImage: "arrow.right.square") { onLogout() }
                } label: {
                    Image(systemName: "car.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(DriveBayTheme.primary.opacity(0.6)))
                        .background(Circle().fill(DriveBayTheme.glow).blur(radius: 24))
                        .overlay(Circle().stroke(DriveBayTheme.glow, lineWidth: 2))
                        .shadow(color: .black.opacity(0.5), radius: 7)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 15)
        }
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Conversation Area
    private var conversationArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    if chatViewModel.messages.isEmpty {
                        WelcomeCard {
                            Task { await chatViewModel.sendMessage("Show me all available driveways") }
                        }
                        .padding(.top, 40)
                    }
                    
                    ForEach(chatViewModel.messages) { msg in
                        MessageRow(message: msg)
                            .id(msg.id)
                    }
                    
                    if chatViewModel.isLoading {
                        AILoadingRow()
                    }
                    
                    Color.clear.frame(height: 30).id(bottomID)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .onChange(of: chatViewModel.messages.count) { _ in
                    withAnimation { proxy.scrollTo(bottomID, anchor: .bottom) }
                }
            }
        }
    }
    
    private struct MessageRow: View {
        let message: ChatMessage
        var isUser: Bool { message.role == .user }
        
        var body: some View {
            HStack {
                if isUser { Spacer(minLength: 60) }
                
                Text(message.content)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .padding(18)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.78, alignment: isUser ? .trailing : .leading)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(DriveBayTheme.glassBorder.opacity(0.6)))
                    .shadow(color: isUser ? DriveBayTheme.glow.opacity(0.4) : .black.opacity(0.2), radius: 12, y: 6)
                
                if !isUser { Spacer(minLength: 60) }
            }
        }
    }
    
    private struct AILoadingRow: View {
        var body: some View {
            HStack(spacing: 10) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(DriveBayTheme.accent)
                        .frame(width: 9, height: 9)
                        .scaleEffect(0.8 + 0.4 * CGFloat(sin(Double(i) * .pi / 1.5 + Date().timeIntervalSince1970)))
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.08))
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(DriveBayTheme.glow.opacity(0.4)))
            .shadow(color: DriveBayTheme.glow.opacity(0.5), radius: 12, y: 6)
        }
    }
    
    // MARK: - Input Panel (exact same glass style as Login/SignUp)
    private var inputPanel: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                GlassField(placeholder: "City", text: $city)
                GlassField(placeholder: "State", text: $stateProvince)
            }
            HStack(spacing: 12) {
                GlassField(placeholder: "Zip Code", text: $zipCode)
                GlassField(placeholder: "Country", text: $country)
            }
            
            HStack(spacing: 16) {
                ActionButton(icon: "location.circle.fill", label: "Near Me", style: .outline) {
                    chatViewModel.handleNearMeSearch()
                    if chatViewModel.permissionStatus != .granted {
                        withAnimation { showPermissionModal = true }
                    }
                }
                
                ActionButton(icon: "sparkles", label: "Find Parking", style: .filled) {
                    let query = [city, stateProvince, zipCode, country]
                        .filter { !$0.isEmpty }
                        .joined(separator: ", ")
                    guard !query.isEmpty else { return }
                    Task { await chatViewModel.sendMessage("Find parking in \(query)") }
                }
                .shadow(color: DriveBayTheme.glow.opacity(0.6), radius: 16, y: 8)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.08))
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(DriveBayTheme.glassBorder.opacity(0.6)))
        .shadow(color: .black.opacity(0.4), radius: 30, y: 15)
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }
    
    private struct GlassField: View {
        let placeholder: String
        @Binding var text: String
        
        var body: some View {
            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.5)))
                .padding(18)
                .background(Color.white.opacity(0.08))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(DriveBayTheme.glassBorder.opacity(0.6)))
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .medium, design: .rounded))
        }
    }
    
    private struct ActionButton: View {
        let icon: String
        let label: String
        let style: ButtonStyleType
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                Label(label, systemImage: icon)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .padding(.vertical, 16)
                    .frame(maxWidth: style == .filled ? .infinity : nil)
                    .padding(.horizontal, style == .filled ? 28 : 22)
                    .background(style == .filled ? DriveBayTheme.accent : Color.white.opacity(0.08))
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(style == .filled ? DriveBayTheme.accent.opacity(0.6) : DriveBayTheme.glassBorder.opacity(0.6), lineWidth: 1.5)
                    )
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
    
    private struct WelcomeCard: View {
        let onExplore: () -> Void
        var body: some View {
            VStack(spacing: 24) {
                Image(systemName: "parkingsign.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(DriveBayTheme.accent)
                    .shadow(color: DriveBayTheme.glow, radius: 20)
                
                VStack(spacing: 12) {
                    Text("Welcome to DriveBay")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                    Text("Instant private parking, driveways,\nand real-time availability.")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                
                Button("Explore Spots", action: onExplore)
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(DriveBayTheme.accent)
                    .cornerRadius(20)
                    .shadow(color: DriveBayTheme.glow, radius: 20)
            }
            .padding(32)
            .frame(maxWidth: 380)
            .background(Color.white.opacity(0.08))
            .cornerRadius(28)
            .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(DriveBayTheme.glassBorder))
            .shadow(color: .black.opacity(0.25), radius: 30, y: 15)
        }
    }
    
    private var overlays: some View {
        Group {
            if showPermissionModal {
                LocationPermissionModal(isPresented: $showPermissionModal)
            }
        }
    }
}

// Keep your existing supporting views (ScaleButtonStyle, LocationPermissionModal, etc.)
// They are already perfect

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

struct LocationPermissionModal: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(DriveBayTheme.accent)
                    .shadow(color: DriveBayTheme.glow, radius: 20)
                
                Text("Enable Location Access")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text("DriveBay needs your location to find parking spots near you. Choose 'Allow While Using App' or 'Always' in Settings.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 20)
                
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                    isPresented = false  // Close modal after opening Settings
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(DriveBayTheme.accent.opacity(0.8))
                .cornerRadius(16)
                .shadow(color: DriveBayTheme.glow, radius: 12)
                .padding(.horizontal, 40)
                
                Button("Cancel") { isPresented = false }
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(32)
            .background(Color.white.opacity(0.08))
            .cornerRadius(24)
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(DriveBayTheme.glassBorder.opacity(0.6)))
            .shadow(color: .black.opacity(0.4), radius: 30, y: 15)
            .frame(width: 340)
        }
    }
}

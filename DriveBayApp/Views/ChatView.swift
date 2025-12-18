import SwiftUI
import UIKit
import CoreLocation

// MARK: - DriveBay Theme
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
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
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
    @State private var showingProfile = false
    @State private var showingProfileSheet = false
    @StateObject private var profileViewModel = ProfileViewModel()
    
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
        .sheet(isPresented: $showingProfile) {
            ProfileView(onLogout: onLogout)
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
            VStack(spacing: 0) {
                // Content Container
                HStack {
                    // App Title and Subtitle
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DriveBay")
                            .font(.system(size: 28, weight: .black, design: .rounded)) // Slightly larger title
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, DriveBayTheme.accent, DriveBayTheme.secondary], // Richer gradient
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                            
                        Text("Smart Parking • Driveways • Instant")
                            .font(.caption) // Slightly smaller, cleaner font
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.leading, 10)

                    Spacer()
                    
                    // Menu Button (Custom Glass/Glow Design)
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
                        Button {
                                showingProfile = true  // Add @State private var showingProfile = false
                            } label: {
                                Label("Profile", systemImage: "person.circle.fill")
                            }
                        Divider()
                        Button("Logout", systemImage: "arrow.right.square") { onLogout() }
                    } label: {
                        // Custom Button Appearance
                        ZStack {
                            // Base Glass Circle
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 44, height: 44)
                                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                            
                            // Internal Glow (Subtle)
                            Circle()
                                .stroke(DriveBayTheme.glow.opacity(0.6), lineWidth: 1)
                                .frame(width: 44, height: 44)
                                .blur(radius: 5)
                            
                            // Icon
                            Image(systemName: "person.circle.fill") // Using person icon for profile/menu
                                .font(.title2)
                                .foregroundColor(DriveBayTheme.accent)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 15)

                }
                .padding(.top, 50) // Increased top padding to accommodate iPhone status bar notch
                .padding(.bottom, 12)
                
                // Bottom Separator Glow/Line
                Rectangle()
                    .fill(DriveBayTheme.glow.opacity(0.3))
                    .frame(height: 1)
            }
            // Background and Shadow for Floating Effect
            .background {
                ZStack {
                    // Material Background
                    Color.clear
                        .background(.ultraThinMaterial)
                    
                    // Top Light Gradient (to define the glass surface)
                    LinearGradient(
                        colors: [.white.opacity(0.1), .white.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
            .shadow(color: .black.opacity(0.2), radius: 10, y: 5) // Bottom shadow for floating effect
        }
    
    // MARK: - Conversation Area – FINAL LUXURY VERSION
    private var conversationArea: some View {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 24) { // Increased spacing slightly for breathability
                        if chatViewModel.messages.isEmpty {
                            WelcomeCard {
                                Task { await chatViewModel.sendMessage("Show me all available driveways") }
                            }
                            .padding(.top, 40)
                            .transition(.opacity)
                        }
                        
                        ForEach(chatViewModel.messages) { msg in
                            MessageRow(message: msg)
                                .id(msg.id)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        if chatViewModel.isLoading {
                            AILoadingRow()
                                .transition(.scale.combined(with: .opacity))
                        }
                        
                        Color.clear.frame(height: 40).id(bottomID)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .onChange(of: chatViewModel.messages.count) { _ in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            proxy.scrollTo(bottomID, anchor: .bottom)
                        }
                    }
                }
                .scrollIndicators(.hidden) // Cleaner look
            }
        }
    // MARK: - MessageRow View
        struct MessageRow: View {
            let message: ChatMessage
            
            @State private var isLoggedIn: Bool = true // Placeholder for actual login status
            
            private var isUser: Bool { message.role == .user }
            
            var body: some View {
                HStack {
                    if isUser { Spacer() }
                    
                    VStack(alignment: isUser ? .trailing : .leading, spacing: 8) {
                        
                        // 💡 CRITICAL LOGIC: Handle text content separately if listings are present
                        // This creates a smaller "Found X spots" bubble above the cards
                        if !message.content.isEmpty {
                            Text(message.content)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                                .multilineTextAlignment(isUser ? .trailing : .leading)
                                .background(
                                    isUser
                                        ? DriveBayTheme.accent.opacity(0.8) // User bubble color
                                        : Color.gray.opacity(0.25) // Model/System bubble color
                                )
                                // Use simple CornerRadius when content is purely text OR if listings are absent
                                .cornerRadius(18, corners: isUser ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight])
                                .foregroundColor(.white)
                        }

                        // --- B. RENDER LISTING CARDS (For "Near Me" results) ---
                        if let listings = message.listings, !listings.isEmpty {
                            ListingCarouselView(listings: listings, isLoggedIn: isLoggedIn) { listing in
                                                // This is the same action that was inside the old onBook closure
                                                if isLoggedIn {
                                                    print("Navigate to booking for \(listing.address)")
                                                }
                                            }
                        }
                    }
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.8, alignment: isUser ? .trailing : .leading)
                    
                    if !isUser { Spacer() }
                }
            }
        }
        // MARK: - Animated AI Loading Row
        private struct AILoadingRow: View {
            @State private var isAnimating = false
            
            var body: some View {
                HStack {
                    HStack(spacing: 6) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(DriveBayTheme.accent)
                                .frame(width: 8, height: 8)
                                .scaleEffect(isAnimating ? 1.0 : 0.5)
                                .opacity(isAnimating ? 1.0 : 0.5)
                                // Staggered animation for the "wave" effect
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                    value: isAnimating
                                )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(DriveBayTheme.glassBorder.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: DriveBayTheme.glow.opacity(0.2), radius: 8, x: 0, y: 4)
                    
                    Spacer()
                }
                .onAppear {
                    isAnimating = true
                }
            }
        }

        // MARK: - Custom Bubble Shape for Chat Tails
        private struct BubbleShape: Shape {
            let isUser: Bool
            
            func path(in rect: CGRect) -> Path {
                let cornerRadius: CGFloat = 20
                
                return Path { path in
                    // Start drawing
                    path.move(to: CGPoint(x: 0, y: 0))
                    
                    let corners: UIRectCorner = isUser
                        ? [.topLeft, .topRight, .bottomLeft]
                        : [.topLeft, .topRight, .bottomRight]
                    
                    let pathRef = UIBezierPath(
                        roundedRect: rect,
                        byRoundingCorners: corners,
                        cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
                    )
                    
                    path.addPath(Path(pathRef.cgPath))
                }
            }
        }
    
    // MARK: - Compact Floating Input Panel
        private var inputPanel: some View {
            VStack(spacing: 12) { // 1. Reduced spacing for a tighter layout
                // Location Inputs Row 1
                HStack(spacing: 10) {
                    GlassField(placeholder: "City", icon: "building.2.fill", text: $city)
                    GlassField(placeholder: "State", icon: "map.fill", text: $stateProvince)
                }
                
                // Location Inputs Row 2
                HStack(spacing: 10) {
                    GlassField(placeholder: "Zip Code", icon: "envelope.fill", text: $zipCode)
                    GlassField(placeholder: "Country", icon: "globe", text: $country)
                }
                
                // Action Buttons
                HStack(spacing: 12) {
                    // 'Near Me' Button
                    ActionButton(
                        icon: "location.circle.fill",
                        label: "Near Me",
                        style: .outline
                    ) {
                        chatViewModel.handleNearMeSearch()
                        if chatViewModel.permissionStatus != .granted {
                            withAnimation { showPermissionModal = true }
                        }
                    }
                    
                    // 'Find Parking' Button
                    ActionButton(
                        icon: "sparkles",
                        label: "Find Parking",
                        style: .filled
                    ) {
                        let query = [city, stateProvince, zipCode, country]
                            .filter { !$0.isEmpty }
                            .joined(separator: ", ")
                        guard !query.isEmpty else { return }
                        Task { await chatViewModel.sendMessage("Find parking in \(query)") }
                    }
                }
            }
            .padding(16) // 2. Reduced container padding
            // Advanced Glassmorphism Container
            .background {
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.95)
                    
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous)) // Slightly smaller corner radius
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .white.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.25), radius: 25, y: 10)
            .padding(.horizontal, 16)
            .padding(.bottom, 4) // 3. Pushed much closer to the bottom edge
        }
        
        // MARK: - Slim Glass Field
        private struct GlassField: View {
            let placeholder: String
            var icon: String? = nil
            @Binding var text: String
            
            var body: some View {
                HStack(spacing: 8) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.4)))
                        .font(.system(size: 14, weight: .medium, design: .rounded)) // Slightly smaller font
                        .foregroundColor(.white)
                }
                .padding(.vertical, 12) // Reduced vertical padding
                .padding(.horizontal, 12)
                .background(Color.black.opacity(0.2))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
        }
        
        // MARK: - Compact Action Button
        private struct ActionButton: View {
            let icon: String
            let label: String
            let style: ButtonStyleType
            let action: () -> Void
            
            var body: some View {
                Button(action: action) {
                    HStack(spacing: 6) {
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .bold))
                        Text(label)
                            .font(.system(size: 14, weight: .bold, design: .rounded)) // Slightly smaller font
                    }
                    .frame(maxWidth: style == .filled ? .infinity : nil)
                    .padding(.vertical, 14) // Reduced vertical padding
                    .padding(.horizontal, style == .filled ? 16 : 14)
                    .background {
                        if style == .filled {
                            LinearGradient(
                                colors: [DriveBayTheme.accent, DriveBayTheme.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            Color.white.opacity(0.08)
                        }
                    }
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        if style == .outline {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                        }
                    }
                    .shadow(
                        color: style == .filled ? DriveBayTheme.accent.opacity(0.4) : .clear,
                        radius: 8, x: 0, y: 4
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    // MARK: - Premium Welcome Card
    private struct WelcomeCard: View {
        let onExplore: () -> Void
        
        var body: some View {
            VStack(spacing: 20) {
                // Ultra-sharp icon with inner + outer glow
                ZStack {
                    Circle()
                        .fill(DriveBayTheme.glow.opacity(0.4))
                        .frame(width: 100, height: 100)
                        .blur(radius: 20)
                    
                    Image(systemName: "parkingsign.circle.fill")
                        .font(.system(size: 56, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [DriveBayTheme.accent, DriveBayTheme.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: DriveBayTheme.glow, radius: 12)
                }
                .frame(height: 100)
                
                VStack(spacing: 8) {
                    Text("Welcome to")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("DriveBay")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
                    
                    Text("Private parking spots, real-time, in your chat.")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .padding(.horizontal, 20)
                
                Button(action: onExplore) {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                        Text("Explore Spots")
                    }
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 36)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [DriveBayTheme.accent, DriveBayTheme.secondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(DriveBayTheme.glow.opacity(0.6), lineWidth: 2)
                    )
                    .shadow(color: DriveBayTheme.glow.opacity(0.8), radius: 16, y: 6)
                }
                .buttonStyle(.plain)
            }
            .padding(32)
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(DriveBayTheme.glassBorder.opacity(0.5), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 30, y: 15)
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

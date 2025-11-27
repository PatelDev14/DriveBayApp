import SwiftUI
import CoreLocation

// MARK: - DriveBay Theme (Improved)
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

// MARK: - Button Style Enum (Was missing!)
enum ButtonStyleType {
    case filled, outline
}

// MARK: - MAIN CHAT VIEW (BEAUTIFUL + COMPILABLE)
struct ChatView: View {
    @ObservedObject var chatViewModel: ChatViewModel
    
    @State private var city: String = ""
    @State private var stateProvince: String = ""
    @State private var zipCode: String = ""
    @State private var country: String = ""
    
    @State private var listingToBook: String? = nil
    @State private var showPermissionModal: Bool = false
    @State private var showAccountMenu: Bool = false
    @State private var showingListingForm = false
    
    var onLogout: () -> Void

    
    @Namespace private var bottomID
    
    var body: some View {
        ZStack {
            AnimatedBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                topBar
                conversationArea
                floatingInputPanel
            }
            
            overlays
        }
        //.preferredColorScheme(.dark)
        .preferredColorScheme(.dark)
                .sheet(isPresented: $showingListingForm) {          
                    ListingFormView()
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                }
    }
    
    // MARK: - Animated Background
    struct AnimatedBackground: View {
        var body: some View {
            DriveBayTheme.backgroundGradient
                .animation(
                    Animation.linear(duration: 30).repeatForever(autoreverses: true),
                    value: UUID()
                )
        }
    }
    
    // MARK: - Top Bar
    var topBar: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DriveBay")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [.white, DriveBayTheme.accent], startPoint: .leading, endPoint: .trailing)
                        )
                    Text("Smart Parking • Driveways • Instant")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                Menu {
                                // Menu Items (These remain the same)
                                Button("My Bookings", systemImage: "list.bullet.clipboard") {
                                    print("My Bookings tapped")
                                }
                                
//                                Button("My Driveway", systemImage: "house.fill") {
//                                    print("My Driveway tapped")
//                                }
                    Button {
                        showingListingForm = true
                    } label: {
                        Label("My Driveway", systemImage: "house.fill")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                    }
                                
                                Divider()
                                
                                Button("Logout", systemImage: "arrow.right.square") {
                                    // TODO: Implement logout logic
                                    onLogout()
                                    print("Logout tapped")
                                }
                                
                            } label: {
                                // The visual icon (your existing car icon code)
                                Image(systemName: "car.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    // Apply a slightly darker/more opaque background to make it stand out
                                    .background(Circle().fill(DriveBayTheme.primary.opacity(0.6)))
                                    .background(Circle().fill(DriveBayTheme.glow).blur(radius: 24))
                                    .overlay(Circle().stroke(DriveBayTheme.glow, lineWidth: 2))
                                    .shadow(color: .black.opacity(0.5), radius: 7, x: 0, y: 3) // Add a subtle shadow
                            }
                            // 💡 FIX: Apply a standard button style to the Menu label for press effect
                            .buttonStyle(.plain)
                            
                        }
                        .padding(.horizontal, 15)
                    }
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Conversation Area
    var conversationArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 20) {
                    if chatViewModel.messages.isEmpty {
                        WelcomeCard {
                            chatViewModel.executeSearch(query: "Show me all available driveways")
                        }
                        .padding(.top, 40)
                    }
                    
                    ForEach(chatViewModel.messages) { msg in
                        MessageBubble(message: msg)
                            .id(msg.id)
                    }
                    
                    if chatViewModel.isLoading {
                        LoadingBubble()
                    }
                    
                    Color.clear.frame(height: 30).id(bottomID)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .onChange(of: chatViewModel.messages.count) { _ in
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        proxy.scrollTo(bottomID, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Floating Input Panel
    var floatingInputPanel: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                GlassTextField(placeholder: "City", text: $city)
                GlassTextField(placeholder: "State", text: $stateProvince)
            }
            HStack(spacing: 12) {
                GlassTextField(placeholder: "Zip Code", text: $zipCode)
                GlassTextField(placeholder: "Country", text: $country)
            }
            
            HStack(spacing: 16) {
                ActionButton(icon: "location.circle.fill", label: "Near Me", style: .outline) {
                    chatViewModel.handleNearMeSearch(requestPermissionAction: {
                        withAnimation { showPermissionModal = true }
                    })
                }
                
                ActionButton(icon: "sparkles", label: "Find Parking", style: .filled) {
                    chatViewModel.handleFormSearch(
                        city: city,
                        state: stateProvince,
                        zipCode: zipCode,
                        country: country
                    )
                }
                .shadow(color: DriveBayTheme.accent.opacity(0.5), radius: 12, y: 6)
            }
        }
        .padding(15)
        .background(.ultraThinMaterial)
        .background(DriveBayTheme.glass)
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(DriveBayTheme.glassBorder))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
        .padding(.top, 10)
    }
    
    // MARK: - Glass TextField
    struct GlassTextField: View {
        let placeholder: String
        @Binding var text: String
        var body: some View {
            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.5)))
                .padding(14)
                .background(DriveBayTheme.glass)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(DriveBayTheme.glassBorder))
                .foregroundColor(.white)
                .font(.system(size: 15, weight: .medium, design: .rounded))
        }
    }
    
    // MARK: - Action Button (Fixed!)
    struct ActionButton: View {
        let icon: String
        let label: String
        let style: ButtonStyleType
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                Label(label, systemImage: icon)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .padding(.vertical,14)
                    .frame(maxWidth: style == .filled ? .infinity : nil)
                    .padding(.horizontal,style == .filled ? 24 : 20)
                    .background(style == .filled ? DriveBayTheme.accent.opacity(0.3) : DriveBayTheme.glass)
                    .foregroundColor(.white)
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                style == .filled ? DriveBayTheme.accent.opacity(0.6) : DriveBayTheme.glassBorder,
                                lineWidth: style == .filled ? 1.5 : 1
                            )
                    )
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
    
    // MARK: - Welcome Card
    struct WelcomeCard: View {
        let onExplore: () -> Void
        var body: some View {
            VStack(spacing: 24) {
                Image(systemName: "parkingsign.circle.fill")
                    .font(.system(size: 50))
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
                
                Button("Explore Spots") {
                    withAnimation { onExplore() }
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(DriveBayTheme.accent.opacity(0.3))
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(DriveBayTheme.accent.opacity(0.6), lineWidth: 1.5))
                .shadow(color: DriveBayTheme.accent.opacity(0.5), radius: 15)
            }
            .padding(32)
            .frame(maxWidth: 380)
            .background(.ultraThinMaterial)
            .cornerRadius(28)
            .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(DriveBayTheme.glassBorder))
            .shadow(color: .black.opacity(0.25), radius: 30, y: 15)
        }
    }
    
    // MARK: - Message Bubble
    struct MessageBubble: View {
        let message: ChatMessage
        var isUser: Bool { message.role == .user }
        
        var body: some View {
            HStack {
                if isUser { Spacer(minLength: 60) }
                
                Text(message.content)
                    .padding(16)
                    .background(
                        Capsule(style: .continuous)
                            .fill(isUser ? DriveBayTheme.secondary.opacity(0.4) : DriveBayTheme.glass)
                            .overlay(Capsule().stroke(DriveBayTheme.glassBorder, lineWidth: 1))
                    )
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: isUser ? .trailing : .leading)
                
                if !isUser { Spacer(minLength: 60) }
            }
        }
    }
    
    // MARK: - Loading Indicator
    struct LoadingBubble: View {
        var body: some View {
            HStack(spacing: 8) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(DriveBayTheme.accent)
                        .frame(width: 8, height: 8)
                        .scaleEffect(0.8 + 0.3 * sin(Double(i) * .pi / 1.5))
                        .animation(.easeInOut(duration: 0.6).repeatForever().delay(Double(i) * 0.15), value: UUID())
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
        }
    }
    
    // MARK: - Overlays
    var overlays: some View {
        Group {
            if showPermissionModal {
                LocationPermissionModal(isPresented: $showPermissionModal)
            }
            if let listingName = listingToBook {
                // Simple fallback modal (replace with your real one later)
                ModalOverlay(title: "Booking: \(listingName)") {
                    listingToBook = nil
                }
            }
        }
    }
}

// MARK: - Simple Modal (Replaces missing BookingConfirmationModal)
struct ModalOverlay: View {
    let title: String
    let onClose: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 20) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Button("Close") {
                    onClose()
                }
                .padding()
                .frame(width: 200)
                .background(DriveBayTheme.accent.opacity(0.4))
                .foregroundColor(.white)
                .cornerRadius(16)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .cornerRadius(24)
            .frame(width: 320)
            .shadow(radius: 20)
        }
    }
}

// MARK: - Location Permission Modal
struct LocationPermissionModal: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "location.slash.circle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.orange)
                
                Text("Location Access Required")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text("DriveBay needs your location to find parking near you.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.8))
                
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.8))
                .cornerRadius(16)
                .padding(.horizontal, 40)
                
                Button("Cancel") { isPresented = false }
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .cornerRadius(24)
            .frame(width: 340)
        }
    }
}

// MARK: - Button Press Animation
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

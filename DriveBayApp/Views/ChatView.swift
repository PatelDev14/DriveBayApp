// ChatView.swift
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

// MARK: - Theme
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

// MARK: - Global Types
enum ProfileTab {
    case driveways, bookings, requests
}

private enum SheetType: Identifiable {
    case booking(Listing)
    case profile
    case dashboard(ProfileTab)
    
    var id: String {
        switch self {
        case .booking(let l):
            return "booking-\(l.id ?? UUID().uuidString)"
        case .profile:
            return "profile"
        case .dashboard(let tab):
            return "dashboard-\(tab)"
        }
    }
}

// MARK: - Main View
struct ChatView: View {
    @StateObject private var chatViewModel = ChatViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()
    
    @State private var showPermissionModal = false
    @State private var showingSearch = false
    @State private var activeSheet: SheetType?
    
    var onLogout: () -> Void
    @Namespace private var bottomID
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    topBar
                    
                    ScrollView {
                        VStack(spacing: 32) {
                            heroWelcomeSection
                            quickActionsSection
                            
                            if !chatViewModel.messages.isEmpty {
                                conversationArea
                            } else {
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                overlays
            }
            .preferredColorScheme(.dark)
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .booking(let listing):
                    BookingRequestView(listing: listing)
                    
                case .profile:
                    ProfileView(onLogout: onLogout)
                    
                case .dashboard(let tab):
                    DashboardHostView(selectedTab: tab)
                }
            }
            .fullScreenCover(isPresented: $showingSearch) {
                DrivewaysSearchView()
            }
        }
    }
    
    // MARK: - Subviews
    private var topBar: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DriveBay")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, DriveBayTheme.accent, DriveBayTheme.secondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                    
                    Text("Smart Parking • Driveways • Instant")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.leading, 10)
                
                Spacer()
                
                userMenu
            }
            .padding(.top, 50)
            .padding(.bottom, 12)
            
            Rectangle()
                .fill(DriveBayTheme.glow.opacity(0.3))
                .frame(height: 1)
        }
        .background(.ultraThinMaterial)
        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
    }
    
    private var userMenu: some View {
        Menu {
            Button {
                activeSheet = .profile
            } label: {
                Label("Profile", systemImage: "person.circle.fill")
            }
            Divider()
            Button("Logout", systemImage: "arrow.right.square") { onLogout() }
        } label: {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 44)
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                
                Circle()
                    .stroke(DriveBayTheme.glow.opacity(0.6), lineWidth: 1)
                    .frame(width: 44, height: 44)
                    .blur(radius: 5)
                
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(DriveBayTheme.accent)
            }
        }
        .padding(.trailing, 15)
    }

    private var heroWelcomeSection: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(DriveBayTheme.glow.opacity(0.4))
                    .frame(width: 140, height: 140)
                    .blur(radius: 30)
            
                Image("DriveBay")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 110, height: 110)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(DriveBayTheme.glow, lineWidth: 4)
                        )
                        .shadow(color: DriveBayTheme.glow, radius: 20, y: 10)
                }
            
            VStack(spacing: 12) {
                Text("Welcome to DriveBay")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Instant private parking • Driveways • Real-time availability")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
        .padding(.top, 40)
    }

    private var quickActionsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                CompactActionCard(
                    icon: "magnifyingglass.circle.fill",
                    title: "Search Driveways",
                    subtitle: "Find spots instantly",
                    gradientColors: [DriveBayTheme.accent, DriveBayTheme.secondary]
                ) {
                    showingSearch = true
                }
                
                CompactActionCard(
                    icon: "house.fill",
                    title: "List Driveway",
                    subtitle: "Earn money easily",
                    gradientColors: [.purple, .indigo]
                ) {
                    activeSheet = .dashboard(.driveways)
                }
            }
            
            HStack(spacing: 16) {
                CompactActionCard(
                    icon: "list.bullet.clipboard",
                    title: "My Bookings",
                    subtitle: "View your reservations",
                    gradientColors: [.teal, .blue]
                ) {
                    activeSheet = .dashboard(.bookings)
                }
                
                CompactActionCard(
                    icon: "bell.fill",
                    title: "Incoming Requests",
                    subtitle: "Approve or reject",
                    gradientColors: [.orange, .red]
                ) {
                    activeSheet = .dashboard(.requests)
                }
            }
        }
    }
    
    private struct CompactActionCard: View {
        let icon: String
        let title: String
        let subtitle: String
        let gradientColors: [Color]
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(
                            Circle()
                                .fill(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                                .shadow(color: gradientColors.first?.opacity(0.6) ?? .clear, radius: 12)
                        )
                    
                    VStack(spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.white.opacity(0.08))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(DriveBayTheme.glassBorder.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    private var conversationArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 24) {
                    ForEach(chatViewModel.messages) { msg in
                        MessageRowView(message: msg, isLoggedIn: true) { selectedListing in
                            activeSheet = .booking(selectedListing)
                        }
                        .id(msg.id)
                    }
                    
                    if chatViewModel.isLoading {
                        AILoadingRow()
                    }
                    
                    Color.clear.frame(height: 40).id(bottomID)
                }
                .padding(.top, 20)
                .onChange(of: chatViewModel.messages.count) { _ in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        proxy.scrollTo(bottomID, anchor: .bottom)
                    }
                }
            }
            .scrollIndicators(.hidden)
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

// MARK: - Dashboard Host

struct DashboardHostView: View {
    let selectedTab: ProfileTab

    var body: some View {
        Group {
            switch selectedTab {
            case .driveways:
                MyDrivewaysTab()
            case .bookings:
                MyBookingsTab()
            case .requests:
                RequestsView(listing: .none)
            }
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed ? 0.94 : 1.0).animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

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
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(Double(index) * 0.2), value: isAnimating)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(DriveBayTheme.glassBorder.opacity(0.3), lineWidth: 1))
            Spacer()
        }.onAppear { isAnimating = true }
    }
}

private struct LocationPermissionModal: View {
    @Binding var isPresented: Bool
    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "location.circle.fill").font(.system(size: 70)).foregroundColor(DriveBayTheme.accent).shadow(color: DriveBayTheme.glow, radius: 20)
                Text("Enable Location Access").font(.title2.bold()).foregroundColor(.white)
                Text("DriveBay needs your location to find parking spots near you.").multilineTextAlignment(.center).foregroundColor(.white.opacity(0.8)).padding(.horizontal, 20)
                Button("Open Settings") { if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }; isPresented = false }.font(.headline).foregroundColor(.white).padding().frame(maxWidth: .infinity).background(DriveBayTheme.accent.opacity(0.8)).cornerRadius(16).shadow(color: DriveBayTheme.glow, radius: 12).padding(.horizontal, 40)
                Button("Cancel") { isPresented = false }.foregroundColor(.white.opacity(0.7))
            }
            .padding(32).background(Color.white.opacity(0.08)).cornerRadius(24).overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(DriveBayTheme.glassBorder.opacity(0.6))).shadow(color: .black.opacity(0.4), radius: 30, y: 15).frame(width: 340)
        }
    }
}

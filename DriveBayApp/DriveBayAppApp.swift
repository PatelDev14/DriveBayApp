import SwiftUI
import FirebaseCore
import FirebaseAppCheck
// MARK: - App Configuration

// Real placeholder listings (auto ID thanks to your Listing init in DataModels.swift)
private let placeholderListings: [Listing] = [
    Listing(
        ownerId: "dummy1",
        address: "123 Ocean Drive",
        city: "Miami",
        state: "FL",
        zipCode: "33139",
        country: "USA",
        description: "Prime beachfront parking",
        rate: 8.0,
        date: Date(), // Must provide a Date for the struct to compile
        startTime: "09:00",
        endTime: "18:00",
        contactEmail: "miami@example.com"
    ),
    Listing(
        ownerId: "dummy2",
        address: "456 Palm Avenue",
        city: "Los Angeles",
        state: "CA",
        zipCode: "90210",
        country: "USA",
        description: "Downtown spot",
        rate: 12.0,
        date: Date(), // Must provide a Date for the struct to compile
        startTime: "08:00",
        endTime: "20:00",
        contactEmail: "la@example.com"
    )
]

@main
struct DriveBayAppApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var chatViewModel = ChatViewModel()

    init() {
        // 1. Configure Firebase services immediately
        FirebaseApp.configure()
        #if DEBUG
        let providerFactory = AppCheckDebugProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        #endif
        
        // 2. Define the static booking handler for the ViewModel
        let bookingHandler: (Listing, Date, Date) async throws -> Void = { listing, start, end in
            print("Booking requested for \(listing.address) from \(start) to \(end)")
        }
        
        // 3. Initialize the StateObject wrapper with the configured ViewModel
        _chatViewModel = StateObject(wrappedValue: ChatViewModel())
    }

    var body: some Scene {
        WindowGroup {
            // Use the authentication state to switch between views
            if authService.isLoggedIn {
                ChatView(
                    //chatViewModel: chatViewModel,
                    // Sign-out logic handles the async call safely
                    onLogout: {
                        Task {
                            do {
                                try authService.signOut()
                            } catch {
                                // Provide user feedback on sign-out failure
                                print("Sign out failed: \(error)")
                            }
                        }
                    }
                )
                .environmentObject(authService)
            } else {
                LoginView()
                    .environmentObject(authService)
            }
        }
    }
}

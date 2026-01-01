// DriveBayApp.swift
import SwiftUI
import FirebaseCore
import FirebaseAppCheck
import StripePaymentSheet

// MARK: - App Configuration
private let placeholderListings: [Listing] = []

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
        
        // 2. Set Stripe Publishable Key from Info.plist
        if let publishableKey = Bundle.main.object(forInfoDictionaryKey: "StripePublishableKey") as? String {
            StripeAPI.defaultPublishableKey = publishableKey
            print("Stripe publishable key loaded successfully")
        } else {
            print("WARNING: StripePublishableKey not found in Info.plist")
        }
        
        _chatViewModel = StateObject(wrappedValue: ChatViewModel())
    }

    var body: some Scene {
        WindowGroup {
            if authService.isLoggedIn {
                ChatView(onLogout: {
                    Task {
                        do {
                            try authService.signOut()
                        } catch {
                            print("Sign out failed: \(error)")
                        }
                    }
                })
                .environmentObject(authService)
            } else {
                LoginView()
                    .environmentObject(authService)
            }
        }
    }
}

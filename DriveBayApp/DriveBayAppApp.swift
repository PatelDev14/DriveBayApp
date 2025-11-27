//import SwiftUI
//import FirebaseCore
//
//@main
//struct DriveBayAppApp: App {
//    @StateObject private var authService = AuthService()
//    @StateObject private var chatViewModel: ChatViewModel
//
//    private static let placeholderListings: [Listing] = []
//
//    // 1. Make this static so it does not depend on `self`
//    private static func handleBookingRequestStatic(
//        listing: Listing,
//        startTime: Date,
//        endTime: Date
//    ) async throws {
//        print("Booking requested for \(listing.name) from \(startTime) to \(endTime)")
//        // Example: try await BookingService.submitBooking(listing, startTime, endTime)
//    }
//
//    init() {
//        FirebaseApp.configure()
//
//        // 2. Local closure that does NOT capture `self`
//        let bookingHandler: (Listing, Date, Date) async throws -> Void = { listing, start, end in
//            try await DriveBayAppApp.handleBookingRequestStatic(
//                listing: listing,
//                startTime: start,
//                endTime: end
//            )
//        }
//
//        // 3. Safe StateObject initialization
//        _chatViewModel = StateObject(
//            wrappedValue: ChatViewModel(
//                marketplaceListings: DriveBayAppApp.placeholderListings,
//                requestBooking: bookingHandler
//            )
//        )
//    }
//
//    var body: some Scene {
//        WindowGroup {
//            if authService.isLoggedIn {
//                ChatView(chatViewModel: chatViewModel)
//                    .environmentObject(authService)
//            } else {
//                LoginView()
//                    .environmentObject(authService)
//            }
//        }
//    }
//}

import SwiftUI
import FirebaseCore

@main
struct DriveBayAppApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var chatViewModel: ChatViewModel

    private static let placeholderListings: [Listing] = []

    private static func handleBookingRequestStatic(
        listing: Listing,
        startTime: Date,
        endTime: Date
    ) async throws {
        print("Booking requested for \(listing.name) from \(startTime) to \(endTime)")
        // Example: try await BookingService.submitBooking(listing, startTime, endTime)
    }

    init() {
        FirebaseApp.configure()

        let bookingHandler: (Listing, Date, Date) async throws -> Void = { listing, start, end in
            try await DriveBayAppApp.handleBookingRequestStatic(
                listing: listing,
                startTime: start,
                endTime: end
            )
        }

        _chatViewModel = StateObject(
            wrappedValue: ChatViewModel(
                marketplaceListings: DriveBayAppApp.placeholderListings,
                requestBooking: bookingHandler
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            // ⭐️ FIX: Correct if-else syntax for the ViewBuilder ⭐️
            if authService.isLoggedIn {
                // Pass the chatViewModel and provide the correct action closure for onLogout
                ChatView(chatViewModel: chatViewModel, onLogout: {
                    authService.isLoggedIn = false
                })
                .environmentObject(authService) // Apply modifier to the view
            } else {
                LoginView()
                    .environmentObject(authService)
            }
        }
    }
}

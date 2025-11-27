// ChatViewModel.swift

import SwiftUI
import Combine
import CoreLocation


class ChatViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading: Bool = false
    @Published var permissionStatus: PermissionState = "prompt"
    @Published var listingToBook: String? = nil
    
    // Populated by your main app or passed in initialization
    let marketplaceListings: [Listing]
    
    // Placeholder for your booking logic
    let requestBooking: (Listing, Date, Date) async throws -> Void

    private let locationManager = CLLocationManager()
    
    init(marketplaceListings: [Listing],
         requestBooking: @escaping (Listing, Date, Date) async throws -> Void) {
        self.marketplaceListings = marketplaceListings
        self.requestBooking = requestBooking
        super.init()
        locationManager.delegate = self
        checkLocationPermission()
    }
    
    // MARK: - Message Helpers
    
    func addSystemChatMessage(content: String) {
        let message = ChatMessage(role: .system, content: content, timestamp: Date())
        DispatchQueue.main.async {
            self.messages.append(message)
        }
    }
    
    // MARK: - Search Execution
    
    func executeSearch(query: String) {
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading { return }

        let userMessage = ChatMessage(role: .user, content: query, timestamp: Date())
        DispatchQueue.main.async {
            self.messages.append(userMessage)
            self.isLoading = true
        }

        Task {
            // PLACEHOLDER: Simulate a delay and a successful JSON response
            try await Task.sleep(for: .seconds(2))
            let placeholderContent = """
            {"marketplaceResults": [{"name": "Driveway 1", "address": "123 Main St", "details": "Available 24/7", "website": null, "listingId": "1"}, {"name": "Driveway 2", "address": "456 Oak Ave", "details": "Nights only", "website": null, "listingId": "2"}], "webResults": [{"name": "City Garage", "address": "789 Central Blvd", "details": "Daily rates", "website": "https://cityparking.com", "listingId": null}]}
            """
            let botMessage = ChatMessage(
                role: .model,
                content: placeholderContent,
                timestamp: Date()
            )
            DispatchQueue.main.async {
                self.messages.append(botMessage)
                self.isLoading = false
            }
        }
    }
    
    func handleFormSearch(city: String, state: String, zipCode: String, country: String) {
        if city.isEmpty && state.isEmpty && zipCode.isEmpty {
            addSystemChatMessage(content: "Please fill out at least one location field to search.")
            return
        }
        let query = "Find parking in \(city), \(state) \(zipCode), \(country)"
        executeSearch(query: query)
    }
    
    // MARK: - Location Logic
    
    private func checkLocationPermission() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            permissionStatus = "granted"
        case .denied, .restricted:
            permissionStatus = "denied"
        case .notDetermined:
            permissionStatus = "prompt"
        @unknown default:
            permissionStatus = "denied"
        }
    }
    
    func fetchLocationAndSearch() {
        isLoading = true
        locationManager.requestLocation() // This will trigger the delegate methods below
    }

    func handleNearMeSearch(requestPermissionAction: () -> Void) {
        checkLocationPermission()
        
        if permissionStatus == "granted" {
            fetchLocationAndSearch()
        } else {
            requestPermissionAction()
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let query = "Find parking near me (latitude: \(location.coordinate.latitude.toFixed(4)), longitude: \(location.coordinate.longitude.toFixed(4)))"
        executeSearch(query: query)
        permissionStatus = "granted" // Update status on successful fetch
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError, clError.code == .denied {
            addSystemChatMessage(content: "It looks like you've denied location permissions. You can change this in your settings if you'd like to use the 'Near Me' feature.")
            permissionStatus = "denied"
        } else {
            addSystemChatMessage(content: "I couldn't get your location. Please try again.")
        }
        isLoading = false
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationPermission()
    }
}

// Helper Extension for simple formatting (like the React toFixed(4))
extension Double {
    func toFixed(_ places: Int) -> String {
        return String(format: "%.\(places)f", self)
    }
}

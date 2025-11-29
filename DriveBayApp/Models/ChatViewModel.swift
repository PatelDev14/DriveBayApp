// ViewModels/ChatViewModel.swift
import SwiftUI
import CoreLocation
import FirebaseAuth
import FirebaseFirestore
import Combine

class ChatViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var permissionStatus: PermissionState = .prompt
    @Published var listingToBook: String? = nil
    @Published var showMyDriveways = false
    
    let marketplaceListings: [Listing]
    let requestBooking: (Listing, Date, Date) async throws -> Void
    
    private let locationManager = CLLocationManager()
    private let geminiService = GeminiService()  // This now works perfectly
    
    init(
        marketplaceListings: [Listing] = [],
        requestBooking: @escaping (Listing, Date, Date) async throws -> Void = { _, _, _ in }
    ) {
        self.marketplaceListings = marketplaceListings
        self.requestBooking = requestBooking
        super.init()
        locationManager.delegate = self
        checkLocationPermission()
    }
    
    // MARK: - Send Message (Uses real Gemini 1.5 Flash)
    func sendMessage(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(role: .user, content: text, timestamp: Date())
        await MainActor.run {
            messages.append(userMessage)
            isLoading = true
        }
        
        let listingsContext = marketplaceListings.map {
            "• \($0.address), \($0.city) \($0.state) — $\($0.rate)/hr (\($0.startTime)–\($0.endTime))"
        }.joined(separator: "\n")
        
        let fullPrompt = """
        You are DriveBay AI — a friendly parking assistant.
        
        Available driveways:
        \(listingsContext.isEmpty ? "No spots listed yet." : listingsContext)
        
        User: \(text)
        
        Respond naturally and helpfully. If the user wants to book, end your reply with:
        BOOK_NOW:\(UUID().uuidString)
        Keep replies short, warm, and under 3 sentences.
        """
        
        do {
            let response = try await geminiService.generateResponse(prompt: fullPrompt)  // WORKS NOW
            
            let botMessage = ChatMessage(role: .model, content: response, timestamp: Date())
            
            await MainActor.run {
                messages.append(botMessage)
                isLoading = false
                
                if response.contains("BOOK_NOW:") {
                    if let listing = marketplaceListings.first {
                        listingToBook = listing.id
                    }
                }
            }
        } catch {
            await MainActor.run {
                messages.append(ChatMessage(
                    role: .system,
                    content: "Sorry, I'm having trouble connecting right now. Try again!",
                    timestamp: Date()
                ))
                isLoading = false
            }
        }
    }
    
    // MARK: - Near Me
    func handleNearMeSearch() {
        if permissionStatus == .granted {
            fetchLocationAndSearch()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    private func fetchLocationAndSearch() {
        isLoading = true
        locationManager.requestLocation()
    }
    
    // MARK: - Location Delegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task {
            await sendMessage("Find parking near me at \(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            messages.append(ChatMessage(role: .system, content: "Couldn't get location. Try typing a city!", timestamp: Date()))
            isLoading = false
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationPermission()
    }
    
    private func checkLocationPermission() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            permissionStatus = .granted
        case .denied, .restricted:
            permissionStatus = .denied
        default:
            permissionStatus = .prompt
        }
    }
}

// MARK: - Supporting Types (Must be in this file or imported)
struct ChatMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    let content: String
    let timestamp: Date
}

enum MessageRole { case user, model, system }

enum PermissionState: String { case prompt, granted, denied }

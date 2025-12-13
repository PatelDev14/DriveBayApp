import SwiftUI
import CoreLocation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class ChatViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var permissionStatus: PermissionState = .prompt
    @Published var showMyDriveways = false
    @Published var showPermissionModal = false
    @Published var isSearchingNearby = false

    private let locationManager = CLLocationManager()
    private let geminiService = GeminiService()
    private let mapKitManager = MapKitManager()

    private var authListenerHandle: AuthStateDidChangeListenerHandle?
    private var currentUserID: String?

    // Real listings for Gemini context
    @Published private var realListings: [Listing] = []

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        checkLocationPermission()
        loadRealListings()
        startListeningToAuthChanges()
        setupAppTerminationObserver()
    }

    // MARK: - Load All Listings (for Gemini AI context)
    private func loadRealListings() {
        Firestore.firestore()
            .collection("listings")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                
                // --- CRITICAL CHANGE: Manual Decoding and ID Assignment ---
                let listings: [Listing] = docs.compactMap { doc in
                    // 1. Attempt to decode the document data into a Listing
                    // NOTE: This requires all Listing fields to be present/optional in Firestore.
                    guard var listing = try? doc.data(as: Listing.self) else { return nil }
                    
                    // 2. Manually set the ID from the Firestore document ID
                    listing.id = doc.documentID
                    return listing
                }
                // -----------------------------------------------------------
                
                DispatchQueue.main.async {
                    self?.realListings = listings
                }
            }
    }

    // MARK: - Send Regular Message to Gemini (UPDATED: Checks for location search)
    func sendMessage(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let userMessage = ChatMessage(role: .user, content: text, timestamp: Date())
        messages.append(userMessage)
        isLoading = true
        
        // --- 1. Prepare Gemini Prompt ---
        let listingsContext = realListings.isEmpty
            ? "No driveways listed yet."
            : realListings.map {
                "• \($0.address), \($0.city) \($0.state) — $\(String(format: "%.2f", $0.rate))/hr"
            }.joined(separator: "\n")

        let fullPrompt = """
        You are DriveBay AI — a friendly, expert parking assistant.

        Available driveways (REAL listings):
        \(listingsContext)

        User asked: "\(text)"

        INSTRUCTION: 
        1. If the user is asking for parking spots, respond with a friendly message and include the special token at the END: [ATTACH_LISTINGS_FOR:[Location Name]]
        2. The token MUST NOT be visible to the user.
        3. If nothing matches, or if it's a general question, just respond normally.
        4. Keep replies short and warm.
        """

        // --- 2. Call Gemini and Process Response ---
        var cleanedResponse: String = ""
        var listingsToAttach: [Listing]? = nil
        let tokenPattern = "\\[ATTACH_LISTINGS_FOR:(.*?)\\]"

        do {
            let response = try await geminiService.generateResponse(prompt: fullPrompt)
            cleanedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)

            // --- 3. Token Check and Filtering (Priority 1) ---
            if let range = response.range(of: tokenPattern, options: .regularExpression) {
                let token = String(response[range])
                
                // Extract the location from the token
                if let locRange = token.range(of: "(?<=\\[ATTACH_LISTINGS_FOR:).*?(?=\\])", options: .regularExpression),
                   let locationQuery = String(token[locRange]).lowercased().components(separatedBy: CharacterSet.punctuationCharacters).first {
                    
                    // • EXPANDED FILTER: Include City, State, Address, and Country
                    listingsToAttach = realListings.filter { listing in
                        let lowercasedListingInfo = "\(listing.address) \(listing.city) \(listing.state) \(listing.country)".lowercased()
                        return lowercasedListingInfo.contains(locationQuery)
                    }.prefix(5).map { $0 }
                }
                
                // Remove the token from the response
                cleanedResponse = response.replacingOccurrences(of: tokenPattern, with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
        } catch {
            cleanedResponse = "Sorry, I'm having trouble connecting right now."
            // We skip all filtering if the network call fails
        }

        // --- 4. Local Keyword Fallback (Priority 2: Only if Token failed or yielded zero) ---
        // • Add a local keyword-based fallback filter
        if (listingsToAttach == nil || listingsToAttach!.isEmpty) && cleanedResponse != "Sorry, I'm having trouble connecting right now." {
            
            let locationKeywords = ["parking in", "spots in", "available in", "show me", "in "]
            let lowercasedText = text.lowercased()
            
            // Use the original simple keyword check for a quick fallback
            let isLocationSearch = locationKeywords.contains { lowercasedText.contains($0) }
            
            if isLocationSearch {
                 // Use a broader filter to catch more results
                listingsToAttach = realListings.filter { listing in
                    let lowercasedListingInfo = "\(listing.address) \(listing.city) \(listing.state) \(listing.country)".lowercased()
                    return lowercasedListingInfo.contains(lowercasedText)
                }.prefix(5).map { $0 }
            }
        }

        // --- 5. Final Message Construction (Ensuring Cards Render) ---
        let finalContent: String
        
        // Check if we have listings to attach
        if let attachedListings = listingsToAttach, !attachedListings.isEmpty {
            
            let count = attachedListings.count
            
            // • IMPROVED FALLBACK: Ensure content exists if Gemini's response was empty after token removal
            if cleanedResponse.isEmpty {
                finalContent = "I found \(count) spot\(count == 1 ? "" : "s") for you:"
            } else {
                finalContent = cleanedResponse // Use Gemini's custom text
            }

            // Append message WITH listings
            messages.append(ChatMessage(
                role: .model,
                content: finalContent,
                listings: attachedListings,
                timestamp: Date()
            ))
        } else {
            // Append message WITHOUT listings (text-only path)
            messages.append(ChatMessage(
                role: .model,
                content: cleanedResponse,
                listings: nil,
                timestamp: Date()
            ))
        }

        isLoading = false
    }
    // MARK: - NEAR ME BUTTON — Perfect Flow
    func handleNearMeSearch() {
        guard !isSearchingNearby else { return }

        checkLocationPermission()

        switch permissionStatus {
        case .granted:
            startNearbySearch()

        case .prompt:
            locationManager.requestWhenInUseAuthorization()

        case .denied:
            showPermissionModal = true
        }
    }

    // MARK: - Start the actual nearby search
    private func startNearbySearch() {
        guard !isSearchingNearby else { return }
        isSearchingNearby = true
        isLoading = true

        messages.append(ChatMessage(
            role: .model,
            content: "Finding parking spots near you...",
            timestamp: Date()
        ))

        locationManager.requestLocation()
    }


    // MARK: - Location Updated → Use MapKitManager (UPDATED: Sends Listings array)
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, isSearchingNearby else { return }
        
        // Stop location updates once we have the data
        locationManager.stopUpdatingLocation()

        Task {
            do {
                // Fetch listings. We pass 'realListings' so MapKitManager can check distances.
                var nearby = try await mapKitManager.fetchNearbyListings(
                    from: location,
//                    maxDistanceKm: 10.0
                )
                nearby.sort { ($0.distanceFromUser ?? Double.greatestFiniteMagnitude) < ($1.distanceFromUser ?? Double.greatestFiniteMagnitude) }

                await MainActor.run {
                    // Remove "finding..." message
                    if let last = messages.last, last.content.contains("Finding parking") {
                        messages.removeLast()
                    }

                    if nearby.isEmpty {
                        messages.append(ChatMessage(
                            role: .model,
                            content: "No parking spots found within 10 km. Try a bigger city or check back soon!",
                            timestamp: Date()
                        ))
                    } else {
                        let count = nearby.count
                        let content = "I found \(count) great spot\(count == 1 ? "" : "s") within 10 km! Check out these options:"
                        //let content = ""
                        
                        messages.append(ChatMessage(
                            role: .model,
                            content: content,
                            listings: nearby.prefix(5).map { $0 },
                            timestamp: Date(),
                        ))
                    }
                }
            } catch {
                await MainActor.run {
                    messages.append(ChatMessage(
                        role: .system,
                        content: "Couldn't load nearby spots. Try again!",
                        timestamp: Date()
                    ))
                }
            }

            isLoading = false
            isSearchingNearby = false
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard isSearchingNearby else { return }
        Task { @MainActor in
            messages.append(ChatMessage(
                role: .system,
                content: "Location unavailable. Try typing a city name!",
                timestamp: Date()
            ))
            isLoading = false
            isSearchingNearby = false
        }
    }

    // MARK: - Permission Changed (e.g. user came back from Settings)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationPermission()

        // User just granted permission in Settings → auto start search!
        if permissionStatus == .granted && isSearchingNearby {
            locationManager.requestLocation()
        }
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

    // MARK: - Auth & Privacy
    private func startListeningToAuthChanges() {
        authListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            let newUserID = user?.uid
            if self?.currentUserID != newUserID {
                self?.currentUserID = newUserID
                DispatchQueue.main.async {
                    self?.messages = []
                    self?.realListings = []
                    self?.isSearchingNearby = false
                    print("Chat cleared for user: \(newUserID ?? "none")")
                }
            }
        }
    }

    private func setupAppTerminationObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.messages = []
        }
    }

    deinit {
        if let handle = authListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}

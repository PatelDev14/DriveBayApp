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
                let listings = docs.compactMap { try? $0.data(as: Listing.self) }
                DispatchQueue.main.async {
                    self?.realListings = listings
                }
            }
    }

    // MARK: - Send Regular Message to Gemini
    func sendMessage(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let userMessage = ChatMessage(role: .user, content: text, timestamp: Date())
        messages.append(userMessage)
        isLoading = true

        let listingsContext = realListings.isEmpty
            ? "No driveways listed yet."
            : realListings.map {
                "• \($0.address), \($0.city) \($0.state) — $\(String(format: "%.2f", $0.rate))/hr — \($0.startTime)–\($0.endTime)"
            }.joined(separator: "\n")

        let fullPrompt = """
        You are DriveBay AI — a friendly, expert parking assistant.

        Available driveways (REAL listings):
        \(listingsContext)

        User asked: "\(text)"

        Respond naturally and helpfully. Only recommend from real listings.
        If nothing matches, say: "No spots match right now — try broadening your search!"
        Keep replies short and warm.
        """

        do {
            let response = try await geminiService.generateResponse(prompt: fullPrompt)
            let botMessage = ChatMessage(role: .model, content: response, timestamp: Date())
            messages.append(botMessage)
        } catch {
            messages.append(ChatMessage(
                role: .system,
                content: "Sorry, I'm having trouble connecting right now.",
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


    // MARK: - Location Updated → Use MapKitManager
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, isSearchingNearby else { return }

        Task {
            do {
                let nearby = try await mapKitManager.fetchNearbyListings(
                    from: location,
                    maxDistanceKm: 10.0
                )

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
                        let closest = nearby[0]
                        let dist = String(format: "%.1f", closest.distanceFromUser ?? 0)

                        let reply = """
                        Found \(count) spot\(count == 1 ? "" : "s") within 10 km!

                        Closest: \(closest.address)
                        → \(dist) km away • $\(String(format: "%.2f", closest.rate))/hr
                        Available: \(closest.startTime)–\(closest.endTime)
                        """

                        messages.append(ChatMessage(role: .model, content: reply, timestamp: Date()))
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

// MARK: - Supporting Types
struct ChatMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    let content: String
    let timestamp: Date
}

enum MessageRole { case user, model, system }
enum PermissionState: String { case prompt, granted, denied }

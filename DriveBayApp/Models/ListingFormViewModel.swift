import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine
import MapKit

final class ListingFormViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var address = ""
    @Published var city = ""
    @Published var state = ""
    @Published var zipCode = ""
    @Published var country = ""
    @Published var description = ""
    @Published var date = Date()
    @Published var startTime = ""
    @Published var endTime = ""
    @Published var contactEmail = ""
    
    @Published var isLoading = false
    @Published var validationError: String?
    
    let emailService = EmailService()
    
    @Published var rate = "" {
        didSet {
            let filtered = rate.filter { "0123456789.".contains($0) }
            if filtered != rate { rate = filtered }

            let parts = rate.split(separator: ".")
            if parts.count > 2 { rate = String(rate.dropLast()); return }
            if let decimal = parts.last, decimal.count > 2 { rate = String(rate.dropLast()); return }
            if rate == "." { rate = "0." }

            if let value = Double(rate) {
                if value < 0.01 { rate = "0.01" }
                if value > 999.99 { rate = "999.99" }
            }
            if rate.isEmpty || rate == "." { rate = "0.00" }
        }
    }
    
    // MARK: - Callbacks
    var onSuccess: (() -> Void)?
    private var editingListingID: String?

    // MARK: - Init
    init() {}

    // MARK: - Load Existing Listing
    func loadListing(_ listing: Listing) {
        address = listing.address
        city = listing.city
        state = listing.state
        zipCode = listing.zipCode
        country = listing.country
        description = listing.description ?? ""
        rate = String(format: "%.2f", listing.rate)
        startTime = listing.startTime
        endTime = listing.endTime
        contactEmail = listing.contactEmail
        editingListingID = listing.id
    }

    // MARK: - Submit
    func submit() {
        validationError = nil
        
        // 1. Basic Validation
        guard !address.isEmpty, !city.isEmpty, !state.isEmpty, !zipCode.isEmpty, !country.isEmpty else {
            validationError = "Please fill out all address fields."
            return
        }
        
        guard let rateValue = Double(rate), rateValue > 0 else {
            validationError = "Rate must be a positive number."
            return
        }

        let normalizedStart = normalizeTime(startTime)
        let normalizedEnd = normalizeTime(endTime)

        guard !normalizedStart.isEmpty, !normalizedEnd.isEmpty else {
            validationError = "Please enter valid times (e.g., 09:00)."
            return
        }

        guard timeToMinutes(normalizedStart) < timeToMinutes(normalizedEnd) else {
            validationError = "End time must be after start time."
            return
        }

        startTime = normalizedStart
        endTime = normalizedEnd
        isLoading = true

        Task { @MainActor in
            do {
                // 2. Geocode & Save
                if let id = editingListingID {
                    try await updateListingInFirebase(id: id, rate: rateValue)
                } else {
                    try await saveToFirebase(rate: rateValue)
                }
                
                // 3. Send Email Notification
                let recipient = contactEmail.isEmpty ? (Auth.auth().currentUser?.email ?? "") : contactEmail
                let displayAddress = "\(address), \(city)"
                
                // We use a try? here so if email fails, the user still sees their driveway was saved
                try? await emailService.sendDrivewayPostedEmail(
                    to: recipient,
                    address: displayAddress,
                    rate: rateValue
                )
                
                onSuccess?()
            } catch {
                validationError = error.localizedDescription
            }
            isLoading = false
        }
    }

    // MARK: - Modern Geocoding Logic
    /// Converts the text address into Latitude and Longitude using MapKit
    private func getCoordinates() async throws -> CLLocationCoordinate2D {
        let fullAddress = "\(address), \(city), \(state), \(zipCode), \(country)"
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = fullAddress
        request.resultTypes = .address
        
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        guard let coordinate = response.mapItems.first?.placemark.coordinate else {
            throw NSError(domain: "GeocodeError", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Could not verify this address location."])
        }
        
        return coordinate
    }

    // MARK: - Firebase Operations
    private func saveToFirebase(rate: Double) async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthError", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "You must be logged in"])
        }

        let coords = try await getCoordinates()
        let ref = Firestore.firestore().collection("listings").document()

        let listing = Listing(
            id: ref.documentID,
            ownerId: user.uid,
            address: address,
            city: city,
            state: state,
            zipCode: zipCode,
            country: country,
            description: description.isEmpty ? nil : description,
            rate: rate,
            date: date,
            startTime: startTime,
            endTime: endTime,
            contactEmail: contactEmail.isEmpty ? (user.email ?? "") : contactEmail,
            createdAt: Timestamp(),
            latitude: coords.latitude,
            longitude: coords.longitude,
            isActive: true
        )

        try ref.setData(from: listing)
    }

    private func updateListingInFirebase(id: String, rate: Double) async throws {
        let coords = try await getCoordinates()

        let updateData: [String: Any] = [
            "address": address,
            "city": city,
            "state": state,
            "zipCode": zipCode,
            "country": country,
            "description": description.isEmpty ? NSNull() : description,
            "rate": rate,
            "startTime": startTime,
            "endTime": endTime,
            "contactEmail": contactEmail,
            "latitude": coords.latitude,
            "longitude": coords.longitude
        ]

        try await Firestore.firestore()
            .collection("listings")
            .document(id)
            .updateData(updateData)
    }

    // MARK: - Helpers
    private func normalizeTime(_ time: String) -> String {
        let parts = time.trimmingCharacters(in: .whitespaces).split(separator: ":")
        guard parts.count == 2,
              let h = Int(parts[0]), h >= 0 && h <= 23,
              let m = Int(parts[1]), m >= 0 && m <= 59 else {
            return ""
        }
        return String(format: "%02d:%02d", h, m)
    }

    private func timeToMinutes(_ time: String) -> Int {
        let parts = time.split(separator: ":")
        guard parts.count == 2 else { return 0 }
        return (Int(parts[0]) ?? 0) * 60 + (Int(parts[1]) ?? 0)
    }
}

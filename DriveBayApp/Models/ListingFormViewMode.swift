import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine
import CoreLocation
//import Resend

class ListingFormViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var address = ""
    @Published var city = ""
    @Published var state = ""
    @Published var zipCode = ""
    @Published var country = "USA"
    @Published var description = ""
    @Published var date = Date()
    @Published var startTime = ""
    @Published var endTime = ""
    @Published var contactEmail = ""
    
    @Published var isLoading = false
    @Published var validationError: String?
    @Published var locationError: String?
    
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
    
    var onSuccess: (() -> Void)?
    private var editingListingID: String?

    // MARK: - Location Manager
    private let locationManager = CLLocationManager()

    // MARK: - Init (CORRECT — no override, no super)
    init() {
        // Request location permission
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    // MARK: - Load Existing Listing
    func loadListing(_ listing: Listing) {
        self.address = listing.address
        self.city = listing.city
        self.state = listing.state
        self.zipCode = listing.zipCode
        self.country = listing.country
        self.description = listing.description ?? ""
        self.rate = String(format: "%.2f", listing.rate)
        self.startTime = listing.startTime
        self.endTime = listing.endTime
        self.contactEmail = listing.contactEmail
        self.editingListingID = listing.id
    }

    // MARK: - Submit
    func submit() {
        validationError = nil
        locationError = nil
        
        guard !address.isEmpty, !city.isEmpty, !state.isEmpty, !zipCode.isEmpty,
              !rate.isEmpty, !startTime.isEmpty, !endTime.isEmpty else {
            validationError = "Please fill out all required fields."
            return
        }
        
        guard let rateValue = Double(rate), rateValue > 0 else {
            validationError = "Rate must be a positive number."
            return
        }
        
        guard validateTime(startTime) && validateTime(endTime) else {
            validationError = "Please enter times in valid HH:MM format (e.g., 09:00)."
            return
        }
        
        guard timeToMinutes(startTime) < timeToMinutes(endTime) else {
            validationError = "End time must be after start time."
            return
        }
        
        if startTime.isEmpty || startTime.count != 5 { startTime = "09:00" }
        if endTime.isEmpty || endTime.count != 5 { endTime = "17:00" }
        
        isLoading = true
        
        Task { @MainActor in
            do {
                if let id = editingListingID {
                    try await updateListingInFirebase(id: id, rate: rateValue)
                } else {
                    try await saveToFirebase(rate: rateValue)
                }
                
                // ← ADD EMAIL SEND HERE (after save succeeds)
                let recipient = contactEmail.isEmpty ? (Auth.auth().currentUser?.email ?? "") : contactEmail
                let fullAddress = "\(address), \(city), \(state) \(zipCode)"
                
                try await emailService.sendDrivewayPostedEmail(
                    to: recipient,
                    address: fullAddress,
                    rate: rateValue
                )
                onSuccess?()
            } catch {
                validationError = "Driveway saved, but email failed: \(error.localizedDescription)"
                onSuccess?()
            }
        }
    }
    
    // MARK: - Save New Listing WITH REAL LAT/LNG
    private func saveToFirebase(rate: Double) async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "You must be logged in"])
        }
        
        let db = Firestore.firestore()
        let ref = db.collection("listings").document()
        
        // Real location or fallback to Toronto
        var latitude: Double = 43.6532   // Toronto
        var longitude: Double = -79.3832
        
        if let location = locationManager.location {
            latitude = location.coordinate.latitude
            longitude = location.coordinate.longitude
            print("Saved real location: \(latitude), \(longitude)")
        } else {
            print("Location denied — using Toronto fallback")
        }
        
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
            contactEmail: contactEmail.isEmpty ? user.email ?? "" : contactEmail,
            createdAt: Timestamp(),
            latitude: latitude,
            longitude: longitude,
            isActive: true
        )
        
        try ref.setData(from: listing)
    }

    // MARK: - Update Existing
    private func updateListingInFirebase(id: String, rate: Double) async throws {
        let db = Firestore.firestore()
        let ref = db.collection("listings").document(id)
        
        var updateData: [String: Any] = [
            "address": address,
            "city": city,
            "state": state,
            "zipCode": zipCode,
            "country": country,
            "description": description.isEmpty ? NSNull() : description,
            "rate": rate,
            "startTime": startTime,
            "endTime": endTime,
            "contactEmail": contactEmail
        ]
        
        if let location = locationManager.location {
            updateData["latitude"] = location.coordinate.latitude
            updateData["longitude"] = location.coordinate.longitude
        }
        
        try await ref.updateData(updateData)
    }

    // MARK: - Helpers
    private func validateTime(_ time: String) -> Bool {
        let components = time.split(separator: ":")
        guard components.count == 2,
              let hours = Int(components[0]), hours >= 0 && hours <= 23,
              let minutes = Int(components[1]), minutes >= 0 && minutes <= 59 else {
            return false
        }
        return true
    }
    
    private func timeToMinutes(_ time: String) -> Int {
        let components = time.split(separator: ":")
        guard components.count == 2,
              let hours = Int(components[0]),
              let minutes = Int(components[1]) else {
            return -1
        }
        return hours * 60 + minutes
    }
}

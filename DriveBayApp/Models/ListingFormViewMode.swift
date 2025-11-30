// ListingFormViewModel.swift
import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class ListingFormViewModel: ObservableObject {
    
    // MARK: - Published Properties (State)
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

    @Published var rate = "" {
        didSet {
            // Allow only numbers and one decimal point
            let filtered = rate.filter { "0123456789.".contains($0) }
            if filtered != rate { rate = filtered }

            // Allow only one decimal point
            let parts = rate.split(separator: ".")
            if parts.count > 2 {
                rate = String(rate.dropLast())
                return
            }

            // Limit to 2 decimal places
            if let decimal = parts.last, decimal.count > 2 {
                rate = String(rate.dropLast())
                return
            }

            // Prevent starting with "." → convert to "0."
            if rate == "." { rate = "0." }

            // Enforce minimum 0.01 and maximum 999.99
            if let value = Double(rate) {
                if value < 0.01 { rate = "0.01" }
                if value > 999.99 { rate = "999.99" }
            }

            // If empty → default
            if rate.isEmpty || rate == "." { rate = "0.00" }
        }
    }
    
    var onSuccess: (() -> Void)?
    
    // THIS IS THE ONLY NEW THING: Track if we're editing
    private var editingListingID: String?

    // YOUR ORIGINAL loadListing — just added one line
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
        
        // THIS LINE FIXES EVERYTHING
        self.editingListingID = listing.id
    }

    // MARK: - Public Methods
    func submit() {
        validationError = nil
        
        // 1. Basic validation
        guard !address.isEmpty, !city.isEmpty, !state.isEmpty, !zipCode.isEmpty,
              !rate.isEmpty, !startTime.isEmpty, !endTime.isEmpty, !contactEmail.isEmpty else {
            validationError = "Please fill out all required fields."
            return
        }
        
        // 2. Rate validation
        guard let rateValue = Double(rate), rateValue > 0 else {
            validationError = "Rate must be a positive number."
            return
        }
        
        // 3. Time validation
        guard validateTime(startTime) && validateTime(endTime) else {
            validationError = "Please enter times in valid HH:MM format (e.g., 09:00)."
            return
        }
        
        guard timeToMinutes(startTime) < timeToMinutes(endTime) else {
            validationError = "End time must be after start time."
            return
        }
        
        if startTime.isEmpty || startTime.count != 5 {
            startTime = "09:00"
        }
        if endTime.isEmpty || endTime.count != 5 {
            endTime = "17:00"
        }
        
        // Submit
        isLoading = true
        
        Task { @MainActor in
            do {
                // THIS IS THE ONLY CHANGE: Check if editing → update, else create
                if let id = editingListingID {
                    try await updateListingInFirebase(id: id, rate: rateValue)
                } else {
                    try await saveToFirebase(rate: rateValue)
                }
                onSuccess?()
            } catch {
                validationError = "Failed to save: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
    
    // NEW: Update existing listing
    private func updateListingInFirebase(id: String, rate: Double) async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "You must be logged in"])
        }
        
        let db = Firestore.firestore()
        let ref = db.collection("listings").document(id)
        
        let updatedData: [String: Any] = [
            "address": address,
            "city": city,
            "state": state,
            "zipCode": zipCode,
            "country": country,
            "description": description.isEmpty ? NSNull() : description,
            "rate": rate,
            "startTime": startTime,
            "endTime": endTime,
            "contactEmail": contactEmail.isEmpty ? user.email ?? "" : contactEmail
        ]
        
        try await ref.updateData(updatedData)
    }

    // YOUR ORIGINAL saveToFirebase — unchanged
    private func saveToFirebase(rate: Double) async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "You must be logged in"])
        }
        
        let db = Firestore.firestore()
        let ref = db.collection("listings").document()
        
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
            startTime: startTime,
            endTime: endTime,
            contactEmail: contactEmail.isEmpty ? user.email ?? "" : contactEmail,
            createdAt: Timestamp()
        )
        
        try ref.setData(from: listing)
    }

    // YOUR ORIGINAL helpers — 100% unchanged
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



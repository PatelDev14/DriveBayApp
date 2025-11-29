// ListingFormViewModel.swift
import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class ListingFormViewModel: ObservableObject {
    
    static let presetRates = [1, 3, 5, 7, 10]
    
    // MARK: - Published Properties (State)
    @Published var address = ""
    @Published var city = ""
    @Published var state = ""
    @Published var zipCode = ""
    @Published var country = "USA"
    @Published var description = ""
    @Published var rate = "5.00"
    @Published var date = Date()
    @Published var startTime = "09:00"
    @Published var endTime = "17:30"
    @Published var contactEmail = ""
    
    @Published var isLoading = false
    @Published var validationError: String?
    
    var onSuccess: (() -> Void)?
    
    // Add this function inside ListingFormViewModel class
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
        
        // Submit
        isLoading = true
        
        Task { @MainActor in
            do {
                try await saveToFirebase(rate: rateValue)
                onSuccess?()
            } catch {
                validationError = "Failed to save: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
    
    // MARK: - Private Helper Methods
    
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
        
        try await ref.setData(from: listing)
    }
}


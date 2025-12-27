import Foundation
import Combine
import FirebaseFirestore
import MapKit

class DrivewaysSearchViewModel: ObservableObject {
    @Published var city = ""
    @Published var state = ""
    @Published var country = ""
    @Published var zipCode = ""
    @Published var address: String = ""
    
    @Published var listings: [Listing] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var didSearch = false
    
    func searchDriveways() {
        // Validation
        guard !(city.isEmpty && state.isEmpty && country.isEmpty && zipCode.isEmpty) else {
            errorMessage = "Please enter a location to search."
            return
        }
        
        errorMessage = nil
        isLoading = true
        didSearch = true
        
        let db = Firestore.firestore()
        var query: Query = db.collection("listings").whereField("isActive", isEqualTo: true)
        
        // FIX: Remove forced Uppercasing/Capitalization that causes case-mismatch with DB
        if !city.isEmpty {
            let cleanedCity = city.trimmingCharacters(in: .whitespaces)
            query = query.whereField("city", isEqualTo: cleanedCity)
        }
        
        if !state.isEmpty {
            let cleanedState = state.trimmingCharacters(in: .whitespaces)
            query = query.whereField("state", isEqualTo: cleanedState)
        }
        
        if !country.isEmpty {
            let cleanedCountry = country.trimmingCharacters(in: .whitespaces)
            query = query.whereField("country", isEqualTo: cleanedCountry)
        }
        
        if !zipCode.isEmpty {
            query = query.whereField("zipCode", isEqualTo: zipCode.trimmingCharacters(in: .whitespaces))
        }
        
        Task {
            do {
                // NOTE: Firestore requires an INDEX for queries with multiple 'where' + 'order'
                // If this crashes or fails, check your Xcode console for a link to create the index.
                let snapshot = try await query
                    .getDocuments()
                
                let results = snapshot.documents.compactMap { document in
                    try? document.data(as: Listing.self)
                }
                
                await MainActor.run {
                    self.listings = results
                    self.isLoading = false
                    if results.isEmpty {
                        self.errorMessage = "No driveways found in \(city)."
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Search error: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}

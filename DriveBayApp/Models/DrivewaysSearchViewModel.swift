import Foundation
import Combine
import FirebaseFirestore
import MapKit

class DrivewaysSearchViewModel: ObservableObject {
    @Published var listings: [Listing] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var didSearch = false
    
    // We only need one input for Geo-search
    @Published var searchQuery: String = ""
    func searchDriveways() {
        guard !searchQuery.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = searchQuery
                let search = MKLocalSearch(request: request)
                let response = try await search.start()
                
                guard let item = response.mapItems.first?.placemark else {
                    await MainActor.run { self.isLoading = false }
                    return
                }
                let center = item.coordinate
                
                let db = Firestore.firestore()
                let collection = db.collection("listings").whereField("isActive", isEqualTo: true)
                
                // 1. BROAD SEARCH (State or Country)
                // If the search result is just a province or country (no street/city)
                if item.thoroughfare == nil && item.locality == nil {
                    var query: Query = collection
                    
                    if let state = item.administrativeArea {
                        query = query.whereField("state", isEqualTo: state)
                    } else if let country = item.country {
                        query = query.whereField("country", isEqualTo: country)
                    }
                    
                    let snapshot = try await query.getDocuments()
                    let results = snapshot.documents.compactMap { try? $0.data(as: Listing.self) }
                    
                    await MainActor.run {
                        self.listings = results
                        self.finalizeSearch()
                    }
                }
                // 2. SPECIFIC SEARCH (City, Zip, or Address)
                                else {
                                    // 1. Generate a WIDE search prefix (3 characters)
                                    // For your Ontario listings, this will be "dpz"
                                    let precision = 3
                                    let centerHash = GeohashHelper.encode(latitude: center.latitude, longitude: center.longitude, precision: precision)
                                    
                                    let start = centerHash
                                    let end = centerHash + "~"
                                    
                                    // 2. Fetch everything in that broad region
                                    let snapshot = try await collection
                                        .order(by: "geohash")
                                        .start(at: [start])
                                        .end(at: [end])
                                        .getDocuments()
                                    
                                    let results = snapshot.documents.compactMap { try? $0.data(as: Listing.self) }
                                    
                                    // 3. APPLY RADIUS FILTER (The "Smart" part)
                                    let searchCenter = CLLocation(latitude: center.latitude, longitude: center.longitude)
                                    let radiusLimit: Double = 30000 // 30km - comfortable for GTA cities
                                    
                                    let filtered = results.filter { listing in
                                        guard let lat = listing.latitude, let lon = listing.longitude else { return false }
                                        let listingLoc = CLLocation(latitude: lat, longitude: lon)
                                        let distance = listingLoc.distance(from: searchCenter)
                                        return distance <= radiusLimit
                                    }
                                    
                                    // 4. Sort by proximity
                                    let sortedResults = filtered.sorted {
                                        let loc1 = CLLocation(latitude: $0.latitude ?? 0, longitude: $0.longitude ?? 0)
                                        let loc2 = CLLocation(latitude: $1.latitude ?? 0, longitude: $1.longitude ?? 0)
                                        return loc1.distance(from: searchCenter) < loc2.distance(from: searchCenter)
                                    }
                                    
                                    await MainActor.run {
                                        self.listings = sortedResults
                                        self.finalizeSearch()
                                    }
                                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func finalizeSearch() {
        self.isLoading = false
        self.didSearch = true
        if self.listings.isEmpty {
            self.errorMessage = "No driveways found for '\(searchQuery)'."
        }
    }
}

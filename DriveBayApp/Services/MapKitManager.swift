import Foundation
import FirebaseFirestore
import CoreLocation

/// Finds parking spots near the user (10 km radius by default)
actor MapKitManager {
    
    private let db = Firestore.firestore()
    
    func fetchNearbyListings(
        from userLocation: CLLocation,
        maxDistanceKm: Double = 10.0
    ) async throws -> [Listing] {
        
        // 1. Fetch recent active listings
        let snapshot = try await db.collection("listings")
            .whereField("isActive", isEqualTo: true)
            .order(by: "createdAt", descending: true)
            .limit(to: 300)
            .getDocuments()
        
        // Use 'var' to allow mutation inside the closure
        var listings: [Listing] = snapshot.documents.compactMap { doc in
            guard var listing = try? doc.data(as: Listing.self) else { return nil }
            // Manually assign ID from document (essential if not using FirestoreSwift)
            listing.id = doc.documentID
            return listing
        }
        
        // 2. Calculate distance for each valid listing
        var results: [Listing] = []
        
        // Use 'enumerated()' to mutate the array directly, or just iterate and append the mutable copy.
        for var listing in listings {
            guard let lat = listing.latitude,
                  let lng = listing.longitude else { continue }
            
            let listingLocation = CLLocation(latitude: lat, longitude: lng)
            let distanceKm = userLocation.distance(from: listingLocation) / 1000.0
            
            // Save the distance
            // NOTE: This requires 'distanceFromUser' to be a standard 'var' in your Listing struct.
            listing.distanceFromUser = distanceKm
            results.append(listing)
        }
        
        // 3. Filter by radius and sort closest first
        return results
            .filter { ($0.distanceFromUser ?? 999) <= maxDistanceKm }
            .sorted { ($0.distanceFromUser ?? 999) < ($1.distanceFromUser ?? 999) }
    }
}

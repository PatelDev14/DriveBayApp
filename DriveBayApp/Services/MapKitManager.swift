import Foundation
import FirebaseFirestore
import CoreLocation

/// Finds parking spots near the user (10 km radius by default)
actor MapKitManager {
    
    private let db = Firestore.firestore()
    
    /// Returns only active listings within maxDistanceKm of the user, sorted closest first
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
        
        var listings = snapshot.documents.compactMap { try? $0.data(as: Listing.self) }
        
        // 2. Calculate distance for each valid listing
        var results: [Listing] = []
        
        for var listing in listings {
            guard let lat = listing.latitude,
                  let lng = listing.longitude else { continue }
            
            let listingLocation = CLLocation(latitude: lat, longitude: lng)
            let distanceKm = userLocation.distance(from: listingLocation) / 1000.0
            
            // THIS LINE WAS MISSING! → Now we actually save the distance
            listing.distanceFromUser = distanceKm
            results.append(listing)
        }
        
        // 3. Filter by radius and sort closest first
        return results
            .filter { ($0.distanceFromUser ?? 999) <= maxDistanceKm }
            .sorted { ($0.distanceFromUser ?? 999) < ($1.distanceFromUser ?? 999) }
    }
}

// MARK: - Safe Distance Storage (works without changing your Listing model)
extension Listing {
    var distanceFromUser: Double {
        get {
            objc_getAssociatedObject(self, &AssociatedKeys.distanceKey) as? Double ?? 999
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.distanceKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lng = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}

private struct AssociatedKeys {
    static var distanceKey = "distanceFromUserKey"
}

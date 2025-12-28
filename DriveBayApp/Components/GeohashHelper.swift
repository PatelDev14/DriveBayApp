import Foundation
import CoreLocation

struct GeohashHelper {
    private static let base32 = Array("0123456789bcdefghjkmnpqrstuvwxyz")
    
    static func encode(latitude: Double, longitude: Double, precision: Int = 10) -> String {
        var latRange = (-90.0, 90.0)
        var lonRange = (-180.0, 180.0)
        var geohash = ""
        var isEven = true
        var bit = 0
        var ch = 0
        
        while geohash.count < precision {
            if isEven {
                let mid = (lonRange.0 + lonRange.1) / 2
                if longitude > mid {
                    ch |= (1 << (4 - bit))
                    lonRange.0 = mid
                } else {
                    lonRange.1 = mid
                }
            } else {
                let mid = (latRange.0 + latRange.1) / 2
                if latitude > mid {
                    ch |= (1 << (4 - bit))
                    latRange.0 = mid
                } else {
                    latRange.1 = mid
                }
            }
            
            isEven.toggle()
            if bit < 4 {
                bit += 1
            } else {
                geohash.append(base32[ch])
                bit = 0
                ch = 0
            }
        }
        return geohash
    }
    static func geohashQueryBounds(for center: CLLocationCoordinate2D, radiusInMeters: Double) -> [(start: String, end: String)] {
        let precision = 4
        let centerHash = encode(latitude: center.latitude, longitude: center.longitude, precision: precision)
        
        let wideHash = String(centerHash.prefix(3))
        let start = wideHash
        let end = wideHash + "~"
        
        return [(start, end)]
    }
}

import Foundation
import FirebaseFirestore
import SwiftUI

struct Booking: Identifiable, Codable {
    @DocumentID var id: String?
    let listingId: String
    let listingAddress: String
    let listingTitle: String
    let listingOwnerId: String
    
    var hiddenByOwner: Bool = false
    var hiddenByRenter: Bool = false
    
    let renterId: String
    let renterEmail: String
    let ownerEmail: String?
    let totalPrice: Double?
    let status: BookingStatus
    var paymentStatus: String?
    
    let requestedDate: Date
    let startTime: String
    let endTime: String
    
    let createdAt: Timestamp
    
    // MARK: - Status Enum (Keeping your existing logic)
    enum BookingStatus: String, Codable {
        case pending, approved, rejected, cancelled
        
        var displayName: String { self.rawValue.capitalized }
        
        var color: Color {
            switch self {
            case .pending: return .orange
            case .approved: return .green
            case .rejected: return .red
            case .cancelled: return .gray
            }
        }
    }
    
    // MARK: - Refined Init
    init(
        id: String? = nil,
        listingId: String,
        listingAddress: String,
        listingTitle: String,
        listingOwnerId: String,
        renterId: String,
        renterEmail: String,
        ownerEmail: String? = nil,
        totalPrice: Double? = 0.0,
        status: BookingStatus = .pending,
        requestedDate: Date = Date(),
        startTime: String,
        endTime: String,
        createdAt: Timestamp = Timestamp(),
        hiddenByOwner: Bool = false,
        hiddenByRenter: Bool = false
    ) {
        self.id = id
        self.listingId = listingId
        self.listingAddress = listingAddress
        self.listingTitle = listingTitle
        self.listingOwnerId = listingOwnerId
        self.renterId = renterId
        self.renterEmail = renterEmail
        self.ownerEmail = ownerEmail
        self.totalPrice = totalPrice
        self.status = status
        self.requestedDate = requestedDate
        self.startTime = startTime
        self.endTime = endTime
        self.createdAt = createdAt
        self.hiddenByOwner = hiddenByOwner
        self.hiddenByRenter = hiddenByRenter
    }
}

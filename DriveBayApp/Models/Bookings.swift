// Models/Booking.swift
import Foundation
import FirebaseFirestore
import SwiftUI

struct Booking: Identifiable, Codable {
    @DocumentID var id: String?  
    let listingId: String
    let listingAddress: String         // For quick display without joining
    let listingOwnerId: String
    let renterId: String
    let renterEmail: String
    let status: BookingStatus          // ← Now uses the enum properly
    
    let requestedDate: Date
    let startTime: String
    let endTime: String
    
    let createdAt: Timestamp
    
    // MARK: - Status Enum
    enum BookingStatus: String, Codable {
        case pending = "pending"
        case approved = "approved"
        case rejected = "rejected"
        
        var displayName: String {
            switch self {
            case .pending: return "Pending"
            case .approved: return "Approved"
            case .rejected: return "Rejected"
            }
        }
        
        var color: Color {
            switch self {
            case .pending: return .orange
            case .approved: return .green
            case .rejected: return .red
            }
        }
    }
    
    // MARK: - Init
    init(
        id: String? = nil,
        listingId: String,
        listingAddress: String,
        listingOwnerId: String,
        renterId: String,
        renterEmail: String,
        status: BookingStatus = .pending,
        requestedDate: Date = Date(),
        startTime: String,
        endTime: String,
        createdAt: Timestamp = Timestamp()
    ) {
        self.id = id
        self.listingId = listingId
        self.listingAddress = listingAddress
        self.listingOwnerId = listingOwnerId
        self.renterId = renterId
        self.renterEmail = renterEmail
        self.status = status
        self.requestedDate = requestedDate
        self.startTime = startTime
        self.endTime = endTime
        self.createdAt = createdAt
    }
}

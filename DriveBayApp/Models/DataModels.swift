// DataModels.swift

import Foundation
import SwiftUI // Used for Color, Identifiable

// MARK: - 1. Core Listing Types

// Represents a driveway listing from your marketplace (equivalent to TypeScript 'Listing')
struct Listing: Identifiable, Codable {
    let id: String
    let name: String
    let address: String
    let pricePerHour: Double
    let details: String
    let website: String?
    // Add other fields from your original Listing type if needed
}

// Represents a search result (Marketplace or Web) (equivalent to TypeScript 'ParkingLocation')
struct ParkingLocation: Decodable, Identifiable {
    var id: String { name + address } // Simple composite ID for SwiftUI
    let name: String
    let address: String
    let details: String
    let website: String?
    let listingId: String? // Only for Marketplace results
}

// Represents the full search result from the Gemini model (equivalent to TypeScript 'ParkingResults')
struct ParkingResults: Decodable {
    let marketplaceResults: [ParkingLocation]
    let webResults: [ParkingLocation]
}

// MARK: - 2. Chat and State Types

// Represents a message in the chat (equivalent to TypeScript 'ChatMessage')
struct ChatMessage: Identifiable, Decodable {
    let id = UUID() // Use UUID for SwiftUI list stability
    let role: ChatRole
    let content: String
    let timestamp: Date // Use Date instead of ISO string
    
    enum CodingKeys: String, CodingKey {
        case role, content, timestamp
    }
}

// Represents the role of the message sender (equivalent to TypeScript 'ChatRole')
enum ChatRole: String, Decodable {
    case user
    case model
    case system // Used for internal notifications/errors
}

// Represents the status of Geolocation permission
typealias PermissionState = String // 'prompt', 'granted', 'denied'

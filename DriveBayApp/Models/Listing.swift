// Models/Listing.swift
import FirebaseFirestore
import Foundation
import SwiftUI

struct Listing: Identifiable, Codable {
    //var id: String
    @DocumentID var id: String?
    var ownerId: String
    var address: String
    var city: String
    var state: String
    var zipCode: String
    var country: String
    var description: String?
    var rate: Double
    var date: Date
    var startTime: String
    var endTime: String
    var contactEmail: String
    var createdAt: Timestamp?
    let latitude: Double?
    let longitude: Double?
    var geohash: String?
    let isActive: Bool
    
    var distanceFromUser: Double? = nil

    // This init lets you skip 'id' — it auto-generates
    init(
        id: String = UUID().uuidString,
        ownerId: String,
        address: String,
        city: String,
        state: String,
        zipCode: String,
        country: String,
        description: String? = nil,
        rate: Double,
        date: Date = Date(),
        startTime: String,
        endTime: String,
        contactEmail: String,
        createdAt: Timestamp? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        geohash: String? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.ownerId = ownerId
        self.address = address
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.country = country
        self.description = description
        self.rate = rate
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.contactEmail = contactEmail
        self.createdAt = createdAt
        self.latitude = latitude
        self.longitude = longitude
        self.geohash = geohash
        self.isActive = isActive
    }

    //var identifiableID: String { id }
    var identifiableID: String { id ?? UUID().uuidString }

    // MOVE THIS INSIDE THE STRUCT ← THIS IS THE FIX!
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct AnimatedGradientBackground: View {
    var body: some View {
        Color.black
    }
}

// Placeholder for the GlassCard container
struct GlassCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(Color.white.opacity(0.15))
            .cornerRadius(12)
            .shadow(radius: 5)
    }
}

enum MessageRole { case user, model, system }
enum PermissionState: String { case prompt, granted, denied }

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    let content: String
    let listings: [Listing]?
    let timestamp: Date
    
    init(role: MessageRole, content: String = "", listings: [Listing]? = nil, timestamp: Date) {
        self.role = role
        self.content = content
        self.listings = listings
        self.timestamp = timestamp
    }
}

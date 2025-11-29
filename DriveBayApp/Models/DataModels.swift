// DataModels.swift
import Foundation
import SwiftUI
import FirebaseFirestore
// ... (Your existing code: Listing, ParkingLocation, ParkingResults, ChatMessage, ChatRole, PermissionState)

// MARK: - 3. Gemini Response Types (For Structured Email Output)

// Single response for booking request, denial, and listing confirmation emails
struct SingleEmailResponse: Codable {
    let subject: String
    let body: String // Changed from 'emailContent' for consistency with JS, but 'body' works fine too.
}

// Multi-part response for booking confirmation and cancellation emails
struct ConfirmationEmailsResponse: Codable {
    let bookerSubject: String
    let bookerEmailContent: String
    let ownerSubject: String
    let ownerEmailContent: String
}

// ⚠️ Note on ParkingResults: Your existing ParkingResults struct is correct.
/*
struct ParkingResults: Decodable {
    let marketplaceResults: [ParkingLocation]
    let webResults: [ParkingLocation]
}
*/
// However, to strictly match the previous Swift response, we should use the specific structs
// defined for the output, even if they are structurally similar to ParkingLocation.

struct ParkingMarketplaceResult: Codable {
    let listingId: String
    let name: String
    let address: String
    let details: String
}

struct ParkingWebResult: Codable {
    let name: String
    let address: String
    let details: String
    let website: String?
}

// Re-defining ParkingResults to use the structured results exactly as designed for Gemini
struct GeminiParkingResponse: Codable {
    let marketplaceResults: [ParkingMarketplaceResult]
    let webResults: [ParkingWebResult]
}

// Suggestion: Since your existing `ParkingResults` and `ParkingLocation` are simpler,
// I recommend leaving them as is for your UI and using `GeminiParkingResponse` for the API.

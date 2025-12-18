// Models/UserProfile.swift
import Foundation
import FirebaseFirestore

struct UserProfile: Identifiable, Codable {
    var id: String?
    let uid: String
    let email: String
    var firstName: String?
    var lastName: String?
    var phoneNumber: String?
    var createdAt: Timestamp = Timestamp()
    
    var displayName: String {
        if let first = firstName, let last = lastName, !first.isEmpty, !last.isEmpty {
            return "\(first) \(last)"
        } else if let first = firstName, !first.isEmpty {
            return first
        } else {
            return email.components(separatedBy: "@").first ?? "User"
        }
    }
    
    // MARK: - CodingKeys to map "id" to Firestore document ID
    enum CodingKeys: String, CodingKey {
        case id
        case uid
        case email
        case firstName
        case lastName
        case phoneNumber
        case createdAt
    }
}

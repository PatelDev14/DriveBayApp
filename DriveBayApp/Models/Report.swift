// Models/Report.swift
import Foundation
import FirebaseFirestore

struct Report: Identifiable, Codable {
    @DocumentID var id: String?
    let bookingId: String
    let reportedById: String
    let reportedUserId: String
    let type: ReportType
    let description: String
    let createdAt: Timestamp = Timestamp()
    
    enum ReportType: String, Codable {
        case drivewayIssue = "driveway_issue"
        case renterIssue = "renter_issue"
        
        var displayName: String {
            switch self {
            case .drivewayIssue: return "Driveway Issue"
            case .renterIssue: return "Renter Issue"
            }
        }
    }
    
    init(
        id: String? = nil,
        bookingId: String,
        reportedById: String,
        reportedUserId: String,
        type: ReportType,
        description: String
    ) {
        self.id = id
        self.bookingId = bookingId
        self.reportedById = reportedById
        self.reportedUserId = reportedUserId
        self.type = type
        self.description = description
    }
}

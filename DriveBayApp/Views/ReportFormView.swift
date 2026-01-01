import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ReportFormView: View {
    let booking: Booking
    let asRenter: Bool
    
    @State private var selectedIssues: Set<ReportIssue> = []
    @State private var customDescription: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    
    @Environment(\.dismiss) private var dismiss
    
    private var issues: [ReportIssue] {
        asRenter ? ReportIssue.renterIssues : ReportIssue.hostIssues
    }
    
    private var isDescriptionMissingForOther: Bool {
        selectedIssues.contains(.other) && customDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        // MARK: - Header
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.orange)
                                .shadow(color: .orange.opacity(0.6), radius: 20)
                            
                            Text(asRenter ? "Report Driveway Issue" : "Report Renter Issue")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            
                            Text(asRenter
                                 ? "Select specific issues or choose 'Other' to describe the problem."
                                 : "Select specific issues or choose 'Other' to describe the behavior.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .padding(.top, 20)
                        
                        // MARK: - Issue Selector
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Select issues (tap to toggle)")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(issues) { issue in
                                    issueButton(issue: issue)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // MARK: - Additional Details
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(selectedIssues.contains(.other) ? "Please describe the issue" : "Additional details (optional)")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.9))
                                
                                if selectedIssues.contains(.other) {
                                    Text("*Required")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                            .padding(.horizontal)
                            
                            TextEditor(text: $customDescription)
                                .frame(height: 140)
                                .padding(12)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(18)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .strokeBorder(
                                            selectedIssues.contains(.other) ? Color.orange : DriveBayTheme.accent.opacity(0.3),
                                            lineWidth: selectedIssues.contains(.other) ? 2 : 1.5
                                        )
                                )
                                .shadow(color: selectedIssues.contains(.other) ? Color.orange.opacity(0.2) : DriveBayTheme.glow.opacity(0.3), radius: 10)
                            
                            HStack {
                                Spacer()
                                Text("\(customDescription.count)/500")
                                    .font(.caption)
                                    .foregroundColor(customDescription.count > 500 ? .red : .white.opacity(0.6))
                            }
                            .padding(.trailing)
                        }
                        .padding(.horizontal)
                        
                        // MARK: - Error
                        if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.subheadline)
                                .padding()
                                .background(Color.red.opacity(0.15))
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                        
                        // MARK: - Submit Button
                        Button("Submit Report") {
                            submitReport()
                        }
                        .disabled(isSubmitting || selectedIssues.isEmpty || isDescriptionMissingForOther)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            (selectedIssues.isEmpty || isDescriptionMissingForOther) ? Color.gray.opacity(0.5) : DriveBayTheme.accent
                        )
                        .foregroundColor(.black)
                        .font(.title3.bold())
                        .cornerRadius(20)
                        .shadow(color: DriveBayTheme.glow.opacity((selectedIssues.isEmpty || isDescriptionMissingForOther) ? 0.3 : 0.8), radius: 20, y: 10)
                        .overlay(isSubmitting ? ProgressView().tint(.black) : nil)
                        .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { dismiss() }
                        .foregroundColor(.white.opacity(0.9))
                        .fontWeight(.medium)
                }
            }
            .alert("Report Submitted", isPresented: $showSuccessAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text("Thank you for your report. We’ll review it promptly and take appropriate action.")
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Issue Button with Exclusive Selection Logic
    private func issueButton(issue: ReportIssue) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                if issue == .other {
                    // Logic: If Other is selected, clear everything else
                    if selectedIssues.contains(.other) {
                        selectedIssues.remove(.other)
                    } else {
                        selectedIssues.removeAll()
                        selectedIssues.insert(.other)
                    }
                } else {
                    // Logic: If standard issue selected, remove "Other"
                    selectedIssues.remove(.other)
                    if selectedIssues.contains(issue) {
                        selectedIssues.remove(issue)
                    } else {
                        selectedIssues.insert(issue)
                    }
                }
            }
        } label: {
            VStack(spacing: 10) {
                Image(systemName: issue.icon)
                    .font(.title2)
                    .foregroundColor(selectedIssues.contains(issue) ? .black : .white.opacity(0.8))
                
                Text(issue.title)
                    .font(.subheadline.bold())
                    .foregroundColor(selectedIssues.contains(issue) ? .black : .white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                selectedIssues.contains(issue)
                ? DriveBayTheme.accent
                : Color.white.opacity(0.08)
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(selectedIssues.contains(issue) ? DriveBayTheme.glow.opacity(0.7) : DriveBayTheme.glassBorder.opacity(0.4), lineWidth: 1.8)
            )
            .shadow(color: selectedIssues.contains(issue) ? DriveBayTheme.glow.opacity(0.8) : .clear, radius: 16)
        }
    }
    
    // MARK: - Submit Report
    private func submitReport() {
        let otherText = customDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Final description builder
        let predefinedTitles = selectedIssues
            .filter { $0 != .other }
            .map { $0.title }
            .joined(separator: "\n• ")
        
        let finalDescription: String = {
            if selectedIssues.contains(.other) {
                return "Type: Other\nDetails: \(otherText)"
            } else {
                var desc = "Selected Issues:\n• \(predefinedTitles)"
                if !otherText.isEmpty {
                    desc += "\n\nAdditional comments: \(otherText)"
                }
                return desc
            }
        }()
        
        isSubmitting = true
        errorMessage = nil
        
        guard let uid = Auth.auth().currentUser?.uid,
              let userEmail = Auth.auth().currentUser?.email else {
            errorMessage = "You must be logged in to submit a report."
            isSubmitting = false
            return
        }
        
        let reportedUserId = asRenter ? booking.listingOwnerId : booking.renterId
        let type = asRenter ? Report.ReportType.drivewayIssue : .renterIssue
        
        let report = Report(
            bookingId: booking.id ?? "unknown",
            reportedById: uid,
            reportedUserId: reportedUserId,
            type: type,
            description: finalDescription
        )
        
        Firestore.firestore().collection("reports").addDocument(data: report.asDictionary) { error in
            if let error = error {
                self.errorMessage = "Failed to submit: \(error.localizedDescription)"
                self.isSubmitting = false
                return
            }
            
            Task {
                let emailService = EmailService()
                try? await emailService.sendReportNotificationEmail(
                    reportType: type.displayName,
                    reporterEmail: userEmail,
                    bookingAddress: booking.listingAddress,
                    description: finalDescription
                )
            }
            
            self.showSuccessAlert = true
            self.isSubmitting = false
        }
    }
}


// MARK: - Report Issues (enum)
enum ReportIssue: String, Identifiable, Hashable {
    case spotNotAvailable = "Spot not available"
    case blocked = "Blocked or obstructed"
    case wrongLocation = "Wrong location/description"
    case unsafe = "Unsafe area"
    case dirty = "Dirty or damaged"
    case other = "Other"
    
    case propertyDamage = "Property damage"
    case leftTrash = "Left trash or mess"
    case unauthorizedVehicle = "Unauthorized vehicle"
    case noShow = "No-show"
    case inappropriateBehavior = "Inappropriate behavior"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .spotNotAvailable: return "Spot not available"
        case .blocked: return "Blocked or obstructed"
        case .wrongLocation: return "Wrong location"
        case .unsafe: return "Unsafe area"
        case .dirty: return "Dirty or damaged"
        case .other: return "Other issue"
        case .propertyDamage: return "Property damage"
        case .leftTrash: return "Left trash"
        case .unauthorizedVehicle: return "Unauthorized vehicle"
        case .noShow: return "No-show"
        case .inappropriateBehavior: return "Inappropriate behavior"
        }
    }
    
    var icon: String {
        switch self {
        case .spotNotAvailable, .blocked: return "xmark.circle.fill"
        case .wrongLocation: return "mappin.slash"
        case .unsafe: return "shield.slash"
        case .dirty, .leftTrash: return "trash.fill"
        case .other: return "ellipsis.circle"
        case .propertyDamage: return "hammer.fill"
        case .unauthorizedVehicle: return "car.fill"
        case .noShow: return "person.crop.circle.badge.xmark"
        case .inappropriateBehavior: return "exclamationmark.bubble.fill"
        }
    }
    
    static var renterIssues: [ReportIssue] = [
        .spotNotAvailable,
        .blocked,
        .wrongLocation,
        .unsafe,
        .dirty,
        .other
    ]
    
    static var hostIssues: [ReportIssue] = [
        .propertyDamage,
        .leftTrash,
        .unauthorizedVehicle,
        .noShow,
        .inappropriateBehavior,
        .other
    ]
}

// MARK: - Firestore Dictionary Conversion
extension Report {
    var asDictionary: [String: Any] {
        [
            "bookingId": bookingId,
            "reportedById": reportedById,
            "reportedUserId": reportedUserId,
            "type": type.rawValue,
            "description": description,
            "createdAt": FieldValue.serverTimestamp()
        ]
    }
}

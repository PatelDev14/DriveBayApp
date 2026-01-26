import Foundation
import FirebaseFunctions

actor EmailService {
    private let functions = Functions.functions()
    private let fromEmail: String = "contact@drivebay.ca"
    
    // Internal helper to call the cloud function to avoid repeating code
    private func sendCloudEmail(to: Any, subject: String, html: String) async throws {
        let data: [String: Any] = [
            "to": to,
            "subject": subject,
            "html": html
        ]
        
        _ = try await functions.httpsCallable("sendEmail").call(data)
    }
        
    // MARK: - 1. Driveway Posted
    func sendDrivewayPostedEmail(to recipient: String, address: String, rate: Double) async throws {
        let html = """
            <h1>Congratulations!</h1>
            <p>Your driveway at <strong>\(address)</strong> is now live for $ \(String(format: "%.2f", rate))/hr.</p>
            <p>Check status: <a href="https://yourapp.com/driveways">My Driveways</a></p>
            <p>Thanks for using DriveBay! 🚗</p>
            """
        try await sendCloudEmail(to: [recipient], subject: "Your Driveway is Live on DriveBay!", html: html)
    }
        
    // MARK: - 2. Booking Requested (Owner Notification)
    func sendBookingRequestEmail(to ownerEmail: String, renterEmail: String, address: String, date: String, startTime: String, endTime: String) async throws {
        let html = """
            <div style="font-family: sans-serif; line-height: 1.5;">
                <h2 style="color: #007AFF;">New Booking Request 🚗</h2>
                <p><strong>\(renterEmail)</strong> wants to book your driveway:</p>
                <hr>
                <p><strong>Address:</strong> \(address)</p>
                <p><strong>Date:</strong> \(date)</p>
                <p><strong>Time:</strong> \(startTime) – \(endTime)</p>
                <hr>
                <p>Open the DriveBay app to approve or reject this request.</p>
                <p>Thanks,<br>DriveBay Team</p>
            </div>
            """
        try await sendCloudEmail(to: [ownerEmail], subject: "New Booking Request for Your Driveway!", html: html)
    }
        
    // MARK: - 3. Booking Approved (Both Parties)
    func sendBookingApprovedEmail(to renterEmail: String, ownerEmail: String, address: String, date: String, startTime: String, endTime: String) async throws {
        let html = """
            <div style="font-family: sans-serif; line-height: 1.5;">
                <h2 style="color: #28a745;">Booking Confirmed!</h2>
                <p>Your parking booking is confirmed and ready:</p>
                <hr>
                <p><strong>Address:</strong> \(address)</p>
                <p><strong>Date:</strong> \(date)</p>
                <p><strong>Time:</strong> \(startTime) – \(endTime)</p>
                <hr>
                <p>See you there! 🚗</p>
                <p>Thanks,<br>DriveBay Team</p>
            </div>
            """
        try await sendCloudEmail(to: [renterEmail, ownerEmail], subject: "Booking Confirmed on DriveBay! 🎉", html: html)
    }
    
    // MARK: - 4. Reports
    func sendReportNotificationEmail(reportType: String, reporterEmail: String, bookingAddress: String, description: String) async throws {
        let html = """
            <h2>New Report Submitted</h2>
            <p><strong>Type:</strong> \(reportType)</p>
            <p><strong>Reporter:</strong> \(reporterEmail)</p>
            <p><strong>Booking Address:</strong> \(bookingAddress)</p>
            <hr>
            <p><strong>Description:</strong></p>
            <p>\(description.replacingOccurrences(of: "\n", with: "<br>"))</p>
            <p>Please review in Firestore > reports collection.</p>
            """
        try await sendCloudEmail(to: ["devp1400@gmail.com"], subject: "New Report: \(reportType)", html: html)
    }
    
    // MARK: - 5. Payment Confirmation
    func sendPaymentConfirmationEmail(to hostEmail: String, renterEmail: String, address: String, date: String, startTime: String, endTime: String, amount: Double) async throws {
        let html = """
            <div style="font-family: system-ui, sans-serif; line-height: 1.6; color: #333;">
                <h2 style="color: #28a745;">Payment Confirmed!</h2>
                <p>Great news — the renter has successfully paid for their booking.</p>
                <hr style="border: 1px solid #eee; margin: 20px 0;">
                <p><strong>Booking Details:</strong></p>
                <ul>
                    <li><strong>Address:</strong> \(address)</li>
                    <li><strong>Date:</strong> \(date)</li>
                    <li><strong>Time:</strong> \(startTime) – \(endTime)</li>
                    <li><strong>Renter:</strong> \(renterEmail)</li>
                    <li><strong>Amount Paid:</strong> $\(String(format: "%.2f", amount))</li>
                </ul>
                <hr style="border: 1px solid #eee; margin: 20px 0;">
                <p>The funds will be released to you 24 hours after the booking ends.</p>
                <p>Thank you for hosting on DriveBay! 🚗</p>
                <p style="color: #666; font-size: 0.9em; margin-top: 30px;">
                    DriveBay Team<br>no-reply@dev-patel.ca
                </p>
            </div>
            """
        try await sendCloudEmail(to: [hostEmail], subject: "Payment Received for Your Driveway Booking! 💰", html: html)
    }
}

import Foundation
import FirebaseFirestore

actor EmailService {
    private let apiKey: String
    private let fromEmail: String = "no-reply@dev-patel.ca"
    
    init() {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "RESEND_API_KEY") as? String,
              !key.isEmpty else {
            fatalError("RESEND_API_KEY not set in Info.plist")
        }
                self.apiKey = key
}
        
        // MARK: - 1. Driveway Posted
        func sendDrivewayPostedEmail(to recipient: String, address: String, rate: Double) async throws {
            let url = URL(string: "https://api.resend.com/emails")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            
            let body: [String: Any] = [
                "from": fromEmail,
                "to": recipient,
                "subject": "Your Driveway is Live on DriveBay!",
                "html": """
            <h1>Congratulations!</h1>
            <p>Your driveway at <strong>\(address)</strong> is now live for $ \(String(format: "%.2f", rate))/hr.</p>
            <p>Check status: <a href="https://yourapp.com/driveways">My Driveways</a></p>
            <p>Thanks for using DriveBay! 🚗</p>
            """
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw NSError(domain: "EmailError", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMsg])
            }
        }
        
        // MARK: - 2. Booking Requested (Owner Notification)
        // Updated to accept Strings for all time/date fields to match ClockPicker
        func sendBookingRequestEmail(to ownerEmail: String, renterEmail: String, address: String, date: String, startTime: String, endTime: String) async throws {
            let url = URL(string: "https://api.resend.com/emails")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            
            let body: [String: Any] = [
                "from": fromEmail,
                "to": ownerEmail,
                "subject": "New Booking Request for Your Driveway!",
                "html": """
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
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw NSError(domain: "EmailError", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMsg])
            }
        }
        
        // MARK: - 3. Booking Approved (Both Parties)
        func sendBookingApprovedEmail(to renterEmail: String, ownerEmail: String, address: String, date: String, startTime: String, endTime: String) async throws {
            let url = URL(string: "https://api.resend.com/emails")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            
            let body: [String: Any] = [
                "from": fromEmail,
                "to": [renterEmail, ownerEmail],
                "subject": "Booking Confirmed on DriveBay! 🎉",
                "html": """
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
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw NSError(domain: "EmailError", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMsg])
            }
        }
    
    func sendReportNotificationEmail(reportType: String, reporterEmail: String, bookingAddress: String, description: String) async throws {
        let url = URL(string: "https://api.resend.com/emails")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "from": fromEmail,
            "to": "devp1400@gmail.com",
            "subject": "New Report: \(reportType)",
            "html": """
            <h2>New Report Submitted</h2>
            <p><strong>Type:</strong> \(reportType)</p>
            <p><strong>Reporter:</strong> \(reporterEmail)</p>
            <p><strong>Booking Address:</strong> \(bookingAddress)</p>
            <hr>
            <p><strong>Description:</strong></p>
            <p>\(description.replacingOccurrences(of: "\n", with: "<br>"))</p>
            <p>Please review in Firestore > reports collection.</p>
            """
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "EmailError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to send admin notification"])
        }
    }
    
    // Add this new function to your EmailService.swift (inside the actor)

    func sendPaymentConfirmationEmail(
        to hostEmail: String,
        renterEmail: String,
        address: String,
        date: String,
        startTime: String,
        endTime: String,
        amount: Double
    ) async throws {
        let url = URL(string: "https://api.resend.com/emails")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "from": fromEmail,
            "to": hostEmail,
            "subject": "Payment Received for Your Driveway Booking! 💰",
            "html": """
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
                    DriveBay Team<br>
                    no-reply@dev-patel.ca
                </p>
            </div>
            """
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "EmailError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to send payment confirmation email"])
        }
    }
}


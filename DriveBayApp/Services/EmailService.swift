import Foundation
import FirebaseFirestore // Added to support Timestamp conversion if needed

actor EmailService {
    private let apiKey: String
    private let fromEmail: String = "no-reply@dev-patel.ca"
    
    init() {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "RESEND_API_KEY") as? String,
              !key.isEmpty else {
            fatalError("RESEND_API_KEY not set in Info.plist")
        }
        self.apiKey = key
        print("Loaded RESEND_API_KEY: \(key.prefix(4))****")
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
}

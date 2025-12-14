// Services/EmailService.swift

import Foundation

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
    
    
    
    /// Sends a confirmation email when driveway is posted
    func sendDrivewayPostedEmail(to recipient: String, address: String, rate: Double) async throws {
        let url = URL(string: "https://api.resend.com/emails")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "from": fromEmail, // Uses your property
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
        
        print("Email sent successfully!")
    }
}

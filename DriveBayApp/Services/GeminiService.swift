import Foundation

actor GeminiService {
    
    private let apiKey: String
    private let modelName = "gemini-2.5-flash"

    
    private lazy var url: URL = {
        // Construct the URL using the model name
        var components = URLComponents(string: "https://generativelanguage.googleapis.com/v1/models/\(modelName):generateContent")!
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        return components.url!
    }()
    
    init() {
        // Fetches API Key securely from the Info.plist file
        guard let key = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String,
              !key.isEmpty else {
            // Fatal error if the key is not set in Info.plist
            fatalError("GEMINI_API_KEY not set in Info.plist or environment!")
        }
        self.apiKey = key
    }
    
    /// Generates a response from the Gemini API for a given prompt.
    func generateResponse(prompt: String) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Use JSON serialization for the request body
        let body: [String: Any] = [
            "contents": [
                ["role": "user", "parts": [["text": prompt]]]
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            throw GeminiServiceError.decodingFailure(message: "Failed to encode request body: \(error.localizedDescription)")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 1. Check for HTTP Status Code errors (e.g., 400, 403, 500)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiServiceError.badServerResponse(statusCode: 0)
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            // If the status code is bad, try to decode the structured API error
            if let apiError = try? JSONDecoder().decode(GeminiErrorResponse.self, from: data) {
                throw GeminiServiceError.apiError(code: apiError.error.code, message: apiError.error.message)
            } else {
                // If we can't decode the error body, throw a generic status error
                throw GeminiServiceError.badServerResponse(statusCode: httpResponse.statusCode)
            }
        }
        
        // 2. Decode the successful response using Codable
        let decodedResponse: GeminiAPIResponse
        do {
            decodedResponse = try JSONDecoder().decode(GeminiAPIResponse.self, from: data)
        } catch {
            throw GeminiServiceError.decodingFailure(message: "Failed to decode successful response: \(error.localizedDescription)")
        }
        
        // 3. Safely extract the text from the nested JSON structure
        guard let text = decodedResponse.candidates.first?.content.parts.first?.text else {
            throw GeminiServiceError.noContent
        }
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

import Foundation
import FirebaseFunctions

actor GeminiService {
    private let functions = Functions.functions()

    /// Generates a response from the Gemini AI by calling the Firebase Cloud Function
    func generateResponse(prompt: String) async throws -> String {
        let data = ["prompt": prompt]
        
        do {
            let result = try await functions.httpsCallable("callGemini").call(data)
            
            if let data = result.data as? [String: Any],
               let text = data["text"] as? String {
                return text.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                throw NSError(domain: "GeminiService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Malformed response from AI"])
            }
        } catch {
            print("Gemini Error: \(error.localizedDescription)")
            throw error
        }
    }
}

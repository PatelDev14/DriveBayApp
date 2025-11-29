import Foundation

enum GeminiServiceError: Error, LocalizedError {
    case apiError(code: Int, message: String)
    case decodingFailure(message: String)
    case noContent
    case badServerResponse(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .apiError(_, let message):
            // This error comes directly from the API response body
            return "Gemini API Error: \(message)"
        case .decodingFailure(let message):
            // This occurs if the JSON structure is unexpected
            return "Failed to process the API response: \(message)"
        case .noContent:
            return "The model returned no text content."
        case .badServerResponse(let statusCode):
            return "Received an unexpected HTTP status code: \(statusCode)."
        }
    }
}

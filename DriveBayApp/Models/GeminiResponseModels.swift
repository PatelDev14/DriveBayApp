import Foundation

// Mirrors the main response object from the Gemini API
struct GeminiAPIResponse: Codable {
    let candidates: [Candidate]
}

struct Candidate: Codable {
    let content: Content
}

struct Content: Codable {
    let parts: [Part]
}

struct Part: Codable {
    let text: String?
}

// Struct to catch API errors (e.g., if the 'error' key exists)
struct GeminiErrorResponse: Codable {
    let error: ErrorDetail
}

struct ErrorDetail: Codable {
    let code: Int
    let message: String
}

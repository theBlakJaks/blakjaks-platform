import Foundation

enum APIError: LocalizedError {
    case unauthorized
    case notFound
    case serverError(statusCode: Int, message: String)
    case decodingError(Error)
    case networkError(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Session expired. Please sign in again."
        case .notFound: return "The requested resource was not found."
        case .serverError(_, let message): return message
        case .decodingError: return "Failed to parse server response."
        case .networkError(let error): return error.localizedDescription
        case .unknown: return "An unexpected error occurred."
        }
    }
}

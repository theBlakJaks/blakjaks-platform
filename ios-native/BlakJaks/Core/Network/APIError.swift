import Foundation

// MARK: - APIError

enum APIError: LocalizedError {
    case unauthorized(detail: String?)   // 401 — could be bad creds or expired session
    case serverError(statusCode: Int, message: String)
    case networkError(Error)
    case decodingError(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .unauthorized(let detail):
            return detail ?? "Invalid credentials. Please try again."
        case .serverError(let code, let msg):
            return "Server error \(code): \(msg)"
        case .networkError(let err):
            return "Network error: \(err.localizedDescription)"
        case .decodingError(let err):
            return "Data error: \(err.localizedDescription)"
        case .unknown:
            return "An unexpected error occurred."
        }
    }
}

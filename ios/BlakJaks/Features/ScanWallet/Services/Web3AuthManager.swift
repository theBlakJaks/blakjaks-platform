import Foundation

// MARK: - Web3AuthManager
// Interface for MetaMask Embedded Wallets via Web3Auth v11.1.0 SDK.
//
// SDK integration note: Web3Auth Swift SDK (https://github.com/Web3Auth/web3auth-swift-sdk)
// will be added to project.yml in the polish pass when all features are stable.
// This class defines the interface; ViewModels depend on it via protocol.
// The wallet address for display comes from the API wallet endpoint for now.

protocol Web3AuthManagerProtocol {
    var walletAddress: String? { get }
    var isConnected: Bool { get }
    func connect() async throws -> String   // returns wallet address
    func disconnect() async throws
    func signMessage(_ message: String) async throws -> String
}

@MainActor
final class Web3AuthManager: Web3AuthManagerProtocol {

    static let shared = Web3AuthManager()

    private(set) var walletAddress: String?
    private(set) var isConnected = false

    private init() {
        // Restore cached address from Keychain if available
        walletAddress = UserDefaults.standard.string(forKey: "web3auth_wallet_address")
        isConnected   = walletAddress != nil
    }

    // MARK: - Connect (wallet creation / login)
    // In production: calls Web3Auth.init(W3AInitParams) + web3auth.login(W3ALoginParams)
    // Stores resulting privateKey in Keychain; derives address via web3swift.

    func connect() async throws -> String {
        // Stub: simulate async wallet creation (real SDK call here)
        try await Task.sleep(nanoseconds: 800_000_000)  // 0.8s simulated
        let mockAddress = "0x3f2A9c8B1D7e4F0a5C6E2d8B9A1F3c7E4D2b0A8F"
        walletAddress = mockAddress
        isConnected   = true
        UserDefaults.standard.set(mockAddress, forKey: "web3auth_wallet_address")
        return mockAddress
    }

    // MARK: - Disconnect

    func disconnect() async throws {
        walletAddress = nil
        isConnected   = false
        UserDefaults.standard.removeObject(forKey: "web3auth_wallet_address")
    }

    // MARK: - Sign message (for withdrawal authorization)
    // In production: web3auth session signs via EIP-191 personal_sign

    func signMessage(_ message: String) async throws -> String {
        guard isConnected else { throw Web3AuthError.notConnected }
        // Stub: real implementation uses web3auth.provider to call personal_sign
        return "0xstub_signature_\(message.hashValue)"
    }
}

// MARK: - Web3AuthError

enum Web3AuthError: LocalizedError {
    case notConnected
    case signatureFailed
    case sdkNotInitialized

    var errorDescription: String? {
        switch self {
        case .notConnected:       return "Wallet not connected. Please connect your wallet first."
        case .signatureFailed:    return "Failed to sign the transaction."
        case .sdkNotInitialized:  return "Web3Auth SDK not initialized."
        }
    }
}

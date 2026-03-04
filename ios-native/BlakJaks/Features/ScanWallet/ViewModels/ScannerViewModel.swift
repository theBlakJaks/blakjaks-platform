import SwiftUI
import AVFoundation

@MainActor
final class ScannerViewModel: ObservableObject {

    @Published var isScanning = false
    @Published var lastScanResult: ScanResult?
    @Published var scanHistory: [Scan] = []
    @Published var errorMessage: String?
    @Published var showResult = false

    private let api: APIClientProtocol

    init(api: APIClientProtocol = APIClient.shared) {
        self.api = api
    }

    // MARK: - QR Processing

    func processQRCode(_ code: String) async {
        isScanning = true
        errorMessage = nil
        do {
            lastScanResult = try await api.submitScan(qrCode: code)
            showResult = true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isScanning = false
    }

    // MARK: - History

    func loadHistory() async {
        do {
            scanHistory = try await api.getScanHistory(limit: 30, offset: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

import Foundation
import AVFoundation

// MARK: - ScannerViewModel
// Manages camera session lifecycle and submits scanned QR codes to the API.

@MainActor
final class ScannerViewModel: ObservableObject {

    // MARK: - Published State

    @Published var scanResult: ScanResult?
    @Published var isLoading   = false
    @Published var error: Error?
    @Published var isShowingManualEntry = false

    // Manual entry input
    @Published var manualCode = ""

    // MARK: - Camera

    let scanner = QRScannerController()

    // MARK: - Dependencies

    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
        scanner.delegate = self
    }

    // MARK: - Session lifecycle

    func startSession() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.scanner.startSession()
                } else {
                    self?.error = QRScannerError.permissionDenied
                }
            }
        }
    }

    func stopSession() {
        scanner.stopSession()
    }

    // MARK: - Submit

    func submitCode(_ code: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            scanResult = try await apiClient.submitScan(qrCode: code)
        } catch {
            self.error = error
            scanner.resetForNextScan()
        }
    }

    func submitManualEntry() async {
        let code = manualCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }
        isShowingManualEntry = false
        await submitCode(code)
    }

    func dismissResult() {
        scanResult = nil
        manualCode = ""
        scanner.resetForNextScan()
    }

    func clearError() {
        error = nil
        scanner.resetForNextScan()
    }
}

// MARK: - QRScannerDelegate

extension ScannerViewModel: QRScannerDelegate {
    nonisolated func didDetect(qrCode: String) {
        Task { @MainActor in
            await submitCode(qrCode)
        }
    }

    nonisolated func didFailWithError(_ error: QRScannerError) {
        Task { @MainActor in
            self.error = error
        }
    }
}

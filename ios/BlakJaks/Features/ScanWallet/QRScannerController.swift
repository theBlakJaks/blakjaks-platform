import AVFoundation
import UIKit

// MARK: - QRScannerController
// AVFoundation QR scanner wrapper. UIKit-based; wrapped in a UIViewRepresentable
// (see ScannerView in ScanModalView.swift).
//
// Lifecycle: call startSession() on appear, stopSession() on disappear and background.
// Per iOS Strategy § Camera (QR Scanner) Lifecycle.

protocol QRScannerDelegate: AnyObject {
    func didDetect(qrCode: String)
    func didFailWithError(_ error: QRScannerError)
}

enum QRScannerError: LocalizedError {
    case cameraUnavailable
    case permissionDenied
    case sessionSetupFailed

    var errorDescription: String? {
        switch self {
        case .cameraUnavailable:   return "Camera is not available on this device."
        case .permissionDenied:    return "Camera access denied. Enable it in Settings."
        case .sessionSetupFailed:  return "Failed to start the camera session."
        }
    }
}

final class QRScannerController: NSObject, AVCaptureMetadataOutputObjectsDelegate {

    // MARK: - Public

    weak var delegate: QRScannerDelegate?
    private(set) var previewLayer: AVCaptureVideoPreviewLayer?

    // MARK: - Private

    private(set) var captureSession = AVCaptureSession()
    private var hasDetected = false   // prevent double-fire

    // MARK: - Setup

    func configure(previewView: UIView) {
        guard AVCaptureDevice.authorizationStatus(for: .video) != .denied else {
            delegate?.didFailWithError(.permissionDenied)
            return
        }

        captureSession.sessionPreset = .medium  // Per iOS Strategy: .medium not .high

        guard let device = AVCaptureDevice.default(for: .video) else {
            delegate?.didFailWithError(.cameraUnavailable)
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard captureSession.canAddInput(input) else {
                delegate?.didFailWithError(.sessionSetupFailed)
                return
            }
            captureSession.addInput(input)
        } catch {
            delegate?.didFailWithError(.sessionSetupFailed)
            return
        }

        let output = AVCaptureMetadataOutput()
        guard captureSession.canAddOutput(output) else {
            delegate?.didFailWithError(.sessionSetupFailed)
            return
        }
        captureSession.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]  // QR only — per iOS Strategy

        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        layer.frame = previewView.bounds
        previewView.layer.insertSublayer(layer, at: 0)
        previewLayer = layer
    }

    // MARK: - Session control

    func startSession() {
        guard !captureSession.isRunning else { return }
        hasDetected = false
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    func stopSession() {
        guard captureSession.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.stopRunning()
        }
    }

    func resetForNextScan() {
        hasDetected = false
    }

    // MARK: - AVCaptureMetadataOutputObjectsDelegate

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !hasDetected,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              object.type == .qr,
              let code = object.stringValue,
              !code.isEmpty else { return }

        hasDetected = true
        stopSession()  // Stop immediately after successful scan — per iOS Strategy
        delegate?.didDetect(qrCode: code)
    }
}

// MARK: - ScannerUIView
// UIViewRepresentable wrapping QRScannerController for SwiftUI.

import SwiftUI

struct ScannerUIView: UIViewRepresentable {
    @ObservedObject var viewModel: ScannerViewModel
    @Environment(\.scenePhase) private var scenePhase

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        viewModel.scanner.configure(previewView: view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Update preview layer frame on layout changes
        DispatchQueue.main.async {
            viewModel.scanner.previewLayer?.frame = uiView.bounds
        }
    }
}

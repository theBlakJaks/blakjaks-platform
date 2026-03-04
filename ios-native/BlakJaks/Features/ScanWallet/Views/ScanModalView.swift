import SwiftUI
import AVFoundation

// MARK: - ScanModalView
// Full-screen QR scanner with an animated gold scanning frame,
// result overlay, and error handling. Wraps AVCaptureSession via
// UIViewRepresentable.

struct ScanModalView: View {

    @ObservedObject var vm: ScannerViewModel
    let onResult: (ScanResult) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var cameraPermission: AVAuthorizationStatus = .notDetermined
    @State private var scanFrameAnimation = false
    @State private var cornerPulse = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch cameraPermission {
            case .authorized:
                cameraLayer
            case .denied, .restricted:
                permissionDeniedView
            default:
                requestingPermissionView
            }

            // Scanning overlay (always on top when authorized)
            if cameraPermission == .authorized {
                scanOverlay
            }
        }
        .onAppear { checkCameraPermission() }
    }

    // MARK: - Camera Layer

    private var cameraLayer: some View {
        ZStack {
            QRScannerRepresentable(
                isScanning: $vm.isScanning,
                onCodeDetected: { code in
                    guard !vm.isScanning && !vm.showResult else { return }
                    Task { await vm.processQRCode(code) }
                }
            )
            .ignoresSafeArea()

            // Dark vignette overlay around scan frame
            GeometryReader { geo in
                let frameSize: CGFloat = min(geo.size.width, geo.size.height) * 0.65
                let frameRect = CGRect(
                    x: (geo.size.width - frameSize) / 2,
                    y: (geo.size.height - frameSize) / 2,
                    width: frameSize,
                    height: frameSize
                )
                DarkVignetteOverlay(cutout: frameRect)
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: - Scan Overlay (frame + result + error)

    private var scanOverlay: some View {
        GeometryReader { geo in
            let frameSize: CGFloat = min(geo.size.width, geo.size.height) * 0.65
            let cx = geo.size.width / 2
            let cy = geo.size.height / 2 - 40

            ZStack {
                // Scanning frame with animated corners
                ScanningFrame(size: frameSize, pulse: $cornerPulse)
                    .position(x: cx, y: cy)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                            cornerPulse = true
                        }
                    }

                // Laser scan line
                if !vm.showResult && !vm.isScanning {
                    LaserLine(frameSize: frameSize)
                        .position(x: cx, y: cy)
                }

                // Instruction text
                if !vm.showResult {
                    VStack(spacing: Spacing.xs) {
                        if vm.isScanning {
                            ProgressView()
                                .tint(Color.gold)
                            Text("Processing scan…")
                                .font(BJFont.caption)
                                .foregroundColor(Color.textSecondary)
                        } else {
                            Text("Align QR code within the frame")
                                .font(BJFont.sora(13))
                                .foregroundColor(Color.textSecondary)
                        }
                    }
                    .position(x: cx, y: cy + frameSize / 2 + Spacing.xl)
                }

                // Error message
                if let err = vm.errorMessage, !vm.showResult {
                    VStack(spacing: Spacing.xs) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Color.error)
                        Text(err)
                            .font(BJFont.caption)
                            .foregroundColor(Color.error)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.xl)
                    }
                    .position(x: cx, y: cy + frameSize / 2 + Spacing.xxl)
                }

                // Result overlay
                if vm.showResult, let result = vm.lastScanResult {
                    ScanResultOverlay(result: result) {
                        vm.showResult = false
                        vm.lastScanResult = nil
                        onResult(result)
                        dismiss()
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }

                // Close button
                closeButton
                    .position(x: geo.size.width - 32, y: geo.safeAreaInsets.top + 28)
            }
        }
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color.textPrimary)
                .frame(width: 44, height: 44)
                .background(Color.black.opacity(0.55))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.borderGold, lineWidth: 0.5))
        }
    }

    // MARK: - Permission Views

    private var requestingPermissionView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView().tint(Color.gold)
            Text("Requesting camera access…")
                .font(BJFont.caption)
                .foregroundColor(Color.textSecondary)
        }
    }

    private var permissionDeniedView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "camera.slash")
                .font(.system(size: 48))
                .foregroundColor(Color.error)

            Text("Camera Access Required")
                .font(BJFont.subheading)
                .foregroundColor(Color.textPrimary)

            Text("BlakJaks needs camera access to scan QR codes. Please enable it in Settings.")
                .font(BJFont.caption)
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)

            GoldButton(title: "Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .padding(.horizontal, Spacing.xl)

            GhostButton(title: "Dismiss") { dismiss() }
                .padding(.horizontal, Spacing.xl)
        }
        .padding(Spacing.xl)
    }

    // MARK: - Permission Check

    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        cameraPermission = status
        if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    cameraPermission = granted ? .authorized : .denied
                }
            }
        }
    }
}

// MARK: - QRScannerRepresentable
// Wraps AVCaptureSession inside a UIView to scan QR codes.

struct QRScannerRepresentable: UIViewRepresentable {

    @Binding var isScanning: Bool
    let onCodeDetected: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeDetected: onCodeDetected)
    }

    func makeUIView(context: Context) -> QRScannerUIView {
        let view = QRScannerUIView()
        view.delegate = context.coordinator
        view.startSession()
        return view
    }

    func updateUIView(_ uiView: QRScannerUIView, context: Context) {
        if isScanning {
            uiView.pauseDetection()
        } else {
            uiView.resumeDetection()
        }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let onCodeDetected: (String) -> Void
        private var lastDetected: String?
        private var lastDetectedTime: Date?

        init(onCodeDetected: @escaping (String) -> Void) {
            self.onCodeDetected = onCodeDetected
        }

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let code = obj.stringValue else { return }

            // Debounce: do not fire twice for same code within 3 seconds
            let now = Date()
            if code == lastDetected,
               let t = lastDetectedTime, now.timeIntervalSince(t) < 3 { return }
            lastDetected = code
            lastDetectedTime = now

            DispatchQueue.main.async { self.onCodeDetected(code) }
        }
    }
}

// MARK: - QRScannerUIView

final class QRScannerUIView: UIView {

    weak var delegate: AVCaptureMetadataOutputObjectsDelegate?

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var metadataOutput: AVCaptureMetadataOutput?
    private var isPaused = false

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }

    func startSession() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        metadataOutput = output
        output.setMetadataObjectsDelegate(delegate, queue: .main)
        output.metadataObjectTypes = [.qr]

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = bounds
        self.layer.insertSublayer(layer, at: 0)
        previewLayer = layer

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    func pauseDetection() {
        metadataOutput?.setMetadataObjectsDelegate(nil, queue: .main)
        isPaused = true
    }

    func resumeDetection() {
        guard isPaused else { return }
        metadataOutput?.setMetadataObjectsDelegate(delegate, queue: .main)
        isPaused = false
    }
}

// MARK: - ScanningFrame
// Animated gold corner brackets defining the scan region.

private struct ScanningFrame: View {

    let size: CGFloat
    @Binding var pulse: Bool

    var body: some View {
        ZStack {
            ForEach(Corner.allCases, id: \.self) { corner in
                CornerBracket(corner: corner, size: size, pulse: pulse)
            }
        }
        .frame(width: size, height: size)
    }

    enum Corner: CaseIterable {
        case topLeft, topRight, bottomLeft, bottomRight
    }
}

private struct CornerBracket: View {

    let corner: ScanningFrame.Corner
    let size: CGFloat
    let pulse: Bool

    private let armLength: CGFloat = 28
    private let thickness: CGFloat = 3

    var body: some View {
        ZStack(alignment: alignment) {
            // Horizontal arm
            Rectangle()
                .fill(Color.gold.opacity(pulse ? 1.0 : 0.6))
                .frame(width: armLength, height: thickness)

            // Vertical arm
            Rectangle()
                .fill(Color.gold.opacity(pulse ? 1.0 : 0.6))
                .frame(width: thickness, height: armLength)
        }
        .frame(width: armLength, height: armLength)
        .frame(width: size, height: size, alignment: frameAlignment)
        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
    }

    private var alignment: Alignment {
        switch corner {
        case .topLeft:     return .topLeading
        case .topRight:    return .topTrailing
        case .bottomLeft:  return .bottomLeading
        case .bottomRight: return .bottomTrailing
        }
    }

    private var frameAlignment: Alignment {
        switch corner {
        case .topLeft:     return .topLeading
        case .topRight:    return .topTrailing
        case .bottomLeft:  return .bottomLeading
        case .bottomRight: return .bottomTrailing
        }
    }
}

// MARK: - LaserLine
// Animated horizontal scan line sweeping through the frame.

private struct LaserLine: View {

    let frameSize: CGFloat
    @State private var offset: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.clear, Color.gold.opacity(0.8), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: frameSize - 16, height: 1.5)
            .offset(y: offset)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    offset = frameSize / 2 - 8
                }
            }
    }
}

// MARK: - DarkVignetteOverlay
// Semi-transparent overlay with a transparent rectangular cutout for the scan frame.

private struct DarkVignetteOverlay: View {

    let cutout: CGRect

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                var path = Path(CGRect(origin: .zero, size: size))
                path.addRoundedRect(
                    in: cutout,
                    cornerSize: CGSize(width: Radius.sm, height: Radius.sm)
                )
                context.fill(path, with: .color(Color.black.opacity(0.72)), style: FillStyle(eoFill: true))
            }
        }
    }
}

// MARK: - ScanResultOverlay
// Success overlay shown after a successful scan.

private struct ScanResultOverlay: View {

    let result: ScanResult
    let onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                // Success icon
                ZStack {
                    Circle()
                        .fill(Color.success.opacity(0.12))
                        .frame(width: 88, height: 88)
                        .overlay(Circle().stroke(Color.success.opacity(0.3), lineWidth: 1))
                    Image(systemName: "checkmark")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color.success)
                }
                .scaleEffect(appeared ? 1.0 : 0.5)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: appeared)

                // Product name
                VStack(spacing: Spacing.xs) {
                    Text("SCAN SUCCESSFUL")
                        .font(BJFont.eyebrow)
                        .tracking(4)
                        .foregroundColor(Color.textTertiary)

                    Text(result.productName)
                        .font(BJFont.playfair(22, weight: .bold))
                        .foregroundColor(Color.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }

                // Earned amount
                BlakJaksCard(padding: Spacing.lg) {
                    VStack(spacing: Spacing.sm) {
                        HStack(spacing: Spacing.xl) {
                            earnedStat(label: "USDC EARNED",
                                       value: "+\(result.usdcEarned.usdFormatted)",
                                       color: .creditAmount)

                            Divider()
                                .background(Color.borderGold)
                                .frame(height: 40)

                            earnedStat(label: "TIER MULT",
                                       value: "×\(String(format: "%.1f", result.tierMultiplier))",
                                       color: .gold)
                        }

                        if result.milestoneHit {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.gold)
                                Text("MILESTONE HIT!")
                                    .font(BJFont.eyebrow)
                                    .tracking(2)
                                    .foregroundColor(Color.gold)
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.gold)
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.xs)
                            .background(Color.gold.opacity(0.1))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.gold.opacity(0.3), lineWidth: 0.8))
                        }

                        // Tier progress note
                        if let nextTier = result.tierProgress.nextTier,
                           let scansNeeded = result.tierProgress.scansRequired {
                            Text("\(scansNeeded) scans to \(nextTier)")
                                .font(BJFont.caption)
                                .foregroundColor(Color.textTertiary)
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)

                GoldButton(title: "Continue", action: onDismiss)
                    .padding(.horizontal, Spacing.xl)
            }
            .padding(.vertical, Spacing.xl)
        }
        .onAppear { appeared = true }
    }

    private func earnedStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(BJFont.micro)
                .tracking(2)
                .foregroundColor(Color.textTertiary)
            Text(value)
                .font(BJFont.outfit(22, weight: .heavy))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ScanModalView(vm: ScannerViewModel(), onResult: { _ in })
}

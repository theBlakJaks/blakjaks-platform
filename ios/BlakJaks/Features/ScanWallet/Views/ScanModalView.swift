import SwiftUI

// MARK: - ScanModalView
// Full-screen cover with 3 states: Camera, Manual Entry, Confirmation.
// Per iOS Strategy § 4.3.2 Scan Modal spec.

struct ScanModalView: View {
    @ObservedObject var viewModel: ScannerViewModel
    @Binding var isPresented: Bool
    var onPayoutChoice: ((String, String) -> Void)? = nil  // (compId, method)
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let result = viewModel.scanResult {
                ScanConfirmationView(result: result, onDone: {
                    viewModel.dismissResult()
                    isPresented = false
                }, onPayoutChoice: { method in
                    if let comp = result.compEarned {
                        onPayoutChoice?(comp.id, method)
                    }
                    viewModel.dismissResult()
                    isPresented = false
                })
            } else if viewModel.isShowingManualEntry {
                ManualEntryView(viewModel: viewModel)
            } else {
                CameraView(viewModel: viewModel, isPresented: $isPresented)
            }
        }
        .onAppear { viewModel.startSession() }
        .onDisappear { viewModel.stopSession() }
        .onChange(of: scenePhase) { phase in
            if phase == .background { viewModel.stopSession() }
            if phase == .active && viewModel.scanResult == nil && !viewModel.isShowingManualEntry {
                viewModel.startSession()
            }
        }
        .overlay(alignment: .topLeading) {
            if viewModel.scanResult == nil {
                Button { isPresented = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Circle().fill(Color.white.opacity(0.15)))
                }
                .padding(.top, 56)
                .padding(.leading, Layout.screenMargin)
            }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") { viewModel.clearError() }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "")
        }
    }
}

// MARK: - CameraView

private struct CameraView: View {
    @ObservedObject var viewModel: ScannerViewModel
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            // Camera preview
            ScannerUIView(viewModel: viewModel)
                .ignoresSafeArea()

            // Dark overlay outside scan frame
            GeometryReader { geo in
                let frameSize: CGFloat = min(geo.size.width, geo.size.height) * 0.65
                let frameX = (geo.size.width - frameSize) / 2
                let frameY = (geo.size.height - frameSize) / 2

                ZStack {
                    Color.black.opacity(0.55)
                        .ignoresSafeArea()
                    RoundedRectangle(cornerRadius: 16)
                        .frame(width: frameSize, height: frameSize)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                        .blendMode(.destinationOut)
                }
                .compositingGroup()

                // Corner brackets
                cornerBrackets(frameX: frameX, frameY: frameY, size: frameSize)

                // Animated laser line
                LaserLineView(frameX: frameX, frameY: frameY, frameSize: frameSize)
            }

            // Bottom controls
            VStack {
                Spacer()
                VStack(spacing: Spacing.md) {
                    Text("Align QR code within frame")
                        .font(.body.weight(.medium))
                        .foregroundColor(.white.opacity(0.85))

                    if viewModel.isLoading {
                        ProgressView().tint(.gold)
                    } else {
                        Button {
                            viewModel.stopSession()
                            viewModel.isShowingManualEntry = true
                        } label: {
                            Text("Enter Code Manually")
                                .font(.body.weight(.medium))
                                .foregroundColor(.gold)
                                .padding(.horizontal, Spacing.xl)
                                .padding(.vertical, Spacing.sm)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Layout.buttonCornerRadius)
                                        .stroke(Color.gold.opacity(0.7), lineWidth: 1.5)
                                )
                        }
                    }
                }
                .padding(.bottom, 60)
            }
        }
    }

    private func cornerBrackets(frameX: CGFloat, frameY: CGFloat, size: CGFloat) -> some View {
        let len: CGFloat = 24
        let thickness: CGFloat = 3
        let color = Color.gold
        return ZStack {
            // Top-left
            Path { p in
                p.move(to: CGPoint(x: frameX, y: frameY + len))
                p.addLine(to: CGPoint(x: frameX, y: frameY))
                p.addLine(to: CGPoint(x: frameX + len, y: frameY))
            }.stroke(color, style: StrokeStyle(lineWidth: thickness, lineCap: .round))
            // Top-right
            Path { p in
                p.move(to: CGPoint(x: frameX + size - len, y: frameY))
                p.addLine(to: CGPoint(x: frameX + size, y: frameY))
                p.addLine(to: CGPoint(x: frameX + size, y: frameY + len))
            }.stroke(color, style: StrokeStyle(lineWidth: thickness, lineCap: .round))
            // Bottom-left
            Path { p in
                p.move(to: CGPoint(x: frameX, y: frameY + size - len))
                p.addLine(to: CGPoint(x: frameX, y: frameY + size))
                p.addLine(to: CGPoint(x: frameX + len, y: frameY + size))
            }.stroke(color, style: StrokeStyle(lineWidth: thickness, lineCap: .round))
            // Bottom-right
            Path { p in
                p.move(to: CGPoint(x: frameX + size - len, y: frameY + size))
                p.addLine(to: CGPoint(x: frameX + size, y: frameY + size))
                p.addLine(to: CGPoint(x: frameX + size, y: frameY + size - len))
            }.stroke(color, style: StrokeStyle(lineWidth: thickness, lineCap: .round))
        }
    }
}

// MARK: - LaserLineView

private struct LaserLineView: View {
    let frameX: CGFloat
    let frameY: CGFloat
    let frameSize: CGFloat
    @State private var offset: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.gold.opacity(0), Color.gold, Color.gold.opacity(0)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: frameSize - 24, height: 1.5)
            .position(x: frameX + frameSize / 2, y: frameY + 12 + offset)
            .onAppear {
                withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: true)) {
                    offset = frameSize - 24
                }
            }
    }
}

// MARK: - ManualEntryView

private struct ManualEntryView: View {
    @ObservedObject var viewModel: ScannerViewModel
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image(systemName: "keyboard")
                .font(.system(size: 52, weight: .light))
                .foregroundColor(.gold)

            VStack(spacing: Spacing.sm) {
                Text("Enter Code Manually")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                Text("Format: XXXX-XXXX-XXXX")
                    .font(.body)
                    .foregroundColor(Color.white.opacity(0.6))
            }

            TextField("A3K7-B9M2-X4P6", text: $viewModel.manualCode)
                .font(.system(.title3, design: .monospaced))
                .multilineTextAlignment(.center)
                .keyboardType(.asciiCapable)
                .autocapitalization(.allCharacters)
                .autocorrectionDisabled()
                .focused($focused)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(Layout.buttonCornerRadius)
                .padding(.horizontal, Layout.screenMargin)

            GoldButton(
                "Submit",
                isLoading: viewModel.isLoading
            ) {
                await viewModel.submitManualEntry()
            }
            .padding(.horizontal, Layout.screenMargin)
            .disabled(viewModel.manualCode.count < 14)
            .opacity(viewModel.manualCode.count >= 14 ? 1 : 0.5)

            Button {
                viewModel.isShowingManualEntry = false
                viewModel.startSession()
            } label: {
                Text("Back to Camera")
                    .font(.body)
                    .foregroundColor(.gold)
            }

            Spacer()
        }
        .onAppear { focused = true }
    }
}

// MARK: - ScanConfirmationView

struct ScanConfirmationView: View {
    let result: ScanResult
    let onDone: () -> Void
    var onPayoutChoice: ((String) -> Void)? = nil

    @State private var checkmarkTrim: CGFloat = 0
    @State private var showDetails    = false
    @State private var showPayoutChoice = false

    // Haptics
    private let impact   = UIImpactFeedbackGenerator(style: .heavy)
    private let notif    = UINotificationFeedbackGenerator()

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                Spacer().frame(height: Spacing.xxl)

                // Animated checkmark
                animatedCheckmark

                // Product name
                VStack(spacing: Spacing.sm) {
                    Text(result.productName)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    Text("Scan confirmed!")
                        .font(.body)
                        .foregroundColor(Color.white.opacity(0.7))
                }
                .opacity(showDetails ? 1 : 0)

                if showDetails {
                    // Tier Progress Card
                    tierProgressCard
                        .transition(.move(edge: .bottom).combined(with: .opacity))

                    // Comp Earned Card
                    if let comp = result.compEarned {
                        compEarnedCard(comp: comp)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Done / Claim button
                    if let comp = result.compEarned, comp.requiresPayoutChoice {
                        GoldButton("Claim Comp") {
                            showPayoutChoice = true
                        }
                        .padding(.horizontal, Layout.screenMargin)
                        .transition(.opacity)
                    } else {
                        GoldButton("Done") { onDone() }
                            .padding(.horizontal, Layout.screenMargin)
                            .transition(.opacity)
                    }
                }

                Spacer().frame(height: Spacing.xxl)
            }
            .padding(.horizontal, Layout.screenMargin)
        }
        .onAppear { triggerHapticsAndAnimate() }
        .sheet(isPresented: $showPayoutChoice) {
            if let comp = result.compEarned {
                PayoutChoiceSheet(comp: comp) { method in
                    showPayoutChoice = false
                    onPayoutChoice?(method)
                    onDone()
                }
            }
        }
    }

    private var animatedCheckmark: some View {
        ZStack {
            Circle()
                .fill(Color.gold)
                .frame(width: 80, height: 80)
            Path { path in
                path.move(to: CGPoint(x: 22, y: 42))
                path.addLine(to: CGPoint(x: 35, y: 55))
                path.addLine(to: CGPoint(x: 58, y: 28))
            }
            .trim(from: 0, to: checkmarkTrim)
            .stroke(.black, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
        }
    }

    private var tierProgressCard: some View {
        let tp = result.tierProgress
        return VStack(alignment: .leading, spacing: Spacing.md) {
            Text("\(tp.quarter) Tier Progress")
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)

            HStack {
                Text("+\(tp.currentCount) scan\(tp.currentCount == 1 ? "" : "s")")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.primary)
                Spacer()
                if let next = tp.nextTier, let required = tp.scansRequired {
                    Text("\(required) more → \(next)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.backgroundSecondary)
        .cornerRadius(Layout.cardCornerRadius)
    }

    private func compEarnedCard(comp: CompEarned) -> some View {
        VStack(spacing: Spacing.md) {
            Text("Comp Earned")
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)

            Text("+$\(comp.amount.formatted(.number.precision(.fractionLength(2))))")
                .font(.walletBalance)
                .foregroundColor(.gold)
                .contentTransition(.numericText())

            if comp.requiresPayoutChoice {
                Text("Choose how to receive your comp below.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Comp added to your virtual balance · Pending payout")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Spacing.md)
        .background(Color.backgroundSecondary)
        .cornerRadius(Layout.cardCornerRadius)
    }

    private func triggerHapticsAndAnimate() {
        impact.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            notif.notificationOccurred(.success)
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
            checkmarkTrim = 1
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
            showDetails = true
        }
    }
}

// MARK: - Preview

#Preview {
    ScanModalView(
        viewModel: ScannerViewModel(apiClient: MockAPIClient()),
        isPresented: .constant(true)
    )
}

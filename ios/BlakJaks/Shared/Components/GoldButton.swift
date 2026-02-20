import SwiftUI

// MARK: - GoldButton
// Primary CTA: 50pt height, 16pt radius, gold background, black text, loading state.
// Usage: GoldButton("Withdraw to Bank") { await viewModel.withdraw() }

struct GoldButton: View {
    let title: String
    let isLoading: Bool
    let isDisabled: Bool
    let action: () async -> Void

    init(
        _ title: String,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () async -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button {
            Task { await action() }
        } label: {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.black)
                } else {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.black)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: Layout.buttonHeight)
        }
        .background(isDisabled ? Color.gold.opacity(0.4) : Color.gold)
        .cornerRadius(Layout.buttonCornerRadius)
        .disabled(isLoading || isDisabled)
    }
}

// MARK: - SecondaryButton (outline style)

struct SecondaryButton: View {
    let title: String
    let isLoading: Bool
    let action: () async -> Void

    init(_ title: String, isLoading: Bool = false, action: @escaping () async -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button {
            Task { await action() }
        } label: {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.gold)
                } else {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.gold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: Layout.buttonHeight)
        }
        .overlay(
            RoundedRectangle(cornerRadius: Layout.buttonCornerRadius)
                .strokeBorder(Color.gold, lineWidth: 1.5)
        )
        .disabled(isLoading)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        GoldButton("Withdraw to Bank") {}
        GoldButton("Loading...", isLoading: true) {}
        GoldButton("Disabled", isDisabled: true) {}
        SecondaryButton("Withdraw as Crypto") {}
    }
    .padding()
    .background(Color.backgroundPrimary)
}

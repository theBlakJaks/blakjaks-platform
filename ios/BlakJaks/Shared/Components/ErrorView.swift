import SwiftUI

// MARK: - ErrorView
// Displays an error message with a retry button.
// Usage: ErrorView(error: viewModel.error) { await viewModel.reload() }

struct ErrorView: View {
    let error: Error?
    let retryAction: (() async -> Void)?

    init(error: Error?, retry retryAction: (() async -> Void)? = nil) {
        self.error = error
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.warning)

            VStack(spacing: Spacing.sm) {
                Text("Something went wrong")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.primary)

                if let error {
                    Text(error.localizedDescription)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            if let retryAction {
                Button("Try Again") {
                    Task { await retryAction() }
                }
                .buttonStyle(.borderedProminent)
                .tint(.gold)
            }
        }
        .padding(Layout.screenMargin * 2)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Inline error banner (for form validation)

struct InlineErrorView: View {
    let message: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.failure)
            Text(message)
                .font(.footnote)
                .foregroundColor(.failure)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        ErrorView(
            error: APIError.serverError(statusCode: 500, message: "Internal server error. Please try again."),
            retry: {}
        )

        InlineErrorView(message: "Email address is required.")
    }
    .background(Color.backgroundPrimary)
}

import SwiftUI

// MARK: - LoadingView
// Skeleton shimmer using .redacted(reason: .placeholder)
// Use instead of a spinner — matches premium app feel.

struct LoadingView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Simulated card skeleton
            BlakJaksCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Loading label placeholder")
                        .font(.caption)
                    Text("Loading value here")
                        .font(.title2)
                    Text("Secondary info line")
                        .font(.body)
                }
            }
            .redacted(reason: .placeholder)
            .shimmering()

            BlakJaksCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Another card title")
                        .font(.headline)
                    Text("Card content placeholder text goes here and spans multiple lines.")
                        .font(.body)
                }
            }
            .redacted(reason: .placeholder)
            .shimmering()
        }
        .padding(.horizontal, Layout.screenMargin)
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.white.opacity(0), location: phase - 0.3),
                        .init(color: Color.white.opacity(0.15), location: phase),
                        .init(color: Color.white.opacity(0), location: phase + 0.3)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 1.3
                }
            }
    }
}

extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Preview

#Preview {
    LoadingView()
        .background(Color.backgroundPrimary)
}

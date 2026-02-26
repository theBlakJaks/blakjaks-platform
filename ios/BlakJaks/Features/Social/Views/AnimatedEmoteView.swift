import SwiftUI
import ImageIO
import UIKit

// MARK: - AnimatedEmoteView
// Renders a 7TV emote GIF with full frame animation.
// AsyncImage only shows the first frame — this uses CGImageSource to extract
// every frame + delay, then drives UIImageView.animationImages for smooth looping.

struct AnimatedEmoteView: UIViewRepresentable {
    let url: URL
    let size: CGFloat

    func makeUIView(context: Context) -> UIImageView {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        return iv
    }

    func updateUIView(_ iv: UIImageView, context: Context) {
        iv.stopAnimating()
        iv.image = nil
        context.coordinator.load(url: url, into: iv)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        private var currentURL: URL?
        private var task: Task<Void, Never>?

        func load(url: URL, into iv: UIImageView) {
            guard url != currentURL else { return }
            currentURL = url
            task?.cancel()
            task = Task {
                guard let (data, _) = try? await URLSession.shared.data(from: url),
                      !Task.isCancelled else { return }
                let (images, duration) = await Task.detached(priority: .userInitiated) {
                    Self.decodeFrames(data: data)
                }.value
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    if images.count > 1 {
                        iv.animationImages = images
                        iv.animationDuration = duration
                        iv.animationRepeatCount = 0
                        iv.startAnimating()
                    } else {
                        iv.image = images.first
                    }
                }
            }
        }

        private static func decodeFrames(data: Data) -> ([UIImage], TimeInterval) {
            guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
                return (UIImage(data: data).map { [$0] } ?? [], 0)
            }
            let count = CGImageSourceGetCount(source)
            var images: [UIImage] = []
            var totalDuration: TimeInterval = 0

            for i in 0..<count {
                guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
                let delay = frameDelay(source: source, index: i)
                totalDuration += delay
                images.append(UIImage(cgImage: cgImage))
            }
            return (images, totalDuration > 0 ? totalDuration : TimeInterval(count) * 0.1)
        }

        private static func frameDelay(source: CGImageSource, index: Int) -> TimeInterval {
            let props = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any]
            // Try GIF dictionary first, then WebP
            let gifDict = props?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
            let delay = (gifDict?[kCGImagePropertyGIFUnclampedDelayTime]
                      ?? gifDict?[kCGImagePropertyGIFDelayTime]) as? TimeInterval
            return (delay ?? 0) > 0.01 ? (delay ?? 0.1) : 0.1
        }
    }
}

import SwiftUI
import ImageIO
import UniformTypeIdentifiers

// MARK: - AnimatedImageView

/// Displays animated GIFs and animated WebP images using UIKit's UIImageView.
/// SwiftUI's AsyncImage only renders the first frame — this view animates the full sequence.

struct AnimatedImageView: View {

    let url: URL
    var height: CGFloat = 28
    var maxWidth: CGFloat? = nil
    var contentMode: UIView.ContentMode = .scaleAspectFit

    @State private var animatedImage: UIImage?
    @State private var isLoading = true
    @State private var failed = false

    var body: some View {
        Group {
            if let image = animatedImage {
                AnimatedUIImageView(image: image, contentMode: contentMode)
                    .frame(maxWidth: maxWidth, maxHeight: height)
            } else if failed {
                fallbackView
            } else {
                placeholder
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.clear)
            .frame(width: height, height: height)
            .overlay(
                ProgressView()
                    .tint(Color.gold)
                    .scaleEffect(0.5)
            )
    }

    private var fallbackView: some View {
        Image(systemName: "photo")
            .font(.system(size: height * 0.5))
            .foregroundColor(Color.textTertiary)
            .frame(width: height, height: height)
    }

    private func loadImage() async {
        isLoading = true
        failed = false

        // Check memory cache first
        if let cached = AnimatedImageCache.shared.get(url) {
            animatedImage = cached
            isLoading = false
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = createAnimatedImage(from: data) {
                AnimatedImageCache.shared.set(url, image: image)
                animatedImage = image
            } else {
                // Fallback to regular UIImage (static)
                if let staticImage = UIImage(data: data) {
                    animatedImage = staticImage
                } else {
                    failed = true
                }
            }
        } catch {
            failed = true
        }
        isLoading = false
    }

    /// Create an animated UIImage from GIF or animated WebP data using ImageIO.
    private func createAnimatedImage(from data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let count = CGImageSourceGetCount(source)
        guard count > 1 else { return nil } // Not animated

        var images: [UIImage] = []
        var totalDuration: Double = 0

        for i in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
            images.append(UIImage(cgImage: cgImage))

            // Get frame duration
            if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any] {
                let frameDuration = gifFrameDuration(from: properties)
                    ?? webpFrameDuration(from: properties)
                    ?? 0.1
                totalDuration += frameDuration
            } else {
                totalDuration += 0.1
            }
        }

        guard !images.isEmpty else { return nil }
        return UIImage.animatedImage(with: images, duration: totalDuration)
    }

    private func gifFrameDuration(from properties: [String: Any]) -> Double? {
        guard let gifProps = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any] else { return nil }
        if let delay = gifProps[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double, delay > 0 {
            return delay
        }
        if let delay = gifProps[kCGImagePropertyGIFDelayTime as String] as? Double, delay > 0 {
            return delay
        }
        return nil
    }

    private func webpFrameDuration(from properties: [String: Any]) -> Double? {
        guard let webpProps = properties[kCGImagePropertyWebPDictionary as String] as? [String: Any] else { return nil }
        if let delay = webpProps[kCGImagePropertyWebPUnclampedDelayTime as String] as? Double, delay > 0 {
            return delay
        }
        if let delay = webpProps[kCGImagePropertyWebPDelayTime as String] as? Double, delay > 0 {
            return delay
        }
        return nil
    }
}

// MARK: - UIKit Bridge

private struct AnimatedUIImageView: UIViewRepresentable {
    let image: UIImage
    var contentMode: UIView.ContentMode = .scaleAspectFit

    func makeUIView(context: Context) -> UIImageView {
        let iv = UIImageView()
        iv.contentMode = contentMode
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = false
        iv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        iv.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return iv
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.image = image
        uiView.contentMode = contentMode
    }
}

// MARK: - Simple Memory Cache

private final class AnimatedImageCache {
    static let shared = AnimatedImageCache()
    private let cache = NSCache<NSURL, UIImage>()

    init() {
        cache.countLimit = 200
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }

    func get(_ url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func set(_ url: URL, image: UIImage) {
        cache.setObject(image, forKey: url as NSURL)
    }
}

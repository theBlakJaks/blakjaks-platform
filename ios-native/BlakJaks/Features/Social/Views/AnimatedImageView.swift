import SwiftUI
import ImageIO
import UniformTypeIdentifiers
import CryptoKit

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
        if let cached = AnimatedImageCache.shared.getMemory(url) {
            animatedImage = cached
            isLoading = false
            return
        }

        // Check disk cache
        if let diskData = AnimatedImageCache.shared.getDisk(url) {
            if let image = Self.createAnimatedImage(from: diskData, maxPixelSize: height * UIScreen.main.scale) {
                AnimatedImageCache.shared.setMemory(url, image: image)
                animatedImage = image
                isLoading = false
                return
            }
        }

        // Deduplicate in-flight requests & throttle downloads
        let image = await AnimatedImageCache.shared.loadOrJoin(url: url) {
            await ImageDownloadThrottle.shared.throttled {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    // Save to disk cache
                    AnimatedImageCache.shared.saveDisk(url, data: data)
                    return data
                } catch {
                    return nil
                }
            }
        }

        if let image {
            animatedImage = image
        } else {
            failed = true
        }
        isLoading = false
    }

    /// Create an animated UIImage from GIF or animated WebP data using ImageIO.
    /// Subsamples large frames and caps frame count for memory efficiency.
    static func createAnimatedImage(from data: Data, maxPixelSize: CGFloat = 56, maxFrames: Int = 60) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let count = min(CGImageSourceGetCount(source), maxFrames)
        guard count > 1 else { return nil } // Not animated

        let thumbOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]

        var images: [UIImage] = []
        var totalDuration: Double = 0

        for i in 0..<count {
            let cgImage: CGImage?
            if maxPixelSize <= 200 {
                cgImage = CGImageSourceCreateThumbnailAtIndex(source, i, thumbOptions as CFDictionary)
            } else {
                cgImage = CGImageSourceCreateImageAtIndex(source, i, nil)
            }
            guard let frame = cgImage else { continue }
            images.append(UIImage(cgImage: frame))

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

    private static func gifFrameDuration(from properties: [String: Any]) -> Double? {
        guard let gifProps = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any] else { return nil }
        if let delay = gifProps[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double, delay > 0 {
            return delay
        }
        if let delay = gifProps[kCGImagePropertyGIFDelayTime as String] as? Double, delay > 0 {
            return delay
        }
        return nil
    }

    private static func webpFrameDuration(from properties: [String: Any]) -> Double? {
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

// MARK: - AnimatedImageCache (Memory + Disk + Deduplication)

private final class AnimatedImageCache: @unchecked Sendable {
    static let shared = AnimatedImageCache()

    private let memoryCache = NSCache<NSURL, UIImage>()
    private let queue = DispatchQueue(label: "com.blakjaks.animatedImageCache", attributes: .concurrent)
    private var inFlight: [URL: Task<UIImage?, Never>] = [:]

    private var diskCacheURL: URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("animated_images", isDirectory: true)
    }

    init() {
        memoryCache.countLimit = 200
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB

        // Ensure disk cache directory exists
        let fm = FileManager.default
        if !fm.fileExists(atPath: diskCacheURL.path) {
            try? fm.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        }
    }

    // MARK: Memory

    func getMemory(_ url: URL) -> UIImage? {
        memoryCache.object(forKey: url as NSURL)
    }

    func setMemory(_ url: URL, image: UIImage) {
        memoryCache.setObject(image, forKey: url as NSURL)
    }

    // MARK: Disk

    private func diskPath(for url: URL) -> URL {
        let hash = Insecure.SHA1.hash(data: Data(url.absoluteString.utf8))
        let name = hash.map { String(format: "%02x", $0) }.joined()
        return diskCacheURL.appendingPathComponent(name)
    }

    func getDisk(_ url: URL) -> Data? {
        let path = diskPath(for: url)
        return try? Data(contentsOf: path)
    }

    func saveDisk(_ url: URL, data: Data) {
        let path = diskPath(for: url)
        try? data.write(to: path, options: .atomic)
    }

    // MARK: Deduplication

    /// Deduplicates in-flight requests. If a download for the same URL is already
    /// in progress, awaits the existing task instead of starting a new one.
    func loadOrJoin(url: URL, fetch: @escaping () async -> Data?) async -> UIImage? {
        // Check if there's an in-flight task
        let existingTask: Task<UIImage?, Never>? = queue.sync { inFlight[url] }
        if let task = existingTask {
            return await task.value
        }

        let task = Task<UIImage?, Never> {
            guard let data = await fetch() else { return nil }
            let scale = await UIScreen.main.scale
            let image = AnimatedImageView.createAnimatedImage(from: data, maxPixelSize: 56 * scale)
            if let image {
                setMemory(url, image: image)
            } else if let staticImage = UIImage(data: data) {
                setMemory(url, image: staticImage)
                return staticImage
            }
            return image
        }

        queue.sync(flags: .barrier) { inFlight[url] = task }
        let result = await task.value
        queue.sync(flags: .barrier) { inFlight.removeValue(forKey: url) }
        return result
    }
}

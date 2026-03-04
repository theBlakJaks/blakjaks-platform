import SwiftUI
import UIKit

// MARK: - EmoteRichInput

/// UITextView-based input that displays emote images inline (Twitch-style).
/// Emotes are inserted as NSTextAttachment images. When extracting text for
/// sending, attachments are converted back to their emote name strings.

struct EmoteRichInput: UIViewRepresentable {

    @Binding var text: String
    @Binding var pendingEmote: CachedEmote?
    @Binding var isFirstResponder: Bool
    let placeholder: String
    let maxCharacters: Int
    let emoteMap: [String: CachedEmote]
    var onSubmit: (() -> Void)?
    var onTextChange: ((String) -> Void)?
    var onBeginEditing: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        tv.backgroundColor = .clear
        tv.textColor = .white
        tv.font = UIFont.systemFont(ofSize: 15)
        tv.tintColor = UIColor(red: 0.85, green: 0.72, blue: 0.35, alpha: 1)
        tv.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        tv.isScrollEnabled = true
        tv.returnKeyType = .send
        tv.enablesReturnKeyAutomatically = true
        tv.autocorrectionType = .default
        tv.spellCheckingType = .default
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // Placeholder label
        let label = UILabel()
        label.text = placeholder
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = UIColor(white: 0.45, alpha: 1)
        label.tag = 999
        label.translatesAutoresizingMaskIntoConstraints = false
        tv.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: tv.leadingAnchor, constant: 13),
            label.topAnchor.constraint(equalTo: tv.topAnchor, constant: 10)
        ])

        context.coordinator.textView = tv

        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.textView = uiView

        // Handle pending emote insertion — MUST defer to avoid
        // "Modifying state during view update" which silently drops changes
        if let emote = pendingEmote, !context.coordinator.isHandlingEmote {
            context.coordinator.isHandlingEmote = true
            DispatchQueue.main.async {
                self.pendingEmote = nil
                context.coordinator.insertEmote(emote, into: uiView)
                context.coordinator.isHandlingEmote = false
            }
        } else if pendingEmote == nil, text.isEmpty {
            // If text was cleared externally (e.g. after send), clear the rich input
            let currentPlain = context.coordinator.extractPlainText(from: uiView.attributedText)
            if !currentPlain.isEmpty {
                DispatchQueue.main.async {
                    context.coordinator.clearTextView(uiView)
                }
            }
        }

        context.coordinator.updatePlaceholder(uiView)

        // First responder management driven by binding
        if isFirstResponder && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !isFirstResponder && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: EmoteRichInput
        var isUpdating = false
        var isHandlingEmote = false
        weak var textView: UITextView?
        private let emoteHeight: CGFloat = 22

        init(_ parent: EmoteRichInput) {
            self.parent = parent
        }

        // MARK: - Insert Emote

        func insertEmote(_ emote: CachedEmote, into textView: UITextView) {
            let currentLength = extractPlainText(from: textView.attributedText).count
            if currentLength + emote.name.count + 2 > parent.maxCharacters { return }

            let mutable = NSMutableAttributedString(attributedString: textView.attributedText)
            var insertPos = textView.selectedRange.location

            // Add space before if needed
            if insertPos > 0 {
                let beforeRange = NSRange(location: insertPos - 1, length: 1)
                let before = (mutable.string as NSString).substring(with: beforeRange)
                if before != " " && before != "\n" {
                    let space = NSAttributedString(string: " ", attributes: defaultAttributes())
                    mutable.insert(space, at: insertPos)
                    insertPos += 1
                }
            }

            // Create emote attachment
            let attachment = EmoteTextAttachment()
            attachment.emoteName = emote.name
            attachment.emoteId = emote.id

            let size = CGSize(width: emoteHeight, height: emoteHeight)
            attachment.bounds = CGRect(origin: CGPoint(x: 0, y: -4), size: size)

            // Try cached image first, fall back to placeholder + async load
            if let url = emote.url(size: "2x"), let cached = EmoteImageLoader.shared.cachedImage(for: url) {
                attachment.image = cached
            } else {
                attachment.image = createPlaceholderImage(size: size)
                if let url = emote.url(size: "2x") {
                    Task { @MainActor [weak textView, weak attachment] in
                        if let image = await EmoteImageLoader.shared.loadImage(url: url) {
                            attachment?.image = image
                            guard let tv = textView else { return }
                            let fullRange = NSRange(location: 0, length: tv.attributedText.length)
                            tv.layoutManager.invalidateDisplay(forCharacterRange: fullRange)
                        }
                    }
                }
            }

            let emoteStr = NSMutableAttributedString(attachment: attachment)
            emoteStr.addAttributes(defaultAttributes(), range: NSRange(location: 0, length: emoteStr.length))
            mutable.insert(emoteStr, at: insertPos)

            // Trailing space
            let trailingSpace = NSAttributedString(string: " ", attributes: defaultAttributes())
            mutable.insert(trailingSpace, at: insertPos + 1)

            isUpdating = true
            textView.attributedText = mutable
            textView.selectedRange = NSRange(location: insertPos + 2, length: 0)
            syncText(from: textView)
            isUpdating = false
        }

        // MARK: - Extract Plain Text

        func extractPlainText(from attributed: NSAttributedString) -> String {
            var result = ""
            attributed.enumerateAttributes(in: NSRange(location: 0, length: attributed.length)) { attrs, range, _ in
                if let attachment = attrs[.attachment] as? EmoteTextAttachment,
                   let name = attachment.emoteName {
                    result += name
                } else {
                    result += (attributed.string as NSString).substring(with: range)
                }
            }
            return result
        }

        // MARK: - UITextViewDelegate

        func textViewDidChange(_ textView: UITextView) {
            guard !isUpdating else { return }

            let plain = extractPlainText(from: textView.attributedText)
            if plain.count > parent.maxCharacters {
                isUpdating = true
                let excess = plain.count - parent.maxCharacters
                let cursorPos = textView.selectedRange.location
                let deleteFrom = max(0, cursorPos - excess)
                let mutable = NSMutableAttributedString(attributedString: textView.attributedText)
                mutable.deleteCharacters(in: NSRange(location: deleteFrom, length: min(excess, mutable.length - deleteFrom)))
                textView.attributedText = mutable
                textView.selectedRange = NSRange(location: deleteFrom, length: 0)
                isUpdating = false
            }

            syncText(from: textView)
            updatePlaceholder(textView)
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if text == "\n" {
                parent.onSubmit?()
                return false
            }
            return true
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            updatePlaceholder(textView)
            if !parent.isFirstResponder {
                DispatchQueue.main.async { self.parent.isFirstResponder = true }
            }
            parent.onBeginEditing?()
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            updatePlaceholder(textView)
            if parent.isFirstResponder {
                DispatchQueue.main.async { self.parent.isFirstResponder = false }
            }
        }

        // MARK: - Helpers

        private func syncText(from textView: UITextView) {
            let plain = extractPlainText(from: textView.attributedText)
            if parent.text != plain {
                parent.text = plain
                parent.onTextChange?(plain)
            }
        }

        func updatePlaceholder(_ textView: UITextView) {
            if let label = textView.viewWithTag(999) as? UILabel {
                label.isHidden = textView.attributedText.length > 0
            }
        }

        func defaultAttributes() -> [NSAttributedString.Key: Any] {
            [
                .font: UIFont.systemFont(ofSize: 15),
                .foregroundColor: UIColor.white
            ]
        }

        private func createPlaceholderImage(size: CGSize) -> UIImage {
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { _ in
                UIColor(white: 0.3, alpha: 1).setFill()
                UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 4).fill()
            }
        }

        func clearTextView(_ textView: UITextView) {
            isUpdating = true
            textView.attributedText = NSAttributedString(string: "", attributes: defaultAttributes())
            parent.text = ""
            updatePlaceholder(textView)
            isUpdating = false
        }
    }
}

// MARK: - EmoteTextAttachment

final class EmoteTextAttachment: NSTextAttachment {
    var emoteName: String?
    var emoteId: String?
}

// MARK: - EmoteImageLoader

/// Async image loader with NSCache for emote thumbnails used in the input bar.
final class EmoteImageLoader {
    static let shared = EmoteImageLoader()
    private let cache = NSCache<NSURL, UIImage>()
    private var inFlight: [URL: Task<UIImage?, Never>] = [:]

    init() {
        cache.countLimit = 300
    }

    func cachedImage(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func loadImage(url: URL) async -> UIImage? {
        if let cached = cache.object(forKey: url as NSURL) {
            return cached
        }

        if let existing = inFlight[url] {
            return await existing.value
        }

        let task = Task<UIImage?, Never> {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else { return nil }
                let size = CGSize(width: 22, height: 22)
                let renderer = UIGraphicsImageRenderer(size: size)
                let scaled = renderer.image { _ in
                    image.draw(in: CGRect(origin: .zero, size: size))
                }
                cache.setObject(scaled, forKey: url as NSURL)
                return scaled
            } catch {
                return nil
            }
        }

        inFlight[url] = task
        let result = await task.value
        inFlight.removeValue(forKey: url)
        return result
    }
}

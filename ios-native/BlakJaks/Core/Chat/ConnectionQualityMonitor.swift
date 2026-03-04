import Foundation

final class ConnectionQualityMonitor {
    private static let windowSize = 5
    private static let goodThresholdMs: Double = 200
    private static let poorThresholdMs: Double = 800

    private var samples: [Double] = []
    private(set) var quality: ConnectionQuality = .good

    var onChange: ((ConnectionQuality) -> Void)?

    var averageRtt: Double {
        guard !samples.isEmpty else { return 0 }
        return samples.reduce(0, +) / Double(samples.count)
    }

    func recordRtt(_ ms: Double) {
        samples.append(ms)
        if samples.count > Self.windowSize {
            samples.removeFirst()
        }
        evaluate()
    }

    func recordMissedPong() {
        setQuality(.poor)
    }

    func reset() {
        samples = []
        setQuality(.good)
    }

    private func evaluate() {
        let avg = averageRtt
        if avg > Self.poorThresholdMs {
            setQuality(.poor)
        } else if avg > Self.goodThresholdMs {
            setQuality(.degraded)
        } else {
            setQuality(.good)
        }
    }

    private func setQuality(_ q: ConnectionQuality) {
        guard quality != q else { return }
        quality = q
        onChange?(q)
    }
}

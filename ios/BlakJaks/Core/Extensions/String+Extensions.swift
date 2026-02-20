import Foundation

extension String {
    var asFormattedDate: String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: self) else { return self }
        let display = DateFormatter()
        display.dateStyle = .medium
        display.timeStyle = .short
        return display.string(from: date)
    }

    var asUSDAmount: String {
        guard let value = Double(self) else { return self }
        return String(format: "$%.2f", value)
    }
}

extension Double {
    var formattedUSD: String { String(format: "$%.2f", self) }
    var formattedUSDC: String { String(format: "%.2f USDC", self) }
}

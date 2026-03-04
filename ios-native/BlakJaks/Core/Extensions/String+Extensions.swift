import Foundation

extension String {
    var isValidEmail: Bool {
        let regex = #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return range(of: regex, options: .regularExpression) != nil
    }

    func truncated(to length: Int, trailing: String = "…") -> String {
        count > length ? String(prefix(length)) + trailing : self
    }

    // Format ISO-8601 date string to short display string
    func formattedDate(style: DateFormatter.Style = .medium) -> String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = iso.date(from: self) ?? DateFormatter().date(from: self) else { return self }
        let df = DateFormatter()
        df.dateStyle = style
        df.timeStyle = .none
        return df.string(from: date)
    }
}

extension Double {
    var usdFormatted: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        return f.string(from: NSNumber(value: self)) ?? "$\(self)"
    }

    var compactUSDFormatted: String {
        let abs = Swift.abs(self)
        let prefix = self < 0 ? "-" : ""
        switch abs {
        case 1_000_000...: return "\(prefix)$\(String(format: "%.1f", abs / 1_000_000))M"
        case 1_000...:     return "\(prefix)$\(String(format: "%.1f", abs / 1_000))K"
        default:           return usdFormatted
        }
    }

    var percentFormatted: String {
        let f = NumberFormatter()
        f.numberStyle = .percent
        f.maximumFractionDigits = 1
        f.multiplier = 1
        return f.string(from: NSNumber(value: self)) ?? "\(self)%"
    }
}

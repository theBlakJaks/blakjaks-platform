import SwiftUI

// MARK: - DateSeparatorView

struct DateSeparatorView: View {

    let date: Date

    private static let todayLabel = "Today"
    private static let yesterdayLabel = "Yesterday"

    var body: some View {
        HStack(spacing: Spacing.sm) {
            line
            Text(label)
                .font(BJFont.sora(10, weight: .semibold))
                .foregroundColor(Color.textTertiary)
            line
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
    }

    private var line: some View {
        Rectangle()
            .fill(Color.borderSubtle)
            .frame(height: 0.5)
    }

    private var label: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return Self.todayLabel
        } else if calendar.isDateInYesterday(date) {
            return Self.yesterdayLabel
        } else {
            let fmt = DateFormatter()
            fmt.dateFormat = "EEEE, MMM d"
            return fmt.string(from: date)
        }
    }
}

// MARK: - Date Grouping Helper

enum DateSeparatorHelper {
    /// Determines whether a date separator should be shown before a message,
    /// given the previous message's timestamp.
    static func shouldShowSeparator(current: String, previous: String?) -> Bool {
        guard let prev = previous else { return true } // first message always gets a separator
        guard let currentDate = parseISO(current),
              let prevDate = parseISO(prev) else { return false }
        return !Calendar.current.isDate(currentDate, inSameDayAs: prevDate)
    }

    static func parseISO(_ iso: String) -> Date? {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = fmt.date(from: iso) { return d }
        // Retry without fractional seconds
        fmt.formatOptions = [.withInternetDateTime]
        return fmt.date(from: iso)
    }
}

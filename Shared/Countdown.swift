import Foundation

enum Countdown {
    static let widgetKind = "SecondsCountdown"
    static let locale = Locale(identifier: "en_US")

    // September 15, 2027, 00:00:00 America/New_York (EDT).
    static let defaultDeadline: Date = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar.date(from: DateComponents(year: 2027, month: 9, day: 15))!
    }()

    static func liveFormat(digits: Int) -> Duration.UnitsFormatStyle {
        Duration.UnitsFormatStyle(
            allowedUnits: [.seconds],
            width: .narrow,
            valueLength: digits,
            fractionalPart: .hide(rounded: .towardZero)
        ).locale(locale)
    }

    static func seconds(until deadline: Date, at now: Date = .now) -> Int {
        max(0, Int(deadline.timeIntervalSince(now).rounded(.down)))
    }

    static func number(_ seconds: Int) -> String {
        seconds.formatted(.number.locale(locale).grouping(.automatic))
    }

    /// Only digit-count boundaries need a new layout; iOS updates the text itself.
    static func layoutDates(until deadline: Date, after now: Date) -> [Date] {
        var dates = [now]
        var threshold = 10.0
        let remaining = deadline.timeIntervalSince(now)
        while threshold <= remaining {
            // The formatter truncates fractional seconds. Just after this instant,
            // 10,000 becomes 9,999 (and so on), requiring a narrower text viewport.
            dates.append(deadline.addingTimeInterval(-threshold + 0.01))
            threshold *= 10
        }
        if deadline > now { dates.append(deadline) }
        return dates.sorted()
    }
}

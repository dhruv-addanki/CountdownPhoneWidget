import Foundation

enum Countdown {
    static let widgetKind = "SecondsCountdown"
    static let locale = Locale(identifier: "en_US")
    static let inspirationQuote = "Inspiration is Fleeting"
    static let timeQuote = "Our time is all we have"

    // Keep today's existing phrase as the first side of the alternating cycle.
    // The calendar used by the caller determines what local midnight means.
    private static let quoteAnchorComponents = DateComponents(year: 2026, month: 9, day: 16)

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

    /// Alternates quotes by local calendar day, with the anchor day showing the
    /// phrase that was already on the widget before rotation was added.
    static func quote(at date: Date, using calendar: Calendar = .autoupdatingCurrent) -> String {
        let anchor = calendar.date(from: quoteAnchorComponents) ?? date
        let dayOffset = calendar.dateComponents(
            [.day],
            from: anchor,
            to: calendar.startOfDay(for: date)
        ).day ?? 0
        return dayOffset.isMultiple(of: 2) ? inspirationQuote : timeQuote
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

    /// Combines digit-width boundaries with local midnights so the quote can
    /// change without interrupting the system-owned live seconds text.
    static func timelineDates(
        until deadline: Date,
        after now: Date,
        using calendar: Calendar = .autoupdatingCurrent
    ) -> [Date] {
        var dates = Set(layoutDates(until: deadline, after: now))
        guard deadline > now else { return dates.sorted() }

        var midnight = calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.startOfDay(for: now)
        )!
        while midnight < deadline {
            dates.insert(midnight)
            midnight = calendar.date(byAdding: .day, value: 1, to: midnight)!
        }
        return dates.sorted()
    }
}

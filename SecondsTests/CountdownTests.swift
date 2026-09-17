import XCTest
@testable import Seconds

final class CountdownTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    func testBirthdayIsMidnightNewYork() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Countdown.defaultDeadline)
        XCTAssertEqual(parts, DateComponents(year: 2027, month: 9, day: 15, hour: 0, minute: 0, second: 0))
    }

    func testSecondsAreTotalSecondsAndClampAtZero() {
        XCTAssertEqual(Countdown.seconds(until: now.addingTimeInterval(31_536_000), at: now), 31_536_000)
        XCTAssertEqual(Countdown.seconds(until: now.addingTimeInterval(1.9), at: now), 1)
        XCTAssertEqual(Countdown.seconds(until: now, at: now), 0)
        XCTAssertEqual(Countdown.seconds(until: now.addingTimeInterval(-100), at: now), 0)
    }

    func testNativeFormatHasStableSuffixGroupingAndPadding() {
        for seconds in [31_536_000, 10_000_000, 9_999_999, 1_000, 999, 10, 9, 1, 0] {
            let format = Countdown.liveFormat(digits: String(seconds).count)
            let sign = seconds == 0 ? "" : "-"
            XCTAssertEqual(format.format(.seconds(-seconds)), "\(sign)\(Countdown.number(seconds))s")
        }
        let format = Countdown.liveFormat(digits: 8)
        XCTAssertEqual(format.format(.seconds(-9_999_999)), "-09,999,999s")
        XCTAssertEqual(format.format(.seconds(-1)), "-00,000,001s")
        XCTAssertEqual(format.format(.zero), "00,000,000s")
    }

    func testNativeFormatTruncatesFractionalSeconds() {
        for remaining in [1.9, 1.1, 1.0, 0.9, 0.1] {
            let expected = Countdown.seconds(until: now.addingTimeInterval(remaining), at: now)
            let formatted = Countdown.liveFormat(digits: 1).format(.seconds(-remaining))
            XCTAssertEqual(formatted.replacingOccurrences(of: "-", with: ""), "\(expected)s")
        }
    }

    func testCaptionLayoutMatchesCountdownWidth() {
        let numberFont = CountdownNumber.numberFont(size: 20)
        let numberWidth = CountdownNumber.width(of: "31,410,180", font: numberFont)
        let layout = CountdownNumber.captionLayout(
            for: Countdown.inspirationQuote,
            preferredSize: 11,
            targetWidth: numberWidth
        )

        XCTAssertEqual(layout.width, numberWidth, accuracy: 0.01)
    }

    func testCaptionLayoutFitsQuoteWithoutShrinkingNumber() {
        let numberFont = CountdownNumber.numberFont(size: 20)
        let numberWidth = CountdownNumber.width(of: "999", font: numberFont)
        let layout = CountdownNumber.captionLayout(
            for: Countdown.timeQuote,
            preferredSize: 11,
            targetWidth: numberWidth
        )

        XCTAssertLessThanOrEqual(layout.width, numberWidth + 0.01)
        XCTAssertLessThanOrEqual(layout.font.pointSize, 11)
    }

    func testQuotesAlternateAtNewYorkMidnight() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        let beforeMidnight = calendar.date(from: DateComponents(year: 2026, month: 9, day: 16, hour: 23, minute: 59, second: 59))!
        let firstSwitch = calendar.date(from: DateComponents(year: 2026, month: 9, day: 17))!
        let secondSwitch = calendar.date(from: DateComponents(year: 2026, month: 9, day: 18))!

        XCTAssertEqual(Countdown.quote(at: beforeMidnight, using: calendar), Countdown.inspirationQuote)
        XCTAssertEqual(Countdown.quote(at: firstSwitch, using: calendar), Countdown.timeQuote)
        XCTAssertEqual(Countdown.quote(at: secondSwitch, using: calendar), Countdown.inspirationQuote)
    }

    func testTimelineIncludesEachMidnightBeforeDeadline() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        let now = calendar.date(from: DateComponents(year: 2026, month: 9, day: 16, hour: 16))!
        let deadline = calendar.date(from: DateComponents(year: 2026, month: 9, day: 19, hour: 1))!
        let dates = Countdown.timelineDates(until: deadline, after: now, using: calendar)

        XCTAssertTrue(dates.contains(calendar.date(from: DateComponents(year: 2026, month: 9, day: 17))!))
        XCTAssertTrue(dates.contains(calendar.date(from: DateComponents(year: 2026, month: 9, day: 18))!))
        XCTAssertTrue(dates.contains(calendar.date(from: DateComponents(year: 2026, month: 9, day: 19))!))
    }

    func testLongDeadlineHasBoundedTimelineAndExpiredCountdownStillRotates() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        let start = calendar.date(from: DateComponents(year: 2026, month: 9, day: 16, hour: 20))!
        let horizon = calendar.date(from: DateComponents(year: 2026, month: 9, day: 19))!
        for deadline in [Countdown.defaultDeadline, start.addingTimeInterval(-1)] {
            let dates = Countdown.timelineDates(until: deadline, after: start, using: calendar)
            XCTAssertEqual(dates.count, 4)
            XCTAssertEqual(dates.first, start)
            XCTAssertEqual(dates.last, horizon)
            XCTAssertEqual(dates, dates.sorted())
        }
    }

    func testRollingTimelineIncludesExpiryAndDigitBoundaries() {
        let end = now.addingTimeInterval(1_050)
        let dates = Countdown.timelineDates(until: end, after: now)
        for boundary in Countdown.layoutDates(until: end, after: now) {
            XCTAssertTrue(dates.contains(boundary))
        }
        XCTAssertEqual(Set(dates).count, dates.count)
    }

    func testMidnightsFollowLocalCalendarAcrossDaylightSaving() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        let start = calendar.date(from: DateComponents(year: 2026, month: 10, day: 31, hour: 12))!
        let dates = Countdown.timelineDates(until: Countdown.defaultDeadline, after: start, using: calendar)
        XCTAssertEqual(dates.count, 4)
        XCTAssertEqual(dates[2].timeIntervalSince(dates[1]), 25 * 3600)
        for date in dates.dropFirst() {
            XCTAssertEqual(calendar.component(.hour, from: date), 0)
        }
        XCTAssertNotEqual(Countdown.quote(at: dates[1], using: calendar), Countdown.quote(at: dates[2], using: calendar))
    }

    func testLayoutEntriesCoverEveryDigitBoundaryAndExpiry() {
        let end = now.addingTimeInterval(1_050)
        let dates = Countdown.layoutDates(until: end, after: now)
        XCTAssertEqual(dates.count, 5)
        XCTAssertEqual(dates.first, now)
        XCTAssertEqual(dates.last, end.addingTimeInterval(0.01))
        XCTAssertEqual(dates, dates.sorted())
        XCTAssertEqual(dates.map { Countdown.seconds(until: end, at: $0) }, [1_050, 999, 99, 9, 0])
        XCTAssertEqual(Countdown.layoutDates(until: now.addingTimeInterval(-1), after: now), [now])
    }

    func testAppAndWidgetSharePersistedInstant() {
        let suite = "SecondsTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let appStore = CountdownStore(defaults: defaults)
        XCTAssertEqual(appStore.deadline, Countdown.defaultDeadline)
        appStore.save(now)
        let widgetStore = CountdownStore(defaults: UserDefaults(suiteName: suite)!)
        XCTAssertEqual(widgetStore.deadline, now)
    }
}

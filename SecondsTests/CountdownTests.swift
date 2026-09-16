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

    func testLiveFormatIsUnsignedAndGrouped() {
        for seconds in [31_536_000, 10_000_000, 9_999_999, 1_000, 999, 10, 9, 1, 0] {
            XCTAssertEqual(Countdown.liveSecondsFormat.format(.seconds(-seconds)), Countdown.number(seconds))
        }
    }

    func testLiveFormatIsCodableForWidgetKit() throws {
        let encoded = try JSONEncoder().encode(Countdown.liveSecondsFormat)
        let decoded = try JSONDecoder().decode(LiveSecondsFormat.self, from: encoded)

        XCTAssertEqual(decoded, Countdown.liveSecondsFormat)
        XCTAssertEqual(decoded.format(.seconds(-31_536_000)), "31,536,000")
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

    func testLayoutEntriesCoverEveryDigitBoundaryAndExpiry() {
        let end = now.addingTimeInterval(1_050)
        let dates = Countdown.layoutDates(until: end, after: now)
        XCTAssertEqual(dates.count, 5)
        XCTAssertEqual(dates.first, now)
        XCTAssertEqual(dates.last, end)
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

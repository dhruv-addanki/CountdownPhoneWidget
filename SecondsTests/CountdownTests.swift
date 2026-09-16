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

    func testBuiltInFormatHasConstantSuffixAndGrouping() {
        for seconds in [31_536_000, 10_000_000, 9_999_999, 1_000, 999, 10, 9, 1, 0] {
            let format = Countdown.liveFormat(digits: String(seconds).count)
            let sign = seconds == 0 ? "" : "-"
            XCTAssertEqual(format.format(.seconds(-seconds)), "\(sign)\(Countdown.number(seconds))s")
        }
    }

    func testLateLayoutKeepsTheNumericViewportPadded() {
        let format = Countdown.liveFormat(digits: 8)
        XCTAssertEqual(format.format(.seconds(-9_999_999)), "-09,999,999s")
        XCTAssertEqual(format.format(.seconds(-1)), "-00,000,001s")
        XCTAssertEqual(format.format(.zero), "00,000,000s")
    }

    func testNativeFormatterAndAppAgreeOnFractionalSeconds() {
        for remaining in [1.9, 1.1, 1.0, 0.9, 0.1] {
            let expected = Countdown.seconds(until: now.addingTimeInterval(remaining), at: now)
            let formatted = Countdown.liveFormat(digits: 1).format(.seconds(-remaining))
            XCTAssertEqual(formatted.replacingOccurrences(of: "-", with: ""), "\(expected)s")
        }
    }

    func testCaptionTrackingMatchesCountdownWidth() {
        let numberFont = CountdownNumber.numberFont(size: 20)
        let captionFont = CountdownNumber.captionFont(size: 11)
        let numberWidth = CountdownNumber.width(of: "31,410,180", font: numberFont)
        let caption = "Inspiration is Fleeting"
        let tracking = CountdownNumber.tracking(for: caption, font: captionFont, targetWidth: numberWidth)

        XCTAssertEqual(
            CountdownNumber.width(of: caption, font: captionFont, tracking: tracking),
            numberWidth,
            accuracy: 0.01
        )
    }

    func testCaptionTrackingRemainsReadableForShortCountdowns() {
        let numberFont = CountdownNumber.numberFont(size: 20)
        let captionFont = CountdownNumber.captionFont(size: 11)
        let numberWidth = CountdownNumber.width(of: "999", font: numberFont)
        let caption = "Inspiration is Fleeting"
        let tracking = CountdownNumber.tracking(for: caption, font: captionFont, targetWidth: numberWidth)

        XCTAssertEqual(tracking, -1.2, accuracy: 0.001)
        XCTAssertGreaterThan(
            CountdownNumber.width(of: caption, font: captionFont, tracking: tracking),
            numberWidth
        )
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

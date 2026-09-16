import SwiftUI
import WidgetKit

struct CountdownEntry: TimelineEntry {
    let date: Date
    let deadline: Date
}

struct CountdownProvider: TimelineProvider {
    func placeholder(in context: Context) -> CountdownEntry {
        CountdownEntry(date: .now, deadline: .now.addingTimeInterval(31_536_000))
    }

    func getSnapshot(in context: Context, completion: @escaping (CountdownEntry) -> Void) {
        completion(CountdownEntry(date: .now, deadline: CountdownStore().deadline))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownEntry>) -> Void) {
        let deadline = CountdownStore().deadline
        let entries = Countdown.layoutDates(until: deadline, after: .now).map {
            CountdownEntry(date: $0, deadline: deadline)
        }
        completion(Timeline(entries: entries, policy: .never))
    }
}

@main
struct SecondsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Countdown.widgetKind, provider: CountdownProvider()) { entry in
            CountdownNumber(deadline: entry.deadline, layoutDate: entry.date)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Seconds")
        .description("Every second until your date.")
        .supportedFamilies([.accessoryRectangular])
        .contentMarginsDisabled()
    }
}

#Preview("One year", as: .accessoryRectangular) {
    SecondsWidget()
} timeline: {
    CountdownEntry(date: .now, deadline: .now.addingTimeInterval(31_536_000))
}

#Preview("Last seconds", as: .accessoryRectangular) {
    SecondsWidget()
} timeline: {
    CountdownEntry(date: .now, deadline: .now.addingTimeInterval(9))
}

#Preview("Complete", as: .accessoryRectangular) {
    SecondsWidget()
} timeline: {
    CountdownEntry(date: .now, deadline: .now.addingTimeInterval(-1))
}

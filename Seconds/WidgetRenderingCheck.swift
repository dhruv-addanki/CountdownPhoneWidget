#if DEBUG
import SwiftUI

/// Development-only view using the exact widget view and its sparse timeline.
/// Run with --preview-widget; never appears in the normal app flow.
struct WidgetRenderingCheck: View {
    private let start = Date.now
    private let intervals: [TimeInterval] = [31_536_000, 1_003, 13, -1]

    var body: some View {
        VStack(spacing: 24) {
            Text("Widget rendering check").font(.headline)
            ForEach(intervals, id: \.self) { interval in
                let deadline = start.addingTimeInterval(interval)
                HStack(spacing: 20) {
                    ForEach([ColorScheme.light, .dark], id: \.self) { scheme in
                        // Keep a sentinel after the final layout date: TimelineView's
                        // explicit schedule may otherwise omit its terminal update.
                        TimelineView(.explicit(Countdown.layoutDates(until: deadline, after: start) + [deadline.addingTimeInterval(1)])) { context in
                            CountdownNumber(deadline: deadline, layoutDate: context.date)
                        }
                        .frame(width: 160, height: 72)
                        .background(scheme == .dark ? Color.black : Color.white)
                        .environment(\.colorScheme, scheme)
                        .border(.gray.opacity(0.2))
                    }
                }
            }
            let tomorrow = Calendar.autoupdatingCurrent.date(byAdding: .day, value: 1, to: start)!
            Text("Quote rotation").font(.headline)
            HStack(spacing: 20) {
                ForEach([ColorScheme.light, .dark], id: \.self) { scheme in
                    VStack(spacing: 8) {
                        CountdownNumber(
                            deadline: start.addingTimeInterval(31_536_000),
                            layoutDate: start
                        )
                        .frame(width: 160, height: 72)
                        .background(scheme == .dark ? Color.black : Color.white)
                        .environment(\.colorScheme, scheme)
                        CountdownNumber(
                            deadline: tomorrow.addingTimeInterval(31_536_000),
                            layoutDate: tomorrow
                        )
                        .frame(width: 160, height: 72)
                        .background(scheme == .dark ? Color.black : Color.white)
                        .environment(\.colorScheme, scheme)
                    }
                }
            }
            Text("Live widget layout. Caption width follows the number.")
                .font(.footnote).foregroundStyle(.secondary)
            CountdownNumber(deadline: start.addingTimeInterval(31_536_000), layoutDate: start)
                .environment(\.isLuminanceReduced, true)
                .frame(width: 160, height: 72)
                .accessibilityIdentifier("dimmedWidgetCheck")
        }
        .padding()
    }
}
#endif

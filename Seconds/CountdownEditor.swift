import SwiftUI
import WidgetKit

struct CountdownEditor: View {
    private let store: CountdownStore
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.timeZone) private var timeZone
    @State private var savedDeadline: Date
    @State private var draftDeadline: Date
    @State private var justSaved = false

    init(store: CountdownStore = CountdownStore()) {
        self.store = store
        _savedDeadline = State(initialValue: store.deadline)
        _draftDeadline = State(initialValue: store.deadline)
    }

    private var hasChanges: Bool { draftDeadline != savedDeadline }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer(minLength: 32)

                TimelineView(.periodic(from: .now, by: 1)) { context in
                    VStack(spacing: 12) {
                        Text(Countdown.number(Countdown.seconds(until: savedDeadline, at: context.date)))
                            .font(.system(size: 52, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .accessibilityIdentifier("countdownPreview")
                            .accessibilityLabel("Seconds remaining")
                            .accessibilityValue(Countdown.number(Countdown.seconds(until: savedDeadline, at: context.date)))

                        Text("SECONDS REMAINING")
                            .font(.system(size: 10, weight: .medium))
                            .tracking(2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 48)

                VStack(alignment: .leading, spacing: 18) {
                    DatePicker("End date", selection: $draftDeadline, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .accessibilityIdentifier("deadlinePicker")

                    Text(timeZone.identifier.replacingOccurrences(of: "_", with: " "))
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Button {
                        // The editor has minute precision; remove hidden seconds.
                        let deadline = Date(timeIntervalSince1970: floor(draftDeadline.timeIntervalSince1970 / 60) * 60)
                        store.save(deadline)
                        savedDeadline = deadline
                        draftDeadline = deadline
                        WidgetCenter.shared.reloadTimelines(ofKind: Countdown.widgetKind)
                        justSaved = true
                    } label: {
                        Text(justSaved && !hasChanges ? "Saved" : "Save")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .tint(.primary)
                    .disabled(!hasChanges)
                    .accessibilityIdentifier("saveDeadline")
                }

                Text("Add Seconds from your Lock Screen’s widget gallery.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 32)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 28)
            .navigationTitle("Seconds")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                WidgetCenter.shared.reloadTimelines(ofKind: Countdown.widgetKind)
            }
            .onChange(of: draftDeadline) { _, _ in justSaved = false }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active && !hasChanges {
                    savedDeadline = store.deadline
                    draftDeadline = savedDeadline
                }
            }
        }
    }
}

#Preview {
    CountdownEditor()
}

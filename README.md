# Seconds

A single date editor and a number-only iPhone Lock Screen widget.

## Open and run

1. Open **Seconds.xcodeproj** in Xcode 16 or newer. Select the **Seconds** scheme and your iPhone (iOS 18+).
2. In **Configuration/Project.xcconfig**, set `DEVELOPMENT_TEAM` to your Apple Developer team ID. Alternatively, select your team under **Signing & Capabilities** for both **Seconds** and **SecondsWidget**.
3. Both targets use the App Group **group.com.dhruv.seconds**. Enable/check that group in **Signing & Capabilities → App Groups** for both targets. Let Xcode register it, or register it in your developer account first.
4. If the bundle identifiers are unavailable, change `BUNDLE_ID_PREFIX` in **Project.xcconfig**. The app ID, extension ID, and App Group derive from that one setting. Register/check the resulting App Group in both targets.
5. Run the app once. It starts with **September 15, 2027, 12:00 AM America/New_York**. Use **End date** and **Save** to change it.
6. On your iPhone, long-press the Lock Screen → **Customize → Lock Screen** → tap the widget area below the clock → choose **Seconds** → add its rectangular widget → **Done**.

The project is included and ready to open. No packages, server, or project generator are needed to run it. The optional Ruby script in `Scripts/` regenerates the project for maintenance only.

## Behavior

- The widget displays total whole seconds, grouped with commas, in rounded medium-weight numerals. It has no visible unit, title, or background.
- It calculates from the actual deadline, so the initial value is the actual remaining time, not a fresh 31,536,000-second interval.
- Seconds are truncated to whole seconds; less than one second remaining displays `0`. An expiration timeline entry switches the widget to a permanent `0`.
- The app's date picker uses the phone's current time zone and minute precision. Saved dates remain fixed instants when you travel or daylight saving time changes.
- All widget instances share the same deadline. Tapping the widget opens the editor.
- Saving stores the date in App Group preferences and requests a widget reload. iOS controls when that request is displayed.

## How the widget ticks

The widget uses `Text(.durationOffset(to:), format:)` with Apple's built-in `Duration.UnitsFormatStyle` restricted to seconds. The system can update this text while the extension is inactive. The widget has no per-second app timer, background task, network request, or Live Activity. The editor's preview uses a foreground timer.

The narrow English formatter outputs a future offset such as `-31,536,000s`. The view measures the exact rounded, monospaced-digit font and clips the minus sign and final `s`. Padding preserves the numeric viewport if a layout entry arrives late. Timeline entries are supplied at digit-count changes and expiration to resize and recenter the number.

The implementation uses native time text rather than a custom formatter because widget content must continue updating in the system process. The comma grouping and English seconds suffix are deliberately fixed independently of the phone locale.

iOS owns display cadence. [Apple documents that reduced-luminance displays may remove seconds or redact changing digits](https://developer.apple.com/documentation/swiftui/text/init(_:format:)-8sfgg). This widget shows a dash when the system reports reduced luminance, then returns to seconds when the display wakes. Continuous visible second-by-second ticking on a dim Always-On display is not guaranteed.

If a digit-boundary layout entry arrives late, the count temporarily retains leading zeros. The expiration entry clamps the value to zero; WidgetKit controls delivery timing, so that transition also needs a physical-device check.

## Checks

Verified with Xcode 26.6 and the iOS 26.5 simulator: simulator Debug build, unsigned iPhone Release build, and all seven unit tests pass. Editing a date, saving, and reopening the app were checked in the simulator; the birthday deadline was restored afterward. The final test result is in `build/VerifiedTests.xcresult` (local, not part of the source).

Build for the simulator:

```sh
xcodebuild -project Seconds.xcodeproj -scheme Seconds \
  -sdk iphonesimulator -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO build
```

Run tests with an installed simulator name:

```sh
xcodebuild -project Seconds.xcodeproj -scheme Seconds \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO test
```

Tests cover the birthday instant, whole-second math, zero clamping, the native formatter's sign/grouping/padding/truncation, digit-boundary timeline entries, and storage persistence. Widget previews are included in `SecondsWidget.swift`.

The exact number view has been visually checked ticking in the iOS simulator, in light and dark mode, including digit-width changes and zero. The Debug-only `--preview-widget` launch argument opens that rendering check. It uses sparse layout updates, so second-by-second changes come from native time text.

**Physical Lock Screen verification remains required.** Xcode's widget canvas rendered a coarse time value even for Apple's standard timer during testing, so it is not evidence of seconds ticking on the Lock Screen. Signing, App Group access between the installed app and extension, and the actual Lock Screen cadence need verification on your iPhone. No device install has been performed.

On your phone, also verify a deadline a few minutes away, saving while a widget is installed, crossing zero, reopening the app, light/dark wallpaper legibility, and Always-On behavior.

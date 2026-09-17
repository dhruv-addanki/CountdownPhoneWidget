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

- The widget displays total whole seconds in compact terminal typography, with a centered dot and a quote underneath. “Inspiration is Fleeting” and “Our time is all we have” alternate at local midnight. The caption is fitted to the countdown's measured width so both lines share the same center and outer edges. It has no visible unit or background.
- It calculates from the actual deadline, so the initial value is the actual remaining time, not a fresh 31,536,000-second interval.
- Seconds are truncated to whole seconds; less than one second remaining displays `0`. A timeline entry just after expiration switches the widget to a permanent `0`.
- The app's date picker uses the phone's current time zone and minute precision. Saved dates remain fixed instants when you travel or daylight saving time changes.
- All widget instances share the same deadline. Tapping the widget opens the editor.
- Saving stores the date in App Group preferences and requests a widget reload. iOS controls when that request is displayed.

## How the widget ticks

The widget uses `Text(.durationOffset(to:), format:)` with Apple's built-in `Duration.UnitsFormatStyle` restricted to seconds. The system can update this text while the extension is inactive. The widget has no per-second app timer, background task, network request, or Live Activity. The editor's preview uses a foreground timer.

The narrow English formatter outputs a future offset such as `-31,536,000s`. The view measures the monospaced font and uses a fixed numeric viewport over a trailing-aligned native text frame to clip the minus sign and final `s`. It does not ask live text for an intrinsic width. Padding preserves the numeric viewport if a layout entry arrives late. A rolling three-day timeline includes local midnights, digit-count changes, and expiration within that window. The `.atEnd` policy requests the next window; quotes continue rotating after expiration.

The implementation uses native time text rather than a custom formatter because widget content must continue updating in the system process. The comma grouping and English seconds suffix are deliberately fixed independently of the phone locale.

iOS owns display cadence. [Apple documents that reduced-luminance displays may remove seconds or redact changing digits](https://developer.apple.com/documentation/swiftui/text/init(_:format:)-8sfgg). This widget shows a dash when the system reports reduced luminance, then returns to seconds when the display wakes. Continuous visible second-by-second ticking on a dim Always-On display is not guaranteed.

If a digit-boundary layout entry arrives late, the count temporarily retains leading zeros. The expiration entry clamps the value to zero; WidgetKit controls delivery timing, so that transition also needs a physical-device check.

## Checks

Recovery verification: Xcode 27, iOS 26.5 simulator, and a signed iPhone Release build. Thirteen unit tests cover native formatter output and padding, truncation, quote alternation, bounded timelines, local midnights across daylight saving time, digit boundaries, expiry, and storage. Test results are in `build/WidgetRecoveryFinalTests.xcresult` (local, not part of source).

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

Widget previews are included in `SecondsWidget.swift`.

The exact number view has been visually checked ticking in the iOS simulator, in light and dark mode, including digit-width changes and zero. The Debug-only `--preview-widget` launch argument opens that rendering check. It uses sparse layout updates, so second-by-second changes come from native time text.

**Physical Lock Screen rendering confirmed:** the signed recovery build was installed and launched on the connected iPhone, and the user confirmed both the countdown and quote appear. Simulator rendering checks also showed clean numeric clipping in light/dark mode, both quotes, and a transition to zero. The debug rendering check includes a sentinel update after expiry because the simulator's explicit `TimelineView` schedule omitted the terminal update without it.

Still verify actual midnight delivery, a short deadline crossing zero on the phone, saving with an installed widget, and Always-On behavior. Unit tests verify the timeline dates, but iOS controls when scheduled widget entries are displayed.

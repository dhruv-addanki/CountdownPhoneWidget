import SwiftUI
import UIKit

/// Keeps Apple's live duration text intact so the system owns the ticking.
/// Future offsets format as `-31,536,000s`; crop the sign and unit to expose
/// just the number. The active caption is fitted to that measured width.
struct CountdownNumber: View {
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    let deadline: Date
    let layoutDate: Date
    var maximumFontSize: CGFloat = 20

    private static let captionSizeRatio: CGFloat = 0.55
    private static let dotDiameter: CGFloat = 2
    private static let separatorGap: CGFloat = 4
    private static let minimumCaptionTracking: CGFloat = -1.2

    var body: some View {
        GeometryReader { geometry in
            let value = Countdown.number(Countdown.seconds(until: deadline, at: layoutDate))
            let caption = Countdown.quote(at: layoutDate)
            let referenceFont = Self.numberFont(size: maximumFontSize)
            let referenceWidth = Self.width(of: value, font: referenceFont)
            let fontSize = maximumFontSize * min(1, geometry.size.width / max(1, referenceWidth))
            let font = Self.numberFont(size: fontSize)
            let numberWidth = Self.width(of: value, font: font)
            let captionLayout = Self.captionLayout(
                for: caption,
                preferredSize: fontSize * Self.captionSizeRatio,
                targetWidth: numberWidth
            )
            let suffixWidth = Self.width(of: "s", font: font)
            let signWidth = Self.width(of: "-", font: font)
            let digits = String(Countdown.seconds(until: deadline, at: layoutDate)).count
            let format = Countdown.liveFormat(digits: digits)
            let scale = fontSize / maximumFontSize

            VStack(spacing: 0) {
                Group {
                    if deadline <= layoutDate {
                        Text("0")
                    } else if isLuminanceReduced {
                        // iOS may replace seconds with minutes on a dim display.
                        // Never present that coarser value as a seconds count.
                        Text("—")
                    } else {
                        Text(.durationOffset(to: deadline), format: format)
                            .lineLimit(1)
                            .multilineTextAlignment(.trailing)
                            .frame(width: signWidth + numberWidth + suffixWidth, alignment: .trailing)
                            .offset(x: -signWidth)
                            .frame(width: numberWidth, alignment: .leading)
                            .clipped()
                    }
                }
                .font(Font(font))
                .foregroundStyle(.primary)
                .frame(width: numberWidth, height: font.lineHeight)

                Color.clear.frame(height: Self.separatorGap * scale)

                Circle()
                    .fill(.primary)
                    .frame(
                        width: Self.dotDiameter * scale,
                        height: Self.dotDiameter * scale
                    )

                Color.clear.frame(height: Self.separatorGap * scale)

                Text(caption)
                    .font(Font(captionLayout.font))
                    .tracking(captionLayout.tracking)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .fixedSize()
                    .frame(width: captionLayout.width, height: captionLayout.font.lineHeight)
                    .clipped()
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .environment(\.locale, Countdown.locale)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Seconds remaining")
            .accessibilityValue(accessibilityValue)
        }
    }

    private var accessibilityValue: Text {
        if deadline <= layoutDate { return Text("0") }
        if isLuminanceReduced { return Text("Wake the display to see seconds") }
        return Text(.currentDate, format: .offset(to: deadline, allowedFields: [.second], maxFieldCount: 1, sign: .never))
    }

    static func numberFont(size: CGFloat) -> UIFont {
        UIFont.monospacedSystemFont(ofSize: size, weight: .medium)
    }

    static func captionFont(size: CGFloat) -> UIFont {
        UIFont.systemFont(ofSize: size, weight: .semibold, width: .condensed)
    }

    struct CaptionLayout {
        let font: UIFont
        let tracking: CGFloat
        let width: CGFloat
    }

    /// Keeps the number's width authoritative. Tracking handles normal-size
    /// captions; font size is reduced only when the active phrase still cannot
    /// fit after the readable tracking limit is reached.
    static func captionLayout(for text: String, preferredSize: CGFloat, targetWidth: CGFloat) -> CaptionLayout {
        var font = captionFont(size: preferredSize)
        var captionTracking = tracking(for: text, font: font, targetWidth: targetWidth)
        var captionWidth = width(of: text, font: font, tracking: captionTracking)

        for _ in 0..<3 where captionWidth > targetWidth && targetWidth > 0 {
            let scale = targetWidth / captionWidth
            font = captionFont(size: max(1, font.pointSize * scale))
            captionTracking = tracking(for: text, font: font, targetWidth: targetWidth)
            captionWidth = width(of: text, font: font, tracking: captionTracking)
        }

        return CaptionLayout(font: font, tracking: captionTracking, width: captionWidth)
    }

    static func width(of text: String, font: UIFont, tracking: CGFloat = 0) -> CGFloat {
        (text as NSString).size(withAttributes: [.font: font, .kern: tracking]).width
    }

    static func tracking(for text: String, font: UIFont, targetWidth: CGFloat) -> CGFloat {
        guard text.count > 1 else { return 0 }
        let naturalWidth = width(of: text, font: font)
        let measuredTrackingSlots = width(of: text, font: font, tracking: 1) - naturalWidth
        guard abs(measuredTrackingSlots) > .ulpOfOne else { return 0 }
        let exactTracking = (targetWidth - naturalWidth) / measuredTrackingSlots
        return max(exactTracking, minimumCaptionTracking)
    }
}

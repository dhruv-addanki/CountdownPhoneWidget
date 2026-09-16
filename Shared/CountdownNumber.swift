import SwiftUI
import UIKit

/// Keeps Apple's live duration text intact so the system owns the ticking.
/// Future offsets format as `-31,536,000s`; crop the sign and unit to expose
/// just the number. The caption is kerned to the same measured width.
struct CountdownNumber: View {
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    let deadline: Date
    let layoutDate: Date
    var maximumFontSize: CGFloat = 18

    private static let caption = "Inspiration is Fleeting"
    private static let captionSizeRatio: CGFloat = 0.5
    private static let dotDiameter: CGFloat = 2
    private static let separatorGap: CGFloat = 6
    private static let minimumCaptionTracking: CGFloat = -1.2

    var body: some View {
        GeometryReader { geometry in
            let value = Countdown.number(Countdown.seconds(until: deadline, at: layoutDate))
            let referenceFont = Self.uiFont(size: maximumFontSize)
            let referenceWidth = Self.width(of: value, font: referenceFont)
            let fontSize = maximumFontSize * min(1, geometry.size.width / max(1, referenceWidth))
            let font = Self.uiFont(size: fontSize)
            let numberWidth = Self.width(of: value, font: font)
            let captionFont = Self.uiFont(size: fontSize * Self.captionSizeRatio)
            let captionTracking = Self.tracking(
                for: Self.caption,
                font: captionFont,
                targetWidth: numberWidth
            )
            let captionWidth = Self.width(
                of: Self.caption,
                font: captionFont,
                tracking: captionTracking
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

                Text(Self.caption)
                    .font(Font(captionFont))
                    .tracking(captionTracking)
                    .foregroundStyle(.primary.opacity(0.72))
                    .lineLimit(1)
                    .fixedSize()
                    .frame(width: captionWidth, height: captionFont.lineHeight)
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

    static func uiFont(size: CGFloat) -> UIFont {
        UIFont.monospacedSystemFont(ofSize: size, weight: .medium)
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

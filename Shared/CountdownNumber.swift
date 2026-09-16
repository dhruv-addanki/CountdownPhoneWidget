import SwiftUI
import UIKit

/// Keeps Apple's live duration text intact so the system owns the ticking.
/// Future offsets format as `-31,536,000s`; crop the sign and unit to expose
/// just the number. Padding preserves that viewport until the next layout entry.
struct CountdownNumber: View {
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    let deadline: Date
    let layoutDate: Date
    var maximumFontSize: CGFloat = 30

    var body: some View {
        GeometryReader { geometry in
            let value = Countdown.number(Countdown.seconds(until: deadline, at: layoutDate))
            let referenceFont = Self.uiFont(size: maximumFontSize)
            let referenceWidth = Self.width(of: value, font: referenceFont)
            let fontSize = maximumFontSize * min(1, geometry.size.width / max(1, referenceWidth))
            let font = Self.uiFont(size: fontSize)
            let numberWidth = Self.width(of: value, font: font)
            let suffixWidth = Self.width(of: "s", font: font)
            let signWidth = Self.width(of: "-", font: font)
            let digits = String(Countdown.seconds(until: deadline, at: layoutDate)).count
            let format = Countdown.liveFormat(digits: digits)

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
            .frame(width: geometry.size.width, height: geometry.size.height)
            .environment(\.locale, Countdown.locale)
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
        let base = UIFont.monospacedDigitSystemFont(ofSize: size, weight: .medium)
        let descriptor = base.fontDescriptor.withDesign(.rounded) ?? base.fontDescriptor
        return UIFont(descriptor: descriptor, size: size)
    }

    static func width(of text: String, font: UIFont) -> CGFloat {
        (text as NSString).size(withAttributes: [.font: font]).width
    }
}

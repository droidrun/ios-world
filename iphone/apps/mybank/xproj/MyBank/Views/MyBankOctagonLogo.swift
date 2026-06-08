import SwiftUI

// The MyBank pinwheel/windmill logo: four interlocking arms in a rotating pattern
struct MyBankPinwheelLogo: View {
    var size: CGFloat = 40
    var color: Color = BankPalette.chaseBlue

    var body: some View {
        Canvas { context, canvasSize in
            let s = min(canvasSize.width, canvasSize.height)
            let cx = canvasSize.width / 2
            let cy = canvasSize.height / 2
            let gap = s * 0.05
            let armLength = s * 0.42
            let armThick = s * 0.22
            let r = s * 0.025

            // Top arm: extends LEFT from upper-center
            let topRect = CGRect(
                x: cx - gap / 2 - armLength,
                y: cy - gap / 2 - armThick,
                width: armLength,
                height: armThick
            )
            context.fill(Path(roundedRect: topRect, cornerRadius: r, style: .continuous), with: .color(color))

            // Right arm: extends UP from center-right
            let rightRect = CGRect(
                x: cx + gap / 2,
                y: cy - gap / 2 - armLength,
                width: armThick,
                height: armLength
            )
            context.fill(Path(roundedRect: rightRect, cornerRadius: r, style: .continuous), with: .color(color))

            // Bottom arm: extends RIGHT from lower-center
            let bottomRect = CGRect(
                x: cx + gap / 2,
                y: cy + gap / 2,
                width: armLength,
                height: armThick
            )
            context.fill(Path(roundedRect: bottomRect, cornerRadius: r, style: .continuous), with: .color(color))

            // Left arm: extends DOWN from center-left
            let leftRect = CGRect(
                x: cx - gap / 2 - armThick,
                y: cy + gap / 2,
                width: armThick,
                height: armLength
            )
            context.fill(Path(roundedRect: leftRect, cornerRadius: r, style: .continuous), with: .color(color))
        }
        .frame(width: size, height: size)
    }
}

// Keep old name as alias for compatibility
typealias MyBankOctagonLogo = MyBankPinwheelLogo

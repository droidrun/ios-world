import SwiftUI

enum ScoreZoneColors {
    /// Primary accent red (#E52534)
    static let accentRed = Color(red: 0.898, green: 0.145, blue: 0.204)

    /// Live game indicator red
    static let liveRed = Color(red: 0.98, green: 0.36, blue: 0.31)

    /// Dark card backgrounds
    static let cardBackground = Color(red: 0.09, green: 0.10, blue: 0.12)
    static let cardBackgroundLighter = Color(red: 0.10, green: 0.11, blue: 0.13)
    static let cardBackgroundElevated = Color(red: 0.12, green: 0.13, blue: 0.15)

    /// Chip / pill backgrounds
    static let chipBackground = Color(red: 0.09, green: 0.10, blue: 0.13)
    static let chipBackgroundSelected = Color(red: 0.17, green: 0.18, blue: 0.22)
    static let chipBackgroundDefault = Color(red: 0.21, green: 0.22, blue: 0.25)

    /// Opacity values for subtle white overlays on dark backgrounds
    static let hairlineOpacity: Double = 0.12
    static let pillBackgroundOpacity: Double = 0.08
    static let dividerOpacity: Double = 0.1
}

import SwiftUI

/// Centralized design tokens for the app
enum Theme {
    // MARK: - Colors
    static let accent = Color(hex: "5B5FC7")
    static let accentGradientStart = Color(hex: "667eea")
    static let accentGradientEnd = Color(hex: "764ba2")

    // MARK: - Gradients
    static let accentGradient = LinearGradient(
        colors: [accentGradientStart, accentGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Typography
    static func monoFont(size: CGFloat) -> Font {
        .system(size: size, design: .monospaced)
    }

    static func monoBoldFont(size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .monospaced)
    }
}

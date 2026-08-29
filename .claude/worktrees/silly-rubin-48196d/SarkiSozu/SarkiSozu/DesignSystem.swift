import SwiftUI

/// The central Design System for SarkiSozu.
/// Accessible via `DS` alias for brevity, e.g., `DS.Color.accent`.
struct DesignSystem {
    
    // MARK: - Colors
    struct Color {
        static let accent = SwiftUI.Color(hex: "5B5FC7")
        static let background = SwiftUI.Color("Background") // Define in Assets or use system
        static let secondaryBackground = SwiftUI.Color("SecondaryBackground")
        
        static let textPrimary = SwiftUI.Color.primary
        static let textSecondary = SwiftUI.Color.secondary
        static let textTertiary = SwiftUI.Color(uiColor: .tertiaryLabel)
        
        static let success = SwiftUI.Color.green
        static let warning = SwiftUI.Color.orange
        static let error = SwiftUI.Color.red
        
        static let chord = SwiftUI.Color(hex: "5B5FC7").opacity(0.9)
        
        static let gradientStart = SwiftUI.Color(hex: "5B5FC7")
        static let gradientEnd = SwiftUI.Color(hex: "764BA2")
        
        static var accentGradient: LinearGradient {
            LinearGradient(
                colors: [gradientStart, gradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // MARK: - Typography
    struct Typography {
        /// Large Title: 34pt
        static func largeTitle(_ text: String) -> Text {
            Text(text).font(.largeTitle).fontWeight(.bold)
        }
        
        /// Title 1: 28pt
        static func title1(_ text: String) -> Text {
            Text(text).font(.title).fontWeight(.bold)
        }
        
        /// Title 2: 22pt
        static func title2(_ text: String) -> Text {
            Text(text).font(.title2).fontWeight(.semibold)
        }
        
        /// Title 3: 20pt
        static func title3(_ text: String) -> Text {
            Text(text).font(.title3).fontWeight(.semibold)
        }
        
        /// Headline: 17pt, Semibold
        static func headline(_ text: String) -> Text {
            Text(text).font(.headline)
        }
        
        /// Body: 17pt, Regular
        static func body(_ text: String) -> Text {
            Text(text).font(.body)
        }
        
        /// Callout: 16pt, Regular
        static func callout(_ text: String) -> Text {
            Text(text).font(.callout)
        }
        
        /// Subheadline: 15pt, Regular
        static func subheadline(_ text: String) -> Text {
            Text(text).font(.subheadline).foregroundColor(.secondary)
        }
        
        /// Footnote: 13pt, Regular
        static func footnote(_ text: String) -> Text {
            Text(text).font(.footnote).foregroundColor(.secondary)
        }
        
        /// Caption: 12pt, Regular
        static func caption(_ text: String) -> Text {
            Text(text).font(.caption).foregroundColor(.secondary)
        }
        
        /// Monospaced lyrics font
        static func lyrics(size: CGFloat) -> Font {
            .system(size: size, weight: .regular, design: .monospaced)
        }
        
        /// Monospaced bold font (for chords)
        static func chords(size: CGFloat) -> Font {
            .system(size: size, weight: .bold, design: .monospaced)
        }
    }
    
    // MARK: - Spacing & Layout
    struct Spacing {
        /// 4pt
        static let xxs: CGFloat = 4
        /// 8pt
        static let xs: CGFloat = 8
        /// 12pt
        static let s: CGFloat = 12
        /// 16pt - Standard padding
        static let m: CGFloat = 16
        /// 24pt
        static let l: CGFloat = 24
        /// 32pt
        static let xl: CGFloat = 32
        /// 48pt
        static let xxl: CGFloat = 48
    }
    
    struct CornerRadius {
        /// 8pt
        static let small: CGFloat = 8
        /// 12pt
        static let medium: CGFloat = 12
        /// 16pt
        static let large: CGFloat = 16
        /// 24pt
        static let xlarge: CGFloat = 24
    }
    
    struct Shadow {
        let color: SwiftUI.Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
        
        static let light = Shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        static let medium = Shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        static let float = Shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 8)
    }
}

// MARK: - Layout Helpers
extension View {
    func standardPadding() -> some View {
        self.padding(DesignSystem.Spacing.m)
    }
    
    func cardStyle() -> some View {
        self
            .background(SwiftUI.Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(DesignSystem.CornerRadius.medium)
            //.shadow(color: DesignSystem.Shadow.light.color, radius: DesignSystem.Shadow.light.radius, x: DesignSystem.Shadow.light.x, y: DesignSystem.Shadow.light.y)
    }
}

// MARK: - Color Hex Extension (Moved from ContentView/Theme)
extension SwiftUI.Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Alias for convenience
typealias DS = DesignSystem

// MARK: - Previews
struct DesignSystem_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: DS.Spacing.m) {
            DS.Typography.title1("Design System")
            
            HStack {
                RoundedRectangle(cornerRadius: DS.CornerRadius.medium)
                    .fill(DS.Color.accent)
                    .frame(width: 50, height: 50)
                
                RoundedRectangle(cornerRadius: DS.CornerRadius.medium)
                    .fill(DS.Color.accentGradient)
                    .frame(width: 50, height: 50)
            }
            
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                DS.Typography.headline("Headline Text")
                DS.Typography.body("Body text goes here. This is a sample paragraph to demonstrate the typography scale.")
                DS.Typography.caption("Caption text details.")
            }
            .padding()
            .cardStyle()
        }
        .standardPadding()
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

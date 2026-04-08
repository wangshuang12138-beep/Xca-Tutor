import SwiftUI

// MARK: - Color Extensions

extension Color {
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
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Apple Colors

enum AppleColors {
    // Background
    static let background = Color(NSColor.windowBackgroundColor)
    static let secondaryBackground = Color(NSColor.controlBackgroundColor)
    static let tertiaryBackground = Color(NSColor.underPageBackgroundColor)
    
    // Text
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    static let tertiaryText = Color.gray
    
    // Accent - Apple Blue
    static let accent = Color(hex: "007AFF")
    static let accentHover = Color(hex: "0066CC")
    static let accentPressed = Color(hex: "0055AA")
    
    // Functional
    static let success = Color(hex: "34C759")
    static let warning = Color(hex: "FF9500")
    static let error = Color(hex: "FF3B30")
    
    // Glass effect
    static let glassBackground = Color.white.opacity(0.1)
    static let glassBorder = Color.white.opacity(0.2)
    
    // Gradients
    static let purpleGradient = [Color(hex: "5856D6"), Color(hex: "AF52DE")]
    static let orangeGradient = [Color(hex: "FF6B35"), Color(hex: "F7931E")]
    static let blueGradient = [Color(hex: "007AFF"), Color(hex: "5856D6")]
}

// MARK: - Typography

enum Typography {
    // Large titles
    static let largeTitle = Font.system(size: 48, weight: .bold, design: .rounded)
    
    // Titles
    static let title1 = Font.system(size: 32, weight: .bold)
    static let title2 = Font.system(size: 24, weight: .semibold)
    static let title3 = Font.system(size: 20, weight: .semibold)
    
    // Body
    static let body = Font.system(size: 15, weight: .regular)
    static let bodyLarge = Font.system(size: 17, weight: .regular)
    static let callout = Font.system(size: 14, weight: .regular)
    
    // Auxiliary
    static let caption = Font.system(size: 12, weight: .regular)
    static let caption2 = Font.system(size: 11, weight: .medium)
}

// MARK: - Spacing

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
}

// MARK: - Corner Radius

enum CornerRadius {
    static let sm: CGFloat = 6
    static let md: CGFloat = 10
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let full: CGFloat = 9999
}

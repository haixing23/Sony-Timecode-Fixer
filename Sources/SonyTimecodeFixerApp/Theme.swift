import SwiftUI

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let red = Double((hex >> 16) & 0xff) / 255
        let green = Double((hex >> 8) & 0xff) / 255
        let blue = Double(hex & 0xff) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    enum Theme {
        static let bgBase = Color(hex: 0x11111B)
        static let bgSurface = Color(hex: 0x181825)
        static let bgElevated = Color(hex: 0x1E1E2E)
        static let bgCode = Color(hex: 0x181825)

        static let borderSubtle = Color.white.opacity(0.06)
        static let borderDefault = Color.white.opacity(0.10)
        static let borderStrong = Color.white.opacity(0.16)

        static let textPrimary = Color(hex: 0xCDD6F4)
        static let textSecondary = Color(hex: 0xA6ADC8)
        static let textTertiary = Color(hex: 0x6C7086)
        static let textDisabled = Color(hex: 0x45475A)

        static let accentBlue = Color(hex: 0x89B4FA)
        static let accentLavender = Color(hex: 0xB4BEFE)
        static let accentGreen = Color(hex: 0xA6E3A1)
        static let accentPeach = Color(hex: 0xFAB387)
        static let accentRed = Color(hex: 0xF38BA8)
        static let accentMauve = Color(hex: 0xCBA6F7)

        static let trafficRed = Color(hex: 0xFF5F57).opacity(0.7)
        static let trafficYellow = Color(hex: 0xFEBC2E).opacity(0.7)
        static let trafficGreen = Color(hex: 0x28C840).opacity(0.7)
    }
}

extension Font {
    enum Theme {
        static let title = Font.system(size: 28, weight: .bold, design: .default)
        static let subtitle = Font.system(size: 13, weight: .regular, design: .default)
        static let section = Font.system(size: 11, weight: .semibold, design: .default)
        static let body = Font.system(size: 13, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 13, weight: .medium, design: .default)
        static let caption = Font.system(size: 11, weight: .regular, design: .default)
        static let code = Font.system(size: 12, weight: .regular, design: .monospaced)
        static let codeLabel = Font.system(size: 11, weight: .medium, design: .monospaced)
    }
}

enum Space {
    static let x1: CGFloat = 4
    static let x2: CGFloat = 8
    static let x3: CGFloat = 12
    static let x4: CGFloat = 16
    static let x5: CGFloat = 20
    static let x6: CGFloat = 24
    static let x8: CGFloat = 32
    static let x10: CGFloat = 40
}

enum Radius {
    static let sm: CGFloat = 10
    static let md: CGFloat = 14
    static let lg: CGFloat = 18
    static let xl: CGFloat = 24
}

extension View {
    func cardShadow() -> some View {
        shadow(color: Color.black.opacity(0.35), radius: 24, x: 0, y: 8)
    }
}

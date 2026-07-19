import SwiftUI

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: alpha)
    }
}

/// The Nixring design system — a confident dark "trust & security" palette:
/// deep ink navy grounds a single electric-cyan accent.
enum Palette {
    static let bg = Color(hex: 0x070A13)
    static let bgElevated = Color(hex: 0x0F1526)
    static let surface = Color(hex: 0x18203A)
    static let surfaceHi = Color(hex: 0x212B49)
    static let stroke = Color(hex: 0x2A3557)

    static let accent = Color(hex: 0x37D7F2)   // electric cyan
    static let accent2 = Color(hex: 0x5B8DEF)  // cool blue (gradient partner)

    static let textPrimary = Color(hex: 0xF4F7FD)
    static let textSecondary = Color(hex: 0x94A0BC)
    static let textMuted = Color(hex: 0x5E6A87)

    static let success = Color(hex: 0x37D9A0)
    static let danger = Color(hex: 0xFB7185)
    static let amber = Color(hex: 0xF6C453)

    static let accentGradient = LinearGradient(
        colors: [accent, accent2], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let shieldGlow = RadialGradient(
        colors: [accent.opacity(0.35), .clear], center: .center, startRadius: 2, endRadius: 170)
}

/// A rounded elevated card used throughout the app.
struct Card<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Palette.stroke, lineWidth: 1))
    }
}

extension View {
    /// Full-bleed app background.
    func nixringBackground() -> some View {
        self.background(Palette.bg.ignoresSafeArea())
    }
}

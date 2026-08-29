import SwiftUI

// MARK: - Design tokens
//
// Palette lifted 1:1 from the Claude Design canvas (`Alcohol Tracker iOS.dc.html`).
// Light and dark are designed independently — dark is not an inversion.

struct Theme: Equatable {
    let bg: Color
    let card: Color
    let card2: Color
    let ink: Color
    let sec: Color
    let ter: Color
    let hair: Color
    let tide: Color
    let tideSoft: Color
    let moss: Color
    let mossSoft: Color
    let amber: Color
    let amberSoft: Color
    let danger: Color
    let glass: Color
    let isDark: Bool

    static let light = Theme(
        bg: Color(hex: 0xF6F5F2),
        card: Color(hex: 0xFFFFFF),
        card2: Color(hex: 0xECEAE4),
        ink: Color(hex: 0x1D1C19),
        sec: Color(hex: 0x1D1C19).opacity(0.55),
        ter: Color(hex: 0x1D1C19).opacity(0.36),
        hair: Color(hex: 0x1D1C19).opacity(0.09),
        tide: Color(hex: 0x2E8FBF),
        tideSoft: Color(hex: 0xDCEFF9),
        moss: Color(hex: 0x4BA36A),
        mossSoft: Color(hex: 0xDEF4E5),
        amber: Color(hex: 0xD68A28),
        amberSoft: Color(hex: 0xFAEED4),
        danger: Color(hex: 0xC9563E),
        glass: Color.white.opacity(0.72),
        isDark: false
    )

    static let dark = Theme(
        bg: Color(hex: 0x151513),
        card: Color(hex: 0x1F1F1C),
        card2: Color(hex: 0x2A2925),
        ink: Color(hex: 0xF2F0EB),
        sec: Color(hex: 0xF2F0EB).opacity(0.6),
        ter: Color(hex: 0xF2F0EB).opacity(0.38),
        hair: Color(hex: 0xF2F0EB).opacity(0.12),
        tide: Color(hex: 0x6BC1E8),
        tideSoft: Color(hex: 0x1E3A4A),
        moss: Color(hex: 0x7FD49A),
        mossSoft: Color(hex: 0x20402C),
        amber: Color(hex: 0xF0B45E),
        amberSoft: Color(hex: 0x403319),
        danger: Color(hex: 0xE88268),
        glass: Color(red: 28 / 255, green: 28 / 255, blue: 26 / 255).opacity(0.72),
        isDark: true
    )
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = .light
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

// MARK: - Motion
//
// The canvas leans on one springy curve — cubic-bezier(.34,1.45,.5,1) — for
// press feedback, and cubic-bezier(.32,.72,0,1) for slides/rises. These map
// closely onto the springs below. Every call site funnels through Motion so
// Reduce Motion can flatten the whole app at once.

enum Motion {
    /// cubic-bezier(.34,1.45,.5,1) — playful overshoot for presses/pops.
    static let pop = Animation.spring(response: 0.4, dampingFraction: 0.62)
    /// cubic-bezier(.32,.72,0,1) — decisive ease-out for slides and rises.
    static let slide = Animation.timingCurve(0.32, 0.72, 0, 1, duration: 0.48)
    static let rise = Animation.timingCurve(0.32, 0.72, 0, 1, duration: 0.5)
    static let fade = Animation.easeInOut(duration: 0.35)
    static let bars = Animation.timingCurve(0.3, 0.9, 0.3, 1, duration: 0.7)
    static let count = Animation.easeOut(duration: 0.85)

    static func riseDelayed(_ delay: Double) -> Animation { rise.delay(delay) }

    static func reduced(_ reduce: Bool, _ animation: Animation) -> Animation? {
        reduce ? .easeOut(duration: 0.12) : animation
    }
}

// MARK: - Reusable styles

/// Press-down scale used on virtually every tappable surface in the canvas
/// (`style-active="transform:scale(.9…0.97)"`).
struct PressScale: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(Motion.pop, value: configuration.isPressed)
    }
}

struct CardBackground: ViewModifier {
    @Environment(\.theme) private var theme
    var radius: CGFloat = 22

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(theme.card)
                    .shadow(color: .black.opacity(0.03), radius: 1, y: 1)
                    .shadow(color: .black.opacity(0.045), radius: 10, y: 6)
            )
    }
}

extension View {
    func card(radius: CGFloat = 22) -> some View { modifier(CardBackground(radius: radius)) }

    /// Staggered entrance used across the canvas: fade + 12pt rise.
    func riseIn(delay: Double = 0) -> some View { modifier(RiseIn(delay: delay)) }
}

struct RiseIn: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var delay: Double
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 12)
            .scaleEffect(shown ? 1 : 0.985)
            .onAppear {
                withAnimation(Motion.reduced(reduceMotion, Motion.riseDelayed(delay))) {
                    shown = true
                }
            }
    }
}

// MARK: - Small shared atoms

/// The app's droplet mark: a circle with one squared corner, rotated 45°.
struct DropletMark: View {
    @Environment(\.theme) private var theme
    var size: CGFloat = 46
    var color: Color?
    var breathing = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe = false

    var body: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: size / 2,
            bottomLeadingRadius: size / 8,
            bottomTrailingRadius: size / 2,
            topTrailingRadius: size / 2,
            style: .continuous
        )
        .fill(color ?? theme.tide)
        .frame(width: size, height: size)
        .rotationEffect(.degrees(45))
        .scaleEffect(breathe ? 1.03 : 1)
        .onAppear {
            guard breathing, !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
        .accessibilityHidden(true)
    }
}

struct ChevronRight: View {
    @Environment(\.theme) private var theme
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(theme.ter)
    }
}

/// Section caption, e.g. "LOGGED TODAY", "YOUR DATA".
struct SectionCaption: View {
    @Environment(\.theme) private var theme
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .kerning(0.6)
            .foregroundStyle(theme.ter)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

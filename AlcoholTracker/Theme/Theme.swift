import SwiftUI

// MARK: - Design tokens
//
// The token set, verbatim from the Claude Design canvas `Coaster Prototype.dc.html`.
//
// The canvas ships **three** themes, each with an independently designed light
// and dark palette — dark is never an inversion. The names here are the
// canvas's own (`bg`, `surface`, `accent`, `b1`…`b4`) so a future canvas
// revision diffs against this file without a translation step.

/// The three themes from the canvas's `THEMES` table.
///
/// The raw value is the persisted identity and never changes; the display name
/// and description are read from the string catalog so they follow the locale.
enum AppTheme: String, CaseIterable, Codable {
    case kiln
    case nocturne
    case coaster

    /// Brand nouns — deliberately not translated, like `Apple Health`.
    var displayName: String {
        switch self {
        case .kiln: "Kiln"
        case .nocturne: "Nocturne"
        case .coaster: "Coaster"
        }
    }

    var blurb: String {
        switch self {
        case .kiln: L.s("theme_kiln_desc")
        case .nocturne: L.s("theme_nocturne_desc")
        case .coaster: L.s("theme_coaster_desc")
        }
    }

    static func from(_ raw: String?) -> AppTheme {
        AppTheme(rawValue: raw ?? "") ?? .kiln
    }
}

/// Corner radii. Each theme sets its own — Kiln is tight and papery at 12,
/// Nocturne soft at 18 — so radius is a theme token, not a constant.
struct Radii: Equatable {
    /// Cards and grouped rows.
    let r: CGFloat
    /// Chips, small controls, inset wells.
    let rs: CGFloat
    /// Primary buttons.
    let rl: CGFloat
}

struct Theme: Equatable {
    /// Page ground.
    let bg: Color
    /// Raised surface: cards, rows, the tab bar.
    let surface: Color
    /// Sunken surface: chips, wells, inset groups.
    let surface2: Color
    /// Hairline borders. In this system a card is a border, not a shadow.
    let line: Color
    /// Primary text.
    let text: Color
    /// Secondary text.
    let muted: Color
    /// Tertiary text, captions, disabled.
    let faint: Color
    /// The one accent: primary actions, links, selection.
    let accent: Color
    /// Text/icon that sits on top of `accent`.
    let onAccent: Color
    /// The earned/premium accent — gold. Owns Pro and the banked-day mark.
    let accent2: Color
    /// Text/icon on top of `accent2`.
    let onAccent2: Color
    /// Band 1 — at or under 75% of the daily goal. Also "dry day".
    let b1: Color
    /// Band 2 — 75–100%.
    let b2: Color
    /// Band 3 — 100–150%. Also the destructive colour.
    let b3: Color
    /// Band 4 — over 150%.
    let b4: Color
    let isDark: Bool
    let radii: Radii
    let fonts: ThemeFonts

    /// The brief's FIXED band scale (§5.2). Colour may judge; copy may not.
    /// Thresholds are the canvas's `band(ratio)` exactly.
    func band(_ ratio: Double) -> Color {
        if ratio <= 0.75 { return b1 }
        if ratio <= 1.0 { return b2 }
        if ratio <= 1.5 { return b3 }
        return b4
    }

    static func resolve(_ theme: AppTheme, dark: Bool) -> Theme {
        switch theme {
        case .kiln: dark ? .kilnDark : .kilnLight
        case .nocturne: dark ? .nocturneDark : .nocturneLight
        case .coaster: dark ? .coasterDark : .coasterLight
        }
    }

    /// Back-compat aliases so a `Theme.light` reference still resolves to the
    /// default look while the app is being migrated screen by screen.
    static let light = Theme.kilnLight
    static let dark = Theme.kilnDark
}

// MARK: - Kiln — warm stone and struck brass

extension Theme {
    static let kilnLight = Theme(
        bg: Color(hex: 0xF6F3EE), surface: Color(hex: 0xFFFFFF),
        surface2: Color(hex: 0xF0E6DE), line: Color(hex: 0xE7E1D7),
        text: Color(hex: 0x1C1A17), muted: Color(hex: 0x6E675D), faint: Color(hex: 0x9A9287),
        accent: Color(hex: 0xB4623A), onAccent: Color(hex: 0xFFFFFF),
        accent2: Color(hex: 0xC9962F), onAccent2: Color(hex: 0xF6F3EE),
        b1: Color(hex: 0x5E7A5B), b2: Color(hex: 0xB08A3C),
        b3: Color(hex: 0x8C4A63), b4: Color(hex: 0x5A2440),
        isDark: false,
        radii: Radii(r: 12, rs: 9, rl: 14),
        fonts: .kiln
    )

    static let kilnDark = Theme(
        bg: Color(hex: 0x16130F), surface: Color(hex: 0x201C17),
        surface2: Color(hex: 0x2A241C), line: Color(hex: 0x332C22),
        text: Color(hex: 0xF2ECE1), muted: Color(hex: 0xA0968A), faint: Color(hex: 0x8C8272),
        accent: Color(hex: 0xC4703F), onAccent: Color(hex: 0x16130F),
        accent2: Color(hex: 0xD9AC48), onAccent2: Color(hex: 0x16130F),
        b1: Color(hex: 0x7E9B79), b2: Color(hex: 0xD2A24A),
        b3: Color(hex: 0xC07694), b4: Color(hex: 0x9A5678),
        isDark: true,
        radii: Radii(r: 12, rs: 9, rl: 14),
        fonts: .kiln
    )
}

// MARK: - Nocturne — graphite, ivory for banked days

extension Theme {
    static let nocturneLight = Theme(
        bg: Color(hex: 0xF4F4F2), surface: Color(hex: 0xFFFFFF),
        surface2: Color(hex: 0xF0F0ED), line: Color(hex: 0xE3E3DF),
        text: Color(hex: 0x14161A), muted: Color(hex: 0x6E747C), faint: Color(hex: 0x8B9096),
        accent: Color(hex: 0x14161A), onAccent: Color(hex: 0xFFFFFF),
        accent2: Color(hex: 0x8A6B2F), onAccent2: Color(hex: 0xF4F4F2),
        b1: Color(hex: 0x4F7A56), b2: Color(hex: 0xA6791F),
        b3: Color(hex: 0xC25A2E), b4: Color(hex: 0xA33227),
        isDark: false,
        radii: Radii(r: 18, rs: 12, rl: 16),
        fonts: .nocturne
    )

    static let nocturneDark = Theme(
        bg: Color(hex: 0x101114), surface: Color(hex: 0x191B1F),
        surface2: Color(hex: 0x23262B), line: Color(hex: 0x2B2F35),
        text: Color(hex: 0xF1EFEA), muted: Color(hex: 0x969CA4), faint: Color(hex: 0x6E747C),
        accent: Color(hex: 0xEDE4D3), onAccent: Color(hex: 0x101114),
        accent2: Color(hex: 0xE3B341), onAccent2: Color(hex: 0x101114),
        b1: Color(hex: 0x8FB07A), b2: Color(hex: 0xE3B341),
        b3: Color(hex: 0xE07A4B), b4: Color(hex: 0xB8443A),
        isDark: true,
        radii: Radii(r: 18, rs: 12, rl: 16),
        fonts: .nocturne
    )
}

// MARK: - Coaster — kraft paper, ink and honey

extension Theme {
    static let coasterLight = Theme(
        bg: Color(hex: 0xEFE9DE), surface: Color(hex: 0xFBF7F0),
        surface2: Color(hex: 0xEFE4D2), line: Color(hex: 0xDED5C6),
        text: Color(hex: 0x17140F), muted: Color(hex: 0x6F6759), faint: Color(hex: 0x9C927F),
        accent: Color(hex: 0xC4872F), onAccent: Color(hex: 0xFFFFFF),
        accent2: Color(hex: 0xC4872F), onAccent2: Color(hex: 0xEFE9DE),
        b1: Color(hex: 0x5E7A5B), b2: Color(hex: 0xC4872F),
        b3: Color(hex: 0xA9713C), b4: Color(hex: 0x17140F),
        isDark: false,
        radii: Radii(r: 16, rs: 12, rl: 16),
        fonts: .coaster
    )

    static let coasterDark = Theme(
        bg: Color(hex: 0x14120F), surface: Color(hex: 0x1D1A16),
        surface2: Color(hex: 0x262119), line: Color(hex: 0x332C22),
        text: Color(hex: 0xF5F0E7), muted: Color(hex: 0xA0968A), faint: Color(hex: 0x8A8172),
        accent: Color(hex: 0xC4872F), onAccent: Color(hex: 0x14120F),
        accent2: Color(hex: 0xD9A441), onAccent2: Color(hex: 0x14120F),
        b1: Color(hex: 0x7E9B79), b2: Color(hex: 0xD9A441),
        b3: Color(hex: 0xC08B54), b4: Color(hex: 0xE7DFCE),
        isDark: true,
        radii: Radii(r: 16, rs: 12, rl: 16),
        fonts: .coaster
    )
}

// MARK: - Typefaces
//
// Each theme pairs a display face with a body face. Where a family has no cut
// at a requested weight the nearest available one is mapped here rather than
// left to the system's synthetic bolding, which smears these designs badly.

struct ThemeFonts: Equatable {
    let displayFamily: String
    let bodyFamily: String
    /// Instrument Serif is drawn at its one optical weight; Space Grotesk and
    /// Outfit are set heavier so their counters hold at small sizes.
    let displayWeight: Font.Weight

    static let kiln = ThemeFonts(
        displayFamily: "InstrumentSerif", bodyFamily: "PublicSans", displayWeight: .regular)
    static let nocturne = ThemeFonts(
        displayFamily: "SpaceGrotesk", bodyFamily: "IBMPlexSans", displayWeight: .semibold)
    static let coaster = ThemeFonts(
        displayFamily: "Outfit", bodyFamily: "PublicSans", displayWeight: .semibold)

    /// PostScript-name suffix for a weight, per family. Space Grotesk ships no
    /// SemiBold and IBM Plex Sans no Bold, so both fall to their nearest cut.
    private func cut(_ family: String, _ weight: Font.Weight) -> String {
        switch weight {
        case .bold, .heavy, .black:
            return family == "IBMPlexSans" ? "SemiBold" : "Bold"
        case .semibold:
            return family == "SpaceGrotesk" ? "Bold" : "SemiBold"
        case .medium:
            return "Medium"
        default:
            return "Regular"
        }
    }

    func body(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        // Instrument Serif is never a body face, so bodyFamily always has cuts.
        .custom("\(bodyFamily)-\(cut(bodyFamily, weight))", size: size)
    }

    func display(_ size: CGFloat, _ weight: Font.Weight? = nil) -> Font {
        let w = weight ?? displayWeight
        // Instrument Serif has a single cut; asking for another yields nothing.
        let name = displayFamily == "InstrumentSerif"
            ? "InstrumentSerif-Regular"
            : "\(displayFamily)-\(cut(displayFamily, w))"
        return .custom(name, size: size)
    }
}

// MARK: - Environment

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = .kilnLight
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
// The canvas leans on one springy curve — cubic-bezier(.34,1.56,.64,1) — for
// press feedback and menu items, and cubic-bezier(.22,1,.36,1) for slides,
// sheets and the ring. Every call site funnels through Motion so Reduce Motion
// can flatten the whole app at once.

enum Motion {
    /// Playful overshoot for presses, pops and the FAB menu.
    static let pop = Animation.spring(response: 0.34, dampingFraction: 0.62)
    /// Decisive ease-out for sheets, panels and screen changes.
    static let slide = Animation.timingCurve(0.22, 1, 0.36, 1, duration: 0.42)
    static let rise = Animation.timingCurve(0.22, 1, 0.36, 1, duration: 0.28)
    static let fade = Animation.easeInOut(duration: 0.3)
    /// Ring and bar growth — the canvas animates stroke-dasharray over 550ms.
    static let bars = Animation.timingCurve(0.22, 1, 0.36, 1, duration: 0.55)
    static let count = Animation.easeOut(duration: 0.85)

    static func riseDelayed(_ delay: Double) -> Animation { rise.delay(delay) }

    static func reduced(_ reduce: Bool, _ animation: Animation) -> Animation? {
        reduce ? .easeOut(duration: 0.12) : animation
    }
}

// MARK: - Reusable styles

/// Press-down scale used on virtually every tappable surface in the canvas.
struct PressScale: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(Motion.pop, value: configuration.isPressed)
    }
}

/// A card here is a plane with an edge, not a floating slab: the canvas draws
/// every surface with a 1px line and no shadow at all.
struct CardBackground: ViewModifier {
    @Environment(\.theme) private var theme
    var radius: CGFloat?
    var filled: Color?
    var bordered: Bool = true

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius ?? theme.radii.r, style: .continuous)
        return content
            .background(shape.fill(filled ?? theme.surface))
            .overlay(bordered ? shape.strokeBorder(theme.line, lineWidth: 1) : nil)
    }
}

extension View {
    func card(radius: CGFloat? = nil, filled: Color? = nil, bordered: Bool = true) -> some View {
        modifier(CardBackground(radius: radius, filled: filled, bordered: bordered))
    }

    /// Staggered entrance used across the canvas: fade + 10pt rise.
    func riseIn(delay: Double = 0) -> some View { modifier(RiseIn(delay: delay)) }
}

struct RiseIn: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var delay: Double
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 10)
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
            bottomLeadingRadius: size / 12,
            bottomTrailingRadius: size / 2,
            topTrailingRadius: size / 2,
            style: .continuous
        )
        .fill(color ?? theme.accent)
        .frame(width: size, height: size)
        .rotationEffect(.degrees(45))
        .scaleEffect(breathe ? 1.09 : 1)
        .onAppear {
            guard breathing, !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
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
            .foregroundStyle(theme.faint)
    }
}

/// Section caption, e.g. "LOGGED TODAY", "YOUR DATA".
struct SectionCaption: View {
    @Environment(\.theme) private var theme
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(theme.fonts.body(9, .bold))
            .kerning(1.1)
            .foregroundStyle(theme.faint)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Drink category tints
//
// Identity colours for a kind of drink, deliberately outside the band scale —
// a wine is plum whether or not you are over your goal.

enum DrinkTints {
    static let beer = Color(hex: 0xD9A441)
    static let wine = Color(hex: 0x8E4257)
    static let spirit = Color(hex: 0xA9713C)
    static let cocktail = Color(hex: 0xB4623A)
    static let rtd = Color(hex: 0x7E8A88)
    static let cider = Color(hex: 0xC9962F)

    /// Category guessed from ABV and serving size, for the presets and logs
    /// that predate a category field. Wide pours at low strength are beer;
    /// small pours at high strength are spirits.
    static func forDrink(abv: Double, ml: Double) -> Color {
        if abv >= 30 { return spirit }
        if abv >= 9, ml <= 220 { return wine }
        if abv <= 7.5, ml >= 300 { return beer }
        if abv <= 7.5 { return rtd }
        return cocktail
    }
}

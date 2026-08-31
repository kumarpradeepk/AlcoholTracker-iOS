import SwiftUI

// MARK: - Design tokens
//
// The token set, verbatim from the Claude Design canvas (`Alcohol Tracker
// Phone.html`, the `.at` / `.at.dk` / `.at.mnl` / `.at.dk.mnd` blocks).
//
// Two families, each designed in light and dark: Warm, and a Mono pair that has
// no hue to judge with and carries state in texture instead. The concrete
// palettes are generated into `Palettes.swift`; this file is the shape they
// fill and the behaviour that hangs off them.

/// Surface texture.
///
/// The mono themes cannot use hue to separate states, so they reach for a dot
/// grid and diagonal hatching instead; the warm themes set `.none` and the
/// drawing is skipped entirely.
enum Pattern: Equatable {
    case none
    /// `radial-gradient(<c> 1px, transparent 1px)` — a 1px dot on a grid.
    case dots(Color, spacing: CGFloat = 10)
    /// `repeating-linear-gradient(135deg, …)` — fine diagonal hatching.
    case diagonal(Color, period: CGFloat = 10, thickness: CGFloat = 2)
}

/// A chart bar's fill. Striped is how the mono themes say "over goal" without
/// a red to say it in.
enum BarFill: Equatable {
    case flat(Color)
    case striped(Color, Color)
}

struct Theme: Equatable {
    /// The page the app is drawn on.
    let page: Color
    /// Behind the page — the frame ground.
    let outer: Color
    /// A raised card. In this design a card is a fill, not a border.
    let card: Color
    /// A sunken well inside a card: icon tiles, inset rows.
    let elev: Color
    /// Primary text.
    let ink: Color
    /// Secondary text. The canvas has exactly two ink levels — do not add a third.
    let sub: Color
    /// Hairline dividers.
    let line: Color

    /// The accent. Fills the intake hero and every primary action.
    let acc: Color
    /// Text and icons on top of `acc`.
    let accInk: Color
    /// Positive: dry days, under-goal bars.
    let moss: Color
    /// Text on top of `moss`.
    let mossInk: Color
    /// Caution: approaching the daily goal.
    let amber: Color
    /// Over goal, and every destructive action.
    let danger: Color
    /// Text on top of `danger`.
    let dangerInk: Color
    /// A switch's track when it is on — its own token, not always `acc`.
    let togOn: Color

    /// The intake ring in its caution band.
    let ringWarn: Color
    /// The intake ring once over goal.
    let ringOver: Color
    /// The ring's second over-goal lap, past 200%.
    let ringOver2: Color

    /// Dimmer behind sheets and dialogs.
    let scrim: Color

    /// Texture behind the page.
    let patPage: Pattern
    /// Texture inside the intake hero.
    let patHero: Pattern
    /// Texture on a moss surface.
    let patMoss: Pattern
    /// Fill for an over-goal bar.
    let barOver: BarFill
    /// Fill for a caution bar.
    let barWarnBg: BarFill
    /// Opacity of the decorative glass silhouettes; zero in the warm themes.
    let silhouette: Double

    let isDark: Bool

    /// Kept so call sites written against the previous direction still read.
    var onAcc: Color { accInk }

    /// The goal-progress ramp. Colour may judge; copy may not.
    ///
    /// The mono themes have no hue to judge with, so their moss/amber/danger
    /// collapse towards greys and the *pattern* carries the meaning instead.
    func forRatio(_ ratio: Double) -> Color {
        if ratio <= 0.75 { return moss }
        if ratio <= 1.0 { return amber }
        return danger
    }

    /// The canvas's `color-mix(in oklab, <c> <pct>%, var(--card))`.
    ///
    /// Mixed in linear space: a plain sRGB blend of a saturated accent into a
    /// warm card goes muddy, and this stays far closer to what the canvas draws.
    func mix(_ color: Color, _ percent: Double) -> Color {
        let t = min(max(percent, 0), 1)
        func lin(_ c: Double) -> Double { c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
        func srgb(_ c: Double) -> Double { c <= 0.0031308 ? c * 12.92 : 1.055 * pow(c, 1 / 2.4) - 0.055 }
        let a = UIColor(color).rgb, b = UIColor(card).rgb
        return Color(
            red: srgb(lin(a.r) * t + lin(b.r) * (1 - t)),
            green: srgb(lin(a.g) * t + lin(b.g) * (1 - t)),
            blue: srgb(lin(a.b) * t + lin(b.b) * (1 - t))
        )
    }

    /// Back-compat aliases for the default look.
    static var light: Theme { .warmLight }
    static var dark: Theme { .warmDark }

    static func resolve(dark: Bool) -> Theme { dark ? .warmDark : .warmLight }
}

/// The two theme families. Each is designed in light and dark independently,
/// so this is orthogonal to the scheme choice.
enum AppTheme: String, CaseIterable, Codable {
    case warm
    case mono

    /// Shown in the picker; the descriptions live in the string catalog.
    var displayName: String {
        switch self {
        case .warm: L.s("theme_warm")
        case .mono: L.s("theme_mono")
        }
    }

    var blurb: String {
        switch self {
        case .warm: L.s("theme_warm_desc")
        case .mono: L.s("theme_mono_desc")
        }
    }

    static func from(_ raw: String?) -> AppTheme { AppTheme(rawValue: raw ?? "") ?? .warm }
}

/// Corner radii, read off the canvas. This design is much rounder than the
/// last one and the steps carry meaning, so they are named for what they wrap.
enum Radii {
    /// Icon buttons and small tiles — 15pt in the canvas.
    static let tile: CGFloat = 15
    /// Chips and pills that are not fully round.
    static let chip: CGFloat = 18
    /// Banners and secondary cards.
    static let banner: CGFloat = 20
    /// Standard content card.
    static let card: CGFloat = 24
    /// The intake hero and bottom sheets.
    static let hero: CGFloat = 30
}

// MARK: - Typeface
//
// General Sans (Fontshare, FFL) — the design's only typeface, replacing the
// five families the previous direction carried. The canvas asks for weight 800
// in places; 700 is the heaviest cut published, so those map to Bold rather
// than being synthesised.

enum Fonts {
    static func face(_ weight: Font.Weight) -> String {
        switch weight {
        case .bold, .heavy, .black: "GeneralSans-Bold"
        case .semibold: "GeneralSans-Semibold"
        case .medium: "GeneralSans-Medium"
        default: "GeneralSans-Regular"
        }
    }

    /// Any text in the app. One family, so this is the only entry point.
    static func text(_ size: CGFloat, _ weight: Font.Weight = .medium) -> Font {
        .custom(face(weight), size: size)
    }

    /// A headline figure: the intake number, a BAC reading, a stat value.
    /// The canvas tracks these tight — `-.02em` at 30pt through `-.04em` at 62pt.
    static func figure(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .custom(face(weight), size: size)
    }

    /// Tracking to pair with `figure(_:)` at a given size.
    static func figureTracking(_ size: CGFloat) -> CGFloat {
        size >= 48 ? -size * 0.04 : -size * 0.025
    }
}

// MARK: - Environment

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

private extension UIColor {
    var rgb: (r: Double, g: Double, b: Double) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
    }
}

// MARK: - Motion
//
// One-for-one with the canvas's `@keyframes` block and its `transition:`
// declarations. Durations and curves are the design's own numbers rather than
// system defaults; the whole feel of this direction is carried by them.

enum Motion {
    /// `cubic-bezier(.32,.72,.33,1)` — sheets, panels, slide-ins.
    static let settle = Animation.timingCurve(0.32, 0.72, 0.33, 1, duration: 0.5)
    /// `cubic-bezier(.3,.7,.3,1)` — the ring sweep and width growth.
    static let sweep = Animation.timingCurve(0.3, 0.7, 0.3, 1, duration: 0.7)
    /// `cubic-bezier(.3,.7,.3,1.2)` — a mild overshoot, e.g. the segmented thumb.
    static let overshoot = Animation.timingCurve(0.3, 0.7, 0.3, 1.2, duration: 0.25)
    /// `cubic-bezier(.3,.7,.3,1.3)` — the toast's livelier arrival.
    static let toast = Animation.timingCurve(0.3, 0.7, 0.3, 1.3, duration: 0.35)
    /// `cubic-bezier(.3,.7,.3,1.5)` — the strongest pop in the design.
    static let popCurve = Animation.timingCurve(0.3, 0.7, 0.3, 1.5, duration: 0.55)
    /// `cubic-bezier(.2,.75,.2,1)` — the odometer digit rise.
    static let riseIn = Animation.timingCurve(0.2, 0.75, 0.2, 1, duration: 0.55)

    /// `animation:fadeUp .4s` — the universal entrance.
    static let fadeUp = Animation.timingCurve(0.32, 0.72, 0.33, 1, duration: 0.4)
    static let fade = Animation.easeInOut(duration: 0.32)
    static let pop = Animation.spring(response: 0.34, dampingFraction: 0.62)
    static let bars = Animation.timingCurve(0.3, 0.7, 0.3, 1, duration: 0.5)
    static let count = Animation.easeOut(duration: 0.85)

    /// The global `transition:background-color .3s,color .3s,…` cross-fade.
    static let theme = Animation.easeInOut(duration: 0.3)

    /// `transition:transform .15s` — the press response on every control.
    static let press = Animation.easeOut(duration: 0.15)

    /// Entry stagger between siblings; the canvas steps in 20 ms.
    static let stagger: Double = 0.02

    static func fadeUpDelayed(_ delay: Double) -> Animation { fadeUp.delay(delay) }

    static func reduced(_ reduce: Bool, _ animation: Animation) -> Animation? {
        reduce ? .easeOut(duration: 0.12) : animation
    }
}

// MARK: - Reusable styles

/// Press-down scale used on virtually every tappable surface in the canvas
/// (`style-active="transform:scale(.92…98)"`).
struct PressScale: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

/// A card here is a fill, not a border and not a shadow — the canvas separates
/// cards from the page by tone alone.
struct CardBackground: ViewModifier {
    @Environment(\.theme) private var theme
    var radius: CGFloat?
    var filled: Color?
    var shadowed: Bool = false

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius ?? Radii.card, style: .continuous)
        return content
            .background(shape.fill(filled ?? theme.card))
            .compositingGroup()
            .shadow(color: shadowed ? .black.opacity(theme.isDark ? 0.7 : 0.35) : .clear,
                    radius: 22, y: 18)
    }
}

extension View {
    func card(radius: CGFloat? = nil, filled: Color? = nil, shadowed: Bool = false) -> some View {
        modifier(CardBackground(radius: radius, filled: filled, shadowed: shadowed))
    }

    /// `animation:fadeUp .4s <delay> both` — 14pt up and a fade.
    func fadeUp(delay: Double = 0) -> some View { modifier(FadeUp(delay: delay)) }

    /// Kept for call sites written against the previous direction.
    func riseIn(delay: Double = 0) -> some View { modifier(FadeUp(delay: delay)) }
}

struct FadeUp: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var delay: Double
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 14)
            .onAppear {
                withAnimation(Motion.reduced(reduceMotion, Motion.fadeUpDelayed(delay))) {
                    shown = true
                }
            }
    }
}

// MARK: - Small shared atoms

/// The app's droplet mark. `animation:breathe` scales it 1 ⇄ 1.13.
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
        .fill(color ?? theme.acc)
        .frame(width: size, height: size)
        .rotationEffect(.degrees(45))
        .scaleEffect(breathe ? 1.13 : 1)
        .onAppear {
            guard breathing, !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
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
            .foregroundStyle(theme.sub)
    }
}

/// Section caption, e.g. "LOGGED TODAY", "YOUR DATA".
struct SectionCaption: View {
    @Environment(\.theme) private var theme
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(Fonts.text(12, .bold))
            .kerning(12 * 0.08)
            .textCase(.uppercase)
            .foregroundStyle(theme.sub)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Drink category tints
//
// Identity colours for a kind of drink, deliberately outside the goal ramp —
// a wine is plum whether or not you are over your goal.

enum DrinkTints {
    static let beer = Color(hex: 0xD9A441)
    static let wine = Color(hex: 0x8E4257)
    static let spirit = Color(hex: 0xA9713C)
    static let cocktail = Color(hex: 0xB4623A)
    static let rtd = Color(hex: 0x7E8A88)
    static let cider = Color(hex: 0xC9962F)

    /// Category guessed from ABV and serving size, for the presets and logs
    /// that predate a category field.
    static func forDrink(abv: Double, ml: Double) -> Color {
        if abv >= 30 { return spirit }
        if abv >= 9, ml <= 220 { return wine }
        if abv <= 7.5, ml >= 300 { return beer }
        if abv <= 7.5 { return rtd }
        return cocktail
    }
}

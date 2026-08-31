import SwiftUI

// GENERATED — do not edit by hand. Regenerate with `scratchpad/gen_themes.py`.
//
// The canvas's four theme states, resolved from its cascading `.at` /
// `.at.dk` / `.at.mnl` / `.at.dk.mnd` blocks. Mono-dark layers on dark in the
// canvas, so it is flattened here rather than left as inheritance.

extension Theme {
    static let warmLight = Theme(
        page: Color(hex: 0xEFECE7),
        outer: Color(hex: 0xE5E1DA),
        card: Color(hex: 0xFFFFFF),
        elev: Color(hex: 0xF4F1EC),
        ink: Color(hex: 0x231C15),
        sub: Color(hex: 0x8D8478),
        line: Color(hex: 0xE7E2DA),
        acc: Color(hex: 0xE0643C),
        accInk: Color(hex: 0xFFFFFF),
        moss: Color(hex: 0x618A5E),
        mossInk: Color(hex: 0xFFFFFF),
        amber: Color(hex: 0xD99A2B),
        danger: Color(hex: 0xC23524),
        dangerInk: Color(hex: 0xFFFFFF),
        togOn: Color(hex: 0xE0643C),
        ringWarn: Color(hex: 0xFFE08A),
        ringOver: Color(hex: 0x000000).opacity(0.502),
        ringOver2: Color(hex: 0x000000).opacity(0.780),
        scrim: Color(hex: 0x1E160E).opacity(0.451),
        patPage: .none,
        patHero: .none,
        patMoss: .none,
        barOver: .flat(Color(hex: 0x000000).opacity(0.400)),
        barWarnBg: .flat(Color(hex: 0xD99A2B)),
        silhouette: 0,
        isDark: false
    )

    static let warmDark = Theme(
        page: Color(hex: 0x161310),
        outer: Color(hex: 0x0D0B09),
        card: Color(hex: 0x211D18),
        elev: Color(hex: 0x2A251F),
        ink: Color(hex: 0xF2EBE2),
        sub: Color(hex: 0x9D9386),
        line: Color(hex: 0x37312A),
        acc: Color(hex: 0xE0643C),
        accInk: Color(hex: 0xFFFFFF),
        moss: Color(hex: 0x618A5E),
        mossInk: Color(hex: 0xFFFFFF),
        amber: Color(hex: 0xD99A2B),
        danger: Color(hex: 0xC23524),
        dangerInk: Color(hex: 0xFFFFFF),
        togOn: Color(hex: 0xE0643C),
        ringWarn: Color(hex: 0xFFE08A),
        ringOver: Color(hex: 0x000000).opacity(0.502),
        ringOver2: Color(hex: 0x000000).opacity(0.780),
        scrim: Color(hex: 0x000000).opacity(0.600),
        patPage: .none,
        patHero: .none,
        patMoss: .none,
        barOver: .flat(Color(hex: 0x000000).opacity(0.400)),
        barWarnBg: .flat(Color(hex: 0xD99A2B)),
        silhouette: 0,
        isDark: true
    )

    static let monoLight = Theme(
        page: Color(hex: 0xF3F3F1),
        outer: Color(hex: 0xE9E9E6),
        card: Color(hex: 0xFFFFFF),
        elev: Color(hex: 0xEBEBE8),
        ink: Color(hex: 0x141413),
        sub: Color(hex: 0x8B8B86),
        line: Color(hex: 0xE3E3DF),
        acc: Color(hex: 0x141413),
        accInk: Color(hex: 0xFFFFFF),
        moss: Color(hex: 0x4A4A46),
        mossInk: Color(hex: 0xFFFFFF),
        amber: Color(hex: 0x9A9A94),
        danger: Color(hex: 0x000000),
        dangerInk: Color(hex: 0xFFFFFF),
        togOn: Color(hex: 0x141413),
        ringWarn: Color(hex: 0xD8D8D2),
        ringOver: Color(hex: 0xFFFFFF).opacity(0.549),
        ringOver2: Color(hex: 0xFFFFFF).opacity(0.851),
        scrim: Color(hex: 0x0A0A0A).opacity(0.451),
        patPage: .dots(Color(hex: 0x141413).opacity(0.071)),
        patHero: .diagonal(Color(hex: 0xFFFFFF).opacity(0.039)),
        patMoss: .diagonal(Color(hex: 0x141413).opacity(0.051)),
        barOver: .striped(Color(hex: 0xFFFFFF).opacity(0.698), Color(hex: 0xFFFFFF).opacity(0.220)),
        barWarnBg: .striped(Color(hex: 0x141413), Color(hex: 0xA9A9A3)),
        silhouette: .09,
        isDark: false
    )

    static let monoDark = Theme(
        page: Color(hex: 0x0F0F0E),
        outer: Color(hex: 0x080808),
        card: Color(hex: 0x1A1A19),
        elev: Color(hex: 0x242422),
        ink: Color(hex: 0xF4F4F1),
        sub: Color(hex: 0x90908A),
        line: Color(hex: 0x2F2F2D),
        acc: Color(hex: 0xF4F4F1),
        accInk: Color(hex: 0x141413),
        moss: Color(hex: 0xCFCFC8),
        mossInk: Color(hex: 0x141413),
        amber: Color(hex: 0x8F8F8A),
        danger: Color(hex: 0xF4F4F1),
        dangerInk: Color(hex: 0x141413),
        togOn: Color(hex: 0x77776F),
        ringWarn: Color(hex: 0x6F6F68),
        ringOver: Color(hex: 0x000000).opacity(0.502),
        ringOver2: Color(hex: 0x000000).opacity(0.800),
        scrim: Color(hex: 0x000000).opacity(0.651),
        patPage: .dots(Color(hex: 0xFFFFFF).opacity(0.059)),
        patHero: .diagonal(Color(hex: 0x000000).opacity(0.051)),
        patMoss: .diagonal(Color(hex: 0xF4F4F1).opacity(0.059)),
        barOver: .striped(Color(hex: 0x000000).opacity(0.600), Color(hex: 0x000000).opacity(0.200)),
        barWarnBg: .striped(Color(hex: 0xF4F4F1), Color(hex: 0x55554F)),
        silhouette: .1,
        isDark: true
    )

    static func of(_ theme: AppTheme, dark: Bool) -> Theme {
        switch theme {
        case .warm: dark ? .warmDark : .warmLight
        case .mono: dark ? .monoDark : .monoLight
        }
    }
}

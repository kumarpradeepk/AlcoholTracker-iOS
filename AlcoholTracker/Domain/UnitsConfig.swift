import Foundation

// MARK: - Standard-drink configuration (punch list A1, A2, A2a–A2d, A4)
//
// The app used to hardcode the WHO 10 g standard drink and the English word
// "units". Neither is true everywhere: a British user reads ~20 % low against
// the UK's 8 g unit, a Danish user ~20 % low against the 12 g genstand, and a
// Japanese user roughly half against the MHLW's 20 g. For a harm-reduction
// product, under-reporting is the worse direction to be wrong in.
//
// Values are pinned in Design/02-product/units-and-guidelines.json.

/// Which noun the country counts in. The raw value is the catalog suffix.
enum UnitVariant: String, CaseIterable {
    /// The UK unit — 8 g of ethanol.
    case unit = "uk"
    /// The standard drink — US 14 g, AU 10 g, CA 13.45 g.
    case standardDrink = "us"
    /// The Danish genstand — 12 g.
    case genstand = "dk"
    /// The Japanese 単位 — the MHLW defines 20 g; 19.75 g is the pinned figure.
    case tanni = "jp"
    /// The Vietnamese đơn vị cồn — matches the WHO 10 g exactly.
    case donVi = "vn"
    /// The WHO / EU yardstick — 10 g. The default when a country has no rule.
    case who = "who"
}

/// The four forms every language must be able to supply.
///
/// `abbreviation` alone is not enough: the stat-tile captions have a
/// 12-character budget and the standard-drink noun is a two-word phrase in
/// most Romance languages (*bicchieri standard* is 18), while the
/// abbreviation is too terse to sit under a number as a caption.
enum UnitNounForm: String {
    case singular = "sg"
    case plural = "pl"
    /// For captions of 12 characters or fewer.
    case short = "short"
    case abbreviation = "abbr"
}

struct UnitsConfig {
    let countryCode: String
    /// Grams of ethanol in one standard drink for this country.
    let gramsPerStandardDrink: Double
    let variant: UnitVariant

    // MARK: Nouns

    /// The unit noun in the given form, in the user's language and the
    /// country's own terms.
    func noun(_ form: UnitNounForm) -> String {
        L.s("unit_noun_\(variant.rawValue)_\(form.rawValue)")
    }

    /// Singular below two, plural otherwise — the rule English, German, Danish
    /// and Polish all want. Languages with no number agreement supply the same
    /// string for both forms, so this is a no-op for them.
    func noun(count: Double) -> String {
        noun(abs(count) == 1 ? .singular : .plural)
    }

    func noun(count: Int) -> String {
        noun(abs(count) == 1 ? .singular : .plural)
    }

    // MARK: Resolution

    /// Grams per standard drink and the noun to count in, by country.
    private static let table: [String: (Double, UnitVariant)] = [
        "US": (14.0, .standardDrink),
        "GB": (8.0, .unit),
        "IE": (10.0, .unit),
        "AU": (10.0, .standardDrink),
        "NZ": (10.0, .standardDrink),
        "CA": (13.45, .standardDrink),
        "JP": (19.75, .tanni),
        "DK": (12.0, .genstand),
        "VN": (10.0, .donVi),
        "IN": (10.0, .who),
    ]

    /// Overridable for previews and tests; `nil` means "ask the device".
    /// Not concurrency-guarded on purpose: it is only ever set from a
    /// preview or a test before any read.
    static var countryOverride: String?

    static var current: UnitsConfig {
        let code = (countryOverride ?? Locale.current.region?.identifier ?? "US").uppercased()
        if let entry = table[code] {
            return UnitsConfig(countryCode: code, gramsPerStandardDrink: entry.0, variant: entry.1)
        }
        // WHO / EU default: 10 g, counted as a standard drink.
        return UnitsConfig(countryCode: code, gramsPerStandardDrink: 10.0, variant: .who)
    }
}

// MARK: - Currency configuration (punch list A3)
//
// `Formatters.money` used to be `"$" + String(format: "%.2f", value)`, which is
// wrong three separate ways: the symbol is not always `$`, `%.2f` renders
// ¥800.00 for a currency with no minor unit, and `€` is a *suffix* in every
// French context.

struct CurrencyConfig {
    enum Position {
        case prefix
        case suffix
        /// Genuinely locale-dependent — the euro leads in Irish English and
        /// trails in French. Ask the platform.
        case localeDetermined
    }

    let code: String
    let symbol: String
    let position: Position
    let fractionDigits: Int

    /// Resolved placement for the language the app is running in.
    var isSuffix: Bool {
        switch position {
        case .prefix: return false
        case .suffix: return true
        case .localeDetermined: return CurrencyConfig.localePutsSymbolLast
        }
    }

    /// Currencies with no minor unit, plus the symbol and placement each one
    /// is written with. Anything not listed falls back to the platform.
    private static let table: [String: (String, Position, Int)] = [
        "USD": ("$", .prefix, 2),
        "CAD": ("$", .prefix, 2),
        "AUD": ("$", .prefix, 2),
        "NZD": ("$", .prefix, 2),
        "HKD": ("HK$", .prefix, 2),
        "SGD": ("S$", .prefix, 2),
        "GBP": ("£", .prefix, 2),
        "EUR": ("€", .localeDetermined, 2),
        "CHF": ("CHF", .prefix, 2),
        "BRL": ("R$", .prefix, 2),
        "MXN": ("$", .prefix, 2),
        "ARS": ("$", .prefix, 2),
        "COP": ("$", .prefix, 2),
        "PEN": ("S/", .prefix, 2),
        "INR": ("₹", .prefix, 2),
        "TRY": ("₺", .prefix, 2),
        "THB": ("฿", .prefix, 2),
        "MYR": ("RM", .prefix, 2),
        "PHP": ("₱", .prefix, 2),
        "DKK": ("kr.", .suffix, 2),
        "SEK": ("kr", .suffix, 2),
        "NOK": ("kr", .suffix, 2),
        "PLN": ("zł", .suffix, 2),
        "CZK": ("Kč", .suffix, 2),
        // No minor unit.
        "JPY": ("¥", .prefix, 0),
        "KRW": ("₩", .prefix, 0),
        "VND": ("₫", .suffix, 0),
        "IDR": ("Rp", .prefix, 0),
        "HUF": ("Ft", .suffix, 0),
        "CLP": ("$", .prefix, 0),
    ]

    /// Overridable for previews and tests; `nil` means "ask the device".
    /// See `UnitsConfig.countryOverride`.
    static var codeOverride: String?

    static var current: CurrencyConfig {
        let code = (codeOverride ?? Locale.current.currency?.identifier ?? "USD").uppercased()
        if let entry = table[code] {
            return CurrencyConfig(code: code, symbol: entry.0, position: entry.1, fractionDigits: entry.2)
        }
        let fallbackSymbol = Locale.current.currencySymbol ?? code
        return CurrencyConfig(
            code: code,
            symbol: fallbackSymbol,
            position: .localeDetermined,
            fractionDigits: platformFractionDigits
        )
    }

    // MARK: Platform probes

    private static var probe: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale.current
        return f
    }

    private static var platformFractionDigits: Int {
        probe.maximumFractionDigits
    }

    /// True when the running locale writes the currency symbol after the
    /// amount. Probing a formatted zero is more reliable than a symbol search,
    /// because several symbols are also ordinary letters.
    private static var localePutsSymbolLast: Bool {
        guard let sample = probe.string(from: 0) else { return false }
        guard let first = sample.unicodeScalars.first(where: { !$0.properties.isWhitespace }) else {
            return false
        }
        return CharacterSet.decimalDigits.contains(first)
    }
}

import Foundation

// MARK: - The one documented formula
//
// grams_ethanol = ml × (abv / 100) × 0.789      (0.789 g/ml = ethanol density)
// standard drink = the country's own definition (UnitsConfig)
// kcal           = 7 kcal per gram of ethanol
//
// Pinned in Design/02-product/units-and-guidelines.json — do not re-derive.
// Validated: UK pint (568 ml) of 5% beer = 2.24 units at 10 g;
// 355 ml of 5% beer = 1.4 units; 150 ml of 13% wine = 1.5 units.

enum AlcoholMath {
    static let ethanolDensity = 0.789
    static let kcalPerGram = 7.0
    /// Alcohol clears at roughly 0.015 %BAC per hour.
    static let clearanceRatePerHour = 0.015

    /// Grams of ethanol in one standard drink, for the configured country.
    /// Was a hardcoded 10.0 — see punch list A1.
    static var gramsPerUnit: Double { UnitsConfig.current.gramsPerStandardDrink }

    /// The US fluid ounce is 29.5735 ml; the imperial one is 28.4131, so an
    /// en-GB conversion off the US factor is ~4 % wrong (punch list A4).
    static let mlPerUSFlOz = 29.5735
    static let mlPerImperialFlOz = 28.4131

    private static let imperialFluidOunceRegions: Set<String> = ["GB", "IE"]

    static var mlPerFlOz: Double {
        let region = (UnitsConfig.countryOverride ?? Locale.current.region?.identifier ?? "US").uppercased()
        return imperialFluidOunceRegions.contains(region) ? mlPerImperialFlOz : mlPerUSFlOz
    }

    static func grams(ml: Double, abv: Double) -> Double {
        ml * abv / 100 * ethanolDensity
    }

    /// Standard drinks for a pour, in the country's own definition.
    static func units(ml: Double, abv: Double) -> Double {
        grams(ml: ml, abv: abv) / gramsPerUnit
    }

    static func kcal(ml: Double, abv: Double) -> Int {
        Int((ml * abv * ethanolDensity * kcalPerGram / 100).rounded())
    }

    /// The "show the working" line rendered beside every derived result,
    /// e.g. `½ × 355 ml × 5% × 0.789 ÷ 1000 = 0.7 units`.
    ///
    /// The formula was assembled by concatenation, which no other grammar can
    /// reorder. It is now one whole format string per shape, with the unit noun
    /// supplied by the config.
    static func workingLine(ml: Double, abv: Double, quantity: Double) -> String {
        let u = units(ml: ml * quantity, abv: abv)
        let noun = UnitsConfig.current.noun(.plural)
        if quantity == 0.5 {
            return L.f("log_working_line_half", Int(ml), Formatters.trim(abv), u, noun)
        }
        if quantity == 1 {
            return L.f("log_working_line", Int(ml), Formatters.trim(abv), u, noun)
        }
        return L.f("log_working_line_qty", Int(quantity), Int(ml), Formatters.trim(abv), u, noun)
    }
}

// MARK: - BAC (Widmark)

struct BacEstimate: Equatable {
    enum Status: String {
        case clear = "CLEAR"
        case rising = "RISING"
        case settling = "SETTLING"

        /// The uppercase chip on the BAC card. The raw value stays English so
        /// stored data and analytics keep their meaning; only the label moves.
        var label: String {
            switch self {
            case .clear: L.upperKey("bac_status_clear")
            case .rising: L.upperKey("bac_status_rising")
            case .settling: L.upperKey("bac_status_settling")
            }
        }
    }

    /// Estimated blood alcohol as a percentage (e.g. 0.065).
    var value: Double
    var status: Status
    /// Hours until the estimate reaches zero.
    var hoursToZero: Double
}

enum BacMath {
    /// Widmark distribution coefficients.
    static func widmarkR(sex: Sex) -> Double { sex == .female ? 0.55 : 0.68 }

    /// Conservative single-day estimate from today's logs.
    /// Educational only — never a fitness-to-drive number.
    static func estimate(logs: [DrinkLog], sex: Sex?, weightKg: Double, now: Date = .now) -> BacEstimate? {
        guard let sex, weightKg > 0 else { return nil }
        guard !logs.isEmpty else { return BacEstimate(value: 0, status: .clear, hoursToZero: 0) }

        let grams = logs.reduce(0.0) { $0 + $1.gramsEthanol }
        let first = logs.map(\.loggedAt).min() ?? now
        let last = logs.map(\.loggedAt).max() ?? now
        let hoursSinceFirst = max(0, now.timeIntervalSince(first) / 3600)
        let minutesSinceLast = now.timeIntervalSince(last) / 60

        let r = widmarkR(sex: sex)
        var value = grams / (weightKg * 1000 * r) * 100 - AlcoholMath.clearanceRatePerHour * hoursSinceFirst
        value = max(0, value)

        let status: BacEstimate.Status
        if value <= 0.002 { status = .clear }
        else if minutesSinceLast < 40 { status = .rising }
        else { status = .settling }

        return BacEstimate(value: value, status: status, hoursToZero: value / AlcoholMath.clearanceRatePerHour)
    }
}

enum Sex: String, Codable, CaseIterable {
    case female = "Female"
    case male = "Male"

    var label: String {
        switch self {
        case .female: L.s("profile_sex_female")
        case .male: L.s("profile_sex_male")
        }
    }
}

// MARK: - Drinking-day arithmetic
//
// "A 1 AM drink counts toward the night before." The cutoff (Midnight / 2 AM /
// 4 AM) shifts the boundary: a drinking day covers cutoff → cutoff.

enum DayCutoff: String, Codable, CaseIterable {
    case midnight = "Midnight"
    case twoAM = "2 AM"
    case fourAM = "4 AM"

    var hours: Int {
        switch self {
        case .midnight: 0
        case .twoAM: 2
        case .fourAM: 4
        }
    }

    var label: String {
        switch self {
        case .midnight: L.s("set_cutoff_midnight")
        case .twoAM: L.s("set_cutoff_2am")
        case .fourAM: L.s("set_cutoff_4am")
        }
    }

    var next: DayCutoff {
        switch self {
        case .midnight: .twoAM
        case .twoAM: .fourAM
        case .fourAM: .midnight
        }
    }
}

enum DrinkingDay {
    static var calendar: Calendar { Calendar.current }

    /// Local midnight of the reference day (2001-01-01 UTC, seen locally).
    /// Keys are whole calendar days from here — exact in every timezone,
    /// DST-safe, and round-trips with `date(for:)`.
    private static var referenceDayStart: Date {
        calendar.startOfDay(for: Date(timeIntervalSinceReferenceDate: 0))
    }

    /// Days-since-reference key for the drinking day an instant belongs to.
    static func key(for date: Date, cutoff: DayCutoff) -> Int {
        let shifted = date.addingTimeInterval(-Double(cutoff.hours) * 3600)
        let start = calendar.startOfDay(for: shifted)
        return calendar.dateComponents([.day], from: referenceDayStart, to: start).day ?? 0
    }

    /// The calendar date (start of day) a drinking-day key labels.
    static func date(for key: Int) -> Date {
        calendar.date(byAdding: .day, value: key, to: referenceDayStart) ?? referenceDayStart
    }

    static func todayKey(cutoff: DayCutoff, now: Date = .now) -> Int {
        key(for: now, cutoff: cutoff)
    }

    /// Key for the drinking day whose *label date* is `date` (midnight-anchored).
    static func key(forLabelDate date: Date) -> Int {
        calendar.dateComponents([.day], from: referenceDayStart, to: calendar.startOfDay(for: date)).day ?? 0
    }
}

// MARK: - Formatting

enum Formatters {
    /// "5" for 5.0, "5.3" for 5.3 — the canvas never shows a dangling ".0"
    /// in metadata strings. The separator follows the user's locale.
    static func trim(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? decimal(value, digits: 0)
            : decimal(value, digits: 1)
    }

    static func units1(_ value: Double) -> String { decimal(value, digits: 1) }

    static func decimal(_ value: Double, digits: Int) -> String {
        let f = NumberFormatter()
        f.locale = Locale.current
        f.numberStyle = .decimal
        f.usesGroupingSeparator = false
        f.minimumFractionDigits = digits
        f.maximumFractionDigits = digits
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.\(digits)f", value)
    }

    // MARK: Money (punch list A3)

    /// The amount alone, with the currency's own number of fraction digits and
    /// the locale's separators. Rows that place the symbol themselves take this
    /// plus `CurrencyConfig.current.symbol`.
    ///
    /// - Parameter exact: keep the minor unit even on a whole amount. A price
    ///   is quoted exactly (`$0.00`); a running total is not (`$14`).
    static func moneyAmount(_ value: Double, exact: Bool = false) -> String {
        let currency = CurrencyConfig.current
        let whole = value.truncatingRemainder(dividingBy: 1) == 0
        let f = NumberFormatter()
        f.locale = Locale.current
        f.numberStyle = .decimal
        f.minimumFractionDigits = (whole && !exact) ? 0 : currency.fractionDigits
        f.maximumFractionDigits = currency.fractionDigits
        return f.string(from: NSNumber(value: value)) ?? String(value)
    }

    /// A complete money string. The symbol, its side and the number of decimals
    /// all come from `CurrencyConfig` — never from a hardcoded `"$%.2f"`.
    static func money(_ value: Double, exact: Bool = false) -> String {
        let currency = CurrencyConfig.current
        let amount = moneyAmount(value, exact: exact)
        return currency.isSuffix
            ? amount + "\u{00A0}" + currency.symbol
            : currency.symbol + amount
    }

    // MARK: Dates

    /// 12- or 24-hour by the user's own setting, never a hardcoded pattern.
    static func time(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale.current
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: date)
    }

    /// Clock time for the backup status lines, in the locale's own shape.
    static func clock(_ date: Date) -> String { time(date) }

    /// A short date such as "Mar 14", localized.
    static func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale.current
        f.setLocalizedDateFormatFromTemplate("MMMd")
        return f.string(from: date)
    }

    /// "Monday, 14 March" in whatever order the locale wants it.
    static func longWeekdayDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale.current
        f.setLocalizedDateFormatFromTemplate("EEEEMMMMd")
        return f.string(from: date)
    }

    static func dateAndTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }

    /// "3h 42m" — the unit names come from the platform, so they translate.
    static func hoursMinutes(_ hours: Double) -> String {
        guard hours > 0 else { return "" }
        let f = DateComponentsFormatter()
        f.calendar = Calendar.current
        f.unitsStyle = .abbreviated
        f.allowedUnits = hours >= 1 ? [.hour, .minute] : [.minute]
        f.zeroFormattingBehavior = .dropAll
        let seconds = hours * 3600
        if let text = f.string(from: seconds), !text.isEmpty { return text }
        let h = Int(hours)
        let m = Int(((hours - Double(h)) * 60).rounded())
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}

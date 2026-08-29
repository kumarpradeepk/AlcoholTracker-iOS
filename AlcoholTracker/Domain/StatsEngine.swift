import Foundation

// MARK: - Statistics

enum StatsPeriod: String, CaseIterable, Identifiable {
    case week = "7D"
    case month = "30D"
    case quarter = "90D"
    case year = "1Y"
    case custom = "Custom"

    var id: String { rawValue }
    var lengthDays: Int {
        switch self {
        case .week: 7
        case .month: 30
        case .quarter: 90
        case .year: 365
        case .custom: 0
        }
    }

    /// Only the 7-day view is free; depth is Pro (never the log or the export).
    var requiresPro: Bool { self != .week }

    var label: String {
        switch self {
        case .week: L.s("stats_period_7d")
        case .month: L.s("stats_period_30d")
        case .quarter: L.s("stats_period_90d")
        case .year: L.s("stats_period_1y")
        case .custom: L.s("stats_period_custom")
        }
    }
}

struct StatsBucket: Identifiable {
    let id: Int
    let label: String
    let units: Double
    let spend: Double
    /// True when this bucket is a single day whose total exceeds the daily goal.
    let overDaily: Bool
}

struct BreakdownRow: Identifiable {
    let name: String
    let pours: Int
    let percent: Int
    var id: String { name }
}

struct StatsRange {
    let label: String
    let fromKey: Int
    let toKey: Int
    let days: Int
    let buckets: [StatsBucket]
    let totalMl: Double
    let totalUnits: Double
    let totalSpend: Double
    let totalKcal: Int
    let previousUnits: Double
    let breakdown: [BreakdownRow]
    let dryCount: Int
    var dryPercent: Int { days > 0 ? Int((Double(dryCount) / Double(days) * 100).rounded()) : 0 }
}

struct DayAggregate {
    var ml: Double = 0
    var units: Double = 0
    var spend: Double = 0
    var kcal: Int = 0
    var count: Int = 0
}

enum StatsEngine {
    /// Groups logs into drinking-day buckets under the current cutoff.
    static func byDay(logs: [DrinkLog], cutoff: DayCutoff) -> [Int: [DrinkLog]] {
        Dictionary(grouping: logs) { DrinkingDay.key(for: $0.loggedAt, cutoff: cutoff) }
    }

    static func aggregate(_ logs: [DrinkLog]) -> DayAggregate {
        var a = DayAggregate()
        for r in logs {
            a.ml += r.ml
            a.units += r.units
            a.spend += r.cost
            a.kcal += r.kcal
            a.count += 1
        }
        return a
    }

    static func compute(
        period: StatsPeriod,
        pageOffset: Int,
        customFrom: Date?,
        customTo: Date?,
        logsByDay: [Int: [DrinkLog]],
        dryKeys: Set<Int>,
        todayKey: Int,
        dailyGoal: Int
    ) -> StatsRange {
        var fromKey: Int
        var toKey: Int

        if period == .custom {
            let today = DrinkingDay.date(for: todayKey)
            let from = customFrom ?? Calendar.current.date(byAdding: .day, value: -13, to: today)!
            let to = customTo ?? today
            fromKey = min(DrinkingDay.key(forLabelDate: from), todayKey)
            toKey = min(DrinkingDay.key(forLabelDate: to), todayKey)
            fromKey = max(fromKey, todayKey - 365)
            if toKey < fromKey { toKey = fromKey }
        } else {
            let len = period.lengthDays
            toKey = todayKey - len * pageOffset
            fromKey = toKey - len + 1
        }

        let days = toKey - fromKey + 1

        func sum(_ a: Int, _ b: Int) -> DayAggregate {
            var agg = DayAggregate()
            for k in a ... max(a, b) {
                let day = aggregate(logsByDay[k] ?? [])
                agg.ml += day.ml
                agg.units += day.units
                agg.spend += day.spend
                agg.kcal += day.kcal
                agg.count += day.count
            }
            return agg
        }

        // Buckets: daily for ≤31 days, weekly for 90D, monthly-ish for 1Y.
        var buckets: [StatsBucket] = []
        // Two-letter weekday symbols from the platform: single letters collide
        // in German (Mo/Mi, Di/Do) and Thai Thursday (พฤ) cannot shorten.
        let weekdaySymbols = Calendar.current.shortWeekdaySymbols.map(CalendarL10n.twoCharacters)
        let cal = Calendar.current

        if days <= 31 {
            for (i, k) in (fromKey ... toKey).enumerated() {
                let d = DrinkingDay.date(for: k)
                let day = aggregate(logsByDay[k] ?? [])
                let label: String
                if period == .week {
                    let index = cal.component(.weekday, from: d) - 1
                    label = weekdaySymbols.indices.contains(index) ? weekdaySymbols[index] : ""
                } else {
                    let dayNum = cal.component(.day, from: d)
                    label = (dayNum == 1 || dayNum % 10 == 0) ? String(dayNum) : ""
                }
                buckets.append(StatsBucket(
                    id: i, label: label, units: day.units, spend: day.spend,
                    overDaily: day.units > Double(dailyGoal)
                ))
            }
        } else if days <= 100 {
            let weekCount = Int(ceil(Double(days) / 7))
            for w in 0 ..< weekCount {
                let a = fromKey + w * 7
                let b = min(toKey, a + 6)
                let agg = sum(a, b)
                let d = DrinkingDay.date(for: a)
                let f = DateFormatter()
                f.locale = Locale.current
                f.setLocalizedDateFormatFromTemplate("MMM")
                buckets.append(StatsBucket(
                    id: w, label: w % 4 == 0 ? f.string(from: d) : "",
                    units: agg.units, spend: agg.spend, overDaily: false
                ))
            }
        } else {
            for m in 0 ..< 12 {
                let a = fromKey + m * 30
                // 12 × 30 = 360 < 365: fold the remaining days into the last bar.
                let b = m == 11 ? toKey : min(toKey, a + 29)
                let agg = sum(a, b)
                let d = DrinkingDay.date(for: b)
                let f = DateFormatter()
                f.locale = Locale.current
                f.setLocalizedDateFormatFromTemplate("MMM")
                buckets.append(StatsBucket(
                    id: m, label: String(f.string(from: d).prefix(1)),
                    units: agg.units, spend: agg.spend, overDaily: false
                ))
            }
        }

        let total = sum(fromKey, toKey)
        let prev = fromKey - days >= todayKey - 3650
            ? sum(fromKey - days, fromKey - 1)
            : DayAggregate()

        // Top-5 drinks by units share.
        var byName: [String: (units: Double, count: Int)] = [:]
        for k in fromKey ... toKey {
            for r in logsByDay[k] ?? [] {
                var e = byName[r.name] ?? (0, 0)
                e.units += r.units
                e.count += 1
                byName[r.name] = e
            }
        }
        let totalU = max(total.units, 0.0001)
        let breakdown = byName
            .map { (name: $0.key, units: $0.value.units, count: $0.value.count) }
            .sorted { $0.units > $1.units }
            .prefix(5)
            .map { BreakdownRow(name: $0.name, pours: $0.count, percent: Int(($0.units / totalU * 100).rounded())) }

        let dryCount = (fromKey ... toKey).filter { dryKeys.contains($0) && (logsByDay[$0] ?? []).isEmpty }.count

        // The range label is an interval, so let the platform build it: the
        // separator, the order of month and day and whether the month repeats
        // are all locale decisions.
        let intervalFormatter = DateIntervalFormatter()
        intervalFormatter.locale = Locale.current
        intervalFormatter.dateStyle = .medium
        intervalFormatter.timeStyle = .none
        let label = intervalFormatter.string(
            from: DrinkingDay.date(for: fromKey),
            to: DrinkingDay.date(for: toKey)
        )

        return StatsRange(
            label: label,
            fromKey: fromKey,
            toKey: toKey,
            days: days,
            buckets: buckets,
            totalMl: total.ml,
            totalUnits: total.units,
            totalSpend: total.spend,
            totalKcal: total.kcal,
            previousUnits: prev.units,
            breakdown: Array(breakdown),
            dryCount: dryCount
        )
    }

    // MARK: Copy

    /// Plain-language verdict line — tone-aware.
    static func verdict(range: StatsRange, tone: Tone) -> (text: String, positive: Bool)? {
        if range.previousUnits > 0 {
            let delta = range.totalUnits - range.previousUnits
            let pct = Int((abs(delta) / range.previousUnits * 100).rounded())
            if tone == .numbers {
                return (
                    L.f(
                        "stats_verdict_numbers",
                        range.totalUnits,
                        range.previousUnits,
                        UnitsConfig.current.noun(.abbreviation)
                    ),
                    false
                )
            }
            if pct == 0 { return (L.s("stats_verdict_level_neutral"), false) }
            return (
                L.f(delta < 0 ? "stats_verdict_less_neutral" : "stats_verdict_more_neutral", pct),
                delta < 0
            )
        }
        if range.totalUnits > 0 {
            return tone == .numbers
                ? (
                    L.f(
                        "stats_verdict_first_numbers",
                        range.totalUnits,
                        UnitsConfig.current.noun(.abbreviation)
                    ),
                    false
                )
                : (L.s("stats_verdict_first_neutral"), false)
        }
        return nil
    }

    /// "≈ N cheeseburgers" (303 kcal each) — suppressed in Numbers tone.
    static func kcalComparison(kcal: Int, tone: Tone) -> String {
        guard tone != .numbers else { return "" }
        let burgers = Int((Double(kcal) / 303).rounded())
        guard burgers >= 1 else { return "" }
        return L.f("stats_kcal_burgers_neutral", burgers)
    }

    /// Money-saved line, from the user's own editable baseline — never
    /// national averages.
    static func savedLine(baseline: Double, range: StatsRange) -> String {
        guard baseline > 0 else {
            return L.s("stats_saved_unset")
        }
        let saved = baseline * (Double(range.days) / 7) - range.totalSpend
        if saved >= 0 {
            return L.f(
                "stats_saved_under",
                Formatters.moneyAmount(saved.rounded()),
                CurrencyConfig.current.symbol
            )
        }
        return L.f(
            "stats_saved_over",
            Formatters.moneyAmount((-saved).rounded()),
            CurrencyConfig.current.symbol
        )
    }
}

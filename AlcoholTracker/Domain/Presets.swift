import Foundation

// MARK: - Static content from the design canvas

struct DrinkPreset: Identifiable, Hashable {
    let name: String
    let abv: Double
    let ml: Double
    let cost: Double

    var id: String { name }
    var units: Double { AlcoholMath.units(ml: ml, abv: abv) }
    var meta: String { L.f("log_grid_meta", Formatters.trim(abv), Int(ml)) }
}

enum Presets {
    /// "POPULAR" grid on the log sheet — order and values from the canvas.
    static let popular: [DrinkPreset] = [
        DrinkPreset(name: "Margarita", abv: 13, ml: 150, cost: 14),
        DrinkPreset(name: "Mojito", abv: 10, ml: 200, cost: 13),
        DrinkPreset(name: "Old Fashioned", abv: 27, ml: 90, cost: 16),
        DrinkPreset(name: "Cosmopolitan", abv: 20, ml: 120, cost: 14),
        DrinkPreset(name: "Gin & Tonic", abv: 11, ml: 210, cost: 12),
        DrinkPreset(name: "Whiskey Sour", abv: 16, ml: 150, cost: 14),
        DrinkPreset(name: "Moscow Mule", abv: 11, ml: 240, cost: 13),
        DrinkPreset(name: "Piña Colada", abv: 13, ml: 180, cost: 15),
        DrinkPreset(name: "Espresso Martini", abv: 23, ml: 110, cost: 16),
        DrinkPreset(name: "Aperol Spritz", abv: 11, ml: 210, cost: 13),
    ]

    /// Onboarding step 2 — "What brings you here?"
    static let goals = [
        "Drinking less",
        "Knowing how much I drink",
        "Giving my body a break",
        "More drink-free days",
        "Drinking consciously",
        "Resetting my defaults",
        "Coping with social situations",
    ]

    /// Onboarding step 3 — "How many drinks in an average week?"
    static let baselines = [
        "0–4 drinks",
        "5–9 drinks",
        "10–14 drinks",
        "15–19 drinks",
        "20 or more",
    ]

    static let customDrinkBases = ["Beer", "Wine", "Spirit", "Cocktail", "Other"]
}

// MARK: - Paywall content

/// The parts of the paywall that are copy rather than commerce.
///
/// Plans, prices, trial lengths and savings all come from `EntitlementStore`,
/// which gets them from the store through RevenueCat — nothing about money is
/// written down here, so nothing here can go stale when a price changes.
enum PaywallContent {
    static var benefits: [String] {
        [
            L.s("pay_benefit_history"),
            L.s("pay_benefit_bac"),
            L.s("pay_benefit_insights"),
            L.s("pay_benefit_streaks"),
            L.s("pay_benefit_quicklog"),
            L.s("pay_benefit_report"),
        ]
    }

    /// (title, free, pro). The free column is deliberately loud: every row
    /// marked free is a promise from the product spec, and seeing it kept is
    /// what makes the paid column believable.
    static var comparison: [(String, Bool, Bool)] {
        [
            (L.s("pay_compare_logging"), true, true),
            (L.s("pay_compare_export"), true, true),
            (L.s("pay_compare_darkmode"), true, true),
            (L.s("pay_compare_history"), false, true),
            (L.s("pay_compare_bac"), false, true),
            (L.s("pay_compare_insights"), false, true),
        ]
    }

    /// The trial questions only appear when a trial is actually on offer.
    static func faq(trialDays: Int) -> [(String, String)] {
        var rows: [(String, String)] = []
        if trialDays > 0 {
            rows.append((L.s("pay_faq_q_trial"), L.f("pay_faq_a_trial", trialDays)))
            rows.append((L.s("pay_faq_q_after"), L.s("pay_faq_a_after")))
        }
        rows.append((L.s("pay_faq_q_logs"), L.s("pay_faq_a_logs")))
        rows.append((L.s("pay_faq_q_cancel"), L.f("pay_faq_a_cancel", "App Store")))
        return rows
    }

    static func planName(_ cadence: Cadence) -> String {
        switch cadence {
        case .week: L.s("pay_plan_weekly")
        case .month: L.s("pay_plan_monthly")
        case .year: L.s("pay_plan_annual")
        case .lifetime: L.s("pay_plan_lifetime")
        }
    }

    static func priceLine(_ plan: ProPlan) -> String {
        switch plan.cadence {
        case .week: L.f("pay_price_line_weekly", plan.price)
        case .month: L.f("pay_price_line_monthly", plan.price)
        case .year: L.f("pay_price_line_annual", plan.price)
        case .lifetime: L.f("pay_price_line_lifetime", plan.price)
        }
    }

    /// At most one badge per row: a trial beats a saving, because the free
    /// week is the thing that actually decides it and two badges read as noise.
    static func badge(_ plan: ProPlan) -> (text: String, good: Bool)? {
        if plan.hasTrial { return (L.f("pay_badge_trial", plan.freeTrialDays), true) }
        if plan.cadence == .lifetime { return (L.s("pay_badge_best"), false) }
        if plan.savingPercent >= 10 { return (L.f("pay_badge_save", plan.savingPercent), false) }
        return nil
    }

    /// The button. Leads with free when free is on the table, price otherwise.
    static func cta(for plan: ProPlan?) -> String {
        guard let plan else { return L.s("pay_cta_default") }
        if plan.hasTrial { return L.f("pay_cta_trial", plan.freeTrialDays) }
        if plan.cadence == .lifetime { return L.s("pay_cta_lifetime") }
        return L.f("pay_cta_plan", plan.price)
    }

    /// The line under the button: what happens next, in plain words, always.
    static func subCopy(for plan: ProPlan?) -> String? {
        guard let plan else { return nil }
        if plan.hasTrial { return L.f("pay_sub_trial", plan.freeTrialDays, plan.price) }
        if plan.cadence == .lifetime { return L.s("pay_sub_lifetime") }
        return L.f("pay_sub_recurring", plan.price)
    }
}

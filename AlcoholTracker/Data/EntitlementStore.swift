import Combine
import Foundation
import RevenueCat

// MARK: - Plans

/// How often a plan bills. Also the paywall's display order.
enum Cadence: Int, Comparable {
    case week = 0, month, year, lifetime
    static func < (a: Cadence, b: Cadence) -> Bool { a.rawValue < b.rawValue }

    /// Weeks in one billing period, for the per-week comparison.
    var weeks: Double {
        switch self {
        case .week: 1
        case .month: 52.0 / 12.0
        case .year: 52
        case .lifetime: 520 // unused; keeps the maths total
        }
    }
}

/// One buyable plan, reduced to what the paywall needs.
///
/// `price` is the store's own localized string — StoreKit has already put the
/// right symbol on the right side with the right number of minor digits for
/// the buyer's App Store country, so no currency is ever formatted here and
/// none appears in the string catalog.
struct ProPlan: Identifiable {
    let id: String
    let cadence: Cadence
    let price: String
    let priceDecimal: Decimal
    let freeTrialDays: Int
    let savingPercent: Int
    let package: Package

    var hasTrial: Bool { freeTrialDays > 0 }
}

// MARK: - Store

/// Pro entitlement and purchases, via RevenueCat.
///
/// Policy (from the product spec, non-negotiable):
/// - Never gate the log, the truth, or the exit — logging, custom drinks,
///   this week's stats, widgets, CSV export, dark mode, app lock and
///   reminders are free forever.
/// - Purchases restore without an account; the entitlement is cached locally
///   so a launch with no network still unlocks.
@MainActor
final class EntitlementStore: NSObject, ObservableObject {
    @Published private(set) var isPro: Bool
    @Published private(set) var plans: [ProPlan] = []
    @Published private(set) var purchaseInFlight = false
    /// True once an offering came back — distinguishes "still loading" from
    /// "the store said no", which the paywall words differently.
    @Published private(set) var loaded = false

    private let defaults = UserDefaults.standard

    /// RevenueCat public SDK key for "Alcohol Tracker (App Store)", project
    /// `4452a7f1`. Public by design: it can read offerings and start a purchase
    /// for this app and nothing else. The secret key is never shipped.
    private static let publicSDKKey = "appl_ppijglOdBrQgRlNNurSkjmJzJyU"

    /// Entitlement identifier, as configured in the RevenueCat dashboard.
    private static let entitlementID = "pro"

    override init() {
        // Offline-tolerant cache; re-verified against RevenueCat on launch.
        isPro = defaults.bool(forKey: "entitlement.pro")
        super.init()

        Purchases.logLevel = isDebugBuild ? .debug : .warn
        Purchases.configure(
            with: Configuration.Builder(withAPIKey: Self.publicSDKKey)
                // The same opaque id the support screen shows, so a purchase
                // can be traced without an account and without a real identity
                // ever reaching RevenueCat.
                .with(appUserID: defaults.string(forKey: "customerID"))
                .build()
        )
        Purchases.shared.delegate = self

        Task { await refresh() }
    }

    /// Pulls the offering and the current entitlement. Cheap; safe on resume.
    func refresh() async {
        if let current = try? await Purchases.shared.offerings().current {
            plans = Self.plans(from: current.availablePackages)
        } else {
            plans = []
        }
        // Set last: the paywall reads `loaded` to tell "one moment" apart from
        // "the App Store did not answer", so it must never be true too early.
        loaded = true

        if let info = try? await Purchases.shared.customerInfo() { apply(info) }
    }

    // MARK: Buying

    /// Runs the App Store sheet for `plan`.
    ///
    /// Returns true only when the `pro` entitlement is actually active
    /// afterwards. A cancelled sheet and a declined card both return false,
    /// and neither is an error worth shouting about.
    func purchase(_ plan: ProPlan) async -> Bool {
        guard !purchaseInFlight else { return false }
        purchaseInFlight = true
        defer { purchaseInFlight = false }
        do {
            let result = try await Purchases.shared.purchase(package: plan.package)
            guard !result.userCancelled else { return false }
            apply(result.customerInfo)
            return isPro
        } catch {
            return false
        }
    }

    /// Re-reads purchases from the App Store. Works without an account.
    func restore() async -> Bool {
        guard let info = try? await Purchases.shared.restorePurchases() else { return false }
        apply(info)
        return isPro
    }

    // MARK: Internals

    private func apply(_ info: CustomerInfo) {
        let active = info.entitlements[Self.entitlementID]?.isActive == true
        guard active != isPro else { return }
        isPro = active
        defaults.set(active, forKey: "entitlement.pro")
    }

    /// Maps RevenueCat packages to plans and fills in the saving badge.
    ///
    /// The saving is measured per week against the dearest week in the
    /// offering — the same number a shopper would get with a calculator, not a
    /// marketing figure. Lifetime is excluded because it has no week.
    private static func plans(from packages: [Package]) -> [ProPlan] {
        var mapped = packages.map { pkg -> ProPlan in
            ProPlan(
                id: pkg.identifier,
                cadence: cadence(for: pkg),
                price: pkg.storeProduct.localizedPriceString,
                priceDecimal: pkg.storeProduct.price,
                freeTrialDays: trialDays(for: pkg),
                savingPercent: 0,
                package: pkg
            )
        }

        let perWeek = { (p: ProPlan) in (p.priceDecimal as NSDecimalNumber).doubleValue / p.cadence.weeks }
        if let dearest = mapped.filter({ $0.cadence != .lifetime }).map(perWeek).max(), dearest > 0 {
            mapped = mapped.map { plan in
                guard plan.cadence != .lifetime else { return plan }
                return ProPlan(
                    id: plan.id, cadence: plan.cadence, price: plan.price,
                    priceDecimal: plan.priceDecimal, freeTrialDays: plan.freeTrialDays,
                    savingPercent: max(0, min(99, Int(100 * (1 - perWeek(plan) / dearest)))),
                    package: plan.package
                )
            }
        }
        return mapped.sorted { $0.cadence < $1.cadence }
    }

    private static func cadence(for pkg: Package) -> Cadence {
        switch pkg.packageType {
        case .weekly: return .week
        case .monthly: return .month
        case .annual: return .year
        case .lifetime: return .lifetime
        default: break
        }
        guard let period = pkg.storeProduct.subscriptionPeriod else { return .lifetime }
        switch period.unit {
        case .day: return period.value >= 300 ? .year : .week
        case .week: return .week
        case .month: return period.value >= 12 ? .year : .month
        case .year: return .year
        @unknown default: return .month
        }
    }

    /// Days in the package's introductory free phase, or 0 when there is none.
    private static func trialDays(for pkg: Package) -> Int {
        guard let intro = pkg.storeProduct.introductoryDiscount, intro.paymentMode == .freeTrial
        else { return 0 }
        let p = intro.subscriptionPeriod
        let perPeriod: Int = switch p.unit {
        case .day: 1
        case .week: 7
        case .month: 30
        case .year: 365
        @unknown default: 0
        }
        return p.value * perPeriod * intro.numberOfPeriods
    }

    private var isDebugBuild: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }
}

// MARK: - Live entitlement updates

extension EntitlementStore: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in apply(customerInfo) }
    }
}

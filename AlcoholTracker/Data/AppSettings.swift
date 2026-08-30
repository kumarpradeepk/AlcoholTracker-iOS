import Foundation
import SwiftUI

// MARK: - Tone modes (Design brief §5.4 — FIXED that they exist)

enum Tone: String, Codable, CaseIterable {
    case neutral = "Neutral"
    case push = "Push me"
    case numbers = "Numbers"

    var label: String {
        switch self {
        case .neutral: L.s("set_tone_neutral")
        case .push: L.s("set_tone_push")
        case .numbers: L.s("set_tone_numbers")
        }
    }

    var subCopy: String {
        switch self {
        case .numbers: L.s("set_tone_sub_numbers")
        case .push: L.s("set_tone_sub_push")
        case .neutral: L.s("set_tone_sub_neutral")
        }
    }
}

enum EnergyUnit: String, Codable, CaseIterable {
    case kcal
    case kJ

    var label: String {
        switch self {
        case .kcal: L.s("units_kcal")
        case .kJ: L.s("units_kj")
        }
    }
}

enum ServingUnit: String, Codable, CaseIterable {
    case ml = "ml"
    case oz = "Ounce"

    /// The compact toggle in the log sheet.
    var shortLabel: String {
        switch self {
        case .ml: L.s("log_unit_ml")
        case .oz: L.s("log_unit_floz")
        }
    }

    /// The spelled-out row in Settings → Units.
    var label: String {
        switch self {
        case .ml: L.s("units_millilitres")
        case .oz: L.s("units_ounces")
        }
    }
}

enum BacUnit: String, Codable, CaseIterable {
    case percent = "%"
    case permille = "‰"

    var label: String {
        switch self {
        case .percent: L.s("set_bac_unit_percent")
        case .permille: L.s("set_bac_unit_permille")
        }
    }
}

enum AppearanceOverride: String, Codable {
    case system, light, dark
}

// MARK: - Settings store
//
// One observable object, persisted to UserDefaults. Drink data itself lives in
// SwiftData; this is preferences only. Nothing here ever leaves the device.

@MainActor
final class AppSettings: ObservableObject {
    private let d = UserDefaults.standard

    @Published var onboardingDone: Bool { didSet { d.set(onboardingDone, forKey: "onboardingDone") } }
    @Published var selectedGoals: [Int] { didSet { d.set(selectedGoals, forKey: "selectedGoals") } }
    @Published var baselineAnswer: Int { didSet { d.set(baselineAnswer, forKey: "baselineAnswer") } }

    @Published var askCost: Bool { didSet { d.set(askCost, forKey: "askCost") } }
    @Published var showCalories: Bool { didSet { d.set(showCalories, forKey: "showCalories") } }
    @Published var autoDry: Bool { didSet { d.set(autoDry, forKey: "autoDry") } }
    @Published var bacOn: Bool { didSet { d.set(bacOn, forKey: "bacOn") } }
    @Published var bacUnit: BacUnit { didSet { d.set(bacUnit.rawValue, forKey: "bacUnit") } }
    @Published var energyUnit: EnergyUnit { didSet { d.set(energyUnit.rawValue, forKey: "energyUnit") } }
    @Published var servingUnit: ServingUnit { didSet { d.set(servingUnit.rawValue, forKey: "servingUnit") } }

    @Published var sex: Sex? { didSet { d.set(sex?.rawValue, forKey: "sex") } }
    @Published var weightText: String { didSet { d.set(weightText, forKey: "weightText") } }
    @Published var weightIsKg: Bool { didSet { d.set(weightIsKg, forKey: "weightIsKg") } }

    @Published var dailyGoal: Int { didSet { d.set(dailyGoal, forKey: "dailyGoal") } }
    @Published var weeklyGoal: Int { didSet { d.set(weeklyGoal, forKey: "weeklyGoal") } }

    @Published var healthConnected: Bool { didSet { d.set(healthConnected, forKey: "healthConnected") } }
    @Published var iconIndex: Int { didSet { d.set(iconIndex, forKey: "iconIndex") } }
    @Published var spendBaseline: String { didSet { d.set(spendBaseline, forKey: "spendBaseline") } }
    @Published var tone: Tone { didSet { d.set(tone.rawValue, forKey: "tone") } }
    @Published var appLock: Bool { didSet { d.set(appLock, forKey: "appLock") } }
    @Published var discreetNotifications: Bool { didSet { d.set(discreetNotifications, forKey: "discreetNotifications") } }
    @Published var cutoff: DayCutoff { didSet { d.set(cutoff.rawValue, forKey: "cutoff") } }
    @Published var appearance: AppearanceOverride { didSet { d.set(appearance.rawValue, forKey: "appearance") } }
    /// Which of the three designed themes is active. Independent of
    /// `appearance`: every theme ships a light and a dark palette.
    @Published var theme: AppTheme { didSet { d.set(theme.rawValue, forKey: "theme") } }
    @Published var lastBackupAt: Date? { didSet { d.set(lastBackupAt, forKey: "lastBackupAt") } }
    @Published var notificationPermissionAsked: Bool { didSet { d.set(notificationPermissionAsked, forKey: "notifPermAsked") } }

    /// Stable, anonymous support reference — shown as "Customer ID".
    let customerID: String

    init() {
        onboardingDone = d.bool(forKey: "onboardingDone")
        selectedGoals = d.array(forKey: "selectedGoals") as? [Int] ?? []
        baselineAnswer = d.object(forKey: "baselineAnswer") as? Int ?? -1
        askCost = d.object(forKey: "askCost") as? Bool ?? true
        showCalories = d.object(forKey: "showCalories") as? Bool ?? true
        autoDry = d.object(forKey: "autoDry") as? Bool ?? true
        bacOn = d.object(forKey: "bacOn") as? Bool ?? true
        bacUnit = BacUnit(rawValue: d.string(forKey: "bacUnit") ?? "") ?? .percent
        energyUnit = EnergyUnit(rawValue: d.string(forKey: "energyUnit") ?? "") ?? .kcal
        servingUnit = ServingUnit(rawValue: d.string(forKey: "servingUnit") ?? "") ?? .ml
        sex = Sex(rawValue: d.string(forKey: "sex") ?? "")
        weightText = d.string(forKey: "weightText") ?? ""
        weightIsKg = d.object(forKey: "weightIsKg") as? Bool ?? true
        dailyGoal = d.object(forKey: "dailyGoal") as? Int ?? 2
        weeklyGoal = d.object(forKey: "weeklyGoal") as? Int ?? 10
        healthConnected = d.bool(forKey: "healthConnected")
        iconIndex = d.integer(forKey: "iconIndex")
        spendBaseline = d.string(forKey: "spendBaseline") ?? ""
        tone = Tone(rawValue: d.string(forKey: "tone") ?? "") ?? .neutral
        appLock = d.bool(forKey: "appLock")
        discreetNotifications = d.object(forKey: "discreetNotifications") as? Bool ?? true
        cutoff = DayCutoff(rawValue: d.string(forKey: "cutoff") ?? "") ?? .fourAM
        appearance = AppearanceOverride(rawValue: d.string(forKey: "appearance") ?? "") ?? .system
        theme = AppTheme.from(d.string(forKey: "theme"))
        lastBackupAt = d.object(forKey: "lastBackupAt") as? Date
        notificationPermissionAsked = d.bool(forKey: "notifPermAsked")

        if let existing = d.string(forKey: "customerID") {
            customerID = existing
        } else {
            let alphabet = Array("23456789ABCDEFGHJKMNPQRSTUVWXYZ")
            let part = { String((0 ..< 4).map { _ in alphabet.randomElement()! }) }
            let generated = "AT-\(part())-\(part())"
            d.set(generated, forKey: "customerID")
            customerID = generated
        }
    }

    var weightKg: Double {
        guard let w = Double(weightText.replacingOccurrences(of: ",", with: ".")), w > 0 else { return 0 }
        return weightIsKg ? w : w * 0.4536
    }

    var monthlyGoal: Int { Int((Double(weeklyGoal) * 4.3).rounded()) }

    var profileSummary: String {
        guard !weightText.isEmpty else { return L.s("set_profile_not_set") }
        let unit = weightIsKg ? L.s("profile_weight_kg") : L.s("profile_weight_lb")
        return L.f("set_profile_summary", weightText, unit, sex?.label ?? "—")
    }

    var unitsSummary: String {
        L.f("set_units_summary", energyUnit.label, servingUnit.shortLabel)
    }

    var colorScheme: ColorScheme? {
        switch appearance {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    func resetForClearAll() {
        selectedGoals = []
        baselineAnswer = -1
        spendBaseline = ""
        sex = nil
        weightText = ""
        lastBackupAt = nil
    }
}

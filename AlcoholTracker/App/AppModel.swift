import Foundation
import SwiftData
import SwiftUI

// MARK: - Routing types

enum AppPhase: Equatable {
    case welcome, goals, baseline, app
}

enum MainTab: String {
    case diary, stats, settings

    /// Tab-bar label. Split from `title` for punch list B1: *Einstellungen*,
    /// *Indstillinger*, *Configuración*, *Impostazioni*, *Statistiques* and
    /// *Estatísticas* are all the correct platform terms and all break the
    /// 11-character tab budget, and §8 forbids inventing a synonym.
    var shortLabel: String {
        switch self {
        case .diary: L.s("tab_diary")
        case .stats: L.s("tab_statistics_short")
        case .settings: L.s("tab_settings_short")
        }
    }

    /// The screen heading, which keeps the full platform term.
    var title: String {
        switch self {
        case .diary: L.s("tab_diary")
        case .stats: L.s("tab_statistics")
        case .settings: L.s("tab_settings")
        }
    }
}

enum AppSheet: Identifiable, Equatable {
    case log
    case calendar(dryMode: Bool)
    case entry(id: UUID)
    case unitsInfo
    case bacInfo
    case customRange
    case newNotification
    case livePreview
    case customDrink
    case export
    case health

    var id: String {
        switch self {
        case .log: "log"
        case .calendar(let dry): "calendar-\(dry)"
        case .entry(let id): "entry-\(id)"
        case .unitsInfo: "unitsInfo"
        case .bacInfo: "bacInfo"
        case .customRange: "customRange"
        case .newNotification: "newNotification"
        case .livePreview: "livePreview"
        case .customDrink: "customDrink"
        case .export: "export"
        case .health: "health"
        }
    }
}

enum AppDialog: Identifiable, Equatable {
    case deleteEntry(id: UUID)
    case clearAll
    case healthPermission

    var id: String {
        switch self {
        case .deleteEntry: "delete"
        case .clearAll: "clear"
        case .healthPermission: "health"
        }
    }
}

enum PushScreen: String, Identifiable {
    case profile, units, notifications, bacMonitor, watch, backup, about, icon, bacTrends, guideline
    case theme

    var id: String { rawValue }

    var title: String {
        switch self {
        case .profile: L.s("set_profile")
        case .units: L.s("set_units")
        case .notifications: L.s("set_notifications")
        case .bacMonitor: L.s("bac_monitor")
        case .watch: L.s("push_title_quick_log")
        case .backup: L.s("push_title_backup")
        case .about: L.s("push_title_about")
        case .icon: L.s("set_app_icon")
        case .theme: L.s("push_title_theme")
        case .bacTrends: L.s("push_title_trends")
        case .guideline: L.s("push_title_guideline")
        }
    }
}

struct Toast: Equatable {
    var message: String
    var showsUndo = false
}

// MARK: - App model
//
// Single source of truth. Every roll-up on screen is computed from the same
// log array so numbers always reconcile (brief P9).

@MainActor
final class AppModel: ObservableObject {
    let settings: AppSettings
    let entitlements: EntitlementStore
    private(set) var context: ModelContext

    // Data mirrors (small local datasets; kept sorted).
    @Published private(set) var logs: [DrinkLog] = []
    @Published private(set) var dryDays: [DryDay] = []
    @Published private(set) var savedDrinks: [SavedDrink] = []
    @Published private(set) var reminders: [ReminderItem] = []

    // Routing
    @Published var phase: AppPhase
    @Published var tab: MainTab = .diary
    @Published var paywallShown = false
    @Published var sheet: AppSheet?
    @Published var dialog: AppDialog?
    @Published var push: PushScreen?
    @Published var fabOpen = false
    @Published var showBoot = true

    // Diary selection: drinking-day offset from today (0 = today, negative = past).
    @Published var dayOffset = 0

    // Statistics state
    @Published var statsPeriod: StatsPeriod = .week
    @Published var statsPage = 0
    @Published var customFrom: Date?
    @Published var customTo: Date?
    @Published var showDailyAverage = false
    @Published var showSpendAverage = false

    // Toast + undo
    @Published var toast: Toast?
    private var toastTask: Task<Void, Never>?
    private var lastLoggedID: UUID?

    // Clock — refreshed each minute so BAC and "today" stay honest.
    @Published private(set) var now = Date()
    private var clockTask: Task<Void, Never>?

    var pro: Bool { entitlements.isPro }

    init(settings: AppSettings, entitlements: EntitlementStore, context: ModelContext) {
        self.settings = settings
        self.entitlements = entitlements
        self.context = context
        phase = settings.onboardingDone ? .app : .welcome
        reload()
        startClock()
    }

    private func startClock() {
        clockTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                self?.now = Date()
            }
        }
    }

    func reload() {
        logs = (try? context.fetch(FetchDescriptor<DrinkLog>(sortBy: [SortDescriptor(\.loggedAt)]))) ?? []
        dryDays = (try? context.fetch(FetchDescriptor<DryDay>())) ?? []
        savedDrinks = (try? context.fetch(FetchDescriptor<SavedDrink>(sortBy: [SortDescriptor(\.createdAt)]))) ?? []
        reminders = (try? context.fetch(FetchDescriptor<ReminderItem>(sortBy: [SortDescriptor(\.timeMinutes)]))) ?? []
    }

    // MARK: Derived — days

    var todayKey: Int { DrinkingDay.todayKey(cutoff: settings.cutoff, now: now) }
    var selectedKey: Int { todayKey + dayOffset }

    var logsByDay: [Int: [DrinkLog]] {
        StatsEngine.byDay(logs: logs, cutoff: settings.cutoff)
    }

    var dryKeys: Set<Int> { Set(dryDays.map(\.epochDay)) }

    func logs(forKey key: Int) -> [DrinkLog] {
        (logsByDay[key] ?? []).sorted { $0.loggedAt < $1.loggedAt }
    }

    var selectedDayLogs: [DrinkLog] { logs(forKey: selectedKey) }

    var selectedDayIsDry: Bool {
        dryKeys.contains(selectedKey) && selectedDayLogs.isEmpty
    }

    func units(forKey key: Int) -> Double {
        logs(forKey: key).reduce(0) { $0 + $1.units }
    }

    var selectedDayUnits: Double { units(forKey: selectedKey) }

    var weekUnits: Double {
        ((todayKey - 6) ... todayKey).reduce(0) { $0 + units(forKey: $1) }
    }

    var monthUnits: Double {
        let month = Calendar.current.component(.month, from: DrinkingDay.date(for: todayKey))
        return ((todayKey - 30) ... todayKey).reduce(0.0) { acc, k in
            Calendar.current.component(.month, from: DrinkingDay.date(for: k)) == month
                ? acc + units(forKey: k)
                : acc
        }
    }

    var selectedDayTitle: String {
        switch dayOffset {
        case 0: return L.s("diary_today")
        case -1: return L.s("diary_yesterday")
        default: return Formatters.shortDate(DrinkingDay.date(for: selectedKey))
        }
    }

    var selectedDaySubtitle: String {
        Formatters.longWeekdayDate(DrinkingDay.date(for: selectedKey))
    }

    // MARK: Derived — BAC

    var bacEstimate: BacEstimate? {
        BacMath.estimate(
            logs: logs(forKey: todayKey),
            sex: settings.sex,
            weightKg: settings.weightKg,
            now: now
        )
    }

    /// Peak estimated BAC per day, last 7 days — powers the trends chart.
    var bacWeekPeaks: [Double]? {
        guard settings.sex != nil, settings.weightKg > 0 else { return nil }
        let r = BacMath.widmarkR(sex: settings.sex ?? .male)
        return ((todayKey - 6) ... todayKey).map { k in
            let grams = logs(forKey: k).reduce(0.0) { $0 + $1.gramsEthanol }
            return grams / (settings.weightKg * 1000 * r) * 100
        }
    }

    // MARK: Derived — quick log

    /// "The usual?" — top three most-poured drinks, falling back to presets.
    var quickItems: [DrinkPreset] {
        var freq: [String: (preset: DrinkPreset, count: Int)] = [:]
        for r in logs {
            let p = DrinkPreset(name: r.name, abv: r.abv, ml: r.ml, cost: r.cost)
            var e = freq[r.name] ?? (p, 0)
            e.count += 1
            freq[r.name] = e
        }
        let top = freq.values.sorted { $0.count > $1.count }.prefix(3).map(\.preset)
        return top.isEmpty ? Array(Presets.popular.prefix(3)) : Array(top)
    }

    // MARK: Derived — statistics

    var statsRange: StatsRange {
        StatsEngine.compute(
            period: statsPeriod,
            pageOffset: statsPage,
            customFrom: customFrom,
            customTo: customTo,
            logsByDay: logsByDay,
            dryKeys: dryKeys,
            todayKey: todayKey,
            dailyGoal: settings.dailyGoal
        )
    }

    // MARK: Logging — never a spinner, always an undo

    func quickLog(_ preset: DrinkPreset) {
        insertLog(
            name: preset.name, ml: preset.ml, abv: preset.abv,
            cost: preset.cost, at: now, dayKey: todayKey
        )
        dayOffset = 0
        Haptics.success()
        showToast(
            L.f("toast_quick_logged", preset.name, preset.units, UnitsConfig.current.noun(.abbreviation)),
            undo: true
        )
    }

    func saveLog(name: String, ml: Double, abv: Double, quantity: Double, cost: Double, hoursAgo: Int) {
        let at = now.addingTimeInterval(-Double(hoursAgo) * 3600)
        let totalMl = (ml * quantity).rounded()
        // Back-dating from the diary: anchor the entry inside the selected
        // drinking day at a representative evening hour.
        let dayKey = selectedKey
        let loggedAt: Date
        if dayKey == todayKey {
            loggedAt = at
        } else {
            loggedAt = DrinkingDay.date(for: dayKey).addingTimeInterval(20 * 3600)
        }
        insertLog(name: name, ml: totalMl, abv: abv, cost: cost, at: loggedAt, dayKey: dayKey)
        Haptics.success()
        closeSheet()
        showToast(
            L.f(
                "toast_logged",
                AlcoholMath.units(ml: totalMl, abv: abv),
                UnitsConfig.current.noun(.plural)
            ),
            undo: true
        )
    }

    private func insertLog(name: String, ml: Double, abv: Double, cost: Double, at: Date, dayKey: Int) {
        let log = DrinkLog(name: name, ml: ml, abv: abv, loggedAt: at, cost: cost)
        context.insert(log)
        // A logged drink un-banks the dry mark for that day — data wins.
        if let dry = dryDays.first(where: { $0.epochDay == dayKey }) {
            context.delete(dry)
        }
        try? context.save()
        lastLoggedID = log.id
        reload()
        HealthSync.shared.writeIfConnected(log: log, settings: settings)
    }

    func undoLastLog() {
        guard let id = lastLoggedID,
              let log = logs.first(where: { $0.id == id }) else { return }
        context.delete(log)
        try? context.save()
        lastLoggedID = nil
        reload()
        dismissToast()
        Haptics.light()
    }

    func relog(_ entry: DrinkLog) {
        insertLog(name: entry.name, ml: entry.ml, abv: entry.abv, cost: entry.cost, at: now, dayKey: todayKey)
        closeSheet()
        showToast(L.s("toast_relogged"))
    }

    func deleteEntry(id: UUID) {
        guard let log = logs.first(where: { $0.id == id }) else { return }
        context.delete(log)
        try? context.save()
        reload()
        dialog = nil
        closeSheet()
        showToast(L.s("toast_entry_removed"))
    }

    // MARK: Dry days

    func markDry(key: Int) {
        guard logs(forKey: key).isEmpty else {
            showToast(L.s("toast_day_has_drinks"))
            return
        }
        guard !dryKeys.contains(key) else { return }
        context.insert(DryDay(epochDay: key))
        try? context.save()
        reload()
        Haptics.success()
        showToast(L.s("toast_dry_marked"))
    }

    func unmarkDry(key: Int) {
        guard let dry = dryDays.first(where: { $0.epochDay == key }) else { return }
        context.delete(dry)
        try? context.save()
        reload()
    }

    /// Calendar sheet in dry-mode: toggles, but never over a day with drinks.
    func toggleDry(key: Int) {
        if !logs(forKey: key).isEmpty {
            showToast(L.s("toast_day_has_drinks_cal"))
            return
        }
        if dryKeys.contains(key) { unmarkDry(key: key) }
        else {
            context.insert(DryDay(epochDay: key))
            try? context.save()
            reload()
            Haptics.light()
        }
    }

    // MARK: Saved drinks

    func saveCustomDrink(name: String, base: String, abv: Double, ml: Double, notes: String) {
        context.insert(SavedDrink(name: name, base: base, abv: abv, ml: ml, notes: notes))
        try? context.save()
        reload()
        closeSheet()
        showToast(L.s("toast_custom_saved"))
    }

    func toggleWatch(_ drink: SavedDrink) {
        if !drink.onWatch, savedDrinks.filter(\.onWatch).count >= 4 { return }
        drink.onWatch.toggle()
        try? context.save()
        reload()
    }

    // MARK: Reminders

    func addReminder(title: String, timeMinutes: Int, message: String) {
        let item = ReminderItem(title: title, timeMinutes: timeMinutes, message: message)
        context.insert(item)
        try? context.save()
        reload()
        closeSheet()

        if !settings.notificationPermissionAsked {
            settings.notificationPermissionAsked = true
            Task {
                let granted = await ReminderScheduler.shared.requestPermission()
                self.rescheduleAllReminders()
                self.showToast(granted
                    ? L.s("toast_reminder_scheduled")
                    : L.f("toast_reminder_silent", "iOS"))
            }
        } else {
            rescheduleAllReminders()
            showToast(L.s("toast_reminder_scheduled"))
        }
    }

    func removeReminder(_ item: ReminderItem) {
        context.delete(item)
        try? context.save()
        reload()
        rescheduleAllReminders()
    }

    func rescheduleAllReminders() {
        ReminderScheduler.shared.schedule(reminders: reminders, discreet: settings.discreetNotifications)
    }

    // MARK: Clear all

    func clearAllData() {
        for l in logs { context.delete(l) }
        for d in dryDays { context.delete(d) }
        for s in savedDrinks { context.delete(s) }
        for r in reminders { context.delete(r) }
        try? context.save()
        settings.resetForClearAll()
        ReminderScheduler.shared.cancelAll()
        reload()
        dialog = nil
        push = nil
        showToast(L.s("toast_cleared"))
    }

    // MARK: Sheet/dialog helpers

    func openSheet(_ s: AppSheet) {
        fabOpen = false
        sheet = s
    }

    func closeSheet() { sheet = nil }

    func openPaywall() { paywallShown = true }

    // MARK: Toast

    func showToast(_ message: String, undo: Bool = false) {
        toastTask?.cancel()
        withAnimation(Motion.pop) { toast = Toast(message: message, showsUndo: undo) }
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(undo ? 5 : 2.6))
            guard !Task.isCancelled else { return }
            self?.dismissToast()
        }
    }

    func dismissToast() {
        toastTask?.cancel()
        withAnimation(Motion.fade) { toast = nil }
    }
}

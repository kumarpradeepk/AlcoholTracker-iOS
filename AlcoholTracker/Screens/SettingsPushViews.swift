import SwiftUI
import UIKit
import UniformTypeIdentifiers

// MARK: - Settings push screens (slide in from the right, like the canvas)

struct PushRouter: View {
    @ObservedObject var model: AppModel
    @ObservedObject var settings: AppSettings

    var body: some View {
        if let push = model.push {
            PushHost(title: push.title, onBack: {
                withAnimation(Motion.slide) { model.push = nil }
            }) {
                switch push {
                case .profile: ProfilePush(model: model, settings: settings)
                case .units: UnitsPush(settings: settings)
                case .notifications: NotificationsPush(model: model)
                case .bacMonitor: BacMonitorPush(model: model, settings: settings)
                case .watch: WatchPush(model: model)
                case .backup: BackupPush(model: model, settings: settings)
                case .about: AboutPush()
                case .icon: IconPush(model: model, settings: settings)
                case .theme: ThemePush(settings: settings)
                case .bacTrends: BacTrendsPush(model: model, settings: settings)
                case .guideline: GuidelinePush(settings: settings)
                }
            }
        }
    }
}

// MARK: - Profile (BAC needs it; never required at onboarding)

struct ProfilePush: View {
    @Environment(\.theme) private var theme
    @ObservedObject var model: AppModel
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 16) {
                AnimatedGlass(width: 58, height: 76)
                VStack(alignment: .leading, spacing: 5) {
                    Text(L.s("profile_headline"))
                        .font(theme.fonts.display(19))
                    Text(L.s("profile_body"))
                        .font(theme.fonts.body(13.5))
                        .foregroundStyle(theme.muted)
                        .lineSpacing(3)
                }
            }
            .padding(.top, 6)

            Text(L.s("profile_privacy_note"))
                .font(theme.fonts.body(12.5))
                .foregroundStyle(theme.faint)
                .padding(.top, 12)

            VStack(alignment: .leading, spacing: 10) {
                Text(L.s("profile_sex_label"))
                    .font(theme.fonts.body(13, .semibold))
                    .foregroundStyle(theme.muted)
                SegmentedPill(
                    options: [(Sex.female, Sex.female.label), (Sex.male, Sex.male.label)],
                    selection: Binding(
                        get: { settings.sex ?? .female },
                        set: { settings.sex = $0 }
                    )
                )
                .opacity(settings.sex == nil ? 0.75 : 1)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .card(radius: 20)
            .padding(.top, 16)

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(L.s("profile_weight_label"))
                        .font(theme.fonts.body(13, .semibold))
                        .foregroundStyle(theme.muted)
                    Spacer()
                    SegmentedPill(
                        options: [(true, L.s("profile_weight_kg")), (false, L.s("profile_weight_lb"))],
                        selection: $settings.weightIsKg,
                        fontSize: 12.5
                    )
                    .frame(width: 110)
                }
                TextField(L.s("profile_weight_placeholder"), text: $settings.weightText)
                    .keyboardType(.decimalPad)
                    .font(theme.fonts.display(17))
                    .monospacedDigit()
                    .multilineTextAlignment(.center)
                    .frame(height: 48)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.surface2))
                    .padding(.top, 12)
            }
            .padding(16)
            .card(radius: 20)
            .padding(.top, 12)

            PrimaryButton(title: L.s("profile_cta"), height: 52) {
                guard !settings.weightText.isEmpty, settings.sex != nil else {
                    model.showToast(L.s("toast_profile_incomplete"))
                    return
                }
                withAnimation(Motion.slide) { model.push = nil }
                model.showToast(L.s("toast_profile_saved"))
            }
            .padding(.top, 18)

            Text(L.s("profile_footer"))
                .font(theme.fonts.body(12.5))
                .foregroundStyle(theme.faint)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
        }
    }
}

// MARK: - Units

struct UnitsPush: View {
    @Environment(\.theme) private var theme
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            segCard(
                title: L.s("units_energy_label"),
                options: [(EnergyUnit.kcal, EnergyUnit.kcal.label), (EnergyUnit.kJ, EnergyUnit.kJ.label)],
                selection: $settings.energyUnit
            )
            segCard(
                title: L.s("units_serving_label"),
                options: [(ServingUnit.ml, ServingUnit.ml.label), (ServingUnit.oz, ServingUnit.oz.label)],
                selection: $settings.servingUnit
            )
            .padding(.top, 12)
            Text(L.s("units_note"))
                .font(theme.fonts.body(13))
                .foregroundStyle(theme.faint)
                .lineSpacing(2)
                .padding(.horizontal, 4)
                .padding(.top, 14)
        }
    }

    private func segCard<T: Hashable>(title: String, options: [(T, String)], selection: Binding<T>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(theme.fonts.body(13, .semibold))
                .foregroundStyle(theme.muted)
            SegmentedPill(options: options, selection: selection)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(radius: 20)
    }
}

// MARK: - Notifications

struct NotificationsPush: View {
    @Environment(\.theme) private var theme
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if model.reminders.isEmpty {
                emptyState
            } else {
                SettingsGroup {
                    ForEach(model.reminders) { item in
                        reminderRow(item)
                    }
                }
                Text(L.s("notif_repeat_hint"))
                    .font(theme.fonts.body(12.5))
                    .foregroundStyle(theme.faint)
                    .padding(.horizontal, 4)
                    .padding(.top, 10)
            }

            PrimaryButton(title: L.s("notif_create_cta"), height: 52) {
                model.openSheet(.newNotification)
            }
            .padding(.top, 18)
        }
    }

    private func reminderRow(_ item: ReminderItem) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title).font(theme.fonts.body(15, .semibold))
                Text(item.message.isEmpty
                     ? timeLabel(item)
                     : L.f("notif_reminder_sub", timeLabel(item), item.message))
                    .font(theme.fonts.body(13))
                    .foregroundStyle(theme.muted)
                    .lineLimit(1)
            }
            Spacer()
            Button {
                Haptics.light()
                model.removeReminder(item)
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.b3)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(theme.surface2))
            }
            .buttonStyle(PressScale(scale: 0.85))
            .accessibilityLabel(L.f("a11y_remove_reminder", item.title))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(minHeight: 56)
        .overlay(alignment: .bottom) {
            Rectangle().fill(theme.line).frame(height: 0.5).padding(.leading, 16)
        }
    }

    private func timeLabel(_ item: ReminderItem) -> String {
        var comps = DateComponents()
        comps.hour = item.timeMinutes / 60
        comps.minute = item.timeMinutes % 60
        let date = Calendar.current.date(from: comps) ?? .now
        return Formatters.time(date)
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            ZStack {
                RippleRings()
                DropletMark(size: 26)
            }
            .frame(width: 84, height: 84)

            Text(L.s("notif_empty_title"))
                .font(theme.fonts.display(18))
                .padding(.top, 18)
            Text(L.s("notif_empty_body"))
                .font(theme.fonts.body(14))
                .foregroundStyle(theme.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: 260)
                .padding(.top, 7)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 36)
        .padding(.bottom, 10)
    }
}

/// Expanding ripple rings behind the droplet (canvas kRipple).
struct RippleRings: View {
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 1 / 30, paused: reduceMotion)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                func ring(phase: Double) {
                    let p = ((t + phase) / 3.6).truncatingRemainder(dividingBy: 1)
                    let scale = 0.55 + p * 1.15
                    let alpha = (1 - p) * 0.55
                    let d = 56 * scale
                    let rect = CGRect(
                        x: (size.width - d) / 2, y: (size.height - d) / 2,
                        width: d, height: d
                    )
                    context.stroke(Path(ellipseIn: rect), with: .color(theme.accent.opacity(alpha)), lineWidth: 1.5)
                }
                ring(phase: 0)
                ring(phase: 1.8)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Create notification sheet

struct NewNotificationSheet: View {
    @Environment(\.theme) private var theme
    @ObservedObject var model: AppModel

    @State private var title = ""
    @State private var time = Calendar.current.date(from: DateComponents(hour: 20, minute: 30)) ?? .now
    @State private var message = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetGrabber().frame(maxWidth: .infinity)

            Text(L.s("notif_create_cta"))
                .font(theme.fonts.display(20))
                .padding(.top, 8)

            TextField(L.s("sheet_notif_title_placeholder"), text: $title)
                .font(theme.fonts.body(15.5))
                .padding(.horizontal, 16)
                .frame(height: 48)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.surface2))
                .padding(.top, 14)

            HStack {
                Text(L.s("sheet_notif_time_label")).font(theme.fonts.body(15, .semibold))
                Spacer()
                DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                    .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .card(radius: 16)
            .padding(.top, 10)

            TextField(L.s("sheet_notif_message_placeholder"), text: $message)
                .font(theme.fonts.body(15.5))
                .padding(.horizontal, 16)
                .frame(height: 48)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.surface2))
                .padding(.top, 10)

            Text(L.s("sheet_notif_repeat_note"))
                .font(theme.fonts.body(12.5))
                .foregroundStyle(theme.faint)
                .padding(.top, 10)

            PrimaryButton(title: L.s("sheet_notif_cta"), enabled: !title.trimmingCharacters(in: .whitespaces).isEmpty, height: 50) {
                let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
                model.addReminder(
                    title: title.trimmingCharacters(in: .whitespaces),
                    timeMinutes: (comps.hour ?? 20) * 60 + (comps.minute ?? 30),
                    message: message
                )
            }
            .padding(.top, 14)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 26)
        .background(theme.bg)
        .presentationDetents([.height(400)])
        .presentationCornerRadius(26)
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - BAC Monitor settings (Pro)

struct BacMonitorPush: View {
    @Environment(\.theme) private var theme
    @ObservedObject var model: AppModel
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsGroup {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L.s("bac_monitor")).font(theme.fonts.body(15.5))
                        Text(L.s("set_bac_row_sub"))
                            .font(theme.fonts.body(12.5))
                            .foregroundStyle(theme.muted)
                    }
                    Spacer()
                    AppToggle(isOn: $settings.bacOn)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(minHeight: 56)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(theme.line).frame(height: 0.5).padding(.leading, 16)
                }

                HStack {
                    Text(L.s("set_bac_unit_label")).font(theme.fonts.body(15.5))
                    Spacer()
                    SegmentedPill(
                        options: [(BacUnit.percent, BacUnit.percent.label), (BacUnit.permille, BacUnit.permille.label)],
                        selection: $settings.bacUnit,
                        fontSize: 13
                    )
                    .frame(width: 110)
                }
                .padding(.horizontal, 16)
                .frame(minHeight: 52)
            }

            Button { model.openSheet(.livePreview) } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L.s("set_bac_preview_title"))
                            .font(theme.fonts.body(15.5))
                            .foregroundStyle(theme.text)
                        Text(L.s("set_bac_preview_sub"))
                            .font(theme.fonts.body(12.5))
                            .foregroundStyle(theme.muted)
                    }
                    Spacer()
                    ChevronRight()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 15)
            }
            .buttonStyle(PressScale(scale: 0.98))
            .card(radius: 20)
            .padding(.top, 12)

            Text(L.s("set_bac_disclaimer"))
                .font(theme.fonts.body(13, .medium))
                .foregroundStyle(theme.b2)
                .lineSpacing(2)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(theme.surface2))
                .padding(.top, 14)
        }
    }
}

// MARK: - Apple Watch quick log (Pro)

struct WatchPush: View {
    @Environment(\.theme) private var theme
    @ObservedObject var model: AppModel

    private var selectedCount: Int { model.savedDrinks.filter(\.onWatch).count }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Watch preview
            HStack {
                Spacer()
                VStack(spacing: 7) {
                    Text(L.s("quicklog_mock_caption"))
                        .font(theme.fonts.body(8.5, .semibold))
                        .kerning(0.5)
                        .foregroundStyle(.white.opacity(0.55))
                    watchPill(model.savedDrinks.first(where: \.onWatch)?.name ?? "Margarita",
                              tint: DrinkTints.cocktail, bg: DrinkTints.cocktail.opacity(0.3))
                    watchPill(model.savedDrinks.filter(\.onWatch).dropFirst().first?.name ?? "Gin & Tonic",
                              tint: DrinkTints.beer, bg: DrinkTints.beer.opacity(0.25))
                    Text(L.s("quicklog_mock_footer"))
                        .font(theme.fonts.body(9))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .frame(width: 132, height: 160)
                .background(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(Color(hex: 0x101012))
                        .overlay(
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .strokeBorder(Color(hex: 0x2E2E33), lineWidth: 4)
                        )
                )
                Spacer()
            }
            .padding(.vertical, 10)

            HStack {
                SectionCaption(L.s("quicklog_section_caption"))
                Text(L.f("quicklog_selected_count", selectedCount, 4))
                    .font(theme.fonts.body(12.5))
                    .foregroundStyle(theme.muted)
            }
            .padding(.top, 16)

            if model.savedDrinks.isEmpty {
                VStack(spacing: 5) {
                    Text(L.s("quicklog_empty_title"))
                        .font(theme.fonts.body(14.5, .semibold))
                    Text(L.s("quicklog_empty_sub"))
                        .font(theme.fonts.body(13))
                        .foregroundStyle(theme.muted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .card(radius: 20)
                .padding(.top, 8)
            } else {
                SettingsGroup {
                    ForEach(model.savedDrinks) { drink in
                        Button { model.toggleWatch(drink) } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .strokeBorder(drink.onWatch ? theme.accent : theme.line, lineWidth: 1.5)
                                        .background(Circle().fill(drink.onWatch ? theme.accent : .clear))
                                        .frame(width: 22, height: 22)
                                    if drink.onWatch {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                                Text(drink.name)
                                    .font(theme.fonts.body(15, .medium))
                                    .foregroundStyle(theme.text)
                                Spacer()
                                Text(L.f("quicklog_drink_meta", Int(drink.ml), Formatters.trim(drink.abv)))
                                    .font(theme.fonts.body(13))
                                    .foregroundStyle(theme.muted)
                            }
                            .padding(.horizontal, 16)
                            .frame(minHeight: 52)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(theme.line).frame(height: 0.5).padding(.leading, 16)
                        }
                    }
                }
                .padding(.top, 8)
            }

            SoftButton(title: L.s("log_custom_title"), background: theme.surface2, foreground: theme.accent) {
                model.openSheet(.customDrink)
            }
            .padding(.top, 12)

            Text(L.s("quicklog_watch_footer"))
                .font(theme.fonts.body(12.5))
                .foregroundStyle(theme.faint)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: .infinity)
                .padding(.top, 14)
        }
    }

    private func watchPill(_ label: String, tint: Color, bg: Color) -> some View {
        Text(label)
            .font(theme.fonts.body(10, .semibold))
            .foregroundStyle(tint)
            .lineLimit(1)
            .frame(width: 92, height: 26)
            .background(Capsule().fill(bg))
    }
}

// MARK: - Backup & Restore

struct BackupPush: View {
    @Environment(\.theme) private var theme
    @ObservedObject var model: AppModel
    @ObservedObject var settings: AppSettings

    @State private var exportDoc: BackupDocument?
    @State private var showImporter = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Circle().fill(theme.b1).frame(width: 8, height: 8)
                Text(BackupManager.statusLine(lastBackupAt: settings.lastBackupAt))
                    .font(theme.fonts.body(13.5, .semibold))
                    .foregroundStyle(theme.b1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(theme.surface2))

            VStack(alignment: .leading, spacing: 12) {
                Text(L.s("backup_whats_here"))
                    .font(theme.fonts.body(13, .semibold))
                    .foregroundStyle(theme.muted)
                HStack(spacing: 10) {
                    countTile("\(model.logs.count)", L.f("backup_count_logs", model.logs.count), tint: theme.text)
                    countTile("\(model.dryDays.count)", L.f("backup_count_dry", model.dryDays.count), tint: theme.b1)
                    countTile("1", L.s("backup_count_profile"), tint: theme.text)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .card(radius: 20)
            .padding(.top, 12)

            SettingsGroup {
                actionRow(L.s("backup_export")) {
                    exportDoc = BackupDocument(data: BackupManager.encode(model: model))
                }
                actionRow(L.s("backup_import")) { showImporter = true }
                actionRow(L.s("backup_create")) {
                    BackupManager.createLocalBackup(model: model)
                    model.showToast(L.s("toast_backup_created"))
                }
                actionRow(L.s("backup_restore"), isLast: true) {
                    if BackupManager.restoreLocalBackup(model: model) {
                        model.showToast(L.s("toast_backup_restored_ios"))
                    } else {
                        model.showToast(L.s("toast_backup_none_ios"))
                    }
                }
            }
            .padding(.top, 12)

            Text(L.s("backup_merge_note"))
                .font(theme.fonts.body(12.5))
                .foregroundStyle(theme.faint)
                .lineSpacing(2)
                .padding(.horizontal, 4)
                .padding(.top, 10)

            Text(L.s("backup_danger_zone"))
                .font(theme.fonts.body(12, .semibold))
                .kerning(0.6)
                .foregroundStyle(theme.b3)
                .padding(.leading, 4)
                .padding(.top, 22)

            SettingsGroup {
                Button { model.dialog = .clearAll } label: {
                    Text(L.s("backup_clear_all"))
                        .font(theme.fonts.body(15.5, .medium))
                        .foregroundStyle(theme.b3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 52)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)

            Text(L.s("backup_clear_note"))
                .font(theme.fonts.body(12.5))
                .foregroundStyle(theme.faint)
                .lineSpacing(2)
                .padding(.horizontal, 4)
                .padding(.top, 10)
        }
        .fileExporter(
            isPresented: Binding(get: { exportDoc != nil }, set: { if !$0 { exportDoc = nil } }),
            document: exportDoc,
            contentType: .json,
            defaultFilename: "AlcoholTracker-export"
        ) { result in
            if case .success = result {
                model.showToast(L.s("toast_export_file_ios"))
            }
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
            guard case .success(let url) = result else { return }
            let secured = url.startAccessingSecurityScopedResource()
            defer { if secured { url.stopAccessingSecurityScopedResource() } }
            guard let data = try? Data(contentsOf: url) else {
                model.showToast(L.s("toast_file_unreadable"))
                return
            }
            let (imported, skipped) = BackupManager.merge(data: data, into: model)
            // The catalog carries the real plural forms: the duplicate count
            // selects the arm, so no count/noun agreement is composed here.
            model.showToast(L.f("toast_import_result_ios", imported, skipped))
        }
    }

    private func countTile(_ value: String, _ label: String, tint: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(theme.fonts.display(19))
                .monospacedDigit()
                .foregroundStyle(tint)
            Text(label)
                .font(theme.fonts.body(11.5))
                .foregroundStyle(theme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.surface2))
    }

    private func actionRow(_ title: String, isLast: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(theme.fonts.body(15.5, .medium))
                .foregroundStyle(theme.accent)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .frame(minHeight: 52)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(theme.line).frame(height: 0.5).padding(.leading, 16)
            }
        }
    }
}

// MARK: - About

struct AboutPush: View {
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 0) {
                DropletMark(size: 44)
                Text(L.s("app_name"))
                    .font(theme.fonts.display(17))
                    .padding(.top, 16)
                // "Still Water" is a release codename — a proper noun the
                // inventory marks as never translated.
                Text(L.f("about_version", L.s("set_about_version_value"), "Still Water"))
                    .font(theme.fonts.body(13))
                    .foregroundStyle(theme.muted)
                    .padding(.top, 3)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 14)
            .padding(.bottom, 6)

            SettingsGroup {
                linkRow(L.s("about_privacy"), url: "https://alcoholtracker.app/privacy")
                linkRow(L.s("about_terms"), url: "https://alcoholtracker.app/terms", isLast: true)
            }
            .padding(.top, 16)

            SectionCaption(L.s("about_ack_caption"))
                .padding(.leading, 4)
                .padding(.top, 20)

            SettingsGroup {
                ackRow("SwiftData", L.s("about_ack_role_db"))
                ackRow("SwiftUI", L.s("about_ack_role_ui_ios"))
                ackRow("HealthKit", L.s("about_ack_role_health_ios"), isLast: true)
            }
            .padding(.top, 8)

            Text(L.s("about_footer"))
                .font(theme.fonts.body(12))
                .foregroundStyle(theme.faint)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
        }
    }

    private func linkRow(_ title: String, url: String, isLast: Bool = false) -> some View {
        Button {
            if let u = URL(string: url) { UIApplication.shared.open(u) }
        } label: {
            HStack {
                Text(title)
                    .font(theme.fonts.body(15.5))
                    .foregroundStyle(theme.text)
                Spacer()
                ChevronRight()
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(theme.line).frame(height: 0.5).padding(.leading, 16)
            }
        }
    }

    private func ackRow(_ name: String, _ role: String, isLast: Bool = false) -> some View {
        HStack {
            Text(name).font(theme.fonts.body(15))
            Spacer()
            Text(role)
                .font(theme.fonts.body(13))
                .foregroundStyle(theme.faint)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 48)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(theme.line).frame(height: 0.5).padding(.leading, 16)
            }
        }
    }
}

// MARK: - App icon

struct IconPush: View {
    @Environment(\.theme) private var theme
    @ObservedObject var model: AppModel
    @ObservedObject var settings: AppSettings

    private let icons: [(name: String, alternate: String?, tile: Color, drop: Color)] = [
        (L.s("set_icon_default"), nil, Color(hex: 0x2E8FBF), .white),
        (L.s("set_icon_gift"), "AppIconGift", Color(hex: 0xF5EBDA), Color(hex: 0xB97F2E)),
        (L.s("set_icon_holiday"), "AppIconHoliday", Color(hex: 0x22333D), Color(hex: 0x8CB694)),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L.s("icon_intro"))
                .font(theme.fonts.body(14))
                .foregroundStyle(theme.muted)
                .lineSpacing(2)

            HStack(spacing: 14) {
                Spacer()
                ForEach(Array(icons.enumerated()), id: \.offset) { i, icon in
                    Button {
                        Haptics.selection()
                        withAnimation(Motion.fade) { settings.iconIndex = i }
                    } label: {
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(icon.tile)
                                .frame(width: 84, height: 84)
                                .overlay(
                                    DropletMark(size: 30, color: icon.drop, breathing: false)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .strokeBorder(settings.iconIndex == i ? theme.accent : .clear, lineWidth: 2.5)
                                )
                                .shadow(color: .black.opacity(0.1), radius: 9, y: 6)
                            Text(icon.name)
                                .font(theme.fonts.body(13, .semibold))
                                .foregroundStyle(theme.muted)
                        }
                    }
                    .buttonStyle(PressScale(scale: 0.93))
                    .accessibilityAddTraits(settings.iconIndex == i ? [.isSelected] : [])
                }
                Spacer()
            }
            .padding(.top, 18)

            PrimaryButton(title: L.s("action_done"), height: 52) {
                applyIcon()
                withAnimation(Motion.slide) { model.push = nil }
                model.showToast(L.s("toast_icon_updated"))
            }
            .padding(.top, 26)
        }
    }

    private func applyIcon() {
        let alternate = icons[min(settings.iconIndex, icons.count - 1)].alternate
        guard UIApplication.shared.supportsAlternateIcons,
              UIApplication.shared.alternateIconName != alternate else { return }
        UIApplication.shared.setAlternateIconName(alternate)
    }
}

// MARK: - BAC trends (Pro)

struct BacTrendsPush: View {
    @Environment(\.theme) private var theme
    @ObservedObject var model: AppModel
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let peaks = model.bacWeekPeaks, peaks.contains(where: { $0 > 0 }) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(L.s("trends_title")).font(theme.fonts.body(15, .semibold))
                    Text(L.s("trends_range"))
                        .font(theme.fonts.body(12.5))
                        .foregroundStyle(theme.muted)
                        .padding(.top, 3)
                    TrendLineChart(values: peaks)
                        .padding(.top, 12)
                    HStack {
                        Text(L.s("trends_axis_start"))
                        Spacer()
                        Text(L.s("trends_axis_end"))
                    }
                    .font(theme.fonts.body(10.5))
                    .foregroundStyle(theme.faint)
                    .padding(.top, 4)
                }
                .padding(18)
                .card()

                Text(L.s("trends_note"))
                    .font(theme.fonts.body(13))
                    .foregroundStyle(theme.muted)
                    .lineSpacing(3)
                    .padding(.horizontal, 4)
                    .padding(.top, 14)
            } else {
                VStack(spacing: 0) {
                    AnimatedGlass(width: 72, height: 96)
                    Text(L.s("trends_empty_title"))
                        .font(theme.fonts.display(17))
                        .padding(.top, 18)
                    Text(L.s("trends_empty_body"))
                        .font(theme.fonts.body(14))
                        .foregroundStyle(theme.muted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .frame(maxWidth: 250)
                        .padding(.top, 7)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
    }
}

// MARK: - Alcohol guideline

struct GuidelinePush: View {
    @Environment(\.theme) private var theme
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L.unit("guideline_intro", UnitsConfig.current.noun(.plural)))
                .font(theme.fonts.body(14))
                .foregroundStyle(theme.muted)
                .lineSpacing(3)

            goalCard(
                title: L.s("guideline_daily_target"),
                value: settings.dailyGoal,
                decrement: { settings.dailyGoal = max(1, settings.dailyGoal - 1) },
                increment: { settings.dailyGoal = min(6, settings.dailyGoal + 1) }
            )
            .padding(.top, 16)

            goalCard(
                title: L.s("guideline_weekly_target"),
                value: settings.weeklyGoal,
                decrement: { settings.weeklyGoal = max(2, settings.weeklyGoal - 1) },
                increment: { settings.weeklyGoal = min(30, settings.weeklyGoal + 1) }
            )
            .padding(.top, 12)

            Text(L.unit("guideline_monthly_note", settings.monthlyGoal, UnitsConfig.current.noun(.plural)))
                .font(theme.fonts.body(13))
                .foregroundStyle(theme.faint)
                .lineSpacing(3)
                .padding(.horizontal, 4)
                .padding(.top, 14)
        }
    }

    private func goalCard(title: String, value: Int, decrement: @escaping () -> Void, increment: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(theme.fonts.body(13, .semibold))
                .foregroundStyle(theme.muted)
            HStack {
                stepCircle("minus", decrement)
                Spacer()
                // One whole phrase: gendered numerals and classifiers make the
                // number and the unit noun inseparable outside English.
                Text(L.unit("guideline_target_units", value, UnitsConfig.current.noun(count: value)))
                    .font(theme.fonts.display(30))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(Motion.fade, value: value)
                Spacer()
                stepCircle("plus", increment)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(radius: 20)
    }

    private func stepCircle(_ icon: String, _ action: @escaping () -> Void) -> some View {
        Button {
            Haptics.light()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(theme.muted)
                .frame(width: 44, height: 44)
                .background(Circle().fill(theme.surface2))
        }
        .buttonStyle(PressScale(scale: 0.86))
    }
}


// MARK: - Theme

/// The canvas's theme cards. Each row previews the theme in its *own* colours
/// rather than the active one, so the choice is legible before it is made.
struct ThemePush: View {
    @Environment(\.theme) private var theme
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L.s("theme_intro"))
                .font(theme.fonts.body(13))
                .foregroundStyle(theme.muted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            SectionCaption(L.s("theme_caption"))
                .padding(.top, 18)
                .padding(.bottom, 8)

            VStack(spacing: 8) {
                ForEach(Array(AppTheme.allCases.enumerated()), id: \.element) { index, option in
                    themeCard(option)
                        .riseIn(delay: Double(index) * 0.045)
                }
            }

            SectionCaption(L.s("theme_scheme_caption"))
                .padding(.top, 22)
                .padding(.bottom, 8)

            // Light/dark is a separate axis: every theme is designed in both,
            // so this never disables and never depends on the theme above.
            SegmentedPill(
                options: [
                    (AppearanceOverride.system, L.s("theme_scheme_system")),
                    (AppearanceOverride.light, L.s("theme_scheme_light")),
                    (AppearanceOverride.dark, L.s("theme_scheme_dark"))
                ],
                selection: $settings.appearance,
                fontSize: 13
            )
        }
    }

    private func themeCard(_ option: AppTheme) -> some View {
        // Swatches come from the theme's own light palette, not the active one.
        let preview = Theme.resolve(option, dark: false)
        let selected = settings.theme == option
        return Button {
            withAnimation(Motion.fade) { settings.theme = option }
            Haptics.light()
        } label: {
            HStack(spacing: 12) {
                HStack(spacing: 0) {
                    preview.bg
                    preview.accent
                    preview.accent2
                }
                .frame(width: 46, height: 46)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 1) {
                    Text(option.displayName)
                        .font(theme.fonts.body(14, .bold))
                        .foregroundStyle(theme.text)
                    Text(option.blurb)
                        .font(theme.fonts.body(11.5))
                        .foregroundStyle(theme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    Circle()
                        .fill(selected ? theme.accent : .clear)
                        .overlay(Circle().strokeBorder(selected ? theme.accent : theme.line, lineWidth: 1.5))
                        .frame(width: 20, height: 20)
                    if selected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(theme.onAccent)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .card(bordered: false)
            .overlay(
                RoundedRectangle(cornerRadius: theme.radii.r, style: .continuous)
                    .strokeBorder(selected ? theme.accent : theme.line, lineWidth: selected ? 1.5 : 1)
            )
        }
        .buttonStyle(PressScale(scale: 0.98))
        .accessibilityLabel("\(option.displayName). \(option.blurb)")
        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
    }
}

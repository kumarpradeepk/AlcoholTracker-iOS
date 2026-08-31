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
                        .font(Fonts.figure(19))
                    Text(L.s("profile_body"))
                        .font(Fonts.text(13.5))
                        .foregroundStyle(theme.sub)
                        .lineSpacing(3)
                }
            }
            .padding(.top, 6)

            Text(L.s("profile_privacy_note"))
                .font(Fonts.text(12.5))
                .foregroundStyle(theme.sub)
                .padding(.top, 12)

            VStack(alignment: .leading, spacing: 10) {
                Text(L.s("profile_sex_label"))
                    .font(Fonts.text(13, .semibold))
                    .foregroundStyle(theme.sub)
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
                        .font(Fonts.text(13, .semibold))
                        .foregroundStyle(theme.sub)
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
                    .font(Fonts.figure(17))
                    .monospacedDigit()
                    .multilineTextAlignment(.center)
                    .frame(height: 48)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.elev))
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
                .font(Fonts.text(12.5))
                .foregroundStyle(theme.sub)
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
                .font(Fonts.text(13))
                .foregroundStyle(theme.sub)
                .lineSpacing(2)
                .padding(.horizontal, 4)
                .padding(.top, 14)
        }
    }

    private func segCard<T: Hashable>(title: String, options: [(T, String)], selection: Binding<T>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(Fonts.text(13, .semibold))
                .foregroundStyle(theme.sub)
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
                    .font(Fonts.text(12.5))
                    .foregroundStyle(theme.sub)
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
                Text(item.title).font(Fonts.text(15, .semibold))
                Text(item.message.isEmpty
                     ? timeLabel(item)
                     : L.f("notif_reminder_sub", timeLabel(item), item.message))
                    .font(Fonts.text(13))
                    .foregroundStyle(theme.sub)
                    .lineLimit(1)
            }
            Spacer()
            Button {
                Haptics.light()
                model.removeReminder(item)
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.danger)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(theme.elev))
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
                .font(Fonts.figure(18))
                .padding(.top, 18)
            Text(L.s("notif_empty_body"))
                .font(Fonts.text(14))
                .foregroundStyle(theme.sub)
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
                    context.stroke(Path(ellipseIn: rect), with: .color(theme.acc.opacity(alpha)), lineWidth: 1.5)
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
                .font(Fonts.figure(20))
                .padding(.top, 8)

            TextField(L.s("sheet_notif_title_placeholder"), text: $title)
                .font(Fonts.text(15.5))
                .padding(.horizontal, 16)
                .frame(height: 48)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.elev))
                .padding(.top, 14)

            HStack {
                Text(L.s("sheet_notif_time_label")).font(Fonts.text(15, .semibold))
                Spacer()
                DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                    .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .card(radius: 16)
            .padding(.top, 10)

            TextField(L.s("sheet_notif_message_placeholder"), text: $message)
                .font(Fonts.text(15.5))
                .padding(.horizontal, 16)
                .frame(height: 48)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.elev))
                .padding(.top, 10)

            Text(L.s("sheet_notif_repeat_note"))
                .font(Fonts.text(12.5))
                .foregroundStyle(theme.sub)
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
        .background(theme.page)
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
                        Text(L.s("bac_monitor")).font(Fonts.text(15.5))
                        Text(L.s("set_bac_row_sub"))
                            .font(Fonts.text(12.5))
                            .foregroundStyle(theme.sub)
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
                    Text(L.s("set_bac_unit_label")).font(Fonts.text(15.5))
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
                            .font(Fonts.text(15.5))
                            .foregroundStyle(theme.ink)
                        Text(L.s("set_bac_preview_sub"))
                            .font(Fonts.text(12.5))
                            .foregroundStyle(theme.sub)
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
                .font(Fonts.text(13, .medium))
                .foregroundStyle(theme.amber)
                .lineSpacing(2)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(theme.elev))
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
                        .font(Fonts.text(8.5, .semibold))
                        .kerning(0.5)
                        .foregroundStyle(.white.opacity(0.55))
                    watchPill(model.savedDrinks.first(where: \.onWatch)?.name ?? "Margarita",
                              tint: DrinkTints.cocktail, bg: DrinkTints.cocktail.opacity(0.3))
                    watchPill(model.savedDrinks.filter(\.onWatch).dropFirst().first?.name ?? "Gin & Tonic",
                              tint: DrinkTints.beer, bg: DrinkTints.beer.opacity(0.25))
                    Text(L.s("quicklog_mock_footer"))
                        .font(Fonts.text(9))
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
                    .font(Fonts.text(12.5))
                    .foregroundStyle(theme.sub)
            }
            .padding(.top, 16)

            if model.savedDrinks.isEmpty {
                VStack(spacing: 5) {
                    Text(L.s("quicklog_empty_title"))
                        .font(Fonts.text(14.5, .semibold))
                    Text(L.s("quicklog_empty_sub"))
                        .font(Fonts.text(13))
                        .foregroundStyle(theme.sub)
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
                                        .strokeBorder(drink.onWatch ? theme.acc : theme.line, lineWidth: 1.5)
                                        .background(Circle().fill(drink.onWatch ? theme.acc : .clear))
                                        .frame(width: 22, height: 22)
                                    if drink.onWatch {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                                Text(drink.name)
                                    .font(Fonts.text(15, .medium))
                                    .foregroundStyle(theme.ink)
                                Spacer()
                                Text(L.f("quicklog_drink_meta", Int(drink.ml), Formatters.trim(drink.abv)))
                                    .font(Fonts.text(13))
                                    .foregroundStyle(theme.sub)
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

            SoftButton(title: L.s("log_custom_title"), background: theme.elev, foreground: theme.acc) {
                model.openSheet(.customDrink)
            }
            .padding(.top, 12)

            Text(L.s("quicklog_watch_footer"))
                .font(Fonts.text(12.5))
                .foregroundStyle(theme.sub)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: .infinity)
                .padding(.top, 14)
        }
    }

    private func watchPill(_ label: String, tint: Color, bg: Color) -> some View {
        Text(label)
            .font(Fonts.text(10, .semibold))
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
                Circle().fill(theme.moss).frame(width: 8, height: 8)
                Text(BackupManager.statusLine(lastBackupAt: settings.lastBackupAt))
                    .font(Fonts.text(13.5, .semibold))
                    .foregroundStyle(theme.moss)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(theme.elev))

            VStack(alignment: .leading, spacing: 12) {
                Text(L.s("backup_whats_here"))
                    .font(Fonts.text(13, .semibold))
                    .foregroundStyle(theme.sub)
                HStack(spacing: 10) {
                    countTile("\(model.logs.count)", L.f("backup_count_logs", model.logs.count), tint: theme.ink)
                    countTile("\(model.dryDays.count)", L.f("backup_count_dry", model.dryDays.count), tint: theme.moss)
                    countTile("1", L.s("backup_count_profile"), tint: theme.ink)
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
                .font(Fonts.text(12.5))
                .foregroundStyle(theme.sub)
                .lineSpacing(2)
                .padding(.horizontal, 4)
                .padding(.top, 10)

            Text(L.s("backup_danger_zone"))
                .font(Fonts.text(12, .semibold))
                .kerning(0.6)
                .foregroundStyle(theme.danger)
                .padding(.leading, 4)
                .padding(.top, 22)

            SettingsGroup {
                Button { model.dialog = .clearAll } label: {
                    Text(L.s("backup_clear_all"))
                        .font(Fonts.text(15.5, .medium))
                        .foregroundStyle(theme.danger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 52)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)

            Text(L.s("backup_clear_note"))
                .font(Fonts.text(12.5))
                .foregroundStyle(theme.sub)
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
                .font(Fonts.figure(19))
                .monospacedDigit()
                .foregroundStyle(tint)
            Text(label)
                .font(Fonts.text(11.5))
                .foregroundStyle(theme.sub)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.elev))
    }

    private func actionRow(_ title: String, isLast: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Fonts.text(15.5, .medium))
                .foregroundStyle(theme.acc)
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
                    .font(Fonts.figure(17))
                    .padding(.top, 16)
                // "Still Water" is a release codename — a proper noun the
                // inventory marks as never translated.
                Text(L.f("about_version", L.s("set_about_version_value"), "Still Water"))
                    .font(Fonts.text(13))
                    .foregroundStyle(theme.sub)
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
                .font(Fonts.text(12))
                .foregroundStyle(theme.sub)
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
                    .font(Fonts.text(15.5))
                    .foregroundStyle(theme.ink)
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
            Text(name).font(Fonts.text(15))
            Spacer()
            Text(role)
                .font(Fonts.text(13))
                .foregroundStyle(theme.sub)
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
                .font(Fonts.text(14))
                .foregroundStyle(theme.sub)
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
                                        .strokeBorder(settings.iconIndex == i ? theme.acc : .clear, lineWidth: 2.5)
                                )
                                .shadow(color: .black.opacity(0.1), radius: 9, y: 6)
                            Text(icon.name)
                                .font(Fonts.text(13, .semibold))
                                .foregroundStyle(theme.sub)
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
                    Text(L.s("trends_title")).font(Fonts.text(15, .semibold))
                    Text(L.s("trends_range"))
                        .font(Fonts.text(12.5))
                        .foregroundStyle(theme.sub)
                        .padding(.top, 3)
                    TrendLineChart(values: peaks)
                        .padding(.top, 12)
                    HStack {
                        Text(L.s("trends_axis_start"))
                        Spacer()
                        Text(L.s("trends_axis_end"))
                    }
                    .font(Fonts.text(10.5))
                    .foregroundStyle(theme.sub)
                    .padding(.top, 4)
                }
                .padding(18)
                .card()

                Text(L.s("trends_note"))
                    .font(Fonts.text(13))
                    .foregroundStyle(theme.sub)
                    .lineSpacing(3)
                    .padding(.horizontal, 4)
                    .padding(.top, 14)
            } else {
                VStack(spacing: 0) {
                    AnimatedGlass(width: 72, height: 96)
                    Text(L.s("trends_empty_title"))
                        .font(Fonts.figure(17))
                        .padding(.top, 18)
                    Text(L.s("trends_empty_body"))
                        .font(Fonts.text(14))
                        .foregroundStyle(theme.sub)
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
                .font(Fonts.text(14))
                .foregroundStyle(theme.sub)
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
                .font(Fonts.text(13))
                .foregroundStyle(theme.sub)
                .lineSpacing(3)
                .padding(.horizontal, 4)
                .padding(.top, 14)
        }
    }

    private func goalCard(title: String, value: Int, decrement: @escaping () -> Void, increment: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(Fonts.text(13, .semibold))
                .foregroundStyle(theme.sub)
            HStack {
                stepCircle("minus", decrement)
                Spacer()
                // One whole phrase: gendered numerals and classifiers make the
                // number and the unit noun inseparable outside English.
                Text(L.unit("guideline_target_units", value, UnitsConfig.current.noun(count: value)))
                    .font(Fonts.figure(30))
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
                .foregroundStyle(theme.sub)
                .frame(width: 44, height: 44)
                .background(Circle().fill(theme.elev))
        }
        .buttonStyle(PressScale(scale: 0.86))
    }
}

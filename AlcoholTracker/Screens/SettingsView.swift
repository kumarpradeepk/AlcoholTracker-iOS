import SwiftUI
import UIKit

// MARK: - Settings

struct SettingsView: View {
    @Environment(\.theme) private var theme
    @ObservedObject var model: AppModel
    @ObservedObject var settings: AppSettings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(MainTab.settings.title)
                    .font(Fonts.figure(32))
                    .kerning(-0.5)
                    .padding(.top, 12)

                if model.pro {
                    HStack(spacing: 10) {
                        Circle().fill(theme.moss).frame(width: 8, height: 8)
                        Text(L.s("set_pro_active"))
                            .font(Fonts.text(13.5, .semibold))
                            .foregroundStyle(theme.moss)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(theme.elev))
                    .padding(.top, 14)
                } else {
                    proBanner.padding(.top, 14)
                }

                section(L.s("set_section_you")) {
                    SettingsGroup {
                        SettingsRow(
                            iconTint: theme.acc, iconBackground: theme.elev,
                            iconSystemName: "person.fill", title: L.s("set_profile"),
                            showChevron: true,
                            action: { pushTo(.profile) }
                        ) {
                            valueText(settings.profileSummary)
                        }
                        SettingsRow(
                            iconTint: theme.moss, iconBackground: theme.elev,
                            iconSystemName: "square.fill", title: L.s("set_units"),
                            showChevron: true,
                            action: { pushTo(.units) }
                        ) {
                            valueText(settings.unitsSummary)
                        }
                        SettingsRow(
                            iconTint: theme.amber, iconBackground: theme.elev,
                            iconSystemName: "drop.fill", title: L.s("set_guideline"),
                            showChevron: true,
                            action: { pushTo(.guideline) }
                        ) {
                            valueText(L.f("set_guideline_value", settings.dailyGoal))
                        }
                        SettingsRow(
                            iconTint: theme.acc, iconBackground: theme.elev,
                            iconSystemName: "dollarsign", title: L.s("set_ask_cost")
                        ) {
                            AppToggle(isOn: $settings.askCost)
                        }
                        SettingsRow(
                            iconTint: theme.amber, iconBackground: theme.elev,
                            iconSystemName: "circle", title: L.s("set_show_calories"),
                            showDivider: false
                        ) {
                            AppToggle(isOn: $settings.showCalories)
                        }
                    }
                }

                section(L.s("set_section_insights")) {
                    SettingsGroup {
                        SettingsRow(
                            iconTint: theme.moss, iconBackground: theme.elev,
                            iconSystemName: "checkmark", title: L.s("set_auto_dry")
                        ) {
                            if !model.pro { ProBadge { model.openPaywall() } }
                            AppToggle(isOn: $settings.autoDry) {
                                if model.pro { settings.autoDry.toggle() }
                                else { model.openPaywall() }
                            }
                        }
                        SettingsRow(
                            iconTint: theme.acc, iconBackground: theme.elev,
                            iconSystemName: "percent", title: PushScreen.bacMonitor.title,
                            showChevron: true,
                            action: {
                                if model.pro { pushTo(.bacMonitor) } else { model.openPaywall() }
                            }
                        ) {
                            if !model.pro { ProBadge() }
                        }
                        SettingsRow(
                            iconTint: theme.amber, iconBackground: theme.elev,
                            iconSystemName: "bell.fill", title: L.s("set_notifications"),
                            showChevron: true,
                            action: { pushTo(.notifications) }
                        ) {
                            valueText(model.reminders.isEmpty
                                ? L.s("set_notif_none")
                                : L.f("set_notif_count", model.reminders.count))
                        }
                        SettingsRow(
                            iconTint: theme.danger, iconBackground: theme.danger.opacity(0.14),
                            iconSystemName: "plus", title: L.s("set_health_sync"),
                            showChevron: true,
                            action: {
                                if model.pro { model.openSheet(.health) } else { model.openPaywall() }
                            }
                        ) {
                            valueText(settings.healthConnected
                                ? L.s("set_health_connected")
                                : L.s("set_health_off"))
                        }
                        SettingsRow(
                            iconTint: theme.sub, iconBackground: theme.elev,
                            iconSystemName: "applewatch", title: L.s("set_quick_log"),
                            showChevron: true, showDivider: false,
                            action: {
                                if model.pro { pushTo(.watch) } else { model.openPaywall() }
                            }
                        ) {
                            let count = model.savedDrinks.filter(\.onWatch).count
                            valueText(count > 0
                                ? L.f("set_quick_log_count", count)
                                : L.s("set_quick_log_setup"))
                        }
                    }
                }

                section(L.s("set_section_appearance")) {
                    SettingsGroup {
                        SettingsRow(
                            iconTint: theme.sub, iconBackground: theme.elev,
                            iconSystemName: "moon.fill", title: L.s("set_dark_mode")
                        ) {
                            AppToggle(isOn: darkBinding)
                        }
                        SettingsRow(
                            iconTint: theme.acc, iconBackground: theme.elev,
                            iconSystemName: "app", title: L.s("set_app_icon"),
                            showChevron: true,
                            action: { pushTo(.icon) }
                        ) {
                            valueText([L.s("set_icon_default"), L.s("set_icon_gift"), L.s("set_icon_holiday")][min(settings.iconIndex, 2)])
                        }
                        SettingsRow(
                            iconTint: theme.moss, iconBackground: theme.elev,
                            iconSystemName: "globe", title: L.s("set_language"),
                            showChevron: true, showDivider: false,
                            action: openLanguageSettings
                        ) {
                            valueText(L.s("set_language_value"))
                        }
                    }
                }

                section(L.s("set_section_data")) {
                    // Backup status is a visible element, not a settings toggle
                    // (brief P6) — silent backup failure destroys multi-year logs.
                    HStack(spacing: 11) {
                        Circle()
                            .fill(theme.elev)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(theme.moss)
                            )
                        VStack(alignment: .leading, spacing: 1) {
                            Text(L.s("set_backup_title"))
                                .font(Fonts.text(14.5, .semibold))
                            Text(BackupManager.statusDetail(lastBackupAt: settings.lastBackupAt))
                                .font(Fonts.text(12.5))
                                .foregroundStyle(theme.sub)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .card(radius: 20)

                    SettingsGroup {
                        SettingsRow(
                            iconTint: theme.acc, iconBackground: theme.elev,
                            iconSystemName: "arrow.up", title: L.s("set_backup_row"),
                            showChevron: true, showDivider: false,
                            action: { pushTo(.backup) }
                        ) {
                            Text(L.s("set_backup_free"))
                                .font(Fonts.text(12.5, .semibold))
                                .foregroundStyle(theme.moss)
                        }
                    }
                    .padding(.top, 8)
                }

                section(L.s("set_section_privacy")) {
                    SettingsGroup {
                        SettingsRow(
                            iconTint: theme.sub, iconBackground: theme.elev,
                            iconSystemName: "lock.fill", title: L.s("set_app_lock"),
                            subtitle: L.s("set_app_lock_sub")
                        ) {
                            AppToggle(isOn: $settings.appLock)
                        }
                        SettingsRow(
                            iconTint: theme.sub, iconBackground: theme.elev,
                            iconSystemName: "eye.slash.fill", title: L.s("set_discreet"),
                            subtitle: L.s("set_discreet_sub")
                        ) {
                            AppToggle(isOn: Binding(
                                get: { settings.discreetNotifications },
                                set: {
                                    settings.discreetNotifications = $0
                                    model.rescheduleAllReminders()
                                }
                            ))
                        }
                        SettingsRow(
                            iconTint: theme.sub, iconBackground: theme.elev,
                            iconSystemName: "clock", title: L.s("set_day_ends"),
                            subtitle: L.s("set_day_ends_sub"),
                            showDivider: false,
                            action: {
                                Haptics.selection()
                                withAnimation(Motion.fade) { settings.cutoff = settings.cutoff.next }
                            }
                        ) {
                            Text(settings.cutoff.label)
                                .font(Fonts.text(14.5, .semibold))
                                .foregroundStyle(theme.acc)
                        }
                    }

                    toneCard.padding(.top, 8)
                }

                section(L.s("set_section_support")) {
                    SettingsGroup {
                        SettingsRow(
                            iconTint: theme.acc, iconBackground: theme.elev,
                            iconSystemName: "envelope.fill", title: L.s("set_contact"),
                            showChevron: true,
                            action: contactSupport
                        ) { EmptyView() }
                        SettingsRow(
                            iconTint: theme.sub, iconBackground: theme.elev,
                            iconSystemName: "info", title: L.s("set_about"),
                            showChevron: true,
                            action: { pushTo(.about) }
                        ) {
                            valueText(L.s("set_about_version_value"))
                        }
                        SettingsRow(
                            iconTint: theme.sub, iconBackground: theme.elev,
                            iconSystemName: "number", title: L.s("set_customer_id"),
                            showDivider: false
                        ) {
                            Text(settings.customerID)
                                .font(Fonts.text(13))
                                .monospacedDigit()
                                .foregroundStyle(theme.sub)
                            Button(L.s("set_copy")) {
                                UIPasteboard.general.string = settings.customerID
                                model.showToast(L.s("toast_customer_id_copied"))
                            }
                            .font(Fonts.text(13.5, .semibold))
                            .foregroundStyle(theme.acc)
                        }
                    }
                }

                Text(L.s("set_footer"))
                    .font(Fonts.text(12))
                    .foregroundStyle(theme.sub)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 22)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 150)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: pieces

    private func pushTo(_ screen: PushScreen) {
        withAnimation(Motion.slide) { model.push = screen }
    }

    private var darkBinding: Binding<Bool> {
        Binding(
            get: {
                switch settings.appearance {
                case .dark: true
                case .light: false
                case .system: UITraitCollection.current.userInterfaceStyle == .dark
                }
            },
            set: { settings.appearance = $0 ? .dark : .light }
        )
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionCaption(title).padding(.leading, 4)
            content()
        }
        .padding(.top, 20)
    }

    private func valueText(_ text: String) -> some View {
        Text(text)
            .font(Fonts.text(14))
            .foregroundStyle(theme.sub)
    }

    private var proBanner: some View {
        Button { model.openPaywall() } label: {
            HStack(spacing: 12) {
                DropletMark(size: 30, breathing: false)
                    .scaleEffect(0.62)
                    .frame(width: 30, height: 30)
                VStack(alignment: .leading, spacing: 1) {
                    Text(L.s("set_pro_banner_title"))
                        .font(Fonts.text(14.5, .semibold))
                        .foregroundStyle(theme.ink)
                    Text(L.s("set_pro_banner_sub"))
                        .font(Fonts.text(12.5))
                        .foregroundStyle(theme.sub)
                }
                Spacer()
                ChevronRight()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(theme.elev))
        }
        .buttonStyle(PressScale(scale: 0.98))
    }

    private var toneCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(theme.elev)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text(L.s("set_tone_icon_sample"))
                            .font(Fonts.text(11, .bold))
                            .foregroundStyle(theme.acc)
                    )
                Text(L.s("set_tone")).font(Fonts.text(15.5))
            }

            SegmentedPill(
                options: Tone.allCases.map { ($0, $0.label) },
                selection: $settings.tone,
                fontSize: 13
            )
            .padding(.top, 10)

            Text(settings.tone.subCopy)
                .font(Fonts.text(12.5))
                .foregroundStyle(theme.sub)
                .padding(.top, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .card(radius: 20)
    }

    private func contactSupport() {
        let device = UIDevice.current
        let body = """


        —
        \(L.s("support_email_diagnostics"))
        App 1.0 · iOS \(device.systemVersion) · \(device.model)
        Customer ID \(settings.customerID)
        """
        let encoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let subject = L.s("support_email_subject").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:support@alcoholtracker.app?subject=\(subject)&body=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }

    private func openLanguageSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

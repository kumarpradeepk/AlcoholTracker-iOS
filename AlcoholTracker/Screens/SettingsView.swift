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
                    .font(theme.fonts.display(32))
                    .kerning(-0.5)
                    .padding(.top, 12)

                if model.pro {
                    HStack(spacing: 10) {
                        Circle().fill(theme.b1).frame(width: 8, height: 8)
                        Text(L.s("set_pro_active"))
                            .font(theme.fonts.body(13.5, .semibold))
                            .foregroundStyle(theme.b1)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(theme.surface2))
                    .padding(.top, 14)
                } else {
                    proBanner.padding(.top, 14)
                }

                section(L.s("set_section_you")) {
                    SettingsGroup {
                        SettingsRow(
                            iconTint: theme.accent, iconBackground: theme.surface2,
                            iconSystemName: "person.fill", title: L.s("set_profile"),
                            showChevron: true,
                            action: { pushTo(.profile) }
                        ) {
                            valueText(settings.profileSummary)
                        }
                        SettingsRow(
                            iconTint: theme.b1, iconBackground: theme.surface2,
                            iconSystemName: "square.fill", title: L.s("set_units"),
                            showChevron: true,
                            action: { pushTo(.units) }
                        ) {
                            valueText(settings.unitsSummary)
                        }
                        SettingsRow(
                            iconTint: theme.b2, iconBackground: theme.surface2,
                            iconSystemName: "drop.fill", title: L.s("set_guideline"),
                            showChevron: true,
                            action: { pushTo(.guideline) }
                        ) {
                            valueText(L.f("set_guideline_value", settings.dailyGoal))
                        }
                        SettingsRow(
                            iconTint: theme.accent, iconBackground: theme.surface2,
                            iconSystemName: "dollarsign", title: L.s("set_ask_cost")
                        ) {
                            AppToggle(isOn: $settings.askCost)
                        }
                        SettingsRow(
                            iconTint: theme.b2, iconBackground: theme.surface2,
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
                            iconTint: theme.b1, iconBackground: theme.surface2,
                            iconSystemName: "checkmark", title: L.s("set_auto_dry")
                        ) {
                            if !model.pro { ProBadge { model.openPaywall() } }
                            AppToggle(isOn: $settings.autoDry) {
                                if model.pro { settings.autoDry.toggle() }
                                else { model.openPaywall() }
                            }
                        }
                        SettingsRow(
                            iconTint: theme.accent, iconBackground: theme.surface2,
                            iconSystemName: "percent", title: PushScreen.bacMonitor.title,
                            showChevron: true,
                            action: {
                                if model.pro { pushTo(.bacMonitor) } else { model.openPaywall() }
                            }
                        ) {
                            if !model.pro { ProBadge() }
                        }
                        SettingsRow(
                            iconTint: theme.b2, iconBackground: theme.surface2,
                            iconSystemName: "bell.fill", title: L.s("set_notifications"),
                            showChevron: true,
                            action: { pushTo(.notifications) }
                        ) {
                            valueText(model.reminders.isEmpty
                                ? L.s("set_notif_none")
                                : L.f("set_notif_count", model.reminders.count))
                        }
                        SettingsRow(
                            iconTint: theme.b3, iconBackground: theme.b3.opacity(0.14),
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
                            iconTint: theme.muted, iconBackground: theme.surface2,
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
                        // Theme and light/dark are one destination now: three
                        // complete looks, each designed in both schemes, which a
                        // single toggle could no longer express.
                        SettingsRow(
                            iconTint: theme.muted, iconBackground: theme.surface2,
                            iconSystemName: "circle.lefthalf.filled",
                            title: L.s("set_theme"),
                            showChevron: true,
                            action: { pushTo(.theme) }
                        ) {
                            valueText(themeSummary)
                        }
                        SettingsRow(
                            iconTint: theme.accent, iconBackground: theme.surface2,
                            iconSystemName: "app", title: L.s("set_app_icon"),
                            showChevron: true,
                            action: { pushTo(.icon) }
                        ) {
                            valueText([L.s("set_icon_default"), L.s("set_icon_gift"), L.s("set_icon_holiday")][min(settings.iconIndex, 2)])
                        }
                        SettingsRow(
                            iconTint: theme.b1, iconBackground: theme.surface2,
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
                            .fill(theme.surface2)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(theme.b1)
                            )
                        VStack(alignment: .leading, spacing: 1) {
                            Text(L.s("set_backup_title"))
                                .font(theme.fonts.body(14.5, .semibold))
                            Text(BackupManager.statusDetail(lastBackupAt: settings.lastBackupAt))
                                .font(theme.fonts.body(12.5))
                                .foregroundStyle(theme.muted)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .card(radius: 20)

                    SettingsGroup {
                        SettingsRow(
                            iconTint: theme.accent, iconBackground: theme.surface2,
                            iconSystemName: "arrow.up", title: L.s("set_backup_row"),
                            showChevron: true, showDivider: false,
                            action: { pushTo(.backup) }
                        ) {
                            Text(L.s("set_backup_free"))
                                .font(theme.fonts.body(12.5, .semibold))
                                .foregroundStyle(theme.b1)
                        }
                    }
                    .padding(.top, 8)
                }

                section(L.s("set_section_privacy")) {
                    SettingsGroup {
                        SettingsRow(
                            iconTint: theme.muted, iconBackground: theme.surface2,
                            iconSystemName: "lock.fill", title: L.s("set_app_lock"),
                            subtitle: L.s("set_app_lock_sub")
                        ) {
                            AppToggle(isOn: $settings.appLock)
                        }
                        SettingsRow(
                            iconTint: theme.muted, iconBackground: theme.surface2,
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
                            iconTint: theme.muted, iconBackground: theme.surface2,
                            iconSystemName: "clock", title: L.s("set_day_ends"),
                            subtitle: L.s("set_day_ends_sub"),
                            showDivider: false,
                            action: {
                                Haptics.selection()
                                withAnimation(Motion.fade) { settings.cutoff = settings.cutoff.next }
                            }
                        ) {
                            Text(settings.cutoff.label)
                                .font(theme.fonts.body(14.5, .semibold))
                                .foregroundStyle(theme.accent)
                        }
                    }

                    toneCard.padding(.top, 8)
                }

                section(L.s("set_section_support")) {
                    SettingsGroup {
                        SettingsRow(
                            iconTint: theme.accent, iconBackground: theme.surface2,
                            iconSystemName: "envelope.fill", title: L.s("set_contact"),
                            showChevron: true,
                            action: contactSupport
                        ) { EmptyView() }
                        SettingsRow(
                            iconTint: theme.muted, iconBackground: theme.surface2,
                            iconSystemName: "info", title: L.s("set_about"),
                            showChevron: true,
                            action: { pushTo(.about) }
                        ) {
                            valueText(L.s("set_about_version_value"))
                        }
                        SettingsRow(
                            iconTint: theme.muted, iconBackground: theme.surface2,
                            iconSystemName: "number", title: L.s("set_customer_id"),
                            showDivider: false
                        ) {
                            Text(settings.customerID)
                                .font(theme.fonts.body(13))
                                .monospacedDigit()
                                .foregroundStyle(theme.faint)
                            Button(L.s("set_copy")) {
                                UIPasteboard.general.string = settings.customerID
                                model.showToast(L.s("toast_customer_id_copied"))
                            }
                            .font(theme.fonts.body(13.5, .semibold))
                            .foregroundStyle(theme.accent)
                        }
                    }
                }

                Text(L.s("set_footer"))
                    .font(theme.fonts.body(12))
                    .foregroundStyle(theme.faint)
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

    /// "Kiln · System" — the theme plus the scheme it is being shown in.
    private var themeSummary: String {
        let scheme: String
        switch settings.appearance {
        case .system: scheme = L.s("theme_scheme_system")
        case .light: scheme = L.s("theme_scheme_light")
        case .dark: scheme = L.s("theme_scheme_dark")
        }
        return "\(settings.theme.displayName) \u{00B7} \(scheme)"
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
            .font(theme.fonts.body(14))
            .foregroundStyle(theme.muted)
    }

    private var proBanner: some View {
        Button { model.openPaywall() } label: {
            HStack(spacing: 12) {
                DropletMark(size: 30, breathing: false)
                    .scaleEffect(0.62)
                    .frame(width: 30, height: 30)
                VStack(alignment: .leading, spacing: 1) {
                    Text(L.s("set_pro_banner_title"))
                        .font(theme.fonts.body(14.5, .semibold))
                        .foregroundStyle(theme.text)
                    Text(L.s("set_pro_banner_sub"))
                        .font(theme.fonts.body(12.5))
                        .foregroundStyle(theme.muted)
                }
                Spacer()
                ChevronRight()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(theme.surface2))
        }
        .buttonStyle(PressScale(scale: 0.98))
    }

    private var toneCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(theme.surface2)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text(L.s("set_tone_icon_sample"))
                            .font(theme.fonts.body(11, .bold))
                            .foregroundStyle(theme.accent)
                    )
                Text(L.s("set_tone")).font(theme.fonts.body(15.5))
            }

            SegmentedPill(
                options: Tone.allCases.map { ($0, $0.label) },
                selection: $settings.tone,
                fontSize: 13
            )
            .padding(.top, 10)

            Text(settings.tone.subCopy)
                .font(theme.fonts.body(12.5))
                .foregroundStyle(theme.faint)
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

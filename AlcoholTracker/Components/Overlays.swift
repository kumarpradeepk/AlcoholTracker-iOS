import SwiftUI

// MARK: - Toast (dark pill above the tab bar, optional Undo)

struct ToastHost: View {
    @Environment(\.theme) private var theme
    @ObservedObject var model: AppModel

    var body: some View {
        VStack {
            Spacer()
            if let toast = model.toast {
                HStack(spacing: 14) {
                    Text(toast.message)
                        .font(Fonts.text(14, .medium))
                        .foregroundStyle(theme.page)
                        .multilineTextAlignment(.center)
                    if toast.showsUndo {
                        Button(L.s("action_undo")) { model.undoLastLog() }
                            .font(Fonts.text(14, .bold))
                            .foregroundStyle(theme.amber)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 11)
                .background(
                    Capsule()
                        .fill(theme.ink)
                        .shadow(color: .black.opacity(0.25), radius: 15, y: 10)
                )
                .frame(maxWidth: 340)
                .padding(.bottom, 108)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.9)),
                    removal: .opacity
                ))
            }
        }
        .animation(Motion.pop, value: model.toast)
        .allowsHitTesting(model.toast?.showsUndo == true)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - Centered dialog (282pt card, pop-in, scrim)

struct DialogHost: View {
    @Environment(\.theme) private var theme
    @ObservedObject var model: AppModel
    @ObservedObject var settings: AppSettings

    var body: some View {
        ZStack {
            if let dialog = model.dialog {
                Color(red: 12 / 255, green: 16 / 255, blue: 18 / 255).opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { model.dialog = nil }
                    .transition(.opacity)

                dialogCard(for: dialog)
                    .frame(width: 282)
                    .padding(22)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(theme.card)
                            .shadow(color: .black.opacity(0.3), radius: 30, y: 20)
                    )
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
        }
        .animation(Motion.pop, value: model.dialog)
    }

    @ViewBuilder
    private func dialogCard(for dialog: AppDialog) -> some View {
        switch dialog {
        case .deleteEntry(let id):
            VStack(spacing: 0) {
                Text(L.s("dialog_delete_title"))
                    .font(Fonts.figure(17))
                Text(L.s("dialog_delete_body"))
                    .font(Fonts.text(13.5))
                    .foregroundStyle(theme.sub)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                HStack(spacing: 10) {
                    dialogButton(L.s("dialog_delete_keep"), fill: theme.elev, text: theme.ink) { model.dialog = nil }
                    dialogButton(L.s("dialog_delete_remove"), fill: theme.danger, text: .white) { model.deleteEntry(id: id) }
                }
                .padding(.top, 18)
            }

        case .clearAll:
            VStack(spacing: 0) {
                Text(L.s("dialog_clear_title"))
                    .font(Fonts.figure(17))
                Text(L.s("dialog_clear_body"))
                    .font(Fonts.text(13.5))
                    .foregroundStyle(theme.sub)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                HStack(spacing: 10) {
                    dialogButton(L.s("action_cancel"), fill: theme.elev, text: theme.ink) { model.dialog = nil }
                    dialogButton(L.s("dialog_clear_delete"), fill: theme.danger, text: .white) { model.clearAllData() }
                }
                .padding(.top, 18)
            }

        case .healthPermission:
            VStack(spacing: 0) {
                Text(L.f("dialog_health_title", L.s("app_name"), HealthService.name))
                    .font(Fonts.text(16, .semibold))
                    .multilineTextAlignment(.center)
                Text(L.s("sheet_health_data_sub"))
                    .font(Fonts.text(13))
                    .foregroundStyle(theme.sub)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                HStack(spacing: 10) {
                    dialogButton(L.s("dialog_health_deny"), fill: theme.elev, text: theme.ink) { model.dialog = nil }
                    dialogButton(L.s("dialog_health_allow"), fill: theme.acc, text: theme.onAcc) {
                        model.dialog = nil
                        Task {
                            let ok = await HealthSync.shared.requestAuthorization()
                            settings.healthConnected = ok
                            model.closeSheet()
                            model.showToast(ok
                                ? L.f("toast_health_connected", HealthService.name)
                                : L.s("toast_health_denied"))
                        }
                    }
                }
                .padding(.top, 18)
            }
        }
    }

    private func dialogButton(_ title: String, fill: Color, text: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Fonts.text(15, .semibold))
                .foregroundStyle(text)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Capsule().fill(fill))
        }
        .buttonStyle(PressScale(scale: 0.95))
    }
}

// MARK: - Push overlay (settings sub-screens slide in from the right)

struct PushHost<Content: View>: View {
    @Environment(\.theme) private var theme
    let title: String
    let onBack: () -> Void
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                CircleIconButton(systemName: "chevron.left", action: onBack)
                    .accessibilityLabel(L.s("a11y_back"))
                Text(title)
                    .font(Fonts.figure(20))
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 10)

            ScrollView {
                content
                    .padding(.horizontal, 18)
                    .padding(.bottom, 44)
                    .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.page.ignoresSafeArea())
        .transition(.move(edge: .trailing))
    }
}

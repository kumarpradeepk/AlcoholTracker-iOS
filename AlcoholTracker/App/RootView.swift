import SwiftUI

// MARK: - Root: phase routing, overlays, sheets, dialogs, boot, app lock

struct RootView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var settings: AppSettings
    @ObservedObject var entitlements: EntitlementStore
    @ObservedObject var appLock: AppLock

    @Environment(\.colorScheme) private var systemScheme
    @Environment(\.scenePhase) private var scenePhase

    private var theme: Theme {
        switch settings.appearance {
        case .dark: .dark
        case .light: .light
        case .system: systemScheme == .dark ? .dark : .light
        }
    }

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()

            switch model.phase {
            case .welcome: WelcomeView(model: model)
            case .goals: GoalsView(model: model, settings: settings)
            case .baseline: BaselineView(model: model, settings: settings)
            case .app: MainTabView(model: model, settings: settings)
            }

            // Settings push screens slide over everything below the paywall.
            PushRouter(model: model, settings: settings)
                .zIndex(20)

            ToastHost(model: model)
                .zIndex(30)

            DialogHost(model: model, settings: settings)
                .zIndex(40)

            if model.showBoot {
                BootOverlay()
                    .zIndex(50)
                    .transition(.opacity)
            }

            if appLock.locked {
                LockOverlay(appLock: appLock)
                    .zIndex(60)
                    .transition(.opacity)
            }
        }
        .environment(\.theme, theme)
        .tint(theme.tide)
        .foregroundStyle(theme.ink)
        .preferredColorScheme(settings.colorScheme)
        .animation(Motion.fade, value: model.phase)
        .fullScreenCover(isPresented: $model.paywallShown) {
            PaywallView(model: model, entitlements: entitlements)
                .overlay(ToastHost(model: model)) // root host is hidden behind the cover
                .environment(\.theme, theme)
                .tint(theme.tide)
                .foregroundStyle(theme.ink)
        }
        .sheet(item: $model.sheet) { sheet in
            sheetContent(sheet)
                .overlay(ToastHost(model: model)) // root host is hidden behind the sheet
                .environment(\.theme, theme)
                .tint(theme.tide)
                .foregroundStyle(theme.ink)
        }
        .task {
            // Boot splash: hold ~1s, then fade (matches the canvas timing).
            try? await Task.sleep(for: .seconds(1))
            withAnimation(.easeOut(duration: 0.6)) { model.showBoot = false }
            appLock.lockIfEnabled(settings.appLock)
            await appLock.unlock()
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                BackupManager.autoBackupIfDue(model: model)
                appLock.lockIfEnabled(settings.appLock)
            case .active:
                if appLock.locked {
                    Task { await appLock.unlock() }
                }
            default:
                break
            }
        }
    }

    @ViewBuilder
    private func sheetContent(_ sheet: AppSheet) -> some View {
        switch sheet {
        case .log:
            LogSheet(model: model, settings: settings)
        case .calendar(let dryMode):
            CalendarSheet(model: model, dryMode: dryMode)
        case .entry(let id):
            EntrySheet(model: model, settings: settings, entryID: id)
        case .unitsInfo:
            UnitsInfoSheet(model: model)
        case .bacInfo:
            BacInfoSheet()
        case .customRange:
            CustomRangeSheet(model: model)
        case .newNotification:
            NewNotificationSheet(model: model)
        case .livePreview:
            LivePreviewSheet(model: model)
        case .customDrink:
            CustomDrinkSheet(model: model)
        case .export:
            ExportSheet(model: model)
        case .health:
            HealthSheet(model: model)
        }
    }
}

// MARK: - Main tab scaffold

struct MainTabView: View {
    @Environment(\.theme) private var theme
    @ObservedObject var model: AppModel
    @ObservedObject var settings: AppSettings

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch model.tab {
                case .diary:
                    DiaryView(model: model, settings: settings)
                case .stats:
                    StatisticsView(model: model, settings: settings)
                case .settings:
                    SettingsView(model: model, settings: settings)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)

            // Scrim to collapse the FAB when tapping elsewhere.
            if model.fabOpen {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(Motion.pop) { model.fabOpen = false }
                    }
            }

            VStack(spacing: 0) {
                if model.tab == .diary {
                    HStack {
                        Spacer()
                        DiaryFab(model: model)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 12)
                }
                AppTabBar(tab: $model.tab) {
                    model.fabOpen = false
                }
            }
        }
    }
}

// MARK: - Boot overlay

struct BootOverlay: View {
    @Environment(\.theme) private var theme
    @State private var labelShown = false

    var body: some View {
        VStack(spacing: 18) {
            DropletMark(size: 46)
            Text(L.s("app_name"))
                .font(.system(size: 15, weight: .semibold))
                .kerning(0.4)
                .foregroundStyle(theme.sec)
                .opacity(labelShown ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.bg.ignoresSafeArea())
        .onAppear {
            withAnimation(.easeIn(duration: 0.8).delay(0.3)) { labelShown = true }
        }
    }
}

// MARK: - App lock overlay

struct LockOverlay: View {
    @Environment(\.theme) private var theme
    @ObservedObject var appLock: AppLock

    var body: some View {
        VStack(spacing: 20) {
            DropletMark(size: 46)
            Text(L.s("lock_title"))
                .font(.system(size: 17, weight: .semibold))
            Button {
                Task { await appLock.unlock() }
            } label: {
                Text(L.s("lock_unlock_cta"))
                    .font(.system(size: 15.5, weight: .semibold))
                    .foregroundStyle(theme.tide)
                    .padding(.horizontal, 22)
                    .frame(height: 44)
                    .background(Capsule().fill(theme.tideSoft))
            }
            .buttonStyle(PressScale(scale: 0.95))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.bg.ignoresSafeArea())
    }
}

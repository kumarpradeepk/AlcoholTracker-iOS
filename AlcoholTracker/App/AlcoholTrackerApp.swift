import SwiftData
import SwiftUI

@main
struct AlcoholTrackerApp: App {
    private let container: ModelContainer
    @StateObject private var settings: AppSettings
    @StateObject private var entitlements: EntitlementStore
    @StateObject private var model: AppModel
    @StateObject private var appLock = AppLock()

    @MainActor
    init() {
        let schema = Schema([DrinkLog.self, DryDay.self, SavedDrink.self, ReminderItem.self])
        do {
            container = try ModelContainer(for: schema)
        } catch {
            // Last resort: an in-memory store beats a crash on first frame.
            // (A tracker that loses its container must still open so the user
            // can reach export/support.)
            container = try! ModelContainer(
                for: schema,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        }

        let settings = AppSettings()
        let entitlements = EntitlementStore()
        _settings = StateObject(wrappedValue: settings)
        _entitlements = StateObject(wrappedValue: entitlements)
        _model = StateObject(wrappedValue: AppModel(
            settings: settings,
            entitlements: entitlements,
            context: ModelContext(container)
        ))
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                model: model,
                settings: settings,
                entitlements: entitlements,
                appLock: appLock
            )
        }
        .modelContainer(container)
    }
}

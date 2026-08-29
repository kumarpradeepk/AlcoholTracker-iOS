import Foundation
import HealthKit

/// Apple's own product name. It is a brand, not copy — every locale pack keeps
/// it in Latin script — so it is a constant rather than a catalog key, and it is
/// fed into the `%@` slot of the rows that name the health service.
enum HealthService {
    static let name = "Apple Health"
}

/// Writes logged drinks to Apple Health as `numberOfAlcoholicBeverages`
/// samples. Write-only — nothing is ever read. Opt-in from Settings.
@MainActor
final class HealthSync {
    static let shared = HealthSync()
    private init() {}

    private let store = HKHealthStore()

    private var beverageType: HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: .numberOfAlcoholicBeverages)
    }

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    /// Requests share authorization for alcohol-consumption samples only.
    func requestAuthorization() async -> Bool {
        guard isAvailable, let type = beverageType else { return false }
        do {
            try await store.requestAuthorization(toShare: [type], read: [])
            return true
        } catch {
            return false
        }
    }

    func writeIfConnected(log: DrinkLog, settings: AppSettings) {
        guard settings.healthConnected, isAvailable, let type = beverageType else { return }
        // Health counts "standard drinks"; our unit is exactly that (10 g).
        let quantity = HKQuantity(unit: .count(), doubleValue: log.units)
        let sample = HKQuantitySample(
            type: type,
            quantity: quantity,
            start: log.loggedAt,
            end: log.loggedAt
        )
        store.save(sample) { _, _ in }
    }
}

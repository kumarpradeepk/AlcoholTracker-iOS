import Foundation
import SwiftData

// MARK: - SwiftData models
//
// Storage rules (from Design/02-product/data-model.md):
// - A log entry snapshots name/ml/abv at save time; editing a saved drink
//   never rewrites history.
// - `loggedAt` is the instant the drink was consumed. The *drinking day* it
//   belongs to is derived at read time from the user's day-cutoff setting,
//   so changing the cutoff re-buckets history correctly.

@Model
final class DrinkLog {
    @Attribute(.unique) var id: UUID
    var name: String
    var ml: Double
    var abv: Double
    var loggedAt: Date
    var createdAt: Date
    var cost: Double
    /// Kilocalories, snapshotted with the entry (7 kcal per gram of ethanol).
    var kcal: Int

    init(
        id: UUID = UUID(),
        name: String,
        ml: Double,
        abv: Double,
        loggedAt: Date,
        createdAt: Date = .now,
        cost: Double = 0
    ) {
        self.id = id
        self.name = name
        self.ml = ml
        self.abv = abv
        self.loggedAt = loggedAt
        self.createdAt = createdAt
        self.cost = cost
        self.kcal = AlcoholMath.kcal(ml: ml, abv: abv)
    }

    var units: Double { AlcoholMath.units(ml: ml, abv: abv) }
    var gramsEthanol: Double { AlcoholMath.grams(ml: ml, abv: abv) }
}

/// A dry day is actively banked, never inferred from an absent entry.
@Model
final class DryDay {
    /// Drinking-day key: days since epoch of the *calendar day* it was banked
    /// under the cutoff in force when it was banked.
    @Attribute(.unique) var epochDay: Int
    var markedAt: Date

    init(epochDay: Int, markedAt: Date = .now) {
        self.epochDay = epochDay
        self.markedAt = markedAt
    }
}

/// A user-created drink ("YOUR DRINKS" on the log sheet; source of quick log).
@Model
final class SavedDrink {
    @Attribute(.unique) var id: UUID
    var name: String
    var base: String
    var abv: Double
    var ml: Double
    var notes: String
    /// Whether the drink is one of the up-to-four wrist quick-log slots.
    var onWatch: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        base: String,
        abv: Double,
        ml: Double,
        notes: String = "",
        onWatch: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.base = base
        self.abv = abv
        self.ml = ml
        self.notes = notes
        self.onWatch = onWatch
        self.createdAt = createdAt
    }

    var defaultCost: Double { (ml * 0.05).rounded() }
}

/// A daily reminder created on Settings → Notifications.
@Model
final class ReminderItem {
    @Attribute(.unique) var id: UUID
    var title: String
    /// Minutes after midnight, local time.
    var timeMinutes: Int
    var message: String
    var createdAt: Date

    init(id: UUID = UUID(), title: String, timeMinutes: Int, message: String = "", createdAt: Date = .now) {
        self.id = id
        self.title = title
        self.timeMinutes = timeMinutes
        self.message = message
        self.createdAt = createdAt
    }
}

import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Backup document format (versioned JSON)

struct BackupPayload: Codable {
    struct Log: Codable {
        var id: UUID
        var name: String
        var ml: Double
        var abv: Double
        var loggedAt: Date
        var cost: Double
    }

    struct Saved: Codable {
        var id: UUID
        var name: String
        var base: String
        var abv: Double
        var ml: Double
        var notes: String
        var onWatch: Bool
    }

    struct Reminder: Codable {
        var id: UUID
        var title: String
        var timeMinutes: Int
        var message: String
    }

    var schemaVersion = 1
    var exportedAt = Date()
    var logs: [Log]
    var dryDayKeys: [Int]
    var savedDrinks: [Saved]
    var reminders: [Reminder]
}

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Backup manager
//
// Backup is free and visible ("Backed up ✓ last night 02:14"), because silent
// backup failure is what destroys multi-year logs. Imports merge; duplicates
// are quietly skipped (matched by stable UUID / day key).

@MainActor
enum BackupManager {
    static func payload(model: AppModel) -> BackupPayload {
        BackupPayload(
            logs: model.logs.map {
                .init(id: $0.id, name: $0.name, ml: $0.ml, abv: $0.abv, loggedAt: $0.loggedAt, cost: $0.cost)
            },
            dryDayKeys: model.dryDays.map(\.epochDay),
            savedDrinks: model.savedDrinks.map {
                .init(id: $0.id, name: $0.name, base: $0.base, abv: $0.abv, ml: $0.ml, notes: $0.notes, onWatch: $0.onWatch)
            },
            reminders: model.reminders.map {
                .init(id: $0.id, title: $0.title, timeMinutes: $0.timeMinutes, message: $0.message)
            }
        )
    }

    static func encode(model: AppModel) -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return (try? encoder.encode(payload(model: model))) ?? Data()
    }

    /// Merge-import. Returns (imported, skipped).
    @discardableResult
    static func merge(data: Data, into model: AppModel) -> (imported: Int, skipped: Int) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let payload = try? decoder.decode(BackupPayload.self, from: data) else { return (0, 0) }

        var imported = 0
        var skipped = 0
        let existingLogIDs = Set(model.logs.map(\.id))
        let existingDry = model.dryKeys
        let existingSaved = Set(model.savedDrinks.map(\.id))
        let existingReminders = Set(model.reminders.map(\.id))

        for l in payload.logs {
            if existingLogIDs.contains(l.id) { skipped += 1; continue }
            model.context.insert(DrinkLog(id: l.id, name: l.name, ml: l.ml, abv: l.abv, loggedAt: l.loggedAt, cost: l.cost))
            imported += 1
        }
        for k in payload.dryDayKeys {
            if existingDry.contains(k) { skipped += 1; continue }
            model.context.insert(DryDay(epochDay: k))
            imported += 1
        }
        for s in payload.savedDrinks {
            if existingSaved.contains(s.id) { skipped += 1; continue }
            model.context.insert(SavedDrink(id: s.id, name: s.name, base: s.base, abv: s.abv, ml: s.ml, notes: s.notes, onWatch: s.onWatch))
            imported += 1
        }
        for r in payload.reminders {
            if existingReminders.contains(r.id) { skipped += 1; continue }
            model.context.insert(ReminderItem(id: r.id, title: r.title, timeMinutes: r.timeMinutes, message: r.message))
            imported += 1
        }

        try? model.context.save()
        model.reload()
        model.rescheduleAllReminders()
        return (imported, skipped)
    }

    // MARK: Local snapshot (the "Backed up" line)

    private static var localURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("AlcoholTracker-backup.json")
    }

    /// Writes the on-device snapshot and stamps the visible status line.
    static func createLocalBackup(model: AppModel) {
        let data = encode(model: model)
        try? data.write(to: localURL, options: .atomic)
        model.settings.lastBackupAt = Date()
    }

    /// Called when the app moves to background — at most once per day, so the
    /// status line stays honest without user effort.
    static func autoBackupIfDue(model: AppModel) {
        if let last = model.settings.lastBackupAt,
           Calendar.current.isDateInToday(last) { return }
        createLocalBackup(model: model)
    }

    static func restoreLocalBackup(model: AppModel) -> Bool {
        guard let data = try? Data(contentsOf: localURL) else { return false }
        merge(data: data, into: model)
        return true
    }

    /// The Settings row detail. Each shape is one whole format string so other
    /// grammars can reorder it, and every date goes through the locale's own
    /// formatter rather than a hardcoded 24-hour pattern.
    static func statusDetail(lastBackupAt: Date?) -> String {
        guard let lastBackupAt else {
            return L.s("set_backup_detail_never_ios")
        }
        if Calendar.current.isDateInToday(lastBackupAt) {
            return L.f("set_backup_detail_today", Formatters.clock(lastBackupAt))
        }
        if Calendar.current.isDateInYesterday(lastBackupAt) {
            return L.f("set_backup_detail_lastnight", Formatters.clock(lastBackupAt))
        }
        return L.f("set_backup_detail_dated", Formatters.dateAndTime(lastBackupAt))
    }

    /// The status line on the Backup & Restore screen itself.
    static func statusLine(lastBackupAt: Date?) -> String {
        guard let lastBackupAt else {
            return L.s("backup_status_never_ios")
        }
        if Calendar.current.isDateInToday(lastBackupAt) {
            return L.f("backup_status_today_ios", Formatters.clock(lastBackupAt))
        }
        if Calendar.current.isDateInYesterday(lastBackupAt) {
            return L.f("backup_status_lastnight_ios", Formatters.clock(lastBackupAt))
        }
        return L.f("set_backup_detail_dated", Formatters.dateAndTime(lastBackupAt))
    }
}

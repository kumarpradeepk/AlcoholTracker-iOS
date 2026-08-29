import Foundation

/// CSV export — free, every field, no account. The insurance policy against
/// every data-loss story in the research.
enum CsvExport {
    static func statisticsCSV(range: StatsRange, logsByDay: [Int: [DrinkLog]], dryKeys: Set<Int>) -> String {
        var rows: [String] = []
        rows.append("date,time,drink,ml,abv_percent,units,kcal,cost,dry_day")

        // The CSV is machine-facing: ISO dates, a dot decimal separator and the
        // Gregorian calendar, whatever the user's locale is. Without pinning
        // these a Thai or Japanese user would export Buddhist-era or Imperial
        // years and a comma decimal, and the file would not round-trip.
        let dateF = DateFormatter()
        dateF.locale = Locale(identifier: "en_US_POSIX")
        dateF.calendar = Calendar(identifier: .gregorian)
        dateF.timeZone = TimeZone.current
        dateF.dateFormat = "yyyy-MM-dd"
        let timeF = DateFormatter()
        timeF.locale = Locale(identifier: "en_US_POSIX")
        timeF.calendar = Calendar(identifier: .gregorian)
        timeF.timeZone = TimeZone.current
        timeF.dateFormat = "HH:mm"

        for key in range.fromKey ... range.toKey {
            let day = DrinkingDay.date(for: key)
            let logs = (logsByDay[key] ?? []).sorted { $0.loggedAt < $1.loggedAt }
            if logs.isEmpty {
                if dryKeys.contains(key) {
                    rows.append("\(dateF.string(from: day)),,,,,,,,yes")
                }
                continue
            }
            for r in logs {
                rows.append([
                    dateF.string(from: day),
                    timeF.string(from: r.loggedAt),
                    escape(r.name),
                    String(Int(r.ml)),
                    String(format: "%g", locale: Locale(identifier: "en_US_POSIX"), r.abv),
                    String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), r.units),
                    String(r.kcal),
                    String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), r.cost),
                    "no",
                ].joined(separator: ","))
            }
        }

        rows.append("")
        rows.append("total_ml,total_units,total_spend,total_kcal,dry_days")
        rows.append([
            String(Int(range.totalMl)),
            String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), range.totalUnits),
            String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), range.totalSpend),
            String(range.totalKcal),
            String(range.dryCount),
        ].joined(separator: ","))

        return rows.joined(separator: "\n")
    }

    /// Writes the CSV to a temp file named exactly as the export sheet shows.
    static func writeTemp(csv: String, fileName: String) -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)
        do {
            try csv.data(using: .utf8)?.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    private static func escape(_ field: String) -> String {
        field.contains(",") || field.contains("\"")
            ? "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
            : field
    }
}

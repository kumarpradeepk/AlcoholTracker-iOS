import Foundation
import UserNotifications

/// Schedules the user's daily reminders.
///
/// Discretion by default (brief P8): when "Discreet notifications" is on,
/// lock-screen copy never names alcohol — the user's own title/message are
/// replaced with neutral check-in copy.
final class ReminderScheduler {
    static let shared = ReminderScheduler()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    func requestPermission() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func schedule(reminders: [ReminderItem], discreet: Bool) {
        center.removeAllPendingNotificationRequests()
        for item in reminders {
            let content = UNMutableNotificationContent()
            if discreet {
                content.title = L.s("notif_discreet_title")
                content.body = L.s("notif_discreet_body")
            } else {
                content.title = item.title
                content.body = item.message.isEmpty ? L.s("notif_reminder_body_fallback") : item.message
            }
            content.sound = .default

            var components = DateComponents()
            components.hour = item.timeMinutes / 60
            components.minute = item.timeMinutes % 60
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

            center.add(UNNotificationRequest(
                identifier: item.id.uuidString,
                content: content,
                trigger: trigger
            ))
        }
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Ongoing BAC status (punch list B5 — safety-relevant)
    //
    // The lock screen truncates from the end. German, Turkish, Polish and
    // Danish each independently rewrote `notif_bac_body` to front the negation,
    // which is four translators working around the same engineering defect.
    // The ordering is guaranteed here instead, so translators can write
    // naturally: the never-drive sentence is emitted first and the countdown
    // second, and the countdown drops out entirely once the two together would
    // not survive a single lock-screen line.
    //
    // The title has the same shape of problem. Korean 추정, Thai ค่าประมาณ and
    // Japanese 推定 lead their line, but French *estimée*, Spanish *estimada*,
    // Italian *stimato* and Portuguese *estimado* all follow the noun, so
    // "front the word" is not a rule that can hold across the programme. The
    // hedge phrase is therefore given a line of its own — the short feature
    // name goes in `title`, `notif_bac_title` in `subtitle` — and if even that
    // line would run long, the figure is dropped rather than the hedge.

    /// Characters a lock-screen notification reliably shows before it
    /// ellipsises. Deliberately conservative; the point is the ordering, not a
    /// pixel-accurate fit.
    static let lockScreenBodyBudget = 92
    static let lockScreenTitleBudget = 34

    /// Content for the ongoing estimate card.
    ///
    /// - Parameters:
    ///   - formattedValue: the BAC figure with its unit, already localized.
    ///   - timeToZero: e.g. "3h 42m", already localized.
    ///   - discreet: when on, nothing may name alcohol.
    static func bacContent(
        formattedValue: String,
        timeToZero: String,
        discreet: Bool
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()

        if discreet {
            content.title = L.s("notif_bac_discreet_title")
            content.body = L.f("notif_bac_discreet_body", timeToZero)
            return content
        }

        content.title = L.s("bac_monitor")
        let withFigure = L.f("notif_bac_title", formattedValue)
        content.subtitle = withFigure.count <= lockScreenTitleBudget
            ? withFigure
            : L.f("notif_bac_title", "").trimmingCharacters(in: .whitespacesAndNewlines)

        // Negation first: a cut line still carries the warning, and the
        // countdown drops out entirely before the sentence can be clipped.
        let neverDrive = L.s("bac_disclaimer_short")
        let countdown = L.f("notif_bac_discreet_body", timeToZero)
        let combined = neverDrive + " " + countdown
        content.body = combined.count <= lockScreenBodyBudget ? combined : neverDrive
        return content
    }
}

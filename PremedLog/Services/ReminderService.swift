import Foundation
import UserNotifications

/// Weekly local "Log your shift?" reminders.
enum ReminderService {
    static let enabledKey = "reminders.enabled"
    static let timeKey = "reminders.time"          // seconds since midnight
    static let weekdaysKey = "reminders.weekdays"  // e.g. "2,4,6" (1 = Sunday … 7 = Saturday)

    static let defaultTime: Double = 19 * 3600     // 7:00 PM
    static let defaultWeekdays = "2,4,6"

    private static let idPrefix = "premedlog.reminder."

    static func parseWeekdays(_ string: String) -> Set<Int> {
        Set(string.split(separator: ",").compactMap { Int($0) }.filter { (1...7).contains($0) })
    }

    static func encodeWeekdays(_ set: Set<Int>) -> String {
        set.sorted().map(String.init).joined(separator: ",")
    }

    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        return granted ?? false
    }

    static func schedule(weekdays: Set<Int>, secondsSinceMidnight: Double) {
        let center = UNUserNotificationCenter.current()
        cancelAll()
        let hour = Int(secondsSinceMidnight) / 3600
        let minute = (Int(secondsSinceMidnight) % 3600) / 60

        for weekday in weekdays {
            let content = UNMutableNotificationContent()
            content.title = "Log your shift?"
            content.body = "Took 10 seconds last time. Add your hours and one quick reflection while it's fresh."
            content.sound = .default

            var components = DateComponents()
            components.weekday = weekday
            components.hour = hour
            components.minute = minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: idPrefix + String(weekday), content: content, trigger: trigger)
            center.add(request)
        }
    }

    static func cancelAll() {
        let ids = (1...7).map { idPrefix + String($0) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
}

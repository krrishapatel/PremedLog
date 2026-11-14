import Foundation

enum Goals {
    static func goal(for group: CategoryGroup, defaults: UserDefaults = .standard) -> Double {
        defaults.object(forKey: group.goalKey) as? Double ?? group.defaultGoal
    }

    static func set(_ value: Double, for group: CategoryGroup, defaults: UserDefaults = .standard) {
        defaults.set(value, forKey: group.goalKey)
    }
}

enum Stats {
    static func totalHours(_ activities: [Activity]) -> Double {
        activities.reduce(0) { $0 + $1.totalHours }
    }

    static func hours(in group: CategoryGroup, activities: [Activity]) -> Double {
        activities.filter { $0.type.group == group }.reduce(0) { $0 + $1.totalHours }
    }

    static func hoursThisWeek(_ entries: [LogEntry], calendar: Calendar = .current, now: Date = .now) -> Double {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else { return 0 }
        return entries.filter { week.contains($0.date) }.reduce(0) { $0 + $1.hours }
    }

    /// Consecutive calendar weeks with at least one log. The current week counts if logged;
    /// if not, the streak is still "alive" from last week until the week ends.
    static func weekStreak(_ entries: [LogEntry], calendar: Calendar = .current, now: Date = .now) -> Int {
        let weekStarts = Set(entries.compactMap { calendar.dateInterval(of: .weekOfYear, for: $0.date)?.start })
        guard var cursor = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return 0 }
        if !weekStarts.contains(cursor) {
            guard let previous = calendar.date(byAdding: .weekOfYear, value: -1, to: cursor) else { return 0 }
            cursor = previous
        }
        var streak = 0
        while weekStarts.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .weekOfYear, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }
}

enum ReflectionPrompts {
    static let general = [
        "What's one patient interaction you'll remember?",
        "What surprised you today?",
        "What did you learn about teamwork today?",
        "When did you feel most useful?",
        "What was hard today, and how did you handle it?",
        "What did someone teach you today?",
        "Did anything challenge your assumptions?",
        "What would you tell a friend about today?",
        "What skill did you practice or improve?",
        "How did today connect to why you want to be a doctor?"
    ]

    static func random(excluding current: String? = nil) -> String {
        let pool = general.filter { $0 != current }
        return pool.randomElement() ?? general[0]
    }
}

import Foundation
import WidgetKit

/// Writes a JSON snapshot into the shared App Group container and reloads widgets.
enum SnapshotService {
    static func update(activities: [Activity], isPro: Bool) {
        let entries = activities.flatMap(\.entries)
        let categories = CategoryGroup.allCases
            .filter { $0 != .other }
            .map { group in
                WidgetSnapshot.Category(
                    group: group.rawValue,
                    hours: Stats.hours(in: group, activities: activities),
                    goal: Goals.goal(for: group)
                )
            }
        let snapshot = WidgetSnapshot(
            totalHours: Stats.totalHours(activities),
            categories: categories,
            weekStreak: Stats.weekStreak(entries),
            activityCount: activities.filter { !$0.isArchived }.count,
            isPro: isPro,
            updatedAt: .now
        )
        SharedStore.write(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

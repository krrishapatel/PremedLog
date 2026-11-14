import Foundation
import SwiftUI

// Code shared between the app and the widget extension.

/// The five buckets admissions committees (and students) actually think in.
enum CategoryGroup: String, CaseIterable, Codable, Identifiable {
    case clinical
    case shadowing
    case volunteering
    case research
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clinical: return "Clinical"
        case .shadowing: return "Shadowing"
        case .volunteering: return "Volunteering"
        case .research: return "Research"
        case .other: return "Other"
        }
    }

    var subtitle: String {
        switch self {
        case .clinical: return "Patient-facing work"
        case .shadowing: return "Physician observation"
        case .volunteering: return "Non-clinical service"
        case .research: return "Lab & research"
        case .other: return "Leadership, teaching & more"
        }
    }

    var symbol: String {
        switch self {
        case .clinical: return "cross.case.fill"
        case .shadowing: return "stethoscope"
        case .volunteering: return "heart.fill"
        case .research: return "testtube.2"
        case .other: return "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .clinical: return Color(red: 0.05, green: 0.62, blue: 0.60)
        case .shadowing: return Color(red: 0.36, green: 0.33, blue: 0.85)
        case .volunteering: return Color(red: 0.93, green: 0.42, blue: 0.40)
        case .research: return Color(red: 0.62, green: 0.38, blue: 0.86)
        case .other: return Color(red: 0.95, green: 0.62, blue: 0.20)
        }
    }

    /// Typical competitive targets. Research defaults to 0 = "optional / no goal".
    var defaultGoal: Double {
        switch self {
        case .clinical: return 150
        case .shadowing: return 50
        case .volunteering: return 100
        case .research: return 0
        case .other: return 0
        }
    }

    var goalKey: String { "goal.\(rawValue)" }
}

/// A small, Codable summary the app writes into the App Group container for the widget.
struct WidgetSnapshot: Codable {
    struct Category: Codable, Identifiable {
        var id: String { group }
        let group: String
        let hours: Double
        let goal: Double

        var categoryGroup: CategoryGroup { CategoryGroup(rawValue: group) ?? .other }
        var progress: Double { goal > 0 ? min(hours / goal, 1) : 0 }
    }

    var totalHours: Double
    var categories: [Category]
    var weekStreak: Int
    var activityCount: Int
    var isPro: Bool
    var updatedAt: Date

    static let placeholder = WidgetSnapshot(
        totalHours: 412.5,
        categories: [
            .init(group: CategoryGroup.clinical.rawValue, hours: 186, goal: 150),
            .init(group: CategoryGroup.shadowing.rawValue, hours: 38, goal: 50),
            .init(group: CategoryGroup.volunteering.rawValue, hours: 72, goal: 100),
            .init(group: CategoryGroup.research.rawValue, hours: 116.5, goal: 0)
        ],
        weekStreak: 6,
        activityCount: 7,
        isPro: true,
        updatedAt: .now
    )

    static let empty = WidgetSnapshot(totalHours: 0, categories: [], weekStreak: 0, activityCount: 0, isPro: false, updatedAt: .now)
}

enum SharedStore {
    static let appGroupID = "group.com.premedlog.shared"
    private static let fileName = "widget-snapshot.json"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    static var snapshotURL: URL? {
        containerURL?.appendingPathComponent(fileName)
    }

    static func write(_ snapshot: WidgetSnapshot) {
        guard let url = snapshotURL else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(snapshot) {
            try? data.write(to: url, options: .atomic)
        }
    }

    static func read() -> WidgetSnapshot? {
        guard let url = snapshotURL, let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(WidgetSnapshot.self, from: data)
    }
}

extension Double {
    /// "12", "12.5", "1,204" – hours formatted for display.
    var hoursText: String {
        formatted(.number.precision(.fractionLength(0...1)))
    }
}

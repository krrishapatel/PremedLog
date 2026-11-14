import Foundation
import SwiftData
import SwiftUI

@Model
final class Activity {
    var uuid: UUID = UUID()
    var title: String = ""
    var typeRaw: String = ExperienceType.other.rawValue
    var organization: String = ""
    var city: String = ""
    var state: String = ""

    var contactName: String = ""
    var contactTitle: String = ""
    var contactEmail: String = ""
    var contactPhone: String = ""

    var startDate: Date = Date.now
    /// `nil` means the experience is ongoing.
    var endDate: Date?
    var hoursGoal: Double?

    var isMostMeaningful: Bool = false
    var colorName: String = ActivityColor.teal.rawValue
    var isArchived: Bool = false
    var createdAt: Date = Date.now

    /// AMCAS "Experience Description" (700 characters).
    var amcasDescription: String = ""
    /// AMCAS "Most Meaningful Experience" remarks (1325 characters, only if most meaningful).
    var meaningfulEssay: String = ""

    @Relationship(deleteRule: .cascade, inverse: \LogEntry.activity)
    var entries: [LogEntry] = []

    init(
        title: String,
        type: ExperienceType,
        organization: String = "",
        city: String = "",
        state: String = "",
        contactName: String = "",
        contactTitle: String = "",
        contactEmail: String = "",
        contactPhone: String = "",
        startDate: Date = .now,
        endDate: Date? = nil,
        hoursGoal: Double? = nil,
        isMostMeaningful: Bool = false,
        color: ActivityColor = .teal
    ) {
        self.uuid = UUID()
        self.title = title
        self.typeRaw = type.rawValue
        self.organization = organization
        self.city = city
        self.state = state
        self.contactName = contactName
        self.contactTitle = contactTitle
        self.contactEmail = contactEmail
        self.contactPhone = contactPhone
        self.startDate = startDate
        self.endDate = endDate
        self.hoursGoal = hoursGoal
        self.isMostMeaningful = isMostMeaningful
        self.colorName = color.rawValue
        self.createdAt = .now
    }

    // MARK: - Computed

    var type: ExperienceType {
        get { ExperienceType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }

    var activityColor: ActivityColor {
        get { ActivityColor(rawValue: colorName) ?? .teal }
        set { colorName = newValue.rawValue }
    }

    var color: Color { activityColor.color }

    var isOngoing: Bool { endDate == nil }

    var totalHours: Double { entries.reduce(0) { $0 + $1.hours } }

    var lastLoggedDate: Date? { entries.map(\.date).max() }

    var sortedEntries: [LogEntry] { entries.sorted { $0.date > $1.date } }

    var memorableEntries: [LogEntry] { sortedEntries.filter(\.isMemorable) }

    var locationText: String {
        [city, state].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    var dateRangeText: String {
        let f = Date.FormatStyle().month(.abbreviated).year()
        let start = startDate.formatted(f)
        let end = endDate.map { $0.formatted(f) } ?? "Present"
        return "\(start) – \(end)"
    }

    /// AMCAS uses MM/YYYY.
    var amcasDateRangeText: String {
        let f = DateFormatter()
        f.dateFormat = "MM/yyyy"
        let start = f.string(from: startDate)
        let end = endDate.map { f.string(from: $0) } ?? "Present (anticipated)"
        return "\(start) – \(end)"
    }

    var hasContact: Bool {
        !(contactName.isEmpty && contactEmail.isEmpty && contactPhone.isEmpty)
    }
}

enum ActivityColor: String, CaseIterable, Identifiable {
    case teal, indigo, blue, purple, pink, red, orange, green, mint

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .teal: return Color(red: 0.05, green: 0.62, blue: 0.60)
        case .indigo: return Color(red: 0.36, green: 0.33, blue: 0.85)
        case .blue: return Color(red: 0.16, green: 0.50, blue: 0.93)
        case .purple: return Color(red: 0.62, green: 0.38, blue: 0.86)
        case .pink: return Color(red: 0.93, green: 0.35, blue: 0.60)
        case .red: return Color(red: 0.93, green: 0.42, blue: 0.40)
        case .orange: return Color(red: 0.95, green: 0.62, blue: 0.20)
        case .green: return Color(red: 0.30, green: 0.72, blue: 0.40)
        case .mint: return Color(red: 0.25, green: 0.78, blue: 0.70)
        }
    }
}

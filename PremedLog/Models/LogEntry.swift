import Foundation
import SwiftData

@Model
final class LogEntry {
    var uuid: UUID = UUID()
    var date: Date = Date.now
    var hours: Double = 0
    /// Free-form reflection. This is the raw material for AMCAS descriptions later.
    var note: String = ""
    /// "Memorable moment" star — these surface first when drafting descriptions.
    var isMemorable: Bool = false
    var createdAt: Date = Date.now

    var activity: Activity?

    init(date: Date, hours: Double, note: String = "", isMemorable: Bool = false, activity: Activity? = nil) {
        self.uuid = UUID()
        self.date = date
        self.hours = hours
        self.note = note
        self.isMemorable = isMemorable
        self.createdAt = .now
        self.activity = activity
    }

    var hasNote: Bool { !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}

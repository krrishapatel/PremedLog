import Foundation
import Observation

/// A running "shift" for one activity. The start time is persisted in UserDefaults,
/// so the timer survives the app being killed or the phone restarting.
@Observable
final class ShiftTimer {
    private static let startKey = "shift.startDate"
    private static let activityKey = "shift.activityID"

    private(set) var startDate: Date?
    private(set) var activityID: UUID?

    struct Result {
        let activityID: UUID
        let start: Date
        let hours: Double
    }

    init(defaults: UserDefaults = .standard) {
        if let start = defaults.object(forKey: Self.startKey) as? Date,
           let idString = defaults.string(forKey: Self.activityKey),
           let id = UUID(uuidString: idString) {
            startDate = start
            activityID = id
        }
    }

    var isRunning: Bool { startDate != nil && activityID != nil }

    func start(activityID: UUID, at date: Date = .now) {
        startDate = date
        self.activityID = activityID
        UserDefaults.standard.set(date, forKey: Self.startKey)
        UserDefaults.standard.set(activityID.uuidString, forKey: Self.activityKey)
    }

    /// Stops the timer and returns elapsed hours rounded to the nearest half hour (min 0.5).
    func stop(at date: Date = .now) -> Result? {
        defer { clear() }
        guard let start = startDate, let id = activityID else { return nil }
        let raw = date.timeIntervalSince(start) / 3600
        let rounded = max(0.5, (raw * 2).rounded() / 2)
        return Result(activityID: id, start: start, hours: rounded)
    }

    func cancel() { clear() }

    private func clear() {
        startDate = nil
        activityID = nil
        UserDefaults.standard.removeObject(forKey: Self.startKey)
        UserDefaults.standard.removeObject(forKey: Self.activityKey)
    }
}

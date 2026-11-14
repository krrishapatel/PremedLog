import Foundation
import Observation

enum AppTab: String, Hashable, CaseIterable {
    case dashboard, activities, application, settings
}

/// Request to open the quick-log sheet, optionally prefilled (e.g. from the shift timer).
struct QuickLogRequest: Identifiable {
    let id = UUID()
    var activityID: UUID?
    var hours: Double?
    var date: Date?
}

@Observable
final class AppState {
    var selectedTab: AppTab
    var quickLog: QuickLogRequest?
    var showPaywall = false

    init() {
        selectedTab = LaunchOptions.initialTab ?? .dashboard
        showPaywall = LaunchOptions.showPaywall
        if LaunchOptions.arguments.contains("-quickLog") { quickLog = QuickLogRequest() }
    }

    func openQuickLog(activityID: UUID? = nil, hours: Double? = nil, date: Date? = nil) {
        quickLog = QuickLogRequest(activityID: activityID, hours: hours, date: date)
    }

    func handle(url: URL) {
        guard url.scheme == "premedlog" else { return }
        switch url.host {
        case "log": openQuickLog()
        case "application": selectedTab = .application
        case "activities": selectedTab = .activities
        default: selectedTab = .dashboard
        }
    }
}

/// Free tier limits.
enum Limits {
    static let freeActivityCount = 5
    static let maxMostMeaningful = 3
    static let amcasMaxExperiences = 15
    static let descriptionLimit = 700
    static let meaningfulLimit = 1325
}

/// Launch arguments, mostly for screenshots/debugging.
///   -sampleData           replace all data with sample data on launch
///   -tab <name>           dashboard | activities | application | settings
///   -pro                  (DEBUG only) unlock Pro without a purchase
///   -paywall              open the paywall on launch
///   -quickLog             open the quick-log sheet on launch
///   -openFirst            push the first activity detail / AMCAS entry on the selected tab
enum LaunchOptions {
    static var arguments: [String] { ProcessInfo.processInfo.arguments }

    static var sampleData: Bool { arguments.contains("-sampleData") }
    static var showPaywall: Bool { arguments.contains("-paywall") }
    static var openFirst: Bool { arguments.contains("-openFirst") }

    static var forcePro: Bool {
        #if DEBUG
        return arguments.contains("-pro")
        #else
        return false
        #endif
    }

    static func value(after flag: String) -> String? {
        guard let i = arguments.firstIndex(of: flag), i + 1 < arguments.count else { return nil }
        return arguments[i + 1]
    }

    static var initialTab: AppTab? {
        value(after: "-tab").flatMap { AppTab(rawValue: $0.lowercased()) }
    }
}

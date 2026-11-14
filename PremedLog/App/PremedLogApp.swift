import SwiftUI
import SwiftData

@main
struct PremedLogApp: App {
    let container: ModelContainer
    @State private var appState = AppState()
    @State private var entitlements = EntitlementManager()
    @State private var shiftTimer = ShiftTimer()

    init() {
        do {
            container = try ModelContainer(for: Activity.self, LogEntry.self)
        } catch {
            fatalError("Could not create the data store: \(error)")
        }
        if LaunchOptions.sampleData {
            UserDefaults.standard.set(true, forKey: "hasOnboarded")
            let container = self.container
            MainActor.assumeIsolated {
                SampleData.load(into: container.mainContext, replacing: true)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(entitlements)
                .environment(shiftTimer)
                .task {
                    await entitlements.refreshEntitlements()
                    await entitlements.loadProducts()
                }
                .onOpenURL { appState.handle(url: $0) }
        }
        .modelContainer(container)
    }
}

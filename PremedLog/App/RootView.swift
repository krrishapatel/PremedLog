import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(EntitlementManager.self) private var entitlements
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    @Query private var activities: [Activity]
    @Query private var entries: [LogEntry]

    // Observed so goal changes refresh the widget snapshot.
    @AppStorage(CategoryGroup.clinical.goalKey) private var clinicalGoal = CategoryGroup.clinical.defaultGoal
    @AppStorage(CategoryGroup.shadowing.goalKey) private var shadowingGoal = CategoryGroup.shadowing.defaultGoal
    @AppStorage(CategoryGroup.volunteering.goalKey) private var volunteeringGoal = CategoryGroup.volunteering.defaultGoal
    @AppStorage(CategoryGroup.research.goalKey) private var researchGoal = CategoryGroup.research.defaultGoal

    var body: some View {
        @Bindable var appState = appState

        TabView(selection: $appState.selectedTab) {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "chart.pie.fill") }
                .tag(AppTab.dashboard)
            ActivitiesView()
                .tabItem { Label("Activities", systemImage: "list.bullet.rectangle.portrait.fill") }
                .tag(AppTab.activities)
            ApplicationView()
                .tabItem { Label("AMCAS", systemImage: "doc.text.fill") }
                .tag(AppTab.application)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
        .sheet(item: $appState.quickLog) { request in
            QuickLogView(request: request)
        }
        .sheet(isPresented: $appState.showPaywall) {
            PaywallView()
        }
        .fullScreenCover(isPresented: Binding(get: { !hasOnboarded }, set: { hasOnboarded = !$0 })) {
            OnboardingView { hasOnboarded = true }
        }
        .onAppear(perform: updateSnapshot)
        .onChange(of: snapshotSignature) { updateSnapshot() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { updateSnapshot() }
        }
    }

    private var snapshotSignature: String {
        let total = entries.reduce(0) { $0 + $1.hours }
        return "\(activities.count)|\(entries.count)|\(total)|\(entitlements.isPro)|\(clinicalGoal)|\(shadowingGoal)|\(volunteeringGoal)|\(researchGoal)"
    }

    private func updateSnapshot() {
        SnapshotService.update(activities: activities, isPro: entitlements.isPro)
    }
}

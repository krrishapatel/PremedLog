import SwiftUI
import SwiftData

struct ActivitiesView: View {
    @Environment(AppState.self) private var appState
    @Environment(EntitlementManager.self) private var entitlements
    @Query(sort: \Activity.createdAt) private var activities: [Activity]

    @State private var showingNew = false
    @State private var showArchived = false
    @State private var path = NavigationPath()
    @State private var didOpenFirst = false

    private var active: [Activity] { activities.filter { !$0.isArchived } }
    private var archived: [Activity] { activities.filter(\.isArchived) }

    private var grouped: [(ExperienceType, [Activity])] {
        Dictionary(grouping: active, by: \.type)
            .map { ($0.key, $0.value.sorted { $0.totalHours > $1.totalHours }) }
            .sorted { $0.0.sortIndex < $1.0.sortIndex }
    }

    private var canAdd: Bool { entitlements.isPro || activities.count < Limits.freeActivityCount }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if activities.isEmpty {
                    EmptyStateView(symbol: "list.bullet.rectangle.portrait",
                                   title: "No activities yet",
                                   message: "Add the clinical, shadowing, volunteering and research experiences you want to track.",
                                   actionTitle: "Add activity") { addTapped() }
                } else {
                    list
                }
            }
            .background(Theme.background)
            .navigationTitle("Activities")
            .navigationDestination(for: PersistentIdentifier.self) { id in
                if let activity = activities.first(where: { $0.persistentModelID == id }) {
                    ActivityDetailView(activity: activity)
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: addTapped) { Image(systemName: "plus") }
                        .accessibilityLabel("Add activity")
                }
            }
            .sheet(isPresented: $showingNew) { ActivityEditView() }
            .onAppear {
                if LaunchOptions.openFirst, !didOpenFirst, let first = grouped.first?.1.first {
                    didOpenFirst = true
                    path.append(first.persistentModelID)
                }
            }
        }
    }

    private var list: some View {
        List {
            if !entitlements.isPro {
                Section {
                    HStack {
                        Image(systemName: "square.stack.3d.up.fill").foregroundStyle(Theme.indigo)
                        Text("\(activities.count) of \(Limits.freeActivityCount) free activities")
                            .font(.subheadline)
                        Spacer()
                        Button("Go Pro") { appState.showPaywall = true }
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
            ForEach(grouped, id: \.0) { type, items in
                Section {
                    ForEach(items) { activity in
                        NavigationLink(value: activity.persistentModelID) {
                            ActivityRow(activity: activity)
                        }
                    }
                } header: {
                    Label(type.shortName, systemImage: type.symbol)
                }
            }
            if !archived.isEmpty {
                Section {
                    DisclosureGroup("Archived (\(archived.count))", isExpanded: $showArchived) {
                        ForEach(archived) { activity in
                            NavigationLink(value: activity.persistentModelID) {
                                ActivityRow(activity: activity).opacity(0.7)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func addTapped() {
        if canAdd { showingNew = true } else { appState.showPaywall = true }
    }
}

struct ActivityRow: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: 12) {
            ActivityIcon(symbol: activity.type.symbol, color: activity.color)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(activity.title).font(.body.weight(.semibold)).lineLimit(1)
                    if activity.isMostMeaningful {
                        Image(systemName: "star.fill").font(.caption).foregroundStyle(.yellow)
                            .accessibilityLabel("Most meaningful")
                    }
                }
                Text(activity.organization.isEmpty ? activity.dateRangeText : activity.organization)
                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 0) {
                Text(activity.totalHours.hoursText)
                    .font(.headline).monospacedDigit()
                Text("hours").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

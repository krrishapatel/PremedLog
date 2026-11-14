import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(ShiftTimer.self) private var shiftTimer

    @Query(sort: \Activity.createdAt) private var activities: [Activity]
    @Query(sort: \LogEntry.date, order: .reverse) private var entries: [LogEntry]

    @AppStorage(CategoryGroup.clinical.goalKey) private var clinicalGoal = CategoryGroup.clinical.defaultGoal
    @AppStorage(CategoryGroup.shadowing.goalKey) private var shadowingGoal = CategoryGroup.shadowing.defaultGoal
    @AppStorage(CategoryGroup.volunteering.goalKey) private var volunteeringGoal = CategoryGroup.volunteering.defaultGoal
    @AppStorage(CategoryGroup.research.goalKey) private var researchGoal = CategoryGroup.research.defaultGoal

    @ScaledMetric(relativeTo: .largeTitle) private var heroSize: CGFloat = 60

    private var activeActivities: [Activity] { activities.filter { !$0.isArchived } }
    private var totalHours: Double { Stats.totalHours(activities) }
    private var streak: Int { Stats.weekStreak(entries) }

    private func goal(for group: CategoryGroup) -> Double {
        switch group {
        case .clinical: return clinicalGoal
        case .shadowing: return shadowingGoal
        case .volunteering: return volunteeringGoal
        case .research: return researchGoal
        case .other: return 0
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    heroCard
                    logButton
                    ShiftTimerCard(activities: activeActivities)
                    categorySection
                    recentSection
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Theme.background)
            .navigationTitle("PremedLog")
        }
    }

    // MARK: Hero

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Total hours")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                    Text(streak == 1 ? "1-week streak" : "\(streak)-week streak")
                }
                .font(.caption.weight(.bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.white.opacity(0.2), in: Capsule())
                .foregroundStyle(.white)
            }
            Text(totalHours.hoursText)
                .font(.system(size: heroSize, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            HStack(spacing: 16) {
                heroStat(value: Stats.hoursThisWeek(entries).hoursText, label: "this week")
                heroStat(value: "\(activeActivities.count)", label: activeActivities.count == 1 ? "activity" : "activities")
                heroStat(value: "\(entries.filter(\.hasNote).count)", label: "reflections")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Theme.indigo.opacity(0.25), radius: 16, y: 8)
        .padding(.top, 8)
    }

    private func heroStat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value).font(.headline).monospacedDigit()
            Text(label).font(.caption)
        }
        .foregroundStyle(.white.opacity(0.92))
    }

    private var logButton: some View {
        Button {
            appState.openQuickLog()
        } label: {
            Label("Log hours", systemImage: "plus.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: 16))
        .controlSize(.large)
    }

    // MARK: Categories

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Goals")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(CategoryGroup.allCases) { group in
                    CategoryCard(group: group,
                                 hours: Stats.hours(in: group, activities: activities),
                                 goal: goal(for: group))
                }
            }
        }
    }

    // MARK: Recent

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Recent", trailing: entries.isEmpty ? nil : "\(entries.count) entries")
            if entries.isEmpty {
                EmptyStateView(symbol: "clock.badge.checkmark",
                               title: "No hours yet",
                               message: "Log your first shift — it takes about ten seconds.")
                    .card()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(entries.prefix(5).enumerated()), id: \.element.persistentModelID) { index, entry in
                        if let activity = entry.activity {
                            NavigationLink {
                                ActivityDetailView(activity: activity)
                            } label: {
                                EntryRow(entry: entry)
                                    .padding(.vertical, 10)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        } else {
                            EntryRow(entry: entry).padding(.vertical, 10)
                        }
                        if index < min(entries.count, 5) - 1 { Divider() }
                    }
                }
                .card(padding: 14)
            }
        }
    }
}

struct CategoryCard: View {
    let group: CategoryGroup
    let hours: Double
    let goal: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: group.symbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(group.color)
                Text(group.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(hours.hoursText)
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .monospacedDigit()
                    Text(goal > 0 ? "of \(goal.hoursText) h" : "hours")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                if goal > 0 {
                    ZStack {
                        ProgressRing(progress: hours / goal, color: group.color, lineWidth: 6)
                        if hours >= goal {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(group.color)
                        } else {
                            Text("\(Int((hours / goal * 100).rounded()))%")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 44, height: 44)
                }
            }
        }
        .card(padding: 14)
        .accessibilityElement(children: .combine)
    }
}

struct ShiftTimerCard: View {
    @Environment(AppState.self) private var appState
    @Environment(ShiftTimer.self) private var shiftTimer
    let activities: [Activity]

    private var runningActivity: Activity? {
        guard let id = shiftTimer.activityID else { return nil }
        return activities.first { $0.uuid == id }
    }

    var body: some View {
        if shiftTimer.isRunning, let start = shiftTimer.startDate {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color.red.opacity(0.15)).frame(width: 44, height: 44)
                    Image(systemName: "record.circle").foregroundStyle(.red).font(.title3)
                        .symbolEffect(.pulse)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(runningActivity?.title ?? "Shift in progress")
                        .font(.subheadline.weight(.semibold)).lineLimit(1)
                    Text(start, style: .timer)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .monospacedDigit()
                }
                Spacer()
                Menu {
                    Button("Discard shift", systemImage: "trash", role: .destructive) { shiftTimer.cancel() }
                } label: {
                    Image(systemName: "ellipsis.circle").font(.title3).foregroundStyle(.secondary)
                }
                Button("Stop") {
                    if let result = shiftTimer.stop() {
                        appState.openQuickLog(activityID: result.activityID, hours: result.hours, date: result.start)
                    }
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(.red)
            }
            .card()
        } else {
            Menu {
                ForEach(activities.sorted { ($0.lastLoggedDate ?? .distantPast) > ($1.lastLoggedDate ?? .distantPast) }) { activity in
                    Button(activity.title, systemImage: activity.type.symbol) {
                        shiftTimer.start(activityID: activity.uuid)
                    }
                }
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(Theme.indigo.opacity(0.15)).frame(width: 44, height: 44)
                        Image(systemName: "timer").foregroundStyle(Theme.indigo).font(.title3)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Start a shift timer").font(.subheadline.weight(.semibold))
                        Text("Stop when you leave — hours fill in for you.")
                            .font(.caption).foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                    Image(systemName: "play.circle.fill").font(.title).foregroundStyle(Theme.indigo)
                }
                .card()
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .disabled(activities.isEmpty)
        }
    }
}

import SwiftUI
import SwiftData

/// "AMCAS Builder": every activity laid out like the Work & Activities form.
struct ApplicationView: View {
    @Environment(AppState.self) private var appState
    @Environment(EntitlementManager.self) private var entitlements
    @Query(filter: #Predicate<Activity> { $0.isArchived == false }) private var activities: [Activity]

    @State private var showingExport = false
    @State private var path = NavigationPath()
    @State private var didOpenFirst = false

    private var ordered: [Activity] {
        activities.sorted {
            if $0.isMostMeaningful != $1.isMostMeaningful { return $0.isMostMeaningful }
            return $0.totalHours > $1.totalHours
        }
    }

    private var meaningfulCount: Int { activities.filter(\.isMostMeaningful).count }
    private var readyCount: Int { activities.filter(isReady).count }

    private func isReady(_ a: Activity) -> Bool {
        let descOK = !a.amcasDescription.isEmpty && a.amcasDescription.count <= Limits.descriptionLimit
        let mmOK = !a.isMostMeaningful || (!a.meaningfulEssay.isEmpty && a.meaningfulEssay.count <= Limits.meaningfulLimit)
        return descOK && mmOK
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 16) {
                    summaryCard
                    if activities.isEmpty {
                        EmptyStateView(symbol: "doc.text",
                                       title: "Nothing to write yet",
                                       message: "Add activities and log reflections — they become your AMCAS descriptions.")
                            .card()
                    } else {
                        VStack(spacing: 10) {
                            ForEach(Array(ordered.enumerated()), id: \.element.persistentModelID) { index, activity in
                                NavigationLink(value: activity.persistentModelID) {
                                    ApplicationRow(index: index + 1, activity: activity, ready: isReady(activity))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Theme.background)
            .navigationTitle("AMCAS Builder")
            .navigationDestination(for: PersistentIdentifier.self) { id in
                if let activity = activities.first(where: { $0.persistentModelID == id }) {
                    AMCASEntryView(activity: activity)
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if entitlements.isPro { showingExport = true } else { appState.showPaywall = true }
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showingExport) { ExportView() }
            .onAppear {
                if LaunchOptions.openFirst, !didOpenFirst, let first = ordered.first {
                    didOpenFirst = true
                    path.append(first.persistentModelID)
                }
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your Work & Activities")
                .font(.headline)
            HStack(spacing: 0) {
                stat(value: "\(activities.count)", of: "\(Limits.amcasMaxExperiences)", label: "experiences",
                     warn: activities.count > Limits.amcasMaxExperiences)
                Divider().frame(height: 36)
                stat(value: "\(meaningfulCount)", of: "\(Limits.maxMostMeaningful)", label: "most meaningful", warn: false)
                Divider().frame(height: 36)
                stat(value: "\(readyCount)", of: "\(activities.count)", label: "ready to paste", warn: false)
            }
            if activities.count > Limits.amcasMaxExperiences {
                Label("AMCAS allows 15 experiences. Archive or combine some.", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption).foregroundStyle(.orange)
            } else {
                Text("Descriptions are limited to 700 characters; most meaningful experiences get 1,325 more.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .card()
        .padding(.top, 8)
    }

    private func stat(value: String, of total: String, label: String, warn: Bool) -> some View {
        VStack(spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value).font(.system(.title2, design: .rounded).weight(.bold))
                Text("/\(total)").font(.subheadline).foregroundStyle(.secondary)
            }
            .foregroundStyle(warn ? .orange : .primary)
            Text(label).font(.caption).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ApplicationRow: View {
    let index: Int
    let activity: Activity
    let ready: Bool

    var body: some View {
        HStack(spacing: 12) {
            ActivityIcon(symbol: activity.type.symbol, color: activity.color)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(activity.title).font(.subheadline.weight(.semibold)).lineLimit(1)
                    if activity.isMostMeaningful {
                        Image(systemName: "star.fill").font(.caption2).foregroundStyle(.yellow)
                    }
                }
                Text("\(activity.type.shortName) · \(Int(activity.totalHours.rounded())) h")
                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                HStack(spacing: 10) {
                    counter(activity.amcasDescription.count, Limits.descriptionLimit)
                    if activity.isMostMeaningful {
                        counter(activity.meaningfulEssay.count, Limits.meaningfulLimit)
                    }
                }
            }
            Spacer()
            Image(systemName: ready ? "checkmark.circle.fill" : "circle.dashed")
                .font(.title3)
                .foregroundStyle(ready ? Color.green : Color.secondary)
            Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
        }
        .card(padding: 14)
        .contentShape(Rectangle())
    }

    private func counter(_ count: Int, _ limit: Int) -> some View {
        Text(count == 0 ? "Not started" : "\(count)/\(limit)")
            .font(.caption2.weight(.semibold))
            .monospacedDigit()
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background((count > limit ? Color.red : count == 0 ? Color.gray : Theme.teal).opacity(0.14), in: Capsule())
            .foregroundStyle(count > limit ? Color.red : count == 0 ? Color.secondary : Theme.teal)
    }
}

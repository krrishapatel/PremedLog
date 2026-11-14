import SwiftUI
import SwiftData

struct ActivityDetailView: View {
    @Bindable var activity: Activity

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Environment(ShiftTimer.self) private var shiftTimer
    @Query private var allActivities: [Activity]

    @State private var editing = false
    @State private var confirmDelete = false
    @State private var showMeaningfulLimit = false

    private var meaningfulBinding: Binding<Bool> {
        Binding(
            get: { activity.isMostMeaningful },
            set: { newValue in
                if newValue {
                    let others = allActivities.filter { $0.isMostMeaningful && $0.persistentModelID != activity.persistentModelID }
                    if others.count >= Limits.maxMostMeaningful {
                        showMeaningfulLimit = true
                        return
                    }
                }
                activity.isMostMeaningful = newValue
            }
        )
    }

    var body: some View {
        List {
            header
            actions
            Section {
                Toggle(isOn: meaningfulBinding) {
                    Label("Most meaningful", systemImage: "star.fill")
                }
                .tint(.yellow)
            } footer: {
                Text("AMCAS lets you pick up to 3 most meaningful experiences, each with an extra 1,325 characters.")
            }
            detailsSection
            if activity.hasContact { contactSection }
            entriesSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle(activity.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Edit", systemImage: "pencil") { editing = true }
                    Button(activity.isArchived ? "Unarchive" : "Archive",
                           systemImage: activity.isArchived ? "tray.and.arrow.up" : "archivebox") {
                        activity.isArchived.toggle()
                    }
                    Divider()
                    Button("Delete", systemImage: "trash", role: .destructive) { confirmDelete = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $editing) { ActivityEditView(activity: activity) }
        .confirmationDialog("Delete \"\(activity.title)\"?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete activity and \(activity.entries.count) entries", role: .destructive) {
                context.delete(activity)
                try? context.save()
                dismiss()
            }
        } message: {
            Text("This can't be undone. Consider archiving instead.")
        }
        .alert("You already have 3 most meaningful experiences", isPresented: $showMeaningfulLimit) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Turn one off first. AMCAS allows a maximum of 3.")
        }
    }

    private var header: some View {
        Section {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    ActivityIcon(symbol: activity.type.symbol, color: activity.color, size: 52)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(activity.title).font(.title3.weight(.bold))
                        Text(activity.type.shortName).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(activity.totalHours.hoursText)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("hours").font(.title3).foregroundStyle(.secondary)
                    Spacer()
                    Text("\(activity.entries.count) entries").font(.subheadline).foregroundStyle(.secondary)
                }
                if let goal = activity.hoursGoal, goal > 0 {
                    VStack(alignment: .leading, spacing: 6) {
                        ProgressBar(progress: activity.totalHours / goal, color: activity.color)
                        Text("\(Int(min(activity.totalHours / goal, 1) * 100))% of \(goal.hoursText)-hour goal")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 6)
        }
    }

    private var actions: some View {
        Section {
            HStack(spacing: 12) {
                Button {
                    appState.openQuickLog(activityID: activity.uuid)
                } label: {
                    Label("Log hours", systemImage: "plus.circle.fill").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                if shiftTimer.isRunning && shiftTimer.activityID == activity.uuid {
                    Button {
                        if let r = shiftTimer.stop() {
                            appState.openQuickLog(activityID: r.activityID, hours: r.hours, date: r.start)
                        }
                    } label: {
                        Label("Stop shift", systemImage: "stop.circle.fill").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                } else {
                    Button {
                        shiftTimer.start(activityID: activity.uuid)
                    } label: {
                        Label("Start shift", systemImage: "timer").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(shiftTimer.isRunning)
                }
            }
            .controlSize(.large)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
        }
    }

    private var detailsSection: some View {
        Section("Details") {
            LabeledContent("Experience type", value: activity.type.amcasName)
            if !activity.organization.isEmpty { LabeledContent("Organization", value: activity.organization) }
            if !activity.locationText.isEmpty { LabeledContent("Location", value: activity.locationText) }
            LabeledContent("Dates", value: activity.dateRangeText)
        }
    }

    private var contactSection: some View {
        Section("Contact") {
            if !activity.contactName.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.contactName).font(.body.weight(.medium))
                    if !activity.contactTitle.isEmpty {
                        Text(activity.contactTitle).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            if !activity.contactEmail.isEmpty, let url = URL(string: "mailto:\(activity.contactEmail)") {
                Link(destination: url) { Label(activity.contactEmail, systemImage: "envelope") }
            }
            if !activity.contactPhone.isEmpty,
               let url = URL(string: "tel:\(activity.contactPhone.filter { $0.isNumber || $0 == "+" })") {
                Link(destination: url) { Label(activity.contactPhone, systemImage: "phone") }
            }
        }
    }

    private var entriesSection: some View {
        Section {
            if activity.entries.isEmpty {
                Text("No hours logged yet.").foregroundStyle(.secondary)
            } else {
                ForEach(activity.sortedEntries) { entry in
                    EntryRow(entry: entry, showActivity: false)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                context.delete(entry)
                                try? context.save()
                            } label: { Label("Delete", systemImage: "trash") }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                entry.isMemorable.toggle()
                            } label: {
                                Label("Memorable", systemImage: entry.isMemorable ? "star.slash" : "star")
                            }
                            .tint(.yellow)
                        }
                }
            }
        } header: {
            Text("Entries & reflections")
        } footer: {
            if !activity.entries.isEmpty {
                Text("Swipe right to star a memorable moment, left to delete.")
            }
        }
    }
}

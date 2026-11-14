import SwiftUI
import SwiftData
import StoreKit

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(EntitlementManager.self) private var entitlements
    @Environment(\.modelContext) private var context

    @AppStorage(ReminderService.enabledKey) private var remindersEnabled = false
    @AppStorage(ReminderService.timeKey) private var reminderTime = ReminderService.defaultTime
    @AppStorage(ReminderService.weekdaysKey) private var reminderWeekdays = ReminderService.defaultWeekdays
    @AppStorage("hasOnboarded") private var hasOnboarded = true

    @State private var showingExport = false
    @State private var showingManageSubs = false
    @State private var confirmSample = false
    @State private var restoring = false
    @State private var notificationsDenied = false

    var body: some View {
        NavigationStack {
            Form {
                proSection
                Section {
                    GoalsEditor()
                } header: {
                    Text("Hour goals")
                } footer: {
                    Text("Common targets: 150+ clinical, 50+ shadowing, 100+ volunteering. Set research to 0 if it's optional for you.")
                }
                remindersSection
                Section("Data") {
                    Button {
                        if entitlements.isPro { showingExport = true } else { appState.showPaywall = true }
                    } label: {
                        HStack {
                            Label("Export PDF & CSV", systemImage: "square.and.arrow.up")
                            Spacer()
                            if !entitlements.isPro { ProBadge() }
                        }
                    }
                }
                #if DEBUG
                Section {
                    Button("Load sample data", systemImage: "wand.and.rays") { confirmSample = true }
                    Button("Show onboarding again", systemImage: "arrow.counterclockwise") { hasOnboarded = false }
                } header: {
                    Text("Debug")
                } footer: {
                    Text("Sample data replaces everything you've logged.")
                }
                #endif
                Section {
                    LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                } footer: {
                    Text("PremedLog is not affiliated with the AAMC. AMCAS is a registered trademark of the AAMC.")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingExport) { ExportView() }
            .manageSubscriptionsSheet(isPresented: $showingManageSubs)
            .confirmationDialog("Replace all data with sample data?", isPresented: $confirmSample, titleVisibility: .visible) {
                Button("Load sample data", role: .destructive) {
                    SampleData.load(into: context, replacing: true)
                }
            }
            .onChange(of: remindersEnabled) { _, _ in applyReminders(requestAuth: true) }
            .onChange(of: reminderTime) { _, _ in applyReminders(requestAuth: false) }
            .onChange(of: reminderWeekdays) { _, _ in applyReminders(requestAuth: false) }
        }
    }

    // MARK: Pro

    private var proSection: some View {
        Section {
            if entitlements.isPro {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill").font(.title2).foregroundStyle(Theme.teal)
                    VStack(alignment: .leading) {
                        Text("PremedLog Pro").font(.headline)
                        Text(entitlements.activePlanName.map { "\($0) plan" } ?? "Active")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Button("Manage subscription", systemImage: "creditcard") { showingManageSubs = true }
            } else {
                Button {
                    appState.showPaywall = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Upgrade to Pro").font(.headline).foregroundStyle(.primary)
                            Text("Unlimited activities, AI drafts, export, all widgets")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
                    }
                }
            }
            Button {
                restoring = true
                Task {
                    await entitlements.restorePurchases()
                    restoring = false
                }
            } label: {
                HStack {
                    Label("Restore purchases", systemImage: "arrow.clockwise")
                    if restoring { Spacer(); ProgressView() }
                }
            }
            .disabled(restoring)
        }
    }

    // MARK: Reminders

    private var timeBinding: Binding<Date> {
        Binding(
            get: { Calendar.current.startOfDay(for: .now).addingTimeInterval(reminderTime) },
            set: { reminderTime = $0.timeIntervalSince(Calendar.current.startOfDay(for: $0)) }
        )
    }

    private var remindersSection: some View {
        Section {
            Toggle(isOn: $remindersEnabled) {
                Label("“Log your shift?” reminder", systemImage: "bell.badge")
            }
            if remindersEnabled {
                DatePicker("Time", selection: timeBinding, displayedComponents: .hourAndMinute)
                WeekdayPicker(selection: Binding(
                    get: { ReminderService.parseWeekdays(reminderWeekdays) },
                    set: { reminderWeekdays = ReminderService.encodeWeekdays($0) }
                ))
            }
        } header: {
            Text("Reminders")
        } footer: {
            if notificationsDenied {
                Text("Notifications are turned off for PremedLog. Enable them in the Settings app.")
                    .foregroundStyle(.red)
            } else {
                Text("A gentle nudge on the days you usually volunteer or work.")
            }
        }
    }

    private func applyReminders(requestAuth: Bool) {
        guard remindersEnabled else {
            ReminderService.cancelAll()
            return
        }
        Task {
            if requestAuth {
                let granted = await ReminderService.requestAuthorization()
                notificationsDenied = !granted
                if !granted { remindersEnabled = false; return }
            }
            ReminderService.schedule(weekdays: ReminderService.parseWeekdays(reminderWeekdays),
                                     secondsSinceMidnight: reminderTime)
        }
    }
}

struct WeekdayPicker: View {
    @Binding var selection: Set<Int>

    var body: some View {
        let symbols = Calendar.current.veryShortWeekdaySymbols // index 0 = Sunday
        HStack(spacing: 6) {
            ForEach(1...7, id: \.self) { day in
                let on = selection.contains(day)
                Button {
                    if on { selection.remove(day) } else { selection.insert(day) }
                } label: {
                    Text(symbols[day - 1])
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(on ? Color.accentColor : Color.accentColor.opacity(0.12), in: Circle())
                        .foregroundStyle(on ? Color.white : Color.accentColor)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Calendar.current.weekdaySymbols[day - 1])
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }
}

/// Steppers for the four goal categories (used in Settings and Onboarding).
struct GoalsEditor: View {
    @AppStorage(CategoryGroup.clinical.goalKey) private var clinical = CategoryGroup.clinical.defaultGoal
    @AppStorage(CategoryGroup.shadowing.goalKey) private var shadowing = CategoryGroup.shadowing.defaultGoal
    @AppStorage(CategoryGroup.volunteering.goalKey) private var volunteering = CategoryGroup.volunteering.defaultGoal
    @AppStorage(CategoryGroup.research.goalKey) private var research = CategoryGroup.research.defaultGoal

    var body: some View {
        GoalRow(group: .clinical, value: $clinical)
        GoalRow(group: .shadowing, value: $shadowing)
        GoalRow(group: .volunteering, value: $volunteering)
        GoalRow(group: .research, value: $research)
    }
}

struct GoalRow: View {
    let group: CategoryGroup
    @Binding var value: Double

    var body: some View {
        Stepper(value: $value, in: 0...3000, step: 10) {
            HStack(spacing: 10) {
                Image(systemName: group.symbol)
                    .foregroundStyle(group.color)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 0) {
                    Text(group.title).font(.body.weight(.medium))
                    Text(value == 0 ? "No goal" : "\(value.hoursText) hours")
                        .font(.caption).foregroundStyle(.secondary).monospacedDigit()
                }
            }
        }
    }
}

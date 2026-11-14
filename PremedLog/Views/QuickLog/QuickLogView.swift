import SwiftUI
import SwiftData

struct QuickLogView: View {
    let request: QuickLogRequest

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Environment(EntitlementManager.self) private var entitlements

    @Query(filter: #Predicate<Activity> { $0.isArchived == false }) private var activities: [Activity]
    @Query private var allActivities: [Activity]

    @State private var selectedID: UUID?
    @State private var hours: Double = 2
    @State private var date: Date = .now
    @State private var note = ""
    @State private var memorable = false
    @State private var prompt = ReflectionPrompts.random()
    @State private var showingNewActivity = false
    @State private var didPrefill = false
    @FocusState private var noteFocused: Bool

    private var sortedActivities: [Activity] {
        activities.sorted { ($0.lastLoggedDate ?? $0.createdAt) > ($1.lastLoggedDate ?? $1.createdAt) }
    }

    private var selectedActivity: Activity? {
        activities.first { $0.uuid == selectedID }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    activitySection
                    hoursSection
                    dateSection
                    reflectionSection
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.background)
            .navigationTitle("Log hours")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                        .disabled(selectedActivity == nil || hours <= 0)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: save) {
                    Text(selectedActivity == nil ? "Choose an activity" : "Save \(hours.hoursText) hours")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: 16))
                .controlSize(.large)
                .disabled(selectedActivity == nil || hours <= 0)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .background(.bar)
            }
            .sheet(isPresented: $showingNewActivity) {
                ActivityEditView { created in selectedID = created.uuid }
            }
            .onAppear(perform: prefill)
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: Sections

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Activity").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
            if activities.isEmpty {
                Button {
                    showingNewActivity = true
                } label: {
                    Label("Add your first activity", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(sortedActivities) { activity in
                            activityChip(activity)
                        }
                        Button {
                            if entitlements.isPro || allActivities.count < Limits.freeActivityCount {
                                showingNewActivity = true
                            } else {
                                appState.showPaywall = true
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.subheadline.weight(.bold))
                                .frame(width: 40, height: 40)
                                .background(Theme.card, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("New activity")
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .card()
    }

    private func activityChip(_ activity: Activity) -> some View {
        let selected = activity.uuid == selectedID
        return Button {
            withAnimation(.snappy) { selectedID = activity.uuid }
            UISelectionFeedbackGenerator().selectionChanged()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: activity.type.symbol).font(.caption.weight(.semibold))
                Text(activity.title).font(.subheadline.weight(.medium)).lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(selected ? activity.color : activity.color.opacity(0.12), in: Capsule())
            .foregroundStyle(selected ? Color.white : activity.color)
        }
        .buttonStyle(.plain)
    }

    private var hoursSection: some View {
        VStack(spacing: 14) {
            HStack {
                Button { adjust(-0.5) } label: {
                    Image(systemName: "minus").font(.title3.weight(.bold)).frame(width: 48, height: 48)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .disabled(hours <= 0.5)

                Spacer()
                VStack(spacing: 0) {
                    Text(hours.hoursText)
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText(value: hours))
                    Text(hours == 1 ? "hour" : "hours").font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()

                Button { adjust(0.5) } label: {
                    Image(systemName: "plus").font(.title3.weight(.bold)).frame(width: 48, height: 48)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .disabled(hours >= 24)
            }
            HStack(spacing: 8) {
                ForEach([1.0, 2.0, 3.0, 4.0], id: \.self) { value in
                    Button {
                        withAnimation(.snappy) { hours = value }
                    } label: {
                        Text("\(Int(value)) h")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(hours == value ? Color.accentColor : Color.accentColor.opacity(0.12), in: Capsule())
                            .foregroundStyle(hours == value ? Color.white : Color.accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .card()
    }

    private var dateSection: some View {
        HStack {
            Label("Date", systemImage: "calendar").font(.subheadline.weight(.semibold))
            Spacer()
            DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: .date)
                .labelsHidden()
        }
        .card()
    }

    private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Reflection").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                Text("optional").font(.caption).foregroundStyle(.tertiary)
                Spacer()
                Button {
                    withAnimation { prompt = ReflectionPrompts.random(excluding: prompt) }
                } label: {
                    Image(systemName: "shuffle")
                }
                .accessibilityLabel("New prompt")
            }
            Text(prompt)
                .font(.callout.italic())
                .foregroundStyle(Theme.indigo)
                .id(prompt)
                .transition(.opacity)

            ZStack(alignment: .topLeading) {
                if note.isEmpty {
                    Text("A sentence or two is plenty. Future-you writing AMCAS will thank you.")
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $note)
                    .focused($noteFocused)
                    .frame(minHeight: 100)
                    .scrollContentBackground(.hidden)
            }
            .padding(6)
            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            Button {
                withAnimation(.snappy) { memorable.toggle() }
                UISelectionFeedbackGenerator().selectionChanged()
            } label: {
                Label(memorable ? "Memorable moment" : "Mark as memorable moment",
                      systemImage: memorable ? "star.fill" : "star")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(memorable ? Color.yellow : Color.secondary)
                    .symbolEffect(.bounce, value: memorable)
            }
            .buttonStyle(.plain)
        }
        .card()
    }

    // MARK: Actions

    private func adjust(_ delta: Double) {
        withAnimation(.snappy) { hours = min(24, max(0.5, hours + delta)) }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    private func prefill() {
        guard !didPrefill else { return }
        didPrefill = true
        selectedID = request.activityID ?? sortedActivities.first?.uuid
        if let h = request.hours { hours = h }
        if let d = request.date { date = min(d, .now) }
    }

    private func save() {
        guard let activity = selectedActivity else { return }
        let entry = LogEntry(date: date, hours: hours,
                             note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                             isMemorable: memorable)
        context.insert(entry)
        entry.activity = activity
        try? context.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}

import SwiftUI
import SwiftData

/// One experience, mirroring the AMCAS form field-by-field, with copy buttons.
struct AMCASEntryView: View {
    @Bindable var activity: Activity

    @Environment(AppState.self) private var appState
    @Environment(EntitlementManager.self) private var entitlements

    @State private var drafting: DraftKind?
    @State private var pendingReplace: DraftKind?
    @State private var draftError: String?
    @State private var lastDrafted: Set<DraftKind> = []
    @FocusState private var focused: DraftKind?

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                fieldsCard
                editorCard(kind: .description,
                           title: "Experience Description",
                           text: $activity.amcasDescription,
                           hint: "Describe your role, responsibilities and impact.")
                if activity.isMostMeaningful {
                    editorCard(kind: .mostMeaningful,
                               title: "Most Meaningful Experience",
                               text: $activity.meaningfulEssay,
                               hint: "Why this was meaningful: the transformative moment and how it changed you.")
                } else {
                    Label("Mark this as a most meaningful experience (Activities tab) to unlock the extra 1,325-character essay.",
                          systemImage: "star")
                        .font(.caption).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                }
                reflectionsCard
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background)
        .navigationTitle(activity.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focused = nil }
            }
        }
        .confirmationDialog("Replace your current text with a new draft?",
                            isPresented: Binding(get: { pendingReplace != nil }, set: { if !$0 { pendingReplace = nil } }),
                            titleVisibility: .visible) {
            Button("Replace with draft", role: .destructive) {
                if let kind = pendingReplace { runDraft(kind) }
            }
        }
        .alert("Couldn't create a draft",
               isPresented: Binding(get: { draftError != nil }, set: { if !$0 { draftError = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(draftError ?? "")
        }
    }

    // MARK: Read-only form fields

    private var fieldsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            FormFieldRow(label: "Experience Type", value: activity.type.amcasName)
            Divider()
            FormFieldRow(label: "Experience Name", value: activity.title)
            Divider()
            FormFieldRow(label: "Organization Name", value: activity.organization)
            Divider()
            FormFieldRow(label: "City / State", value: activity.locationText)
            Divider()
            FormFieldRow(label: "Dates (MM/YYYY)", value: activity.amcasDateRangeText)
            Divider()
            FormFieldRow(label: "Total Hours", value: String(Int(activity.totalHours.rounded())))
            Divider()
            FormFieldRow(label: "Contact Name", value: activity.contactName)
            Divider()
            FormFieldRow(label: "Contact Title", value: activity.contactTitle)
            Divider()
            FormFieldRow(label: "Contact Email", value: activity.contactEmail)
            Divider()
            FormFieldRow(label: "Contact Phone", value: activity.contactPhone)
        }
        .card(padding: 14)
    }

    // MARK: Editors

    private func editorCard(kind: DraftKind, title: String, text: Binding<String>, hint: String) -> some View {
        let limit = kind.limit
        let over = text.wrappedValue.count > limit
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                CopyButton(text: text.wrappedValue)
            }
            ZStack(alignment: .topLeading) {
                if text.wrappedValue.isEmpty {
                    Text(hint)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
                TextEditor(text: text)
                    .focused($focused, equals: kind)
                    .frame(minHeight: kind == .description ? 180 : 260)
                    .scrollContentBackground(.hidden)
            }
            .padding(6)
            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(over ? Color.red : Color.clear, lineWidth: 1.5)
            )

            HStack {
                ProgressBar(progress: Double(text.wrappedValue.count) / Double(limit),
                            color: over ? .red : Theme.teal, height: 5)
                    .frame(maxWidth: 120)
                Spacer()
                CharacterCounter(count: text.wrappedValue.count, limit: limit)
            }

            Button {
                requestDraft(kind, current: text.wrappedValue)
            } label: {
                HStack {
                    if drafting == kind {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "wand.and.stars")
                    }
                    Text("Draft from my notes")
                    if !entitlements.isPro { ProBadge() }
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .tint(Theme.indigo)
            .disabled(drafting != nil)

            if lastDrafted.contains(kind) {
                Label("Draft from your notes — edit to make it yours", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(Theme.indigo)
            }
        }
        .card()
    }

    // MARK: Reflections reference

    private var reflectionsCard: some View {
        let notes = activity.sortedEntries.filter(\.hasNote)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Your reflections").font(.headline)
                Spacer()
                Text("\(notes.count)").font(.subheadline).foregroundStyle(.secondary)
            }
            if notes.isEmpty {
                Text("Reflections you add when logging hours show up here as raw material.")
                    .font(.subheadline).foregroundStyle(.secondary)
            } else {
                ForEach(notes.sorted { $0.isMemorable && !$1.isMemorable }.prefix(8)) { entry in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: entry.isMemorable ? "star.fill" : "text.quote")
                            .font(.caption)
                            .foregroundStyle(entry.isMemorable ? Color.yellow : Color.secondary)
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.note).font(.footnote)
                            Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .card()
    }

    // MARK: Drafting

    private func requestDraft(_ kind: DraftKind, current: String) {
        guard entitlements.isPro else {
            appState.showPaywall = true
            return
        }
        if current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            runDraft(kind)
        } else {
            pendingReplace = kind
        }
    }

    private func runDraft(_ kind: DraftKind) {
        let request = DraftRequest(activity: activity, kind: kind)
        drafting = kind
        Task {
            defer { drafting = nil }
            do {
                let text = try await DraftServiceFactory.make().draft(request)
                withAnimation {
                    switch kind {
                    case .description: activity.amcasDescription = text
                    case .mostMeaningful: activity.meaningfulEssay = text
                    }
                    lastDrafted.insert(kind)
                }
            } catch {
                draftError = error.localizedDescription
            }
        }
    }
}

struct FormFieldRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value.isEmpty ? "Not set" : value)
                    .font(.subheadline)
                    .foregroundStyle(value.isEmpty ? .tertiary : .primary)
                    .textSelection(.enabled)
            }
            Spacer()
            if !value.isEmpty {
                CopyButton(text: value, compact: true)
            }
        }
        .padding(.vertical, 8)
    }
}

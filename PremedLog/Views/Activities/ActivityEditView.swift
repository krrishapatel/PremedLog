import SwiftUI
import SwiftData

/// Create or edit an activity.
struct ActivityEditView: View {
    let activity: Activity?
    var onCreate: ((Activity) -> Void)?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var type: ExperienceType
    @State private var organization: String
    @State private var city: String
    @State private var state: String
    @State private var startDate: Date
    @State private var ongoing: Bool
    @State private var endDate: Date
    @State private var hasGoal: Bool
    @State private var goal: Double
    @State private var contactName: String
    @State private var contactTitle: String
    @State private var contactEmail: String
    @State private var contactPhone: String
    @State private var color: ActivityColor

    init(activity: Activity? = nil, onCreate: ((Activity) -> Void)? = nil) {
        self.activity = activity
        self.onCreate = onCreate
        _title = State(initialValue: activity?.title ?? "")
        _type = State(initialValue: activity?.type ?? .volunteerClinical)
        _organization = State(initialValue: activity?.organization ?? "")
        _city = State(initialValue: activity?.city ?? "")
        _state = State(initialValue: activity?.state ?? "")
        _startDate = State(initialValue: activity?.startDate ?? .now)
        _ongoing = State(initialValue: activity?.endDate == nil)
        _endDate = State(initialValue: activity?.endDate ?? .now)
        _hasGoal = State(initialValue: activity?.hoursGoal != nil)
        _goal = State(initialValue: activity?.hoursGoal ?? 100)
        _contactName = State(initialValue: activity?.contactName ?? "")
        _contactTitle = State(initialValue: activity?.contactTitle ?? "")
        _contactEmail = State(initialValue: activity?.contactEmail ?? "")
        _contactPhone = State(initialValue: activity?.contactPhone ?? "")
        _color = State(initialValue: activity?.activityColor ?? ActivityColor.allCases.randomElement() ?? .teal)
    }

    private var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title (e.g. ED Volunteer)", text: $title)
                        .font(.headline)
                    Picker("Experience type", selection: $type) {
                        ForEach(ExperienceType.allCases) { t in
                            Label(t.amcasName, systemImage: t.symbol).tag(t)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    TextField("Organization", text: $organization)
                    HStack {
                        TextField("City", text: $city)
                        Divider()
                        TextField("State", text: $state)
                            .frame(maxWidth: 90)
                    }
                } header: {
                    Text("Basics")
                } footer: {
                    Text("Types match the AMCAS Work & Activities form.")
                }

                Section("Dates") {
                    DatePicker("Start", selection: $startDate, displayedComponents: .date)
                    Toggle("Ongoing", isOn: $ongoing.animation())
                    if !ongoing {
                        DatePicker("End", selection: $endDate, in: startDate..., displayedComponents: .date)
                    }
                }

                Section("Hours goal") {
                    Toggle("Set a goal for this activity", isOn: $hasGoal.animation())
                    if hasGoal {
                        Stepper(value: $goal, in: 5...5000, step: 5) {
                            Text("\(goal.hoursText) hours").monospacedDigit()
                        }
                    }
                }

                Section {
                    TextField("Name", text: $contactName)
                        .textContentType(.name)
                    TextField("Title (e.g. Volunteer Coordinator)", text: $contactTitle)
                    TextField("Email", text: $contactEmail)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Phone", text: $contactPhone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                } header: {
                    Text("Contact / supervisor")
                } footer: {
                    Text("AMCAS asks for a contact who can verify each experience. Save it now while you still have it.")
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 9), spacing: 10) {
                        ForEach(ActivityColor.allCases) { c in
                            Circle()
                                .fill(c.color)
                                .frame(width: 28, height: 28)
                                .overlay {
                                    if c == color {
                                        Image(systemName: "checkmark").font(.caption.weight(.bold)).foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture { color = c }
                                .accessibilityLabel(c.rawValue)
                                .accessibilityAddTraits(c == color ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(activity == nil ? "New activity" : "Edit activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).fontWeight(.semibold).disabled(!isValid)
                }
            }
        }
    }

    private func save() {
        let target: Activity
        if let activity {
            target = activity
        } else {
            target = Activity(title: "", type: type)
            context.insert(target)
        }
        target.title = title.trimmingCharacters(in: .whitespaces)
        target.type = type
        target.organization = organization
        target.city = city
        target.state = state
        target.startDate = startDate
        target.endDate = ongoing ? nil : endDate
        target.hoursGoal = hasGoal ? goal : nil
        target.contactName = contactName
        target.contactTitle = contactTitle
        target.contactEmail = contactEmail
        target.contactPhone = contactPhone
        target.activityColor = color
        try? context.save()
        if activity == nil { onCreate?(target) }
        dismiss()
    }
}

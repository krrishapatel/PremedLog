import SwiftUI
import SwiftData

struct OnboardingView: View {
    var onFinish: () -> Void

    @Environment(\.modelContext) private var context
    @State private var page = 0
    @State private var title = ""
    @State private var type: ExperienceType = .volunteerClinical
    @State private var organization = ""

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                welcome.tag(0)
                goals.tag(1)
                firstActivity.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            VStack(spacing: 8) {
                Button(action: next) {
                    Text(page < 2 ? "Continue" : (title.isEmpty ? "Start logging" : "Add & start logging"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: 16))
                .controlSize(.large)

                if page == 2 {
                    Button("Skip for now", action: onFinish)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .background(Theme.background)
    }

    private func next() {
        if page < 2 {
            withAnimation { page += 1 }
        } else {
            let trimmed = title.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                let activity = Activity(title: trimmed, type: type, organization: organization)
                context.insert(activity)
                try? context.save()
            }
            onFinish()
        }
    }

    // MARK: Pages

    private var welcome: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Theme.heroGradient)
                    .frame(width: 120, height: 120)
                    .shadow(color: Theme.indigo.opacity(0.3), radius: 20, y: 10)
                Image(systemName: "cross.case.fill")
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Text("Log hours in 10 seconds.\nWrite AMCAS in minutes.")
                .font(.system(.title, design: .rounded).weight(.bold))
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 14) {
                bullet("clock.fill", "Track clinical, shadowing, volunteering & research hours")
                bullet("text.quote", "Capture a quick reflection while it's fresh")
                bullet("doc.text.fill", "Turn years of notes into 700-character descriptions")
            }
            .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
        .padding()
    }

    private func bullet(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol).foregroundStyle(Theme.teal).frame(width: 24)
            Text(text).font(.callout)
        }
    }

    private var goals: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 24)
            Image(systemName: "target")
                .font(.system(size: 48))
                .foregroundStyle(Theme.heroGradient)
            Text("Set your goals")
                .font(.system(.title, design: .rounded).weight(.bold))
            Text("Rough targets many applicants aim for. You can change these anytime.")
                .font(.callout).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Form {
                GoalsEditor()
            }
            .scrollContentBackground(.hidden)
            .scrollDisabled(true)
            .frame(height: 300)
            Spacer()
        }
    }

    private var firstActivity: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 24)
            Image(systemName: "plus.rectangle.on.rectangle")
                .font(.system(size: 48))
                .foregroundStyle(Theme.heroGradient)
            Text("Add your first activity")
                .font(.system(.title, design: .rounded).weight(.bold))
            Text("What are you doing right now? You can add contact info and more later.")
                .font(.callout).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Form {
                TextField("e.g. ED Volunteer", text: $title)
                TextField("Organization (optional)", text: $organization)
                Picker("Type", selection: $type) {
                    ForEach(ExperienceType.allCases) { t in
                        Text(t.shortName).tag(t)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .scrollDisabled(true)
            .frame(height: 220)
            Spacer()
        }
    }
}

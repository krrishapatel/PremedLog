import Foundation
import SwiftData

/// Realistic, deterministic demo data (used by "Load sample data" and the `-sampleData` launch argument).
enum SampleData {
    private struct Spec {
        let title: String
        let type: ExperienceType
        let org: String
        let city: String
        let state: String
        let contact: (String, String, String, String)
        let monthsAgo: Int
        let ended: Bool
        let weeks: Int
        let probability: Double
        let hourOptions: [Double]
        let mostMeaningful: Bool
        let color: ActivityColor
        let goal: Double?
        let description: String
        let notes: [(String, Bool)]
    }

    private static let specs: [Spec] = [
        Spec(title: "Emergency Department Volunteer", type: .volunteerClinical, org: "Riverside General Hospital",
             city: "Boston", state: "MA",
             contact: ("Maria Alvarez", "Volunteer Services Coordinator", "malvarez@riversidegeneral.org", "(617) 555-0142"),
             monthsAgo: 14, ended: false, weeks: 40, probability: 0.95, hourOptions: [3, 3.5, 4, 4],
             mostMeaningful: true, color: .teal, goal: 200,
             description: "As an ED volunteer I restock rooms, transport patients, and spend time with patients waiting for results. Over 150+ hours I've learned to read a room—when a family needs space and when an elderly patient just needs someone to sit with them. One night I stayed with a woman whose husband was in trauma bay 2 until the chaplain arrived; I didn't say much, but she held my hand the whole time.",
             notes: [
                ("Sat with an elderly patient waiting for CT results for almost an hour. She told me about raising six kids. The nurse said it calmed her more than the Ativan would have.", true),
                ("Busy night — trauma activation. Watched how the charge nurse kept everyone calm with three words at a time.", true),
                ("Restocked rooms and transported four patients. Learned where everything is finally.", false),
                ("A father asked me to explain what 'observation status' meant. I didn't know, so I found the case manager. Learned to say 'let me find someone who knows.'", true),
                ("Quiet shift. Helped the tech clean and turn over rooms.", false),
                ("Translated basic directions in Spanish for a family until the interpreter arrived.", true)
             ]),
        Spec(title: "Medical Scribe", type: .paidClinical, org: "Northside Urgent Care",
             city: "Cambridge", state: "MA",
             contact: ("Dr. James Whitfield", "Medical Director", "jwhitfield@northsideuc.com", "(617) 555-0198"),
             monthsAgo: 9, ended: false, weeks: 30, probability: 0.7, hourOptions: [6, 8, 8],
             mostMeaningful: true, color: .indigo, goal: nil,
             description: "",
             notes: [
                ("Scribed 31 patients today. Dr. W walked me through why he ordered a chest X-ray for a 'simple' cough — red flags I'd never have noticed.", true),
                ("Learned to write a clean HPI. Got my first 'perfect note' from Dr. W.", false),
                ("Patient came in for a sprained ankle and left with a diabetes diagnosis. Watching Dr. W deliver that news with such care stuck with me.", true),
                ("Long shift, lots of URIs. Getting faster at templates.", false)
             ]),
        Spec(title: "Shadowing – Family Medicine", type: .shadowing, org: "Harbor Community Health Center",
             city: "Boston", state: "MA",
             contact: ("Dr. Lena Chen, MD", "Family Physician", "lchen@harborchc.org", ""),
             monthsAgo: 6, ended: true, weeks: 8, probability: 1.0, hourOptions: [4, 4, 5],
             mostMeaningful: false, color: .blue, goal: 40,
             description: "",
             notes: [
                ("Dr. Chen spent 20 minutes on a med reconciliation with a patient on 14 meds. Continuity of care is real.", true),
                ("Saw three well-child visits. Dr. Chen talks to the kids first, parents second.", false)
             ]),
        Spec(title: "Shadowing – Cardiology", type: .shadowing, org: "Riverside General Hospital",
             city: "Boston", state: "MA",
             contact: ("Dr. Samuel Okafor, MD", "Interventional Cardiologist", "", ""),
             monthsAgo: 3, ended: false, weeks: 5, probability: 0.8, hourOptions: [4, 6],
             mostMeaningful: false, color: .purple, goal: 20,
             description: "",
             notes: [
                ("Watched my first cath. The patient was awake and Dr. Okafor narrated everything to him — so reassuring.", true)
             ]),
        Spec(title: "Undergraduate Research Assistant", type: .research, org: "Mehta Lab, Dept. of Neuroscience",
             city: "Boston", state: "MA",
             contact: ("Dr. Priya Mehta, PhD", "Principal Investigator", "pmehta@university.edu", ""),
             monthsAgo: 18, ended: false, weeks: 52, probability: 0.8, hourOptions: [3, 4, 5],
             mostMeaningful: true, color: .mint, goal: nil,
             description: "I study how chronic stress alters microglia in the mouse hippocampus. I run immunostaining, confocal imaging and the analysis pipeline in Python. After three failed staining runs I redesigned our antigen-retrieval step, which became the lab's standard protocol. I presented a poster at the spring undergraduate symposium.",
             notes: [
                ("Third failed stain in a row. Went back to the protocol line by line — found the antigen retrieval temp was off.", true),
                ("Staining finally worked! Beautiful images. Priya said to write up the protocol change.", true),
                ("Lab meeting: presented my preliminary data. Nervous but got good questions.", false),
                ("Imaging all afternoon on the confocal.", false)
             ]),
        Spec(title: "Community Food Bank Volunteer", type: .volunteerNonClinical, org: "Greater Boston Food Bank",
             city: "Boston", state: "MA",
             contact: ("Tom Reyes", "Volunteer Lead", "treyes@gbfb.org", ""),
             monthsAgo: 20, ended: false, weeks: 45, probability: 0.45, hourOptions: [2, 3],
             mostMeaningful: false, color: .orange, goal: nil,
             description: "",
             notes: [
                ("Sorted produce with a group of retirees who've volunteered here for 15 years. Food insecurity is everywhere.", true),
                ("Mobile pantry at the senior center — a man told me it was the only fresh fruit he'd get this week.", true)
             ]),
        Spec(title: "Organic Chemistry Teaching Assistant", type: .teaching, org: "Department of Chemistry",
             city: "Boston", state: "MA",
             contact: ("Dr. Alan Brooks, PhD", "Senior Lecturer", "abrooks@university.edu", ""),
             monthsAgo: 10, ended: false, weeks: 26, probability: 0.85, hourOptions: [2, 3],
             mostMeaningful: false, color: .pink, goal: nil,
             description: "",
             notes: [
                ("A student who was failing finally 'got' SN1 vs SN2 using my parking-lot analogy.", true)
             ])
    ]

    @MainActor
    static func load(into context: ModelContext, replacing: Bool = true) {
        if replacing {
            if let entries = try? context.fetch(FetchDescriptor<LogEntry>()) { entries.forEach { context.delete($0) } }
            if let activities = try? context.fetch(FetchDescriptor<Activity>()) { activities.forEach { context.delete($0) } }
        }

        var rng = SeededGenerator(seed: 42)
        let calendar = Calendar.current
        let now = Date.now

        for spec in specs {
            let start = calendar.date(byAdding: .month, value: -spec.monthsAgo, to: now) ?? now
            let end = spec.ended ? calendar.date(byAdding: .month, value: -4, to: now) : nil
            let activity = Activity(
                title: spec.title, type: spec.type, organization: spec.org, city: spec.city, state: spec.state,
                contactName: spec.contact.0, contactTitle: spec.contact.1, contactEmail: spec.contact.2,
                contactPhone: spec.contact.3, startDate: start, endDate: end, hoursGoal: spec.goal,
                isMostMeaningful: spec.mostMeaningful, color: spec.color
            )
            activity.amcasDescription = spec.description
            activity.createdAt = start
            context.insert(activity)

            let weekOffset = spec.ended ? 17 : 0 // ended activities stopped ~4 months ago
            var noteIndex = 0
            for week in 0..<spec.weeks {
                let isRecent = week == 0 && !spec.ended
                guard isRecent || Double.random(in: 0..<1, using: &rng) < spec.probability else { continue }
                let dayOffset = isRecent ? Int.random(in: 0...1, using: &rng) : Int.random(in: 0...6, using: &rng)
                let daysAgo = (week + weekOffset) * 7 + dayOffset
                guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: now), date >= start else { continue }
                let hours = spec.hourOptions.randomElement(using: &rng) ?? 2

                var note = ""
                var memorable = false
                if noteIndex < spec.notes.count, week % 3 == 0 || week < 2 {
                    note = spec.notes[noteIndex].0
                    memorable = spec.notes[noteIndex].1
                    noteIndex += 1
                }
                let entry = LogEntry(date: date, hours: hours, note: note, isMemorable: memorable)
                context.insert(entry)
                entry.activity = activity
            }
        }
        try? context.save()
    }
}

/// SplitMix64 — deterministic so screenshots are reproducible.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

import Foundation

/// The 19 AMCAS "Work and Activities" experience types, spelled exactly as on the form.
enum ExperienceType: String, CaseIterable, Codable, Identifiable {
    case artistic = "Artistic Endeavors"
    case volunteerClinical = "Community Service/Volunteer – Medical/Clinical"
    case volunteerNonClinical = "Community Service/Volunteer – Not Medical/Clinical"
    case conferences = "Conferences Attended"
    case extracurricular = "Extracurricular Activities"
    case hobbies = "Hobbies"
    case honors = "Honors/Awards/Recognitions"
    case athletics = "Intercollegiate Athletics"
    case leadership = "Leadership – Not Listed Elsewhere"
    case military = "Military Service"
    case other = "Other"
    case paidClinical = "Paid Employment – Medical/Clinical"
    case paidNonClinical = "Paid Employment – Not Medical/Clinical"
    case shadowing = "Physician Shadowing/Clinical Observation"
    case presentations = "Presentations/Posters"
    case publications = "Publications"
    case research = "Research/Lab"
    case socialJustice = "Social Justice/Advocacy"
    case teaching = "Teaching/Tutoring/Teaching Assistant"

    var id: String { rawValue }

    /// The official AMCAS label.
    var amcasName: String { rawValue }

    /// Short label for chips and rows.
    var shortName: String {
        switch self {
        case .artistic: return "Artistic"
        case .volunteerClinical: return "Clinical Volunteering"
        case .volunteerNonClinical: return "Non-Clinical Volunteering"
        case .conferences: return "Conferences"
        case .extracurricular: return "Extracurricular"
        case .hobbies: return "Hobbies"
        case .honors: return "Honors & Awards"
        case .athletics: return "Athletics"
        case .leadership: return "Leadership"
        case .military: return "Military Service"
        case .other: return "Other"
        case .paidClinical: return "Clinical Employment"
        case .paidNonClinical: return "Employment"
        case .shadowing: return "Shadowing"
        case .presentations: return "Presentations/Posters"
        case .publications: return "Publications"
        case .research: return "Research"
        case .socialJustice: return "Advocacy"
        case .teaching: return "Teaching & Tutoring"
        }
    }

    var symbol: String {
        switch self {
        case .artistic: return "paintpalette.fill"
        case .volunteerClinical: return "cross.case.fill"
        case .volunteerNonClinical: return "heart.fill"
        case .conferences: return "person.3.fill"
        case .extracurricular: return "star.circle.fill"
        case .hobbies: return "gamecontroller.fill"
        case .honors: return "rosette"
        case .athletics: return "sportscourt.fill"
        case .leadership: return "flag.fill"
        case .military: return "shield.fill"
        case .other: return "ellipsis.circle.fill"
        case .paidClinical: return "stethoscope"
        case .paidNonClinical: return "briefcase.fill"
        case .shadowing: return "eye.fill"
        case .presentations: return "chart.bar.doc.horizontal.fill"
        case .publications: return "doc.text.fill"
        case .research: return "testtube.2"
        case .socialJustice: return "megaphone.fill"
        case .teaching: return "graduationcap.fill"
        }
    }

    var group: CategoryGroup {
        switch self {
        case .volunteerClinical, .paidClinical: return .clinical
        case .shadowing: return .shadowing
        case .volunteerNonClinical, .socialJustice: return .volunteering
        case .research: return .research
        default: return .other
        }
    }

    /// Some types (honors, publications, conferences) usually aren't tracked in hours.
    var tracksHours: Bool {
        switch self {
        case .honors, .publications, .presentations, .conferences: return false
        default: return true
        }
    }

    var sortIndex: Int { Self.allCases.firstIndex(of: self) ?? 0 }
}

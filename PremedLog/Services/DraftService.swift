import Foundation

// MARK: - Configuration

enum AppConfig {
    /// URL of YOUR server-side proxy that calls an LLM and returns `{ "draft": "..." }`.
    ///
    /// IMPORTANT: Never put an AI provider API key in the app binary — anyone can extract it.
    /// The key lives only on the proxy server, which should also authenticate the user
    /// (e.g. verify an App Store transaction / Pro entitlement) and rate-limit requests.
    ///
    /// Leave empty to use the on-device `LocalDraftService` template fallback.
    static let draftProxyURL = ""
}

// MARK: - Request

enum DraftKind: String, Codable {
    case description       // 700-char Experience Description
    case mostMeaningful    // 1325-char Most Meaningful remarks

    var limit: Int {
        switch self {
        case .description: return Limits.descriptionLimit
        case .mostMeaningful: return Limits.meaningfulLimit
        }
    }
}

struct DraftRequest: Codable {
    var kind: DraftKind
    var characterLimit: Int
    var title: String
    var experienceType: String
    var organization: String
    var totalHours: Double
    var startDate: Date
    var endDate: Date?
    var memorableReflections: [String]
    var otherReflections: [String]

    init(activity: Activity, kind: DraftKind) {
        self.kind = kind
        self.characterLimit = kind.limit
        self.title = activity.title
        self.experienceType = activity.type.amcasName
        self.organization = activity.organization
        self.totalHours = activity.totalHours
        self.startDate = activity.startDate
        self.endDate = activity.endDate
        let withNotes = activity.sortedEntries.filter(\.hasNote)
        self.memorableReflections = withNotes.filter(\.isMemorable).map(\.note)
        self.otherReflections = withNotes.filter { !$0.isMemorable }.map(\.note)
    }
}

// MARK: - Service protocol

protocol DraftService {
    func draft(_ request: DraftRequest) async throws -> String
}

enum DraftServiceFactory {
    static func make() -> DraftService {
        if let url = URL(string: AppConfig.draftProxyURL), !AppConfig.draftProxyURL.isEmpty {
            return RemoteDraftService(endpoint: url)
        }
        return LocalDraftService()
    }
}

enum DraftError: LocalizedError {
    case badResponse
    case noReflections

    var errorDescription: String? {
        switch self {
        case .badResponse: return "The drafting service didn't return a draft. Try again later."
        case .noReflections: return "Add a few reflections to your log entries first — drafts are built from your own notes."
        }
    }
}

// MARK: - Remote (server-side proxy)

struct RemoteDraftService: DraftService {
    let endpoint: URL
    var session: URLSession = .shared

    private struct Response: Decodable { let draft: String }

    func draft(_ request: DraftRequest) async throws -> String {
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 30
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        urlRequest.httpBody = try encoder.encode(request)

        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw DraftError.badResponse
        }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        return DraftText.trim(decoded.draft, to: request.characterLimit)
    }
}

// MARK: - Local template fallback (no network, no AI)

struct LocalDraftService: DraftService {
    func draft(_ request: DraftRequest) async throws -> String {
        let reflections = request.memorableReflections + request.otherReflections
        guard !reflections.isEmpty else { throw DraftError.noReflections }

        var parts: [String] = []
        parts.append(opening(request))
        parts.append(roleSentence(for: request.experienceType))

        let budget = request.kind == .mostMeaningful ? 5 : 3
        for note in reflections.prefix(budget) {
            parts.append(DraftText.sentences(from: note, max: request.kind == .mostMeaningful ? 3 : 2))
        }

        if request.kind == .mostMeaningful {
            parts.append("[Add: how this experience changed you, and why it matters for the physician you want to become.]")
        } else {
            parts.append(closing(for: request.experienceType))
        }

        let text = parts.filter { !$0.isEmpty }.joined(separator: " ")
        return DraftText.trim(text, to: request.characterLimit)
    }

    private func opening(_ r: DraftRequest) -> String {
        let hours = Int(r.totalHours.rounded())
        let since = r.startDate.formatted(.dateTime.month(.wide).year())
        let org = r.organization.isEmpty ? "" : " at \(r.organization)"
        let span = r.endDate == nil
            ? "since \(since)"
            : "from \(since) to \(r.endDate!.formatted(.dateTime.month(.wide).year()))"
        let hoursText = hours > 0 ? ", contributing \(hours) hours" : ""
        return "I have served as \(article(for: r.title)) \(r.title)\(org) \(span)\(hoursText)."
    }

    private func article(for word: String) -> String {
        guard let first = word.lowercased().first else { return "a" }
        return "aeiou".contains(first) ? "an" : "a"
    }

    private func roleSentence(for type: String) -> String {
        guard let t = ExperienceType(rawValue: type) else { return "" }
        switch t.group {
        case .clinical: return "The role put me in direct contact with patients and the care team."
        case .shadowing: return "Observing physicians showed me the day-to-day realities of practicing medicine."
        case .volunteering: return "The work connected me with my community and the people it serves."
        case .research: return "The work taught me to ask careful questions and follow the data."
        case .other: return ""
        }
    }

    private func closing(for type: String) -> String {
        guard let t = ExperienceType(rawValue: type) else { return "" }
        switch t.group {
        case .clinical, .shadowing: return "These moments continue to shape how I think about patient care."
        case .volunteering: return "It strengthened my commitment to serving others."
        case .research: return "It deepened my appreciation for the science behind medicine."
        case .other: return "It taught me lessons I bring into everything I do."
        }
    }
}

// MARK: - Text helpers

enum DraftText {
    /// Takes up to `max` sentences from a note and makes sure it ends with punctuation.
    static func sentences(from note: String, max: Int) -> String {
        let cleaned = note.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
        var result: [String] = []
        cleaned.enumerateSubstrings(in: cleaned.startIndex..., options: .bySentences) { sub, _, _, stop in
            if let s = sub?.trimmingCharacters(in: .whitespaces), !s.isEmpty { result.append(s) }
            if result.count >= max { stop = true }
        }
        var joined = result.joined(separator: " ")
        if let last = joined.last, !".!?".contains(last) { joined += "." }
        if let first = joined.first { joined = first.uppercased() + joined.dropFirst() }
        return joined
    }

    /// Trims to the limit, preferring to cut at the end of a sentence, then a word.
    static func trim(_ text: String, to limit: Int) -> String {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count > limit else { return text }
        let prefix = String(text.prefix(limit))
        if let end = prefix.lastIndex(where: { ".!?".contains($0) }),
           prefix.distance(from: prefix.startIndex, to: end) > limit / 2 {
            return String(prefix[...end])
        }
        if let space = prefix.lastIndex(of: " ") {
            return String(prefix[..<space]) + "…"
        }
        return prefix
    }
}

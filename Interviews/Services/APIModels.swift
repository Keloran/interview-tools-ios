//
//  APIModels.swift
//  Interviews
//
//  Created by keloran on 06/12/2025.
//

import Foundation

// MARK: - API Response Models

struct APIInterview: Codable, Sendable {
    let id: Int
    let jobTitle: String
    let interviewer: String?
    let company: APICompany
    let clientCompany: String?
    let stage: APIStage?
    let stageMethod: APIStageMethod?
    let applicationDate: String
    let date: String?
    let deadline: String?
    let outcome: String?
    let notes: String?
    let metadata: APIMetadata?
    let link: String?
    /// The application this stage belongs to (stages of one application share it)
    let applicationId: Int?
    let durationMinutes: Int?
    let viaRecruiter: Bool?
    let recruiterName: String?
    let recruiterEmail: String?
    let recruiterLinkedIn: String?

    enum CodingKeys: String, CodingKey {
        case id, jobTitle, interviewer, company, clientCompany
        case stage, stageMethod, applicationDate, date, deadline
        case outcome, notes, metadata, link, applicationId, durationMinutes
        case viaRecruiter, recruiterName, recruiterEmail, recruiterLinkedIn
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        jobTitle = try container.decode(String.self, forKey: .jobTitle)
        interviewer = try container.decodeIfPresent(String.self, forKey: .interviewer)
        company = try container.decode(APICompany.self, forKey: .company)
        clientCompany = try container.decodeIfPresent(String.self, forKey: .clientCompany)
        stage = try container.decodeIfPresent(APIStage.self, forKey: .stage)
        stageMethod = try container.decodeIfPresent(APIStageMethod.self, forKey: .stageMethod)
        applicationDate = try container.decode(String.self, forKey: .applicationDate)
        date = try container.decodeIfPresent(String.self, forKey: .date)
        deadline = try container.decodeIfPresent(String.self, forKey: .deadline)
        outcome = try container.decodeIfPresent(String.self, forKey: .outcome)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        metadata = try container.decodeIfPresent(APIMetadata.self, forKey: .metadata)
        link = try container.decodeIfPresent(String.self, forKey: .link)
        applicationId = try container.decodeIfPresent(Int.self, forKey: .applicationId)
        durationMinutes = try container.decodeIfPresent(Int.self, forKey: .durationMinutes)
        viaRecruiter = try container.decodeIfPresent(Bool.self, forKey: .viaRecruiter)
        recruiterName = try container.decodeIfPresent(String.self, forKey: .recruiterName)
        recruiterEmail = try container.decodeIfPresent(String.self, forKey: .recruiterEmail)
        recruiterLinkedIn = try container.decodeIfPresent(String.self, forKey: .recruiterLinkedIn)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(jobTitle, forKey: .jobTitle)
        try container.encodeIfPresent(interviewer, forKey: .interviewer)
        try container.encode(company, forKey: .company)
        try container.encodeIfPresent(clientCompany, forKey: .clientCompany)
        try container.encodeIfPresent(stage, forKey: .stage)
        try container.encodeIfPresent(stageMethod, forKey: .stageMethod)
        try container.encode(applicationDate, forKey: .applicationDate)
        try container.encodeIfPresent(date, forKey: .date)
        try container.encodeIfPresent(deadline, forKey: .deadline)
        try container.encodeIfPresent(outcome, forKey: .outcome)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(metadata, forKey: .metadata)
        try container.encodeIfPresent(link, forKey: .link)
    }
}

struct APICompany: Codable, Sendable {
    let id: Int
    let name: String

    enum CodingKeys: String, CodingKey {
        case id, name
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
    }
}

struct APIStage: Codable, Sendable {
    let id: Int
    let stage: String

    enum CodingKeys: String, CodingKey {
        case id, stage
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        stage = try container.decode(String.self, forKey: .stage)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(stage, forKey: .stage)
    }
}

struct APIStageMethod: Codable, Sendable {
    let id: Int
    let method: String

    enum CodingKeys: String, CodingKey {
        case id, method
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        method = try container.decode(String.self, forKey: .method)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(method, forKey: .method)
    }
}

struct APIMetadata: Codable, Sendable {
    let jobListing: String?
    let location: String?

    enum CodingKeys: String, CodingKey {
        case jobListing, location
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        jobListing = try container.decodeIfPresent(String.self, forKey: .jobListing)
        location = try container.decodeIfPresent(String.self, forKey: .location)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(jobListing, forKey: .jobListing)
        try container.encodeIfPresent(location, forKey: .location)
    }
}

// MARK: - API Request Models

struct CreateInterviewRequest: Codable, Sendable {
    let stage: String
    let companyName: String
    let clientCompany: String?
    let jobTitle: String
    let jobPostingLink: String?
    let date: String?
    let deadline: String?
    let interviewer: String?
    let locationType: String?
    let interviewLink: String?
    let notes: String?
    /// The stage this follows; the server adds it to that application instead of creating a new one
    var previousInterviewId: Int? = nil
    /// An offer's respond-by day, "yyyy-MM-dd" (offers ignore `deadline`)
    var offerDeadline: String? = nil

    enum CodingKeys: String, CodingKey {
        case stage, companyName, clientCompany, jobTitle
        case jobPostingLink, date, deadline, interviewer
        case locationType, interviewLink, notes, previousInterviewId, offerDeadline
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(stage, forKey: .stage)
        try container.encode(companyName, forKey: .companyName)
        try container.encodeIfPresent(clientCompany, forKey: .clientCompany)
        try container.encode(jobTitle, forKey: .jobTitle)
        try container.encodeIfPresent(jobPostingLink, forKey: .jobPostingLink)
        try container.encodeIfPresent(date, forKey: .date)
        try container.encodeIfPresent(deadline, forKey: .deadline)
        try container.encodeIfPresent(interviewer, forKey: .interviewer)
        try container.encodeIfPresent(locationType, forKey: .locationType)
        try container.encodeIfPresent(interviewLink, forKey: .interviewLink)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(previousInterviewId, forKey: .previousInterviewId)
        try container.encodeIfPresent(offerDeadline, forKey: .offerDeadline)
    }
}

struct UpdateInterviewRequest: Encodable, Sendable {
    let outcome: String?
    let stage: String?
    let date: String?
    let deadline: String?
    let interviewer: String?
    let notes: String?
    let link: String?
    var jobTitle: String? = nil
    var clientCompany: String? = nil
    var jobListing: String? = nil
    var durationMinutes: Int? = nil
    /// A full snapshot of the edit screen: empty fields are sent as cleared (null, or "" for notes, which the
    /// server only takes as a string) instead of being left out and silently kept on the server
    var clearsEmptyFields = false

    enum CodingKeys: String, CodingKey {
        case outcome, stage, date, deadline, interviewer, notes, link, jobTitle, clientCompany, metadata, durationMinutes
    }
    private enum MetadataKeys: String, CodingKey { case jobListing }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(outcome, forKey: .outcome)
        try container.encodeIfPresent(stage, forKey: .stage)
        try container.encodeIfPresent(jobTitle, forKey: .jobTitle)
        try container.encodeIfPresent(durationMinutes, forKey: .durationMinutes)
        // The job link lives on the application; the server reads it from metadata.jobListing
        if clearsEmptyFields || jobListing != nil {
            var metadata = container.nestedContainer(keyedBy: MetadataKeys.self, forKey: .metadata)
            if let jobListing { try metadata.encode(jobListing, forKey: .jobListing) } else { try metadata.encodeNil(forKey: .jobListing) }
        }
        if clearsEmptyFields {
            for (value, key) in [(date, CodingKeys.date), (deadline, .deadline), (interviewer, .interviewer), (link, .link), (clientCompany, .clientCompany)] {
                if let value { try container.encode(value, forKey: key) } else { try container.encodeNil(forKey: key) }
            }
            try container.encode(notes ?? "", forKey: .notes)
        } else {
            try container.encodeIfPresent(date, forKey: .date)
            try container.encodeIfPresent(deadline, forKey: .deadline)
            try container.encodeIfPresent(interviewer, forKey: .interviewer)
            try container.encodeIfPresent(notes, forKey: .notes)
            try container.encodeIfPresent(link, forKey: .link)
            try container.encodeIfPresent(clientCompany, forKey: .clientCompany)
        }
    }
}

// MARK: - API Error

enum APIError: Error, LocalizedError {
    case unauthorized
    case invalidResponse
    case networkError(Error)
    case serverError(String)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Unauthorized. Please sign in."
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        }
    }
}

// MARK: - Application timeline (GET /api/applications/{id}/timeline)

nonisolated struct APITimeline: Decodable, Sendable {
    nonisolated struct Named: Decodable, Sendable { let name: String }
    nonisolated struct StageName: Decodable, Sendable { let stage: String }
    nonisolated struct Stage: Decodable, Sendable {
        let id: Int
        let parentId: Int?
        let date: String?
        let deadline: String?
        let created_at: String
        let updated_at: String
        let outcome: String?
        let interviewer: String?
        let stage: StageName
    }
    nonisolated struct FollowUp: Decodable, Sendable { let id: Int; let sentAt: String }
    nonisolated struct Link: Decodable, Sendable {
        let id: Int
        let created_at: String
        let bookedSlot: String?
        let viewCount: Int
        let firstViewedAt: String?
        let stage: StageName
    }

    let id: Int
    let jobTitle: String
    let clientCompany: String?
    let applicationDate: String
    let company: Named
    let interviews: [Stage]
    let followUps: [FollowUp]
    let availabilityLinks: [Link]
}

// MARK: - Offers (GET /api/offers)

/// An open offer: the latest stage of an application is an Offer still waiting on your decision
nonisolated struct APIOffer: Decodable, Sendable, Identifiable {
    let applicationId: Int
    let interviewId: Int
    let jobTitle: String
    /// The employer (the client, for agency roles)
    let company: String
    let agency: String?
    let interviewer: String?
    /// Respond-by day, "yyyy-MM-dd"
    let deadline: String?
    let outcome: String?
    let advertisedSalary: String?
    let offerBase: String?
    let offerBonus: String?
    let offerEquity: String?
    let offerBenefits: String?
    let offerNotice: String?
    let offerLocation: String?

    var id: Int { interviewId }

    /// The comparison rows, in the website's order and wording
    static let details: [(label: String, value: KeyPath<APIOffer, String?>, key: String)] = [
        ("Advertised salary", \.advertisedSalary, "advertisedSalary"),
        ("Base salary", \.offerBase, "offerBase"),
        ("Bonus", \.offerBonus, "offerBonus"),
        ("Equity", \.offerEquity, "offerEquity"),
        ("Benefits", \.offerBenefits, "offerBenefits"),
        ("Notice period", \.offerNotice, "offerNotice"),
        ("Location / working pattern", \.offerLocation, "offerLocation"),
    ]
}

// MARK: - Follow-ups and stale applications

/// An application due a chase (GET /api/follow-ups)
nonisolated struct APIFollowUp: Decodable, Sendable, Identifiable {
    let id: Int
    let jobTitle: String
    let clientCompany: String?
    let company: String
    let stage: String
    let interviewer: String?
    let date: String?
    let nextStep: String?
    let replyBy: String?
    let followUps: Int
    let lastFollowUp: String?
    let dueAt: String
}

/// Applications that have gone quiet past your threshold (GET /api/stale-applications)
nonisolated struct APIStaleList: Decodable, Sendable {
    nonisolated struct Candidate: Decodable, Sendable, Identifiable {
        let id: Int
        let company: String
        let jobTitle: String
        let lastStage: String
        let lastActivity: String
        let quietDays: Int
    }
    let days: Int
    let total: Int
    let candidates: [Candidate]
}

nonisolated struct APICloseResult: Decodable, Sendable {
    let closed: [Int]
    let skipped: [Int]
}

// MARK: - After the interview: debrief, prep, questions, stories

/// The debrief and feedback recorded on one stage (from GET /api/interview/{id})
nonisolated struct APIDebrief: Decodable, Sendable {
    let rating: Int?
    let debriefNotes: String?
    let peopleMet: String?
    let questionsAsked: String?
    let nextStep: String?
    let replyBy: String?
    let feedbackType: String?
    let feedbackText: String?
    let debriefedAt: String?
}

/// What PUT /api/interview/{id} takes for a debrief. prepNotes is left out on purpose, so saving a
/// debrief never wipes separately saved preparation.
nonisolated struct DebriefRequest: Encodable, Sendable {
    nonisolated struct Debrief: Encodable, Sendable {
        var rating: Int?
        var debriefNotes: String
        var peopleMet: String
        var questionsAsked: String
        var nextStep: String
        var replyBy: String?
    }
    nonisolated struct Feedback: Encodable, Sendable {
        var type: String?
        var text: String
    }
    var debrief: Debrief
    var feedback: Feedback?
}

nonisolated struct APIPrep: Codable, Sendable {
    var notes: String
    var storyIds: [Int]
}

nonisolated struct APIStory: Codable, Sendable, Identifiable, Hashable {
    nonisolated struct Use: Codable, Sendable, Hashable { let interviewId: Int; let company: String; let stage: String }
    var id: Int
    var title: String
    var situation: String
    var task: String
    var action: String
    var result: String
    var tags: [String]
    var usedIn: [Use]
}

/// Fields for creating or editing a story
nonisolated struct StoryInput: Encodable, Sendable {
    var title = ""
    var situation = ""
    var task = ""
    var action = ""
    var result = ""
    var tags: [String] = []
}

/// One stage's recorded questions (GET /api/questions)
nonisolated struct APIQuestionEntry: Decodable, Sendable, Identifiable {
    let interviewId: Int
    let company: String
    let recruiter: String?
    let stage: String
    let date: String
    let jobTitle: String
    let questions: [String]
    let notes: String?
    var id: Int { interviewId }
}

// MARK: - Availability links

nonisolated struct APIAvailabilityList: Decodable, Sendable {
    nonisolated struct Link: Decodable, Sendable, Identifiable {
        let id: String
        let slots: [String]
        let durationMinutes: Int
        let bookedSlot: String?
        let viewCount: Int
        let firstViewedAt: String?
        let lastViewedAt: String?
        let created_at: String
        let sentAt: String?
        let stage: String
        let path: String
    }
    let jobTitle: String
    let company: String
    let links: [Link]
}

nonisolated struct APICreatedLink: Decodable, Sendable {
    let id: String
    let path: String
}

nonisolated struct APIBusy: Decodable, Sendable {
    let start: String
    let durationMinutes: Int
}

// MARK: - Report, activity log, calendar feed

/// GET /api/report/summary: the website's job-search report for a period
nonisolated struct APIReport: Decodable, Sendable {
    nonisolated struct Step: Decodable, Sendable { let label: String; let count: Int; let conversion: Int? }
    nonisolated struct Insights: Decodable, Sendable {
        let roles: Int
        let responded: Int
        let ghosted: Int
        let waiting: Int
        let responseRate: Int?
        let ghostRate: Int?
        let feedbackRate: Int?
        let medianReplyDays: Double?
    }
    nonisolated struct Week: Decodable, Sendable { let week: String; let applications: Int; let interviews: Int }
    nonisolated struct Source: Decodable, Sendable {
        let source: String
        let roles: Int
        let responseRate: Int?
        let ghostRate: Int?
    }
    let from: String
    let through: String
    let funnel: [Step]
    let response: Insights
    let weekly: [Week]
    let sources: [Source]
}

/// GET /api/activity-log/rows: the evidence log for a work coach
nonisolated struct APIActivityLog: Decodable, Sendable {
    nonisolated struct Totals: Decodable, Sendable { let total: Int; let applied: Int; let interviews: Int; let followUps: Int; let availability: Int; let other: Int }
    nonisolated struct Row: Decodable, Sendable, Identifiable {
        let id: String
        let date: String
        let kind: String
        let activity: String
        let employer: String
        let role: String
        let how: String
        let outcome: String
        let notes: String
        /// Rows you added yourself ("entry-12") can be deleted
        var entryId: Int? { id.hasPrefix("entry-") ? Int(id.dropFirst(6)) : nil }
    }
    let from: String
    let through: String
    let totals: Totals
    let rows: [Row]
}

/// Something that isn't an application: a careers fair, a CV workshop, a Jobcentre appointment
nonisolated struct ActivityEntryInput: Encodable, Sendable {
    var date: String
    var activity = ""
    var employer = ""
    var role = ""
    var how = ""
    var outcome = ""
    var notes = ""
}

nonisolated struct APICalendarSettings: Decodable, Sendable {
    let calendarUrl: String
}

// MARK: - Recruiters and agencies

/// One agency (contact nil) or one recruiter at it, with their record (GET /api/recruiters)
nonisolated struct APIRecruiterRecord: Decodable, Sendable, Identifiable {
    nonisolated struct Contact: Decodable, Sendable {
        let recruiterName: String?
        let recruiterEmail: String?
        let recruiterLinkedIn: String?
    }
    nonisolated struct Stats: Decodable, Sendable {
        let roles: Int
        let responded: Int
        let ghosted: Int
        let waiting: Int
        let responseRate: Int?
        let ghostRate: Int?
        let feedbackRate: Int?
    }
    let key: String
    let agency: String
    let contact: Contact?
    let stats: Stats
    var id: String { key }
}

/// PUT /api/applications/{id}/recruiter
nonisolated struct RecruiterContactRequest: Encodable, Sendable {
    var viaRecruiter: Bool
    var recruiterName: String
    var recruiterEmail: String
    var recruiterLinkedIn: String
}

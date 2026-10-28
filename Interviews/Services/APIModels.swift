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

    enum CodingKeys: String, CodingKey {
        case id, jobTitle, interviewer, company, clientCompany
        case stage, stageMethod, applicationDate, date, deadline
        case outcome, notes, metadata, link, applicationId, durationMinutes
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

struct APITimeline: Decodable, Sendable {
    struct Named: Decodable, Sendable { let name: String }
    struct StageName: Decodable, Sendable { let stage: String }
    struct Stage: Decodable, Sendable {
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
    struct FollowUp: Decodable, Sendable { let id: Int; let sentAt: String }
    struct Link: Decodable, Sendable {
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
struct APIOffer: Decodable, Sendable, Identifiable {
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

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

    enum CodingKeys: String, CodingKey {
        case id, jobTitle, interviewer, company, clientCompany
        case stage, stageMethod, applicationDate, date, deadline
        case outcome, notes, metadata, link
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

    enum CodingKeys: String, CodingKey {
        case stage, companyName, clientCompany, jobTitle
        case jobPostingLink, date, deadline, interviewer
        case locationType, interviewLink, notes
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
    }
}

struct UpdateInterviewRequest: Codable, Sendable {
    let outcome: String?
    let stage: String?
    let date: String?
    let deadline: String?
    let interviewer: String?
    let notes: String?
    let link: String?

    enum CodingKeys: String, CodingKey {
        case outcome, stage, date, deadline, interviewer, notes, link
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(outcome, forKey: .outcome)
        try container.encodeIfPresent(stage, forKey: .stage)
        try container.encodeIfPresent(date, forKey: .date)
        try container.encodeIfPresent(deadline, forKey: .deadline)
        try container.encodeIfPresent(interviewer, forKey: .interviewer)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(link, forKey: .link)
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

//
//  APIModels.swift
//  Interviews
//
//  Created by keloran on 06/12/2025.
//

import Foundation

// MARK: - API Response Models

struct APIInterview: Codable {
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
}

struct APICompany: Codable {
    let id: Int
    let name: String
}

struct APIStage: Codable {
    let id: Int
    let stage: String
}

struct APIStageMethod: Codable {
    let id: Int
    let method: String
}

struct APIMetadata: Codable {
    let jobListing: String?
    let location: String?
}

// MARK: - API Request Models

struct CreateInterviewRequest: Codable {
    let stage: String
    let companyName: String
    let clientCompany: String?
    let jobTitle: String
    let jobPostingLink: String?
    let date: String? // ISO string
    let deadline: String? // ISO string for Technical Test
    let interviewer: String?
    let locationType: String? // "phone" | "link"
    let interviewLink: String?
    let notes: String?
}

struct UpdateInterviewRequest: Codable {
    let outcome: String?
    let stage: String?
    let date: String?
    let deadline: String?
    let interviewer: String?
    let notes: String?
    let link: String?
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

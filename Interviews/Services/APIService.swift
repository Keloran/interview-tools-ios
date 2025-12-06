//
//  APIService.swift
//  Interviews
//
//  Created by keloran on 06/12/2025.
//

import Foundation

// Empty body type for requests without a body
private struct EmptyBody: Encodable, Sendable {
    nonisolated func encode(to encoder: Encoder) throws {
        // Empty body, nothing to encode
        _ = encoder.container(keyedBy: _CodingKeys.self)
    }

    private enum _CodingKeys: CodingKey {}
}

actor APIService {
    static let shared = APIService()

    private let baseURL = "https://interviews.tools/api"
    private var authToken: String?

    private init() {}

    // MARK: - Authentication

    func setAuthToken(_ token: String?) {
        self.authToken = token
    }

    // MARK: - Companies

    func fetchCompanies() async throws -> [APICompany] {
        let url = URL(string: "\(baseURL)/companies")!
        return try await performRequest(url: url, method: "GET")
    }

    // MARK: - Stages

    func fetchStages() async throws -> [APIStage] {
        let url = URL(string: "\(baseURL)/stages")!
        return try await performRequest(url: url, method: "GET")
    }

    // MARK: - Stage Methods

    func fetchStageMethods() async throws -> [APIStageMethod] {
        let url = URL(string: "\(baseURL)/stage-methods")!
        return try await performRequest(url: url, method: "GET")
    }

    // MARK: - Interviews

    func fetchInterviews(
        date: String? = nil,
        dateFrom: String? = nil,
        dateTo: String? = nil,
        includePast: Bool? = nil,
        companyId: Int? = nil,
        companyName: String? = nil,
        outcome: String? = nil
    ) async throws -> [APIInterview] {
        var components = URLComponents(string: "\(baseURL)/interviews")!
        var queryItems: [URLQueryItem] = []

        if let date = date {
            queryItems.append(URLQueryItem(name: "date", value: date))
        }
        if let dateFrom = dateFrom {
            queryItems.append(URLQueryItem(name: "dateFrom", value: dateFrom))
        }
        if let dateTo = dateTo {
            queryItems.append(URLQueryItem(name: "dateTo", value: dateTo))
        }
        if let includePast = includePast {
            queryItems.append(URLQueryItem(name: "includePast", value: String(includePast)))
        }
        if let companyId = companyId {
            queryItems.append(URLQueryItem(name: "companyId", value: String(companyId)))
        }
        if let companyName = companyName {
            queryItems.append(URLQueryItem(name: "company", value: companyName))
        }
        if let outcome = outcome {
            queryItems.append(URLQueryItem(name: "outcome", value: outcome))
        }

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw APIError.invalidResponse
        }

        return try await performRequest(url: url, method: "GET")
    }

    func createInterview(_ request: CreateInterviewRequest) async throws -> APIInterview {
        let url = URL(string: "\(baseURL)/interview")!
        return try await performRequest(url: url, method: "POST", body: request)
    }

    func updateInterview(id: Int, _ request: UpdateInterviewRequest) async throws -> APIInterview {
        let url = URL(string: "\(baseURL)/interview/\(id)")!
        return try await performRequest(url: url, method: "PUT", body: request)
    }

    // MARK: - Private Helpers

    private func performRequest<T: Decodable & Sendable>(
        url: URL,
        method: String
    ) async throws -> T {
        try await performRequestWithBody(url: url, method: method, body: Optional<EmptyBody>.none)
    }

    private func performRequest<T: Decodable & Sendable, Body: Encodable & Sendable>(
        url: URL,
        method: String,
        body: Body
    ) async throws -> T {
        try await performRequestWithBody(url: url, method: method, body: body)
    }

    private func performRequestWithBody<T: Decodable & Sendable, Body: Encodable & Sendable>(
        url: URL,
        method: String,
        body: Body?
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth token if available
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Encode body if provided
        if let body = body {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        case 401:
            throw APIError.unauthorized
        default:
            if let errorMessage = try? JSONDecoder().decode([String: String].self, from: data),
               let message = errorMessage["message"] {
                throw APIError.serverError(message)
            }
            throw APIError.serverError("HTTP \(httpResponse.statusCode)")
        }
    }
}

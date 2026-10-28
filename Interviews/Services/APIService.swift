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

    private init() {}

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
        outcome: String? = nil,
        take: Int? = nil,
        skip: Int? = nil
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
        if let take = take {
            queryItems.append(URLQueryItem(name: "take", value: String(take)))
        }
        if let skip = skip {
            queryItems.append(URLQueryItem(name: "skip", value: String(skip)))
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

    // MARK: - Applications

    func fetchTimeline(applicationId: Int) async throws -> APITimeline {
        let url = URL(string: "\(baseURL)/applications/\(applicationId)/timeline")!
        return try await performRequest(url: url, method: "GET")
    }

    // MARK: - Offers

    func fetchOffers() async throws -> [APIOffer] {
        let url = URL(string: "\(baseURL)/offers")!
        return try await performRequest(url: url, method: "GET")
    }

    /// Set or clear the respond-by day ("yyyy-MM-dd"), or record accepting/declining
    func updateOffer(interviewId: Int, deadline: String?? = nil, decision: InterviewOutcome? = nil) async throws {
        nonisolated struct Body: Encodable, Sendable {
            let deadline: String??
            let decision: String?
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: Keys.self)
                if let deadline { if let day = deadline { try container.encode(day, forKey: .deadline) } else { try container.encodeNil(forKey: .deadline) } }
                if let decision {
                    try container.encode(decision, forKey: .decision)
                    try container.encode(true, forKey: .confirmDecision)
                }
            }
            enum Keys: String, CodingKey { case deadline, decision, confirmDecision }
        }
        let url = URL(string: "\(baseURL)/offers/\(interviewId)")!
        _ = try await send(url: url, method: "PUT", body: Body(deadline: deadline, decision: decision?.rawValue))
    }

    /// Save salary and offer details; an empty field clears it
    func updateCompensation(interviewId: Int, _ fields: [String: String]) async throws {
        let url = URL(string: "\(baseURL)/interview/\(interviewId)/compensation")!
        let body = fields.mapValues { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.mapValues { $0.isEmpty ? nil : $0 }
        _ = try await send(url: url, method: "PUT", body: body)
    }

    // MARK: - Follow-ups and ghosting

    func fetchFollowUps() async throws -> [APIFollowUp] {
        try await performRequest(url: URL(string: "\(baseURL)/follow-ups")!, method: "GET")
    }

    /// Record that you chased this application today
    func recordFollowUp(applicationId: Int) async throws {
        _ = try await send(url: URL(string: "\(baseURL)/follow-ups")!, method: "POST", body: ["applicationId": applicationId])
    }

    func fetchStaleApplications() async throws -> APIStaleList {
        try await performRequest(url: URL(string: "\(baseURL)/stale-applications")!, method: "GET")
    }

    /// Close applications as ghosted (NO_RESPONSE); ones that changed since the list loaded are skipped
    func closeStaleApplications(ids: [Int], days: Int) async throws -> APICloseResult {
        nonisolated struct Body: Encodable, Sendable { let ids: [Int]; let days: Int; let confirm = true }
        return try await performRequest(url: URL(string: "\(baseURL)/stale-applications")!, method: "POST", body: Body(ids: ids, days: days))
    }

    // MARK: - After the interview

    func fetchDebrief(interviewId: Int) async throws -> APIDebrief {
        try await performRequest(url: URL(string: "\(baseURL)/interview/\(interviewId)")!, method: "GET")
    }

    func saveDebrief(interviewId: Int, _ request: DebriefRequest) async throws {
        _ = try await send(url: URL(string: "\(baseURL)/interview/\(interviewId)")!, method: "PUT", body: request)
    }

    func fetchPrep(interviewId: Int) async throws -> APIPrep {
        try await performRequest(url: URL(string: "\(baseURL)/interview/\(interviewId)/prep")!, method: "GET")
    }

    func savePrep(interviewId: Int, _ prep: APIPrep) async throws {
        _ = try await send(url: URL(string: "\(baseURL)/interview/\(interviewId)/prep")!, method: "PUT", body: prep)
    }

    func fetchQuestions() async throws -> [APIQuestionEntry] {
        try await performRequest(url: URL(string: "\(baseURL)/questions")!, method: "GET")
    }

    func fetchStories() async throws -> [APIStory] {
        try await performRequest(url: URL(string: "\(baseURL)/stories")!, method: "GET")
    }

    /// Create (no id) or update a STAR story
    func saveStory(id: Int?, _ story: StoryInput) async throws {
        let url = URL(string: "\(baseURL)/stories" + (id.map { "/\($0)" } ?? ""))!
        _ = try await send(url: url, method: id == nil ? "POST" : "PUT", body: story)
    }

    func deleteStory(id: Int) async throws {
        _ = try await send(url: URL(string: "\(baseURL)/stories/\(id)")!, method: "DELETE", body: Optional<EmptyBody>.none)
    }

    // MARK: - Availability links

    func fetchAvailability(interviewId: Int) async throws -> APIAvailabilityList {
        var components = URLComponents(string: "\(baseURL)/availability")!
        components.queryItems = [URLQueryItem(name: "interviewId", value: String(interviewId))]
        return try await performRequest(url: components.url!, method: "GET")
    }

    func createAvailability(interviewId: Int, stage: String, durationMinutes: Int, slots: [Date]) async throws -> APICreatedLink {
        nonisolated struct Body: Encodable, Sendable { let interviewId: Int; let stage: String; let durationMinutes: Int; let slots: [String] }
        let body = Body(interviewId: interviewId, stage: stage, durationMinutes: durationMinutes, slots: slots.map(APIDates.instantString))
        return try await performRequest(url: URL(string: "\(baseURL)/availability")!, method: "POST", body: body)
    }

    func markAvailabilitySent(linkId: String, sent: Bool = true) async throws {
        _ = try await send(url: URL(string: "\(baseURL)/availability/\(linkId)/sent")!, method: "PUT", body: ["sent": sent])
    }

    /// Google Calendar busy times; [] when nothing is connected (or on any error, so slots still show)
    func fetchBusy(from: Date, to: Date) async -> [APIBusy] {
        var components = URLComponents(string: "\(baseURL)/busy")!
        components.queryItems = [URLQueryItem(name: "from", value: APIDates.instantString(from)), URLQueryItem(name: "to", value: APIDates.instantString(to))]
        return (try? await performRequest(url: components.url!, method: "GET")) ?? []
    }

    // MARK: - Report and activity log

    private func periodURL(_ path: String, from: String, through: String, csv: Bool = false) -> URL {
        var components = URLComponents(string: "\(baseURL)/\(path)")!
        components.queryItems = [URLQueryItem(name: "from", value: from), URLQueryItem(name: "through", value: through)]
            + (csv ? [URLQueryItem(name: "format", value: "csv")] : [])
        return components.url!
    }

    func fetchReport(from: String, through: String) async throws -> APIReport {
        try await performRequest(url: periodURL("report/summary", from: from, through: through), method: "GET")
    }

    func fetchActivityLog(from: String, through: String) async throws -> APIActivityLog {
        try await performRequest(url: periodURL("activity-log/rows", from: from, through: through), method: "GET")
    }

    /// The same CSV the website exports, for a work coach
    func exportActivityLog(from: String, through: String) async throws -> Data {
        try await send(url: periodURL("activity-log/rows", from: from, through: through, csv: true), method: "GET", body: Optional<EmptyBody>.none)
    }

    func addActivity(_ entry: ActivityEntryInput) async throws {
        _ = try await send(url: URL(string: "\(baseURL)/activity-log")!, method: "POST", body: entry)
    }

    func deleteActivity(id: Int) async throws {
        _ = try await send(url: URL(string: "\(baseURL)/activity-log/\(id)")!, method: "DELETE", body: Optional<EmptyBody>.none)
    }

    func fetchCalendarSettings() async throws -> APICalendarSettings {
        try await performRequest(url: URL(string: "\(baseURL)/calendar-settings")!, method: "GET")
    }

    // MARK: - Your data

    /// The server needs the same typed phrase as the website before it deletes anything
    static let deleteConfirmation = "delete my account"

    /// Deletes everything on the server, then the login. Throws with the server's message if either part fails,
    /// and retrying is safe.
    func deleteAccount() async throws {
        let url = URL(string: "\(baseURL)/account")!
        _ = try await send(url: url, method: "DELETE", body: ["confirm": Self.deleteConfirmation])
    }

    /// CSV of your applications (with stages and notes) or your STAR stories, fetched with the Bearer token
    func exportData(kind: String) async throws -> Data {
        var components = URLComponents(string: "\(baseURL)/data/export")!
        components.queryItems = [URLQueryItem(name: "kind", value: kind)]
        return try await send(url: components.url!, method: "GET", body: Optional<EmptyBody>.none)
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
        let data = try await send(url: url, method: method, body: body)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    /// Sends the request and returns the raw body of a 2xx response
    private func send<Body: Encodable & Sendable>(
        url: URL,
        method: String,
        body: Body?
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // A fresh token from the current session each time; signed out means no token
        if let token = await AuthToken.current() {
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
            return data
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

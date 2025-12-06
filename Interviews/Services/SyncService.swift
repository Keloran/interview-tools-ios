//
//  SyncService.swift
//  Interviews
//
//  Created by keloran on 06/12/2025.
//

import Foundation
import Combine
import SwiftData

@MainActor
class SyncService: ObservableObject {
    private let apiService = APIService.shared
    private let modelContext: ModelContext

    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: Error?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Sync All Data

    func syncAll() async {
        isSyncing = true
        syncError = nil

        do {
            // Sync in order: Companies -> Stages -> Methods -> Interviews
            try await syncCompanies()
            try await syncStages()
            try await syncStageMethods()
            try await syncInterviews()

            lastSyncDate = Date()
        } catch {
            syncError = error
            print("Sync error: \(error)")
        }

        isSyncing = false
    }

    // MARK: - Sync Companies

    private func syncCompanies() async throws {
        let apiCompanies = try await apiService.fetchCompanies()

        for apiCompany in apiCompanies {
            // Find or create company
            let companyId = apiCompany.id
            let descriptor = FetchDescriptor<Company>(
                predicate: #Predicate { company in
                    company.id == companyId
                }
            )

            let existing = try modelContext.fetch(descriptor).first

            if let existing = existing {
                // Update existing
                existing.name = apiCompany.name
            } else {
                // Create new
                let company = Company(id: apiCompany.id, name: apiCompany.name)
                modelContext.insert(company)
            }
        }

        try modelContext.save()
    }

    // MARK: - Sync Stages

    private func syncStages() async throws {
        let apiStages = try await apiService.fetchStages()

        for apiStage in apiStages {
            // Capture the ID in a local variable to use in predicate
            let stageId = apiStage.id
            let descriptor = FetchDescriptor<Stage>(
                predicate: #Predicate { stage in
                    stage.id == stageId
                }
            )

            let existing = try modelContext.fetch(descriptor).first

            if let existing = existing {
                existing.stage = apiStage.stage
            } else {
                let stage = Stage(id: apiStage.id, stage: apiStage.stage)
                modelContext.insert(stage)
            }
        }

        try modelContext.save()
    }

    // MARK: - Sync Stage Methods

    private func syncStageMethods() async throws {
        let apiMethods = try await apiService.fetchStageMethods()

        for apiMethod in apiMethods {
            // Capture the ID in a local variable to use in predicate
            let methodId = apiMethod.id
            let descriptor = FetchDescriptor<StageMethod>(
                predicate: #Predicate { method in
                    method.id == methodId
                }
            )

            let existing = try modelContext.fetch(descriptor).first

            if let existing = existing {
                existing.method = apiMethod.method
            } else {
                let method = StageMethod(id: apiMethod.id, method: apiMethod.method)
                modelContext.insert(method)
            }
        }

        try modelContext.save()
    }

    // MARK: - Sync Interviews

    private func syncInterviews() async throws {
        let apiInterviews = try await apiService.fetchInterviews(includePast: true)

        for apiInterview in apiInterviews {
            // Find or create company
            let companyId = apiInterview.company.id
            let companyDescriptor = FetchDescriptor<Company>(
                predicate: #Predicate { company in
                    company.id == companyId
                }
            )
            guard let company = try modelContext.fetch(companyDescriptor).first else {
                continue
            }

            // Find stage
            var stage: Stage?
            if let apiStage = apiInterview.stage {
                let stageId = apiStage.id
                let stageDescriptor = FetchDescriptor<Stage>(
                    predicate: #Predicate { stage in
                        stage.id == stageId
                    }
                )
                stage = try modelContext.fetch(stageDescriptor).first
            }

            // Find stage method
            var stageMethod: StageMethod?
            if let apiMethod = apiInterview.stageMethod {
                let methodId = apiMethod.id
                let methodDescriptor = FetchDescriptor<StageMethod>(
                    predicate: #Predicate { method in
                        method.id == methodId
                    }
                )
                stageMethod = try modelContext.fetch(methodDescriptor).first
            }

            // Parse dates
            let dateFormatter = ISO8601DateFormatter()
            let applicationDate = dateFormatter.date(from: apiInterview.applicationDate) ?? Date()
            let date = apiInterview.date.flatMap { dateFormatter.date(from: $0) }
            let deadline = apiInterview.deadline.flatMap { dateFormatter.date(from: $0) }

            // Parse outcome
            let outcome: InterviewOutcome?
            if let outcomeStr = apiInterview.outcome {
                outcome = InterviewOutcome(rawValue: outcomeStr)
            } else {
                outcome = nil
            }

            // Find existing interview
            let interviewId = apiInterview.id
            let interviewDescriptor = FetchDescriptor<Interview>(
                predicate: #Predicate { interview in
                    interview.id == interviewId
                }
            )

            let existing = try modelContext.fetch(interviewDescriptor).first

            if let existing = existing {
                // Update existing
                existing.company = company
                existing.clientCompany = apiInterview.clientCompany
                existing.jobTitle = apiInterview.jobTitle
                existing.applicationDate = applicationDate
                existing.interviewer = apiInterview.interviewer
                existing.stage = stage
                existing.stageMethod = stageMethod
                existing.date = date
                existing.deadline = deadline
                existing.outcome = outcome
                existing.notes = apiInterview.notes
                existing.link = apiInterview.link

                // Update metadata JSON if needed
                if let metadata = apiInterview.metadata,
                   let jobListing = metadata.jobListing {
                    existing.metadataJSON = "{\"jobListing\":\"\(jobListing)\"}"
                }
            } else {
                // Create new
                let interview = Interview(
                    id: apiInterview.id,
                    company: company,
                    clientCompany: apiInterview.clientCompany,
                    jobTitle: apiInterview.jobTitle,
                    applicationDate: applicationDate,
                    interviewer: apiInterview.interviewer,
                    stage: stage,
                    stageMethod: stageMethod,
                    date: date,
                    deadline: deadline,
                    outcome: outcome,
                    notes: apiInterview.notes,
                    link: apiInterview.link
                )

                // Set metadata JSON if needed
                if let metadata = apiInterview.metadata,
                   let jobListing = metadata.jobListing {
                    interview.metadataJSON = "{\"jobListing\":\"\(jobListing)\"}"
                }

                modelContext.insert(interview)
            }
        }

        try modelContext.save()
    }

    // MARK: - Push Interview to API

    func pushInterview(_ interview: Interview) async throws -> APIInterview {
        guard let company = interview.company else {
            throw APIError.serverError("Interview must have a company")
        }

        let dateFormatter = ISO8601DateFormatter()

        let request = CreateInterviewRequest(
            stage: interview.stage?.stage ?? "Applied",
            companyName: company.name,
            clientCompany: interview.clientCompany,
            jobTitle: interview.jobTitle,
            jobPostingLink: extractJobListing(from: interview.metadataJSON),
            date: interview.date.map { dateFormatter.string(from: $0) },
            deadline: interview.deadline.map { dateFormatter.string(from: $0) },
            interviewer: interview.interviewer,
            locationType: interview.stageMethod?.method.lowercased().contains("video") == true ? "link" : "phone",
            interviewLink: interview.link,
            notes: interview.notes
        )

        return try await apiService.createInterview(request)
    }

    // MARK: - Helpers

    private func extractJobListing(from metadataJSON: String?) -> String? {
        guard let json = metadataJSON,
              let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let jobListing = dict["jobListing"] as? String else {
            return nil
        }
        return jobListing
    }
}

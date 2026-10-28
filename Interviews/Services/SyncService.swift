//
//  SyncService.swift
//  Interviews
//
//  Created by keloran on 06/12/2025.
//

import Foundation
import Combine
import SwiftData
import Clerk

@MainActor
class SyncService: ObservableObject {
    private let apiService = APIService.shared
    let modelContext: ModelContext

    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: Error?

    /// The account this store belongs to, when the sync started
    private let owner: String?
    var currentOwner: () -> String? = { Clerk.shared.user?.id }

    // The two calls the outbox makes, replaceable in tests
    var sendCreate: (CreateInterviewRequest) async throws -> APIInterview = { try await APIService.shared.createInterview($0) }
    var sendUpdate: (Int, UpdateInterviewRequest) async throws -> APIInterview = { try await APIService.shared.updateInterview(id: $0, $1) }
    /// One outbox run at a time, so a create can't go out twice
    private static var isPushing = false

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.owner = Clerk.shared.user?.id
    }

    /// A response that arrives after a sign-out or a switch to another account is dropped, not saved
    func ensureSameAccount() throws {
        guard currentOwner() == owner else { throw CancellationError() }
    }

    // MARK: - Sync All Data

    func syncAll() async {
        isSyncing = true
        syncError = nil

        do {
            // Local changes go up first, so the pull below can't overwrite them
            await pushPending()
            // Sync in order: Companies -> Stages -> Methods -> Interviews
            try await syncCompanies()
            try await syncStages()
            try await syncStageMethods()
            try await syncInterviews()
            try ensureSameAccount()

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
        try ensureSameAccount()

        // Create a set of server company IDs for deletion check
        let serverCompanyIds = Set(apiCompanies.map { $0.id })
        
        // Fetch all local companies that have a server ID
        let allLocalCompaniesDescriptor = FetchDescriptor<Company>(
            predicate: #Predicate { company in
                company.id != nil
            }
        )
        let allLocalCompanies = try modelContext.fetch(allLocalCompaniesDescriptor)
        
        // Delete local companies that no longer exist on the server
        for localCompany in allLocalCompanies {
            if let localId = localCompany.id, !serverCompanyIds.contains(localId) {
//                print("🗑️ Deleting company '\(localCompany.name)' (ID: \(localId)) - no longer on server")
                modelContext.delete(localCompany)
            }
        }
        
        // Save immediately after deletions to prevent fault errors
        try modelContext.save()

        for apiCompany in apiCompanies {
            // Find or create company
            let companyId = apiCompany.id
            
            // First, try to find by server ID
            let idDescriptor = FetchDescriptor<Company>(
                predicate: #Predicate { company in
                    company.id == companyId
                }
            )

            if let existing = try modelContext.fetch(idDescriptor).first {
                // Update existing record with server data
                existing.name = apiCompany.name
                existing.id = apiCompany.id // Ensure server ID is set
            } else {
                // Check if there's a local-only record (nil ID) with same name
                let nameDescriptor = FetchDescriptor<Company>(
                    predicate: #Predicate { company in
                        company.name == apiCompany.name && company.id == nil
                    }
                )
                
                if let localRecord = try modelContext.fetch(nameDescriptor).first {
                    // Update the local record with server ID (merge)
                    localRecord.id = apiCompany.id
//                    print("🔄 Merged local Company '\(apiCompany.name)' with server ID \(apiCompany.id)")
                } else {
                    // Create new record
                    let company = Company(id: apiCompany.id, name: apiCompany.name)
                    modelContext.insert(company)
                }
            }
        }

        try modelContext.save()
    }

    // MARK: - Sync Stages

    private func syncStages() async throws {
        let apiStages = try await apiService.fetchStages()
        try ensureSameAccount()

        // Create a set of server stage IDs for deletion check
        let serverStageIds = Set(apiStages.map { $0.id })
        
        // Fetch all local stages that have a server ID
        let allLocalStagesDescriptor = FetchDescriptor<Stage>(
            predicate: #Predicate { stage in
                stage.id != nil
            }
        )
        let allLocalStages = try modelContext.fetch(allLocalStagesDescriptor)
        
        // Delete local stages that no longer exist on the server
        for localStage in allLocalStages {
            if let localId = localStage.id, !serverStageIds.contains(localId) {
//                print("🗑️ Deleting stage '\(localStage.stage)' (ID: \(localId)) - no longer on server")
                modelContext.delete(localStage)
            }
        }
        
        // Save immediately after deletions to prevent fault errors
        try modelContext.save()

        for apiStage in apiStages {
            // Capture the ID in a local variable to use in predicate
            let stageId = apiStage.id
            
            // First, try to find by server ID
            let idDescriptor = FetchDescriptor<Stage>(
                predicate: #Predicate { stage in
                    stage.id == stageId
                }
            )

            if let existing = try modelContext.fetch(idDescriptor).first {
                // Update existing record with server data
                existing.stage = apiStage.stage
                existing.id = apiStage.id // Ensure server ID is set
            } else {
                // Check if there's a local-only record (nil ID) with same name
                let nameDescriptor = FetchDescriptor<Stage>(
                    predicate: #Predicate { stage in
                        stage.stage == apiStage.stage && stage.id == nil
                    }
                )
                
                if let localRecord = try modelContext.fetch(nameDescriptor).first {
                    // Update the local record with server ID (merge)
                    localRecord.id = apiStage.id
//                    print("🔄 Merged local Stage '\(apiStage.stage)' with server ID \(apiStage.id)")
                } else {
                    // Create new record
                    let stage = Stage(id: apiStage.id, stage: apiStage.stage)
                    modelContext.insert(stage)
                }
            }
        }

        try modelContext.save()
    }

    // MARK: - Sync Stage Methods

    private func syncStageMethods() async throws {
        let apiMethods = try await apiService.fetchStageMethods()
        try ensureSameAccount()

        // Create a set of server method IDs for deletion check
        let serverMethodIds = Set(apiMethods.map { $0.id })
        
        // Fetch all local stage methods that have a server ID
        let allLocalMethodsDescriptor = FetchDescriptor<StageMethod>(
            predicate: #Predicate { method in
                method.id != nil
            }
        )
        let allLocalMethods = try modelContext.fetch(allLocalMethodsDescriptor)
        
        // Delete local methods that no longer exist on the server
        for localMethod in allLocalMethods {
            if let localId = localMethod.id, !serverMethodIds.contains(localId) {
//                print("🗑️ Deleting stage method '\(localMethod.method)' (ID: \(localId)) - no longer on server")
                modelContext.delete(localMethod)
            }
        }
        
        // Save immediately after deletions to prevent fault errors
        try modelContext.save()

        for apiMethod in apiMethods {
            // Capture the ID in a local variable to use in predicate
            let methodId = apiMethod.id
            
            // First, try to find by server ID
            let idDescriptor = FetchDescriptor<StageMethod>(
                predicate: #Predicate { method in
                    method.id == methodId
                }
            )
            
            if let existing = try modelContext.fetch(idDescriptor).first {
                // Update existing record with server ID
                existing.method = apiMethod.method
                existing.id = apiMethod.id // Ensure server ID is set
            } else {
                // Check if there's a local-only record (nil ID) with same name
                let nameDescriptor = FetchDescriptor<StageMethod>(
                    predicate: #Predicate { method in
                        method.method == apiMethod.method && method.id == nil
                    }
                )
                
                if let localRecord = try modelContext.fetch(nameDescriptor).first {
                    // Update the local record with server ID (merge)
                    localRecord.id = apiMethod.id
//                    print("🔄 Merged local StageMethod '\(apiMethod.method)' with server ID \(apiMethod.id)")
                } else {
                    // Create new record
                    let method = StageMethod(id: apiMethod.id, method: apiMethod.method)
                    modelContext.insert(method)
                }
            }
        }

        try modelContext.save()
    }

    // MARK: - Sync Interviews

    /// Every page of the user's interviews, deduplicated by id. Throws if any page fails, so the caller never
    /// treats a partial list as "everything else was deleted on the server".
    /// ponytail: a stage added mid-fetch can shift a row past a page edge; the next sync puts it back.
    static func fetchAllInterviews(
        pageSize: Int = 500,
        fetchPage: (_ skip: Int, _ take: Int) async throws -> [APIInterview]
    ) async throws -> [APIInterview] {
        var all: [APIInterview] = []
        var seen = Set<Int>()
        var skip = 0
        while true {
            try Task.checkCancellation()
            let page = try await fetchPage(skip, pageSize)
            for interview in page where seen.insert(interview.id).inserted {
                all.append(interview)
            }
            if page.count < pageSize { return all }
            skip += pageSize
        }
    }

    private func syncInterviews() async throws {
        let apiService = self.apiService
        let apiInterviews = try await Self.fetchAllInterviews { skip, take in
            try await apiService.fetchInterviews(includePast: true, take: take, skip: skip)
        }
        try ensureSameAccount()
        try apply(apiInterviews)
    }

    /// Bring the local store in line with a complete list from the server, without losing unsent local changes
    func apply(_ apiInterviews: [APIInterview]) throws {
        try reconcileUncertainCreates(with: apiInterviews)

        // Create a set of server interview IDs for deletion check
        let serverInterviewIds = Set(apiInterviews.map { $0.id })
        
        // Fetch all local interviews that have a server ID
        let allLocalInterviewsDescriptor = FetchDescriptor<Interview>(
            predicate: #Predicate { interview in
                interview.id != nil
            }
        )
        let allLocalInterviews = try modelContext.fetch(allLocalInterviewsDescriptor)
        
        // Delete local interviews that no longer exist on the server
        for localInterview in allLocalInterviews where localInterview.pendingSince == nil {
            if let localId = localInterview.id, !serverInterviewIds.contains(localId) {
//                print("🗑️ Deleting interview '\(localInterview.jobTitle)' (ID: \(localId)) - no longer on server")
                modelContext.delete(localInterview)
            }
        }
        
        // Save immediately after deletions to prevent fault errors
        try modelContext.save()

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

            // Interview times are moments; application dates and offer respond-by dates are calendar days
            guard let applicationDate = APIDates.day(apiInterview.applicationDate) else {
                // Never invent "today" for history; keep whatever is here and move on
                print("⚠️ Skipping interview \(apiInterview.id): unreadable applicationDate \(apiInterview.applicationDate)")
                continue
            }
            let date = APIDates.instant(apiInterview.date)
            let deadline = APIDates.isOffer(apiInterview.stage?.stage) ? APIDates.day(apiInterview.deadline) : APIDates.instant(apiInterview.deadline)

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

            // Prepare metadata dictionary that merges existing jobListing or other keys with applied flag
            var mergedMetadata: [String: Any] = [:]
            // If metadata exists from API, parse it into dictionary
            if let metadata = apiInterview.metadata {
                if let jobListing = metadata.jobListing {
                    mergedMetadata["jobListing"] = jobListing
                }
                // Add other keys from metadata if any, assuming metadata may have more keys in future
                // (If actual metadata has more keys, parsing and merging should be extended accordingly)
            }
            // Always add 'applied' key depending on apiInterview.stage?.stage
            mergedMetadata["applied"] = (apiInterview.stage?.stage == "Applied")

            // Serialize mergedMetadata to JSON string
            let metadataJSON: String
            if let jsonData = try? JSONSerialization.data(withJSONObject: mergedMetadata, options: []),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                metadataJSON = jsonString
            } else {
                metadataJSON = "{}"
            }

            if let existing, existing.pendingSince != nil {
                // An unsent local edit wins until the server has confirmed it
                continue
            } else if let existing = existing {
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

                // Update metadata JSON with merged metadata including 'applied' field.
                // Also update jobListing property if present in metadata.
                existing.metadataJSON = metadataJSON
                if let jobListing = mergedMetadata["jobListing"] as? String {
                    existing.jobListing = jobListing
                } else {
                    existing.jobListing = nil
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

                // Set metadata JSON with merged metadata including 'applied' field.
                // Also set jobListing property if present.
                interview.metadataJSON = metadataJSON
                if let jobListing = mergedMetadata["jobListing"] as? String {
                    interview.jobListing = jobListing
                }

                modelContext.insert(interview)
            }
        }

        try modelContext.save()
    }

    // MARK: - Push Interview to API

    func pushInterview(_ interview: Interview, previousInterviewId: Int? = nil) async throws -> APIInterview {
        try await sendCreate(createRequest(for: interview, previousInterviewId: previousInterviewId))
    }

    /// Everything the edit screen can change, with cleared fields sent as cleared
    func updateRequest(for interview: Interview) -> UpdateInterviewRequest {
        // The server keeps an offer's respond-by as a day (the first 10 characters), so send the local day
        let isOffer = APIDates.isOffer(interview.stage?.stage)
        return UpdateInterviewRequest(
            outcome: interview.outcome?.rawValue,
            stage: nil,
            date: interview.date.map(APIDates.instantString),
            deadline: interview.deadline.map { isOffer ? APIDates.dayString($0) : APIDates.instantString($0) },
            interviewer: interview.interviewer,
            notes: interview.notes,
            link: interview.link,
            jobTitle: interview.jobTitle,
            clientCompany: interview.clientCompany,
            clearsEmptyFields: true
        )
    }

    // MARK: - Outbox

    /// Send every local change the server hasn't confirmed. Each account has its own store (and so its own
    /// queue), and the token comes from the current session, so nothing goes out under another account.
    func pushPending() async {
        guard !Self.isPushing else { return }
        Self.isPushing = true
        defer { Self.isPushing = false }

        // In an account's store a row without a server id is always an unsent create
        let descriptor = FetchDescriptor<Interview>(
            predicate: #Predicate { $0.pendingSince != nil || $0.id == nil },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        for interview in (try? modelContext.fetch(descriptor)) ?? [] where interview.createUncertain != true {
            guard (try? ensureSameAccount()) != nil else { return }
            let started = interview.pendingSince
            do {
                if let id = interview.id {
                    _ = try await sendUpdate(id, updateRequest(for: interview))
                } else {
                    do {
                        interview.id = try await pushInterview(interview, previousInterviewId: interview.pendingPreviousId).id
                    } catch is URLError {
                        // It may have been created; don't send it again until a full sync says whether it was
                        interview.createUncertain = true
                        interview.syncError = "Waiting to confirm with the server"
                        try? modelContext.save()
                        continue
                    }
                }
                // An edit made while this was in flight stays queued
                if interview.pendingSince == started {
                    interview.pendingSince = nil
                    interview.pendingPreviousId = nil
                }
                interview.syncError = nil
            } catch {
                interview.syncError = error.localizedDescription
            }
            try? modelContext.save()
        }
    }

    /// A create whose answer never came: if the full list has it, adopt that id; if not, it wasn't created
    /// and is safe to send again
    private func reconcileUncertainCreates(with apiInterviews: [APIInterview]) throws {
        let uncertain = try modelContext.fetch(FetchDescriptor<Interview>(predicate: #Predicate { $0.createUncertain == true && $0.id == nil }))
        guard !uncertain.isEmpty else { return }
        let known = Set(try modelContext.fetch(FetchDescriptor<Interview>(predicate: #Predicate { $0.id != nil })).compactMap(\.id))
        var claimed = known
        for interview in uncertain {
            let match = apiInterviews.first { api in
                !claimed.contains(api.id)
                    && api.company.name == interview.company?.name
                    && api.jobTitle == interview.jobTitle
                    && api.stage?.stage == (interview.stage?.stage ?? "Applied")
                    && APIDates.instant(api.date) == interview.date
            }
            if let match {
                interview.id = match.id
                claimed.insert(match.id)
            }
            interview.createUncertain = nil
            interview.syncError = nil
        }
        try modelContext.save()
    }

    func createRequest(for interview: Interview, previousInterviewId: Int? = nil) throws -> CreateInterviewRequest {
        guard let company = interview.company else {
            throw APIError.serverError("Interview must have a company")
        }

        let isOffer = APIDates.isOffer(interview.stage?.stage)

        return CreateInterviewRequest(
            stage: interview.stage?.stage ?? "Applied",
            companyName: company.name,
            clientCompany: interview.clientCompany,
            jobTitle: interview.jobTitle,
            jobPostingLink: extractJobListing(from: interview.metadataJSON),
            date: interview.date.map(APIDates.instantString),
            deadline: isOffer ? nil : interview.deadline.map(APIDates.instantString),
            interviewer: interview.interviewer,
            locationType: interview.stageMethod?.method.lowercased().contains("video") == true ? "link" : "phone",
            interviewLink: interview.link,
            notes: interview.notes,
            previousInterviewId: previousInterviewId,
            offerDeadline: isOffer ? interview.deadline.map { APIDates.dayString($0) } : nil
        )
    }

    /// Queues a next stage to join the earlier stage's application, and the earlier stage's PASSED.
    /// If the earlier stage never reached the server, it goes first so there's an application to join.
    /// ponytail: offline with an unsynced earlier stage, the next stage can't know its parent id and becomes
    /// its own application; store a relationship if that turns out to matter.
    func pushNextStage(_ next: Interview, after previous: Interview) async throws {
        previous.markChanged()
        next.markChanged()
        try modelContext.save()
        if previous.id == nil {
            previous.id = try await pushInterview(previous).id
            try modelContext.save()
        }
        next.pendingPreviousId = previous.id
        try modelContext.save()
        await pushPending()
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


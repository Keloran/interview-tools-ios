//
//  Interview.swift
//  Interviews
//
//  Created by keloran on 05/12/2025.
//

import Foundation
import SwiftData

@Model
final class Interview {
    var id: Int?
    var clientCompany: String?
    var jobTitle: String
    var applicationDate: Date
    var interviewer: String?
    var userId: Int?
    var date: Date?
    var deadline: Date?
    var outcome: InterviewOutcome?
    var notes: String?
    var metadataJSON: String? // Store JSON as string
    var createdAt: Date
    var updatedAt: Date
    var link: String?
    var jobListing: String?

    // Outbox state. All optional so existing stores migrate without a version bump.
    /// When a local change was made that the server hasn't confirmed; nil once it has
    var pendingSince: Date?
    /// Why the last attempt to send it failed, shown on the row
    var syncError: String?
    /// A next stage that hasn't reached the server: the server id of the stage it follows
    var pendingPreviousId: Int?
    /// The create request went out but no answer came back, so it may exist on the server.
    /// It's matched against the next full sync instead of being sent again.
    var createUncertain: Bool?

    @Relationship(deleteRule: .nullify)
    var company: Company?

    @Relationship(deleteRule: .nullify)
    var stage: Stage?

    @Relationship(deleteRule: .nullify)
    var stageMethod: StageMethod?

    init(
        id: Int? = nil,
        company: Company? = nil,
        clientCompany: String? = nil,
        jobTitle: String,
        applicationDate: Date,
        interviewer: String? = nil,
        stage: Stage? = nil,
        stageMethod: StageMethod? = nil,
        userId: Int? = nil,
        date: Date? = nil,
        deadline: Date? = nil,
        outcome: InterviewOutcome? = nil,
        notes: String? = nil,
        metadataJSON: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        link: String? = nil,
        jobListing: String? = nil
    ) {
        self.id = id
        self.company = company
        self.clientCompany = clientCompany
        self.jobTitle = jobTitle
        self.applicationDate = applicationDate
        self.interviewer = interviewer
        self.stage = stage
        self.stageMethod = stageMethod
        self.userId = userId
        self.date = date
        self.deadline = deadline
        self.outcome = outcome
        self.notes = notes
        self.metadataJSON = metadataJSON
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.link = link
        self.jobListing = jobListing
    }

    /// Record a local edit so the outbox sends it, even after a relaunch
    func markChanged() {
        updatedAt = Date()
        pendingSince = updatedAt
        syncError = nil
    }

    // Helper to get display date (prefer date over deadline)
    var displayDate: Date? {
        return date ?? deadline
    }

    // Helper to determine color based on outcome or stage
    var displayColor: String {
        if let outcome = outcome {
            return outcome.color
        }
        return stage?.stage ?? "gray"
    }
}

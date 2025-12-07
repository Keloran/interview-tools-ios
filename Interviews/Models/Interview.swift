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
    var jobPostingLink: String?

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
        jobPostingLink: String? = nil
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
        self.jobPostingLink = jobPostingLink
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

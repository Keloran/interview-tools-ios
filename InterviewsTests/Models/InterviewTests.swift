//
//  InterviewTests.swift
//  InterviewsTests
//
//  Created by keloran on 05/12/2025.
//

import Testing
import SwiftData
@testable import Interviews

struct InterviewTests {
    @Test func testInterviewInitialization() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext

        let company = Company(name: "Apple")
        let stage = Stage(stage: "Technical Interview")
        let method = StageMethod(method: "Video Call")

        context.insert(company)
        context.insert(stage)
        context.insert(method)

        let applicationDate = Date()
        let interview = Interview(
            company: company,
            jobTitle: "iOS Engineer",
            applicationDate: applicationDate,
            stage: stage,
            stageMethod: method
        )

        #expect(interview.company?.name == "Apple")
        #expect(interview.jobTitle == "iOS Engineer")
        #expect(interview.applicationDate == applicationDate)
        #expect(interview.stage?.stage == "Technical Interview")
        #expect(interview.stageMethod?.method == "Video Call")
    }

    @Test func testInterviewWithOptionalFields() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext

        let company = Company(name: "Google")
        let stage = Stage(stage: "Phone Screen")
        let method = StageMethod(method: "Phone Call")

        context.insert(company)
        context.insert(stage)
        context.insert(method)

        let interview = Interview(
            company: company,
            clientCompany: "Acme Corp",
            jobTitle: "Software Engineer",
            applicationDate: Date(),
            interviewer: "John Doe",
            stage: stage,
            stageMethod: method,
            date: Date(),
            outcome: .scheduled,
            notes: "Technical interview focused on algorithms",
            link: "https://meet.google.com/abc-defg-hij"
        )

        #expect(interview.clientCompany == "Acme Corp")
        #expect(interview.interviewer == "John Doe")
        #expect(interview.date != nil)
        #expect(interview.outcome == .scheduled)
        #expect(interview.notes == "Technical interview focused on algorithms")
        #expect(interview.link == "https://meet.google.com/abc-defg-hij")
    }

    @Test func testInterviewDisplayDate() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext

        let company = Company(name: "Microsoft")
        let stage = Stage(stage: "Technical Test")
        let method = StageMethod(method: "Take Home")

        context.insert(company)
        context.insert(stage)
        context.insert(method)

        let interviewDate = Date()
        let interview1 = Interview(
            company: company,
            jobTitle: "Engineer",
            applicationDate: Date(),
            stage: stage,
            stageMethod: method,
            date: interviewDate
        )

        #expect(interview1.displayDate == interviewDate)

        let deadlineDate = Date().addingTimeInterval(86400)
        let interview2 = Interview(
            company: company,
            jobTitle: "Designer",
            applicationDate: Date(),
            stage: stage,
            stageMethod: method,
            deadline: deadlineDate
        )

        #expect(interview2.displayDate == deadlineDate)
    }

    @Test func testInterviewDisplayDatePrefersDateOverDeadline() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext

        let company = Company(name: "Amazon")
        let stage = Stage(stage: "Coding Challenge")
        let method = StageMethod(method: "Online Assessment")

        context.insert(company)
        context.insert(stage)
        context.insert(method)

        let interviewDate = Date()
        let deadlineDate = Date().addingTimeInterval(86400)

        let interview = Interview(
            company: company,
            jobTitle: "SDE",
            applicationDate: Date(),
            stage: stage,
            stageMethod: method,
            date: interviewDate,
            deadline: deadlineDate
        )

        #expect(interview.displayDate == interviewDate)
    }

    @Test func testInterviewDisplayColor() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext

        let company = Company(name: "Netflix")
        let stage = Stage(stage: "Final Round")
        let method = StageMethod(method: "In Person")

        context.insert(company)
        context.insert(stage)
        context.insert(method)

        let interview1 = Interview(
            company: company,
            jobTitle: "Engineer",
            applicationDate: Date(),
            stage: stage,
            stageMethod: method,
            outcome: .passed
        )

        #expect(interview1.displayColor == "green")

        let interview2 = Interview(
            company: company,
            jobTitle: "Designer",
            applicationDate: Date(),
            stage: stage,
            stageMethod: method
        )

        #expect(interview2.displayColor == "Final Round")
    }

    @Test func testInterviewOutcomeTransitions() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext

        let company = Company(name: "Meta")
        let stage = Stage(stage: "Phone Screen")
        let method = StageMethod(method: "Video Call")

        context.insert(company)
        context.insert(stage)
        context.insert(method)

        let interview = Interview(
            company: company,
            jobTitle: "Software Engineer",
            applicationDate: Date(),
            stage: stage,
            stageMethod: method,
            outcome: .scheduled
        )

        context.insert(interview)

        #expect(interview.outcome == .scheduled)

        interview.outcome = .passed
        #expect(interview.outcome == .passed)

        interview.outcome = .offerReceived
        #expect(interview.outcome == .offerReceived)

        interview.outcome = .offerAccepted
        #expect(interview.outcome == .offerAccepted)
    }

    @Test func testInterviewTimestamps() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext

        let company = Company(name: "Tesla")
        let stage = Stage(stage: "System Design")
        let method = StageMethod(method: "Video Call")

        context.insert(company)
        context.insert(stage)
        context.insert(method)

        let beforeDate = Date()
        let interview = Interview(
            company: company,
            jobTitle: "Engineer",
            applicationDate: Date(),
            stage: stage,
            stageMethod: method
        )
        let afterDate = Date()

        #expect(interview.createdAt >= beforeDate)
        #expect(interview.createdAt <= afterDate)
        #expect(interview.updatedAt >= beforeDate)
        #expect(interview.updatedAt <= afterDate)
    }

    @Test func testInterviewMetadataJSON() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext

        let company = Company(name: "Spotify")
        let stage = Stage(stage: "Phone Screen")
        let method = StageMethod(method: "Phone Call")

        context.insert(company)
        context.insert(stage)
        context.insert(method)

        let metadata = "{\"salary\":\"150000\",\"jobUrl\":\"https://example.com/job/123\"}"
        let interview = Interview(
            company: company,
            jobTitle: "Backend Engineer",
            applicationDate: Date(),
            stage: stage,
            stageMethod: method,
            metadataJSON: metadata
        )

        #expect(interview.metadataJSON == metadata)
    }
}

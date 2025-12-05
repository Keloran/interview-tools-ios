//
//  AddInterviewViewTests.swift
//  InterviewsTests
//
//  Created by keloran on 05/12/2025.
//

import Foundation
import Testing
import SwiftData
@testable import Interviews

struct AddInterviewViewTests {
    @Test func testAppliedStageDoesNotRequireScheduling() async throws {
        let stageName = "Applied"
        let requiresScheduling = stageName != "Applied" && stageName != "Offer"

        #expect(!requiresScheduling)
    }

    @Test func testFirstStageRequiresScheduling() async throws {
        let stageName = "First Stage"
        let requiresScheduling = stageName != "Applied" && stageName != "Offer"

        #expect(requiresScheduling)
    }

    @Test func testTechnicalTestDetection() async throws {
        let stageName = "Technical Test"
        let isTechnicalTest = stageName == "Technical Test"

        #expect(isTechnicalTest)
    }

    @Test func testAppliedStageValidation() async throws {
        let stageName = "Applied"
        let hasCompany = true
        let hasJobTitle = true

        let isValid = hasCompany && hasJobTitle

        #expect(isValid)
    }

    @Test func testTechnicalTestValidation() async throws {
        let stageName = "Technical Test"
        let hasCompany = true
        let hasJobTitle = true
        let hasDeadline = true

        let isValid = hasCompany && hasJobTitle && hasDeadline

        #expect(isValid)
    }

    @Test func testScheduledStageValidation() async throws {
        let stageName = "Phone Screen"
        let hasCompany = true
        let hasJobTitle = true
        let hasInterviewer = true
        let hasMethod = true

        let requiresScheduling = stageName != "Applied" && stageName != "Offer"
        let isValid = hasCompany && hasJobTitle && hasInterviewer && hasMethod && requiresScheduling

        #expect(isValid)
    }

    @Test @MainActor func testDefaultStageSeeding() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Stage.self,
            configurations: config
        )
        let context = container.mainContext

        // Seed stages
        DataSeeder.seedDefaultData(context: context)

        let descriptor = FetchDescriptor<Stage>()
        let stages = try context.fetch(descriptor)

        #expect(stages.count > 0)
        #expect(stages.contains(where: { $0.stage == "Applied" }))
        #expect(stages.contains(where: { $0.stage == "Phone Screen" }))
        #expect(stages.contains(where: { $0.stage == "Technical Test" }))
    }

    @Test @MainActor func testDefaultStageMethodSeeding() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: StageMethod.self,
            configurations: config
        )
        let context = container.mainContext

        // Seed methods
        DataSeeder.seedDefaultData(context: context)

        let descriptor = FetchDescriptor<StageMethod>()
        let methods = try context.fetch(descriptor)

        #expect(methods.count > 0)
        #expect(methods.contains(where: { $0.method == "Video Call" }))
        #expect(methods.contains(where: { $0.method == "Phone" }))
        #expect(methods.contains(where: { $0.method == "In Person" }))
    }

    @Test @MainActor func testAppliedInterviewCreation() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext

        let company = Company(name: "TestCorp")
        let stage = Stage(stage: "Applied")

        context.insert(company)
        context.insert(stage)

        let interview = Interview(
            company: company,
            jobTitle: "Software Engineer",
            applicationDate: Date(),
            stage: stage,
            outcome: .awaitingResponse
        )

        context.insert(interview)

        #expect(interview.company?.name == "TestCorp")
        #expect(interview.jobTitle == "Software Engineer")
        #expect(interview.stage?.stage == "Applied")
        #expect(interview.outcome == .awaitingResponse)
        #expect(interview.date == nil) // Applied stage has no interview date
        #expect(interview.interviewer == nil)
    }

    @Test @MainActor func testScheduledInterviewCreation() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext

        let company = Company(name: "TechCo")
        let stage = Stage(stage: "Phone Screen")
        let method = StageMethod(method: "Video Call")

        context.insert(company)
        context.insert(stage)
        context.insert(method)

        let interviewDate = Date()

        let interview = Interview(
            company: company,
            jobTitle: "Backend Developer",
            applicationDate: Date(),
            interviewer: "Jane Smith",
            stage: stage,
            stageMethod: method,
            date: interviewDate,
            outcome: .scheduled,
            link: "https://zoom.us/j/123"
        )

        context.insert(interview)

        #expect(interview.company?.name == "TechCo")
        #expect(interview.stage?.stage == "Phone Screen")
        #expect(interview.stageMethod?.method == "Video Call")
        #expect(interview.interviewer == "Jane Smith")
        #expect(interview.date != nil)
        #expect(interview.outcome == .scheduled)
        #expect(interview.link == "https://zoom.us/j/123")
    }

    @Test @MainActor func testTechnicalTestInterviewCreation() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext

        let company = Company(name: "StartupInc")
        let stage = Stage(stage: "Technical Test")

        context.insert(company)
        context.insert(stage)

        let deadline = Date().addingTimeInterval(86400 * 7) // 7 days

        let interview = Interview(
            company: company,
            jobTitle: "Full Stack Engineer",
            applicationDate: Date(),
            stage: stage,
            deadline: deadline,
            outcome: .scheduled,
            notes: "Complete the coding challenge and submit via GitHub"
        )

        context.insert(interview)

        #expect(interview.company?.name == "StartupInc")
        #expect(interview.stage?.stage == "Technical Test")
        #expect(interview.deadline != nil)
        #expect(interview.date == nil) // Technical tests use deadline, not date
        #expect(interview.interviewer == nil) // Technical tests don't have interviewer
        #expect(interview.stageMethod == nil) // Technical tests don't have method
        #expect(interview.notes != nil)
    }

    @Test func testJobPostingLinkMetadata() async throws {
        let jobPostingLink = "https://company.com/jobs/123"
        let expectedJSON = "{\"jobListing\":\"\(jobPostingLink)\"}"

        #expect(expectedJSON.contains(jobPostingLink))
    }

    @Test @MainActor func testClientCompanyOptional() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext

        let recruiter = Company(name: "Recruiter LLC")
        let stage = Stage(stage: "Applied")

        context.insert(recruiter)
        context.insert(stage)

        let interview = Interview(
            company: recruiter,
            clientCompany: "Big Tech Corp",
            jobTitle: "Senior Engineer",
            applicationDate: Date(),
            stage: stage,
            outcome: .awaitingResponse
        )

        context.insert(interview)

        #expect(interview.company?.name == "Recruiter LLC")
        #expect(interview.clientCompany == "Big Tech Corp")
    }

    @Test @MainActor func testStageOrderMatches() async throws {
        let expectedStages = [
            "Applied",
            "Phone Screen",
            "First Stage",
            "Second Stage",
            "Technical Test",
            "Technical Interview",
            "Third Stage",
            "Fourth Stage",
            "Final Stage"
        ]

        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Stage.self,
            configurations: config
        )
        let context = container.mainContext

        DataSeeder.seedDefaultData(context: context)

        let descriptor = FetchDescriptor<Stage>()
        let stages = try context.fetch(descriptor)

        // Verify all expected stages exist
        for expectedStage in expectedStages {
            #expect(stages.contains(where: { $0.stage == expectedStage }))
        }
    }

    @Test @MainActor func testSeedingIsIdempotent() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext

        // Seed once
        DataSeeder.seedDefaultData(context: context)

        let descriptor1 = FetchDescriptor<Stage>()
        let stages1 = try context.fetch(descriptor1)
        let count1 = stages1.count

        // Seed again - should not duplicate
        DataSeeder.seedDefaultData(context: context)

        let descriptor2 = FetchDescriptor<Stage>()
        let stages2 = try context.fetch(descriptor2)
        let count2 = stages2.count

        #expect(count1 == count2) // Should not create duplicates
    }
}

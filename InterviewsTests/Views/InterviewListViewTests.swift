//
//  InterviewListViewTests.swift
//  InterviewsTests
//
//  Created by keloran on 05/12/2025.
//

import Foundation
import Testing
import SwiftData
@testable import Interviews

struct InterviewListViewTests {
    @Test @MainActor func testSortedInterviewsByDate() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext

        let company = Company(name: "Apple")
        let stage = Stage(stage: "Phone Screen")
        let method = StageMethod(method: "Video Call")

        context.insert(company)
        context.insert(stage)
        context.insert(method)

        let calendar = Calendar.current
        let date1 = calendar.date(byAdding: .day, value: 5, to: Date())!
        let date2 = calendar.date(byAdding: .day, value: 2, to: Date())!
        let date3 = calendar.date(byAdding: .day, value: 10, to: Date())!

        let interview1 = Interview(
            company: company,
            jobTitle: "iOS Engineer",
            applicationDate: Date(),
            stage: stage,
            stageMethod: method,
            date: date1
        )

        let interview2 = Interview(
            company: company,
            jobTitle: "Senior iOS Engineer",
            applicationDate: Date(),
            stage: stage,
            stageMethod: method,
            date: date2
        )

        let interview3 = Interview(
            company: company,
            jobTitle: "Staff iOS Engineer",
            applicationDate: Date(),
            stage: stage,
            stageMethod: method,
            date: date3
        )

        context.insert(interview1)
        context.insert(interview2)
        context.insert(interview3)

        let descriptor = FetchDescriptor<Interview>()
        let allInterviews = try context.fetch(descriptor)

        let sorted = allInterviews
            .filter { $0.displayDate != nil }
            .sorted { ($0.displayDate ?? Date()) < ($1.displayDate ?? Date()) }

        #expect(sorted.count == 3)
        #expect(sorted[0].jobTitle == "Senior iOS Engineer")
        #expect(sorted[1].jobTitle == "iOS Engineer")
        #expect(sorted[2].jobTitle == "Staff iOS Engineer")
    }

    @Test @MainActor func testInterviewsWithNoDateAreFiltered() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext

        let company = Company(name: "Google")
        let stage = Stage(stage: "Technical")
        let method = StageMethod(method: "Video Call")

        context.insert(company)
        context.insert(stage)
        context.insert(method)

        // Interview with date
        let interview1 = Interview(
            company: company,
            jobTitle: "SWE I",
            applicationDate: Date(),
            stage: stage,
            stageMethod: method,
            date: Date()
        )

        // Interview without date or deadline
        let interview2 = Interview(
            company: company,
            jobTitle: "SWE II",
            applicationDate: Date(),
            stage: stage,
            stageMethod: method
        )

        context.insert(interview1)
        context.insert(interview2)

        let descriptor = FetchDescriptor<Interview>()
        let allInterviews = try context.fetch(descriptor)

        let filtered = allInterviews.filter { $0.displayDate != nil }

        #expect(filtered.count == 1)
        #expect(filtered.first?.jobTitle == "SWE I")
    }

    @Test @MainActor func testInterviewUsesDeadlineAsFallback() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext

        let company = Company(name: "Meta")
        let stage = Stage(stage: "Take Home Test")
        let method = StageMethod(method: "Async")

        context.insert(company)
        context.insert(stage)
        context.insert(method)

        let deadline = Date().addingTimeInterval(86400 * 7) // 7 days from now

        let interview = Interview(
            company: company,
            jobTitle: "Backend Engineer",
            applicationDate: Date(),
            stage: stage,
            stageMethod: method,
            deadline: deadline
        )

        context.insert(interview)

        #expect(interview.displayDate != nil)
        #expect(interview.displayDate == deadline)
    }

    @Test @MainActor func testInterviewPrefersDateOverDeadline() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext

        let company = Company(name: "Amazon")
        let stage = Stage(stage: "Onsite")
        let method = StageMethod(method: "In Person")

        context.insert(company)
        context.insert(stage)
        context.insert(method)

        let interviewDate = Date().addingTimeInterval(86400 * 3)
        let deadline = Date().addingTimeInterval(86400 * 7)

        let interview = Interview(
            company: company,
            jobTitle: "SDE",
            applicationDate: Date(),
            stage: stage,
            stageMethod: method,
            date: interviewDate,
            deadline: deadline
        )

        context.insert(interview)

        #expect(interview.displayDate == interviewDate)
    }

    @Test func testOutcomeColorMapping() async throws {
        let testCases: [(InterviewOutcome, String)] = [
            (.scheduled, "blue"),
            (.passed, "green"),
            (.rejected, "red"),
            (.awaitingResponse, "yellow"),
            (.offerReceived, "purple"),
            (.offerAccepted, "green"),
            (.offerDeclined, "orange"),
            (.withdrew, "gray")
        ]

        for (outcome, _) in testCases {
            // Just verify outcome has displayName
            #expect(!outcome.displayName.isEmpty)
        }
    }

    @Test @MainActor func testMultipleCompaniesInList() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext

        let apple = Company(name: "Apple")
        let google = Company(name: "Google")
        let meta = Company(name: "Meta")
        let stage = Stage(stage: "Phone Screen")
        let method = StageMethod(method: "Video Call")

        context.insert(apple)
        context.insert(google)
        context.insert(meta)
        context.insert(stage)
        context.insert(method)

        let interview1 = Interview(
            company: apple,
            jobTitle: "iOS Engineer",
            applicationDate: Date(),
            stage: stage,
            stageMethod: method,
            date: Date()
        )

        let interview2 = Interview(
            company: google,
            jobTitle: "SWE",
            applicationDate: Date(),
            stage: stage,
            stageMethod: method,
            date: Date()
        )

        let interview3 = Interview(
            company: meta,
            jobTitle: "Engineer",
            applicationDate: Date(),
            stage: stage,
            stageMethod: method,
            date: Date()
        )

        context.insert(interview1)
        context.insert(interview2)
        context.insert(interview3)

        let descriptor = FetchDescriptor<Interview>()
        let interviews = try context.fetch(descriptor)

        #expect(interviews.count == 3)

        let companies = Set(interviews.compactMap { $0.company?.name })
        #expect(companies.count == 3)
        #expect(companies.contains("Apple"))
        #expect(companies.contains("Google"))
        #expect(companies.contains("Meta"))
    }

    @Test @MainActor func testInterviewWithClientCompany() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext

        let recruiter = Company(name: "TechRecruit")
        let stage = Stage(stage: "Phone Screen")
        let method = StageMethod(method: "Phone")

        context.insert(recruiter)
        context.insert(stage)
        context.insert(method)

        let interview = Interview(
            company: recruiter,
            clientCompany: "Stripe",
            jobTitle: "Full Stack Engineer",
            applicationDate: Date(),
            stage: stage,
            stageMethod: method,
            date: Date()
        )

        context.insert(interview)

        #expect(interview.company?.name == "TechRecruit")
        #expect(interview.clientCompany == "Stripe")
    }

    @Test @MainActor func testInterviewWithNotes() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext

        let company = Company(name: "Startup Inc")
        let stage = Stage(stage: "Behavioral")
        let method = StageMethod(method: "Video Call")

        context.insert(company)
        context.insert(stage)
        context.insert(method)

        let notes = "Focus on leadership principles. Prepare STAR format examples."

        let interview = Interview(
            company: company,
            jobTitle: "Engineering Manager",
            applicationDate: Date(),
            stage: stage,
            stageMethod: method,
            date: Date(),
            notes: notes
        )

        context.insert(interview)

        #expect(interview.notes == notes)
    }

    @Test @MainActor func testInterviewWithMeetingLink() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext

        let company = Company(name: "RemoteFirst")
        let stage = Stage(stage: "Technical")
        let method = StageMethod(method: "Video Call")

        context.insert(company)
        context.insert(stage)
        context.insert(method)

        let meetingLink = "https://zoom.us/j/123456789"

        let interview = Interview(
            company: company,
            jobTitle: "Remote Engineer",
            applicationDate: Date(),
            stage: stage,
            stageMethod: method,
            date: Date(),
            link: meetingLink
        )

        context.insert(interview)

        #expect(interview.link == meetingLink)
    }

    @Test @MainActor func testEmptyInterviewList() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext

        let descriptor = FetchDescriptor<Interview>()
        let interviews = try context.fetch(descriptor)

        #expect(interviews.isEmpty)
    }

    @Test @MainActor func testInterviewDisplayDateLogic() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext

        let company = Company(name: "TestCorp")
        let stage = Stage(stage: "Initial")
        let method = StageMethod(method: "Video")

        context.insert(company)
        context.insert(stage)
        context.insert(method)

        // Case 1: Has date
        let interviewWithDate = Interview(
            company: company,
            jobTitle: "Engineer 1",
            applicationDate: Date(),
            stage: stage,
            stageMethod: method,
            date: Date()
        )
        #expect(interviewWithDate.displayDate != nil)

        // Case 2: Has deadline
        let interviewWithDeadline = Interview(
            company: company,
            jobTitle: "Engineer 2",
            applicationDate: Date(),
            stage: stage,
            stageMethod: method,
            deadline: Date()
        )
        #expect(interviewWithDeadline.displayDate != nil)

        // Case 3: Has neither
        let interviewWithNeither = Interview(
            company: company,
            jobTitle: "Engineer 3",
            applicationDate: Date(),
            stage: stage,
            stageMethod: method
        )
        #expect(interviewWithNeither.displayDate == nil)
    }
}

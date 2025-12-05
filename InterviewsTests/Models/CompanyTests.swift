//
//  CompanyTests.swift
//  InterviewsTests
//
//  Created by keloran on 05/12/2025.
//

import Foundation
import Testing
import SwiftData
@testable import Interviews

struct CompanyTests {
    @Test func testCompanyInitialization() async throws {
        let company = Company(id: 1, name: "Apple Inc.", userId: 100)

        #expect(company.id == 1)
        #expect(company.name == "Apple Inc.")
        #expect(company.userId == 100)
        #expect(company.interviews?.isEmpty == true)
    }

    @Test func testCompanyDefaultValues() async throws {
        let company = Company(name: "Google")

        #expect(company.id == nil)
        #expect(company.name == "Google")
        #expect(company.userId == nil)
        #expect(company.createdAt != nil)
    }

    @Test @MainActor func testCompanyWithInterviews() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Company.self, Interview.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext

        let company = Company(name: "Microsoft")
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
            stageMethod: method
        )

        context.insert(interview)

        #expect(company.interviews?.count == 1)
        #expect(company.interviews?.first?.jobTitle == "Software Engineer")
    }

    @Test func testCompanyDateTracking() async throws {
        let beforeDate = Date()
        let company = Company(name: "Amazon")
        let afterDate = Date()

        #expect(company.createdAt >= beforeDate)
        #expect(company.createdAt <= afterDate)
    }

    @Test func testCompanyNameNotEmpty() async throws {
        let company = Company(name: "Netflix")
        #expect(!company.name.isEmpty)
    }
}

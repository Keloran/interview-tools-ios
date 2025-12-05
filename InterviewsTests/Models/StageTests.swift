//
//  StageTests.swift
//  InterviewsTests
//
//  Created by keloran on 05/12/2025.
//

import Testing
import SwiftData
@testable import Interviews

struct StageTests {
    @Test func testStageInitialization() async throws {
        let stage = Stage(id: 1, stage: "Technical Interview")

        #expect(stage.id == 1)
        #expect(stage.stage == "Technical Interview")
        #expect(stage.interviews?.isEmpty == true)
    }

    @Test func testStageDefaultValues() async throws {
        let stage = Stage(stage: "Phone Screen")

        #expect(stage.id == nil)
        #expect(stage.stage == "Phone Screen")
    }

    @Test func testStageWithInterviews() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Stage.self, Interview.self, Company.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext

        let stage = Stage(stage: "Final Round")
        let company = Company(name: "Tesla")
        let method = StageMethod(method: "In Person")

        context.insert(stage)
        context.insert(company)
        context.insert(method)

        let interview1 = Interview(
            company: company,
            jobTitle: "Engineer",
            applicationDate: Date(),
            stage: stage,
            stageMethod: method
        )

        let interview2 = Interview(
            company: company,
            jobTitle: "Designer",
            applicationDate: Date(),
            stage: stage,
            stageMethod: method
        )

        context.insert(interview1)
        context.insert(interview2)

        #expect(stage.interviews?.count == 2)
    }

    @Test func testCommonStageNames() async throws {
        let stages = [
            "Phone Screen",
            "Technical Interview",
            "Coding Challenge",
            "System Design",
            "Behavioral Interview",
            "Final Round",
            "Offer Discussion"
        ]

        for stageName in stages {
            let stage = Stage(stage: stageName)
            #expect(stage.stage == stageName)
            #expect(!stage.stage.isEmpty)
        }
    }
}

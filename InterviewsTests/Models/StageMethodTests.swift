//
//  StageMethodTests.swift
//  InterviewsTests
//
//  Created by keloran on 05/12/2025.
//

import Foundation
import Testing
import SwiftData
@testable import Interviews

struct StageMethodTests {
    @Test func testStageMethodInitialization() async throws {
        let method = StageMethod(id: 1, method: "Video Call")

        #expect(method.id == 1)
        #expect(method.method == "Video Call")
        #expect(method.interviews?.isEmpty == true)
    }

    @Test func testStageMethodDefaultValues() async throws {
        let method = StageMethod(method: "In Person")

        #expect(method.id == nil)
        #expect(method.method == "In Person")
    }

    @Test @MainActor func testStageMethodWithInterviews() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: StageMethod.self, Interview.self, Company.self, Stage.self,
            configurations: config
        )
        let context = container.mainContext

        let method = StageMethod(method: "Phone Call")
        let company = Company(name: "Stripe")
        let stage = Stage(stage: "Phone Screen")

        context.insert(method)
        context.insert(company)
        context.insert(stage)

        let interview1 = Interview(
            company: company,
            jobTitle: "Backend Engineer",
            applicationDate: Date(),
            stage: stage,
            stageMethod: method
        )

        let interview2 = Interview(
            company: company,
            jobTitle: "Frontend Engineer",
            applicationDate: Date(),
            stage: stage,
            stageMethod: method
        )

        context.insert(interview1)
        context.insert(interview2)

        #expect(method.interviews?.count == 2)
    }

    @Test func testCommonStageMethods() async throws {
        let methods = [
            "Video Call",
            "In Person",
            "Phone Call",
            "Take Home Test",
            "Live Coding",
            "Online Assessment"
        ]

        for methodName in methods {
            let method = StageMethod(method: methodName)
            #expect(method.method == methodName)
            #expect(!method.method.isEmpty)
        }
    }
}

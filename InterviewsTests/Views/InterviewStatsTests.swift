//
//  InterviewStatsTests.swift
//  InterviewsTests
//
//  Created by keloran on 09/12/2025.
//

import Foundation
import Testing
import SwiftData
@testable import Interviews

struct InterviewStatsTests {
    
    @Test @MainActor func testEmptyStats() async throws {
        let stats = InterviewStats.compute(from: [])
        
        #expect(stats.totalInterviews == 0)
        #expect(stats.applied == 0)
        #expect(stats.passed == 0)
        #expect(stats.rejected == 0)
        #expect(stats.successRate == 0.0)
    }
    
    @Test @MainActor func testAppliedInterviews() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext
        
        let company = Company(name: "Apple")
        let appliedStage = Stage(stage: "Applied")
        
        context.insert(company)
        context.insert(appliedStage)
        
        // Create an interview in "Applied" stage with no outcome
        let interview = Interview(
            company: company,
            jobTitle: "iOS Engineer",
            applicationDate: Date(),
            stage: appliedStage,
            stageMethod: nil
        )
        
        context.insert(interview)
        
        let stats = InterviewStats.compute(from: [interview])
        
        #expect(stats.totalInterviews == 1)
        #expect(stats.applied == 1)
        #expect(stats.scheduled == 0)
    }
    
    @Test @MainActor func testPassedInterviews() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext
        
        let company = Company(name: "Apple")
        let stage = Stage(stage: "Technical Interview")
        
        context.insert(company)
        context.insert(stage)
        
        let interview = Interview(
            company: company,
            jobTitle: "iOS Engineer",
            applicationDate: Date(),
            stage: stage,
            stageMethod: nil
        )
        interview.outcome = .passed
        
        context.insert(interview)
        
        let stats = InterviewStats.compute(from: [interview])
        
        #expect(stats.totalInterviews == 1)
        #expect(stats.passed == 1)
        #expect(stats.rejected == 0)
        #expect(stats.successRate == 100.0)
    }
    
    @Test @MainActor func testRejectedInterviews() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext
        
        let company = Company(name: "Apple")
        let stage = Stage(stage: "Technical Interview")
        
        context.insert(company)
        context.insert(stage)
        
        let interview = Interview(
            company: company,
            jobTitle: "iOS Engineer",
            applicationDate: Date(),
            stage: stage,
            stageMethod: nil
        )
        interview.outcome = .rejected
        
        context.insert(interview)
        
        let stats = InterviewStats.compute(from: [interview])
        
        #expect(stats.totalInterviews == 1)
        #expect(stats.passed == 0)
        #expect(stats.rejected == 1)
        #expect(stats.successRate == 0.0)
    }
    
    @Test @MainActor func testSuccessRate() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext
        
        let company = Company(name: "Apple")
        let stage = Stage(stage: "Technical Interview")
        
        context.insert(company)
        context.insert(stage)
        
        // Create 3 passed and 1 rejected (75% success rate)
        var interviews: [Interview] = []
        
        for i in 0..<3 {
            let interview = Interview(
                company: company,
                jobTitle: "iOS Engineer \(i)",
                applicationDate: Date(),
                stage: stage,
                stageMethod: nil
            )
            interview.outcome = .passed
            context.insert(interview)
            interviews.append(interview)
        }
        
        let rejectedInterview = Interview(
            company: company,
            jobTitle: "iOS Engineer 4",
            applicationDate: Date(),
            stage: stage,
            stageMethod: nil
        )
        rejectedInterview.outcome = .rejected
        context.insert(rejectedInterview)
        interviews.append(rejectedInterview)
        
        let stats = InterviewStats.compute(from: interviews)
        
        #expect(stats.totalInterviews == 4)
        #expect(stats.passed == 3)
        #expect(stats.rejected == 1)
        #expect(stats.successRate == 75.0)
    }
    
    @Test @MainActor func testMixedOutcomes() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext
        
        let company = Company(name: "Apple")
        let appliedStage = Stage(stage: "Applied")
        let techStage = Stage(stage: "Technical")
        
        context.insert(company)
        context.insert(appliedStage)
        context.insert(techStage)
        
        var interviews: [Interview] = []
        
        // 2 applied (no outcome)
        for i in 0..<2 {
            let interview = Interview(
                company: company,
                jobTitle: "Applied \(i)",
                applicationDate: Date(),
                stage: appliedStage,
                stageMethod: nil
            )
            context.insert(interview)
            interviews.append(interview)
        }
        
        // 1 scheduled
        let scheduled = Interview(
            company: company,
            jobTitle: "Scheduled",
            applicationDate: Date(),
            stage: techStage,
            stageMethod: nil
        )
        scheduled.outcome = .scheduled
        context.insert(scheduled)
        interviews.append(scheduled)
        
        // 1 awaiting response
        let awaiting = Interview(
            company: company,
            jobTitle: "Awaiting",
            applicationDate: Date(),
            stage: techStage,
            stageMethod: nil
        )
        awaiting.outcome = .awaitingResponse
        context.insert(awaiting)
        interviews.append(awaiting)
        
        // 1 passed
        let passed = Interview(
            company: company,
            jobTitle: "Passed",
            applicationDate: Date(),
            stage: techStage,
            stageMethod: nil
        )
        passed.outcome = .passed
        context.insert(passed)
        interviews.append(passed)
        
        // 1 rejected
        let rejected = Interview(
            company: company,
            jobTitle: "Rejected",
            applicationDate: Date(),
            stage: techStage,
            stageMethod: nil
        )
        rejected.outcome = .rejected
        context.insert(rejected)
        interviews.append(rejected)
        
        // 1 offer received
        let offer = Interview(
            company: company,
            jobTitle: "Offer",
            applicationDate: Date(),
            stage: techStage,
            stageMethod: nil
        )
        offer.outcome = .offerReceived
        context.insert(offer)
        interviews.append(offer)
        
        let stats = InterviewStats.compute(from: interviews)
        
        #expect(stats.totalInterviews == 7)
        #expect(stats.applied == 2)
        #expect(stats.scheduled == 1)
        #expect(stats.awaitingResponse == 1)
        #expect(stats.passed == 1)
        #expect(stats.rejected == 1)
        #expect(stats.offerReceived == 1)
        #expect(stats.activeInterviews == 2) // scheduled + awaiting
        #expect(stats.successRate == 50.0) // 1 passed / (1 passed + 1 rejected)
    }
    
    @Test @MainActor func testOfferOutcomes() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext
        
        let company = Company(name: "Apple")
        let stage = Stage(stage: "Final")
        
        context.insert(company)
        context.insert(stage)
        
        var interviews: [Interview] = []
        
        // Offer received
        let received = Interview(
            company: company,
            jobTitle: "Job 1",
            applicationDate: Date(),
            stage: stage,
            stageMethod: nil
        )
        received.outcome = .offerReceived
        context.insert(received)
        interviews.append(received)
        
        // Offer accepted
        let accepted = Interview(
            company: company,
            jobTitle: "Job 2",
            applicationDate: Date(),
            stage: stage,
            stageMethod: nil
        )
        accepted.outcome = .offerAccepted
        context.insert(accepted)
        interviews.append(accepted)
        
        // Offer declined
        let declined = Interview(
            company: company,
            jobTitle: "Job 3",
            applicationDate: Date(),
            stage: stage,
            stageMethod: nil
        )
        declined.outcome = .offerDeclined
        context.insert(declined)
        interviews.append(declined)
        
        let stats = InterviewStats.compute(from: interviews)
        
        #expect(stats.totalInterviews == 3)
        #expect(stats.offerReceived == 1)
        #expect(stats.offerAccepted == 1)
        #expect(stats.offerDeclined == 1)
    }
}

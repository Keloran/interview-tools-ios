//
//  DatabaseCleanupTests.swift
//  InterviewsTests
//
//  Created by keloran on 06/12/2025.
//

import Foundation
import Testing
import SwiftData
@testable import Interviews

@MainActor
struct DatabaseCleanupTests {
    
    // MARK: - Stage Deduplication Tests
    
    @Test("Remove duplicate stages keeps first occurrence")
    func testRemoveDuplicateStagesKeepsFirst() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext
        
        // Create duplicate stages
        let stage1 = Stage(id: 1, stage: "Phone Screen")
        let stage2 = Stage(id: 2, stage: "Phone Screen")
        let stage3 = Stage(id: 3, stage: "Phone Screen")
        let stage4 = Stage(id: 4, stage: "Technical Interview")
        
        context.insert(stage1)
        context.insert(stage2)
        context.insert(stage3)
        context.insert(stage4)
        
        try context.save()
        
        // Verify we have 4 stages
        var allStages = try context.fetch(FetchDescriptor<Stage>())
        #expect(allStages.count == 4, "Should have 4 stages before cleanup")
        
        // Run cleanup
        try DatabaseCleanup.removeDuplicateStages(context: context)
        
        // Verify duplicates removed
        allStages = try context.fetch(FetchDescriptor<Stage>())
        #expect(allStages.count == 2, "Should have 2 unique stages after cleanup")
        
        // Verify we kept the right ones
        let phoneScreens = allStages.filter { $0.stage == "Phone Screen" }
        #expect(phoneScreens.count == 1, "Should have only 1 Phone Screen")
        #expect(phoneScreens.first?.id == 1, "Should keep the first occurrence")
        
        let technicalInterviews = allStages.filter { $0.stage == "Technical Interview" }
        #expect(technicalInterviews.count == 1, "Should have only 1 Technical Interview")
    }
    
    @Test("Remove duplicate stages handles empty database")
    func testRemoveDuplicateStagesEmptyDatabase() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext
        
        // Run cleanup on empty database - should not crash
        try DatabaseCleanup.removeDuplicateStages(context: context)
        
        let allStages = try context.fetch(FetchDescriptor<Stage>())
        #expect(allStages.isEmpty, "Should still be empty after cleanup")
    }
    
    @Test("Remove duplicate stages handles no duplicates")
    func testRemoveDuplicateStagesNoDuplicates() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext
        
        // Create unique stages only
        let stage1 = Stage(id: 1, stage: "Applied")
        let stage2 = Stage(id: 2, stage: "Phone Screen")
        let stage3 = Stage(id: 3, stage: "Technical Interview")
        
        context.insert(stage1)
        context.insert(stage2)
        context.insert(stage3)
        
        try context.save()
        
        // Run cleanup
        try DatabaseCleanup.removeDuplicateStages(context: context)
        
        // Verify nothing was deleted
        let allStages = try context.fetch(FetchDescriptor<Stage>())
        #expect(allStages.count == 3, "Should still have 3 unique stages")
    }
    
    @Test("Remove duplicate stages handles many duplicates")
    func testRemoveDuplicateStagesManyDuplicates() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext
        
        // Create 12 "Phone Screen" duplicates (like the reported bug)
        for i in 1...12 {
            let stage = Stage(id: i, stage: "Phone Screen")
            context.insert(stage)
        }
        
        try context.save()
        
        // Verify we have 12 duplicates
        var allStages = try context.fetch(FetchDescriptor<Stage>())
        #expect(allStages.count == 12, "Should have 12 duplicate stages")
        
        // Run cleanup
        try DatabaseCleanup.removeDuplicateStages(context: context)
        
        // Verify only 1 remains
        allStages = try context.fetch(FetchDescriptor<Stage>())
        #expect(allStages.count == 1, "Should have only 1 stage after cleanup")
        #expect(allStages.first?.stage == "Phone Screen")
        #expect(allStages.first?.id == 1, "Should keep the first one")
    }
    
    // MARK: - Stage Method Deduplication Tests
    
    @Test("Remove duplicate stage methods keeps first occurrence")
    func testRemoveDuplicateStageMethodsKeepsFirst() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext
        
        // Create duplicate methods
        let method1 = StageMethod(id: 1, method: "Video Call")
        let method2 = StageMethod(id: 2, method: "Video Call")
        let method3 = StageMethod(id: 3, method: "In Person")
        
        context.insert(method1)
        context.insert(method2)
        context.insert(method3)
        
        try context.save()
        
        // Run cleanup
        try DatabaseCleanup.removeDuplicateStageMethods(context: context)
        
        // Verify duplicates removed
        let allMethods = try context.fetch(FetchDescriptor<StageMethod>())
        #expect(allMethods.count == 2, "Should have 2 unique methods")
        
        let videoCalls = allMethods.filter { $0.method == "Video Call" }
        #expect(videoCalls.count == 1, "Should have only 1 Video Call")
        #expect(videoCalls.first?.id == 1, "Should keep the first occurrence")
    }
    
    // MARK: - Company Deduplication Tests
    
    @Test("Remove duplicate companies keeps first occurrence")
    func testRemoveDuplicateCompaniesKeepsFirst() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext
        
        // Create duplicate companies
        let company1 = Company(id: 1, name: "Apple")
        let company2 = Company(id: 2, name: "Apple")
        let company3 = Company(id: 3, name: "Google")
        
        context.insert(company1)
        context.insert(company2)
        context.insert(company3)
        
        try context.save()
        
        // Run cleanup
        try DatabaseCleanup.removeDuplicateCompanies(context: context)
        
        // Verify duplicates removed
        let allCompanies = try context.fetch(FetchDescriptor<Company>())
        #expect(allCompanies.count == 2, "Should have 2 unique companies")
        
        let apples = allCompanies.filter { $0.name == "Apple" }
        #expect(apples.count == 1, "Should have only 1 Apple")
        #expect(apples.first?.id == 1, "Should keep the first occurrence")
    }
    
    // MARK: - CleanupAll Tests
    
    @Test("CleanupAll removes duplicates from all entities")
    func testCleanupAllRemovesAllDuplicates() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext
        
        // Create duplicates in all entities
        let stage1 = Stage(id: 1, stage: "Phone Screen")
        let stage2 = Stage(id: 2, stage: "Phone Screen")
        
        let method1 = StageMethod(id: 1, method: "Video Call")
        let method2 = StageMethod(id: 2, method: "Video Call")
        
        let company1 = Company(id: 1, name: "Apple")
        let company2 = Company(id: 2, name: "Apple")
        
        context.insert(stage1)
        context.insert(stage2)
        context.insert(method1)
        context.insert(method2)
        context.insert(company1)
        context.insert(company2)
        
        try context.save()
        
        // Run full cleanup
        try DatabaseCleanup.cleanupAll(context: context)
        
        // Verify all duplicates removed
        let allStages = try context.fetch(FetchDescriptor<Stage>())
        #expect(allStages.count == 1, "Should have 1 unique stage")
        
        let allMethods = try context.fetch(FetchDescriptor<StageMethod>())
        #expect(allMethods.count == 1, "Should have 1 unique method")
        
        let allCompanies = try context.fetch(FetchDescriptor<Company>())
        #expect(allCompanies.count == 1, "Should have 1 unique company")
    }
    
    // MARK: - Relationship Preservation Tests
    
    @Test("Cleanup preserves interview relationships")
    func testCleanupPreservesInterviewRelationships() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext
        
        // Create duplicate stage
        let stage1 = Stage(id: 1, stage: "Phone Screen")
        let stage2 = Stage(id: 2, stage: "Phone Screen")
        context.insert(stage1)
        context.insert(stage2)
        
        // Create company
        let company = Company(id: 1, name: "Apple")
        context.insert(company)
        
        // Create interview using the FIRST stage (which will be kept)
        let interview1 = Interview(
            id: 1,
            company: company,
            jobTitle: "iOS Engineer",
            applicationDate: Date(),
            stage: stage1
        )
        context.insert(interview1)
        
        try context.save()
        
        // Verify initial state
        var allStages = try context.fetch(FetchDescriptor<Stage>())
        #expect(allStages.count == 2, "Should have 2 stages before cleanup")
        
        // Run cleanup
        try DatabaseCleanup.removeDuplicateStages(context: context)
        
        // Verify stage deduplicated
        allStages = try context.fetch(FetchDescriptor<Stage>())
        #expect(allStages.count == 1, "Should have 1 stage after cleanup")
        
        // Verify interview relationship still works
        let allInterviews = try context.fetch(FetchDescriptor<Interview>())
        #expect(allInterviews.count == 1, "Interview should still exist")
        #expect(allInterviews.first?.stage?.stage == "Phone Screen", "Interview should still have stage")
        #expect(allInterviews.first?.stage?.id == 1, "Interview should reference the kept stage")
    }
    
    // MARK: - Case Sensitivity Tests
    
    @Test("Cleanup is case-sensitive for stage names")
    func testCleanupCaseSensitive() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext
        
        // Create stages with different casing
        let stage1 = Stage(id: 1, stage: "Phone Screen")
        let stage2 = Stage(id: 2, stage: "phone screen")
        let stage3 = Stage(id: 3, stage: "PHONE SCREEN")
        
        context.insert(stage1)
        context.insert(stage2)
        context.insert(stage3)
        
        try context.save()
        
        // Run cleanup
        try DatabaseCleanup.removeDuplicateStages(context: context)
        
        // Verify case sensitivity - all three should be kept as different
        let allStages = try context.fetch(FetchDescriptor<Stage>())
        #expect(allStages.count == 3, "Should keep all three different casings")
    }
    
    // MARK: - Multiple Stage Mix Tests
    
    @Test("Cleanup handles mix of unique and duplicate stages")
    func testCleanupMixedStages() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext
        
        // Create a realistic mix
        let stages = [
            Stage(id: 1, stage: "Applied"),
            Stage(id: 2, stage: "Phone Screen"),
            Stage(id: 3, stage: "Phone Screen"),  // duplicate
            Stage(id: 4, stage: "Phone Screen"),  // duplicate
            Stage(id: 5, stage: "Technical Test"),
            Stage(id: 6, stage: "Technical Interview"),
            Stage(id: 7, stage: "Technical Interview"),  // duplicate
            Stage(id: 8, stage: "Onsite"),
            Stage(id: 9, stage: "Offer")
        ]
        
        for stage in stages {
            context.insert(stage)
        }
        
        try context.save()
        
        // Run cleanup
        try DatabaseCleanup.removeDuplicateStages(context: context)
        
        // Verify correct deduplication
        let allStages = try context.fetch(FetchDescriptor<Stage>())
        #expect(allStages.count == 6, "Should have 6 unique stages")
        
        // Verify each unique stage exists once
        let stageNames = allStages.map { $0.stage }
        #expect(stageNames.contains("Applied"))
        #expect(stageNames.contains("Phone Screen"))
        #expect(stageNames.contains("Technical Test"))
        #expect(stageNames.contains("Technical Interview"))
        #expect(stageNames.contains("Onsite"))
        #expect(stageNames.contains("Offer"))
        
        // Verify no duplicates
        let phoneScreens = allStages.filter { $0.stage == "Phone Screen" }
        #expect(phoneScreens.count == 1)
        
        let technicalInterviews = allStages.filter { $0.stage == "Technical Interview" }
        #expect(technicalInterviews.count == 1)
    }
}

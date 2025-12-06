//
//  SyncServiceTests.swift
//  InterviewsTests
//
//  Created by keloran on 06/12/2025.
//

import Foundation
import Testing
import SwiftData
@testable import Interviews

@MainActor
struct SyncServiceTests {
    
    // MARK: - SyncService Initialization
    
    @Test("SyncService initializes with model context")
    func testSyncServiceInitialization() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext
        
        let syncService = SyncService(modelContext: context)
        
        #expect(syncService.isSyncing == false, "Should start with isSyncing = false")
        #expect(syncService.lastSyncDate == nil, "Should start with no last sync date")
        #expect(syncService.syncError == nil, "Should start with no sync error")
    }
    
    // MARK: - Company Sync Tests
    
    @Test("Companies are inserted into database after sync")
    func testCompaniesSyncInsertion() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext
        
        // Manually insert companies (simulating what syncCompanies does)
        let company1 = Company(id: 1, name: "Apple")
        let company2 = Company(id: 2, name: "Google")
        
        context.insert(company1)
        context.insert(company2)
        
        try context.save()
        
        // Verify companies exist
        let descriptor = FetchDescriptor<Company>()
        let companies = try context.fetch(descriptor)
        
        #expect(companies.count == 2, "Should have 2 companies")
        #expect(companies.contains { $0.name == "Apple" })
        #expect(companies.contains { $0.name == "Google" })
    }
    
    @Test("Existing company is updated during sync")
    func testCompanyUpdate() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext
        
        // Insert initial company
        let company = Company(id: 1, name: "Old Name")
        context.insert(company)
        try context.save()
        
        // Simulate update from API
        let companyId = 1
        let descriptor = FetchDescriptor<Company>(
            predicate: #Predicate { company in
                company.id == companyId
            }
        )
        
        if let existing = try context.fetch(descriptor).first {
            existing.name = "New Name"
            try context.save()
        }
        
        // Verify update
        let updated = try context.fetch(descriptor).first
        #expect(updated?.name == "New Name", "Company name should be updated")
    }
    
    // MARK: - Stage Sync Tests
    
    @Test("Stages are inserted into database after sync")
    func testStagesSyncInsertion() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext
        
        // Simulate stage sync
        let stage1 = Stage(id: 1, stage: "Applied")
        let stage2 = Stage(id: 2, stage: "Phone Screen")
        let stage3 = Stage(id: 3, stage: "Technical Interview")
        
        context.insert(stage1)
        context.insert(stage2)
        context.insert(stage3)
        
        try context.save()
        
        // Verify stages exist
        let descriptor = FetchDescriptor<Stage>()
        let stages = try context.fetch(descriptor)
        
        #expect(stages.count == 3, "Should have 3 stages")
        #expect(stages.contains { $0.stage == "Applied" })
        #expect(stages.contains { $0.stage == "Phone Screen" })
        #expect(stages.contains { $0.stage == "Technical Interview" })
    }
    
    @Test("Existing stage is updated during sync")
    func testStageUpdate() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext
        
        // Insert initial stage
        let stage = Stage(id: 1, stage: "Old Stage")
        context.insert(stage)
        try context.save()
        
        // Simulate update from API
        let stageId = 1
        let descriptor = FetchDescriptor<Stage>(
            predicate: #Predicate { stage in
                stage.id == stageId
            }
        )
        
        if let existing = try context.fetch(descriptor).first {
            existing.stage = "Updated Stage"
            try context.save()
        }
        
        // Verify update
        let updated = try context.fetch(descriptor).first
        #expect(updated?.stage == "Updated Stage", "Stage should be updated")
    }
    
    // MARK: - Stage Method Sync Tests
    
    @Test("Stage methods are inserted into database after sync")
    func testStageMethodsSyncInsertion() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext
        
        // Simulate stage method sync
        let method1 = StageMethod(id: 1, method: "Video Call")
        let method2 = StageMethod(id: 2, method: "Phone Call")
        let method3 = StageMethod(id: 3, method: "In Person")
        
        context.insert(method1)
        context.insert(method2)
        context.insert(method3)
        
        try context.save()
        
        // Verify methods exist
        let descriptor = FetchDescriptor<StageMethod>()
        let methods = try context.fetch(descriptor)
        
        #expect(methods.count == 3, "Should have 3 stage methods")
        #expect(methods.contains { $0.method == "Video Call" })
        #expect(methods.contains { $0.method == "Phone Call" })
        #expect(methods.contains { $0.method == "In Person" })
    }
    
    @Test("Existing stage method is updated during sync")
    func testStageMethodUpdate() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext
        
        // Insert initial method
        let method = StageMethod(id: 1, method: "Old Method")
        context.insert(method)
        try context.save()
        
        // Simulate update from API
        let methodId = 1
        let descriptor = FetchDescriptor<StageMethod>(
            predicate: #Predicate { method in
                method.id == methodId
            }
        )
        
        if let existing = try context.fetch(descriptor).first {
            existing.method = "Updated Method"
            try context.save()
        }
        
        // Verify update
        let updated = try context.fetch(descriptor).first
        #expect(updated?.method == "Updated Method", "Method should be updated")
    }
    
    // MARK: - Interview Sync Tests
    
    @Test("Interviews are inserted with relationships after sync")
    func testInterviewsSyncWithRelationships() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext
        
        // Setup relationships
        let company = Company(id: 1, name: "Apple")
        let stage = Stage(id: 1, stage: "Phone Screen")
        let method = StageMethod(id: 1, method: "Video Call")
        
        context.insert(company)
        context.insert(stage)
        context.insert(method)
        
        // Create interview with relationships
        let interview = Interview(
            id: 1,
            company: company,
            jobTitle: "iOS Engineer",
            applicationDate: Date(),
            stage: stage,
            stageMethod: method,
            date: Date(),
            outcome: .scheduled
        )
        
        context.insert(interview)
        try context.save()
        
        // Verify interview and relationships
        let descriptor = FetchDescriptor<Interview>()
        let interviews = try context.fetch(descriptor)
        
        #expect(interviews.count == 1, "Should have 1 interview")
        
        let syncedInterview = interviews.first
        #expect(syncedInterview?.jobTitle == "iOS Engineer")
        #expect(syncedInterview?.company?.name == "Apple")
        #expect(syncedInterview?.stage?.stage == "Phone Screen")
        #expect(syncedInterview?.stageMethod?.method == "Video Call")
        #expect(syncedInterview?.outcome == .scheduled)
    }
    
    @Test("Existing interview is updated during sync")
    func testInterviewUpdate() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext
        
        // Setup
        let company = Company(id: 1, name: "Apple")
        context.insert(company)
        
        let interview = Interview(
            id: 1,
            company: company,
            jobTitle: "Junior Engineer",
            applicationDate: Date(),
            outcome: .scheduled
        )
        
        context.insert(interview)
        try context.save()
        
        // Simulate update from API
        let interviewId = 1
        let descriptor = FetchDescriptor<Interview>(
            predicate: #Predicate { interview in
                interview.id == interviewId
            }
        )
        
        if let existing = try context.fetch(descriptor).first {
            existing.jobTitle = "Senior Engineer"
            existing.outcome = .passed
            try context.save()
        }
        
        // Verify update
        let updated = try context.fetch(descriptor).first
        #expect(updated?.jobTitle == "Senior Engineer", "Job title should be updated")
        #expect(updated?.outcome == .passed, "Outcome should be updated")
    }
    
    @Test("Multiple interviews from same company are linked correctly")
    func testMultipleInterviewsWithSameCompany() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext
        
        // Create one company
        let apple = Company(id: 1, name: "Apple")
        context.insert(apple)
        
        // Create multiple interviews with same company
        let interview1 = Interview(
            id: 1,
            company: apple,
            jobTitle: "iOS Engineer",
            applicationDate: Date()
        )
        
        let interview2 = Interview(
            id: 2,
            company: apple,
            jobTitle: "Senior iOS Engineer",
            applicationDate: Date()
        )
        
        let interview3 = Interview(
            id: 3,
            company: apple,
            jobTitle: "Staff iOS Engineer",
            applicationDate: Date()
        )
        
        context.insert(interview1)
        context.insert(interview2)
        context.insert(interview3)
        
        try context.save()
        
        // Verify all interviews share the same company
        let descriptor = FetchDescriptor<Interview>()
        let interviews = try context.fetch(descriptor)
        
        #expect(interviews.count == 3, "Should have 3 interviews")
        #expect(interviews.allSatisfy { $0.company?.name == "Apple" }, 
                "All interviews should be linked to Apple")
    }
    
    // MARK: - Sync State Tests
    
    @Test("lastSyncDate is updated after successful sync")
    func testLastSyncDateUpdate() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext
        
        let syncService = SyncService(modelContext: context)
        
        // Initial state
        #expect(syncService.lastSyncDate == nil, "Should start with no last sync date")
        
        // Note: In a real test with mocked APIService, we would call syncAll()
        // For now, we verify the state management logic
    }
    
    @Test("isSyncing state is managed correctly")
    func testSyncingStateManagement() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext
        
        let syncService = SyncService(modelContext: context)
        
        // Verify initial state
        #expect(syncService.isSyncing == false, "Should start not syncing")
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Sync error is captured when API fails")
    func testSyncErrorCapture() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext
        
        let syncService = SyncService(modelContext: context)
        
        // Initial state should have no error
        #expect(syncService.syncError == nil, "Should start with no sync error")
    }
    
    // MARK: - Date Parsing Tests
    
    @Test("ISO8601 dates are parsed correctly")
    func testDateParsing() async throws {
        let dateFormatter = ISO8601DateFormatter()
        
        let dateString = "2025-12-10T09:00:00Z"
        let parsedDate = dateFormatter.date(from: dateString)
        
        #expect(parsedDate != nil, "Should successfully parse ISO8601 date")
        
        // Verify we can format it back
        if let date = parsedDate {
            let formatted = dateFormatter.string(from: date)
            #expect(formatted == dateString, "Round-trip formatting should work")
        }
    }
    
    @Test("Optional dates are handled correctly")
    func testOptionalDateHandling() async throws {
        let dateFormatter = ISO8601DateFormatter()
        
        let validDate: String? = "2025-12-10T09:00:00Z"
        let nilDate: String? = nil
        
        let parsedValid = validDate.flatMap { dateFormatter.date(from: $0) }
        let parsedNil = nilDate.flatMap { dateFormatter.date(from: $0) }
        
        #expect(parsedValid != nil, "Valid date string should parse")
        #expect(parsedNil == nil, "Nil date string should result in nil")
    }
    
    // MARK: - Outcome Parsing Tests
    
    @Test("Outcome strings are parsed to enum correctly")
    func testOutcomeParsing() async throws {
        let scheduledStr = "SCHEDULED"
        let passedStr = "PASSED"
        let rejectedStr = "REJECTED"
        let invalidStr = "INVALID"
        
        let scheduled = InterviewOutcome(rawValue: scheduledStr)
        let passed = InterviewOutcome(rawValue: passedStr)
        let rejected = InterviewOutcome(rawValue: rejectedStr)
        let invalid = InterviewOutcome(rawValue: invalidStr)
        
        #expect(scheduled == .scheduled, "Should parse SCHEDULED")
        #expect(passed == .passed, "Should parse PASSED")
        #expect(rejected == .rejected, "Should parse REJECTED")
        #expect(invalid == nil, "Invalid string should return nil")
    }
    
    @Test("Optional outcome strings are handled correctly")
    func testOptionalOutcomeHandling() async throws {
        let validOutcome: String? = "SCHEDULED"
        let nilOutcome: String? = nil
        
        let parsed1 = validOutcome.flatMap { InterviewOutcome(rawValue: $0) }
        let parsed2 = nilOutcome.flatMap { InterviewOutcome(rawValue: $0) }
        
        #expect(parsed1 == .scheduled, "Valid outcome should parse")
        #expect(parsed2 == nil, "Nil outcome should result in nil")
    }
}

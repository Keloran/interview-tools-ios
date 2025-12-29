//
//  DatabaseCleanup.swift
//  Interviews
//
//  Created by keloran on 06/12/2025.
//

import Foundation
import SwiftData

@MainActor
class DatabaseCleanup {
    
    /// Remove duplicate stages from the database, keeping only the first occurrence of each unique name
    /// In guest mode, keeps stages without IDs. After sign-in, server IDs will be assigned during sync.
    static func removeDuplicateStages(context: ModelContext) throws {
        let descriptor = FetchDescriptor<Stage>(
            sortBy: [SortDescriptor(\.id)]
        )
        let allStages = try context.fetch(descriptor)
        
        guard !allStages.isEmpty else {
//            print("⚠️ No stages found in database")
            return
        }
        
//        print("📊 Found \(allStages.count) total stages")
        
        // Count stages with nil IDs
//        let nilIdCount = allStages.filter { $0.id == nil }.count
//        if nilIdCount > 0 {
//            print("⚠️ Warning: \(nilIdCount) stage(s) have nil ID - this can cause UI issues")
//        }
        
        // Group by name to find duplicates (maintaining sorted order by ID)
        var stagesByName: [String: [Stage]] = [:]
        for stage in allStages {
            stagesByName[stage.stage, default: []].append(stage)
        }
        
//        print("📊 Unique stage names: \(stagesByName.keys.sorted().joined(separator: ", "))")
        
        var stagesToKeep: [Stage] = []
        var stagesToDelete: [Stage] = []
        
        // For each group, keep the first one (lowest ID) and mark the rest for deletion
        for (_, stages) in stagesByName {
            if stages.count > 1 {
//                print("🔍 Found \(stages.count) duplicates of '\(name)'")
                
                // Sort by ID to ensure we keep the first one
                let sorted = stages.sorted { (s1, s2) -> Bool in
                    guard let id1 = s1.id, let id2 = s2.id else {
                        // If either has nil ID, prefer the one with an ID
                        if s1.id != nil { return true }
                        if s2.id != nil { return false }
                        return false // Both nil, doesn't matter
                    }
                    return id1 < id2
                }
                
                // Keep the first one, delete the rest
                if let first = sorted.first {
                    stagesToKeep.append(first)
                }
                stagesToDelete.append(contentsOf: sorted.dropFirst())
            } else {
                // No duplicates, keep it
                if let stage = stages.first {
                    stagesToKeep.append(stage)
                }
            }
        }
        
        guard !stagesToDelete.isEmpty else {
//            print("✅ No duplicate stages found")
            return
        }
        
        // IMPORTANT: Update any interviews that reference the stages we're about to delete
        // to reference the stage we're keeping instead
        let interviewDescriptor = FetchDescriptor<Interview>()
        let allInterviews = try context.fetch(interviewDescriptor)
        
        var reassignCount = 0
        for interview in allInterviews {
            guard let currentStage = interview.stage else { continue }
            
            // If this interview references a stage we're about to delete, reassign it
            if stagesToDelete.contains(where: { $0.persistentModelID == currentStage.persistentModelID }) {
                // Find the replacement stage (the one we're keeping with the same name)
                if let replacement = stagesToKeep.first(where: { $0.stage == currentStage.stage }) {
                    interview.stage = replacement
                    reassignCount += 1
                }
            }
        }
        
//        if reassignCount > 0 {
//            print("🔗 Reassigned \(reassignCount) interview(s) to deduplicated stages")
//        }
        
        // Delete duplicates
//        print("🗑️ Deleting \(stagesToDelete.count) duplicate stage(s)")
        for duplicate in stagesToDelete {
            context.delete(duplicate)
        }
        
        try context.save()
//        print("🧹 Cleaned up \(stagesToDelete.count) duplicate stage(s)")
        
        // Verify what's left
//        let remaining = try context.fetch(FetchDescriptor<Stage>())
//        let remainingNilIds = remaining.filter { $0.id == nil }.count
//        print("✅ \(remaining.count) unique stages remaining: \(remaining.map { $0.stage }.sorted().joined(separator: ", "))")
//        if remainingNilIds > 0 {
//            print("⚠️ Note: \(remainingNilIds) stage(s) still have nil ID")
//        }
    }
    
    /// Remove duplicate stage methods from the database, keeping only the first occurrence of each unique name
    static func removeDuplicateStageMethods(context: ModelContext) throws {
        let descriptor = FetchDescriptor<StageMethod>(
            sortBy: [SortDescriptor(\.id)]
        )
        let allMethods = try context.fetch(descriptor)
        
        var seenNames: [String: StageMethod] = [:]
        var methodsToDelete: [StageMethod] = []
        
        for method in allMethods {
            if seenNames[method.method] !== nil {
                // This is a duplicate, mark for deletion
                methodsToDelete.append(method)
            } else {
                // First occurrence, keep it
                seenNames[method.method] = method
            }
        }
        
        guard !methodsToDelete.isEmpty else {
//            print("✅ No duplicate stage methods found")
            return
        }
        
        // IMPORTANT: Update any interviews that reference the methods we're about to delete
        let interviewDescriptor = FetchDescriptor<Interview>()
        let allInterviews = try context.fetch(interviewDescriptor)
        
        var reassignCount = 0
        for interview in allInterviews {
            guard let currentMethod = interview.stageMethod else { continue }
            
            // If this interview references a method we're about to delete, reassign it
            if methodsToDelete.contains(where: { $0.persistentModelID == currentMethod.persistentModelID }) {
                // Find the replacement method (the one we're keeping with the same name)
                if let replacement = seenNames[currentMethod.method] {
                    interview.stageMethod = replacement
                    reassignCount += 1
                }
            }
        }
        
//        if reassignCount > 0 {
//            print("🔗 Reassigned \(reassignCount) interview(s) to deduplicated methods")
//        }
        
        // Delete duplicates
        for duplicate in methodsToDelete {
            context.delete(duplicate)
        }
        
        try context.save()
//        print("🧹 Cleaned up \(methodsToDelete.count) duplicate stage method(s)")
    }
    
    /// Remove duplicate companies from the database, keeping only the first occurrence of each unique name
    static func removeDuplicateCompanies(context: ModelContext) throws {
        let descriptor = FetchDescriptor<Company>(
            sortBy: [SortDescriptor(\.id)]
        )
        let allCompanies = try context.fetch(descriptor)
        
        var seenNames: [String: Company] = [:]
        var companiesToDelete: [Company] = []
        
        for company in allCompanies {
            if seenNames[company.name] !== nil {
                // This is a duplicate, mark for deletion
                companiesToDelete.append(company)
            } else {
                // First occurrence, keep it
                seenNames[company.name] = company
            }
        }
        
        guard !companiesToDelete.isEmpty else {
//            print("✅ No duplicate companies found")
            return
        }
        
        // IMPORTANT: Update any interviews that reference the companies we're about to delete
        let interviewDescriptor = FetchDescriptor<Interview>()
        let allInterviews = try context.fetch(interviewDescriptor)
        
        var reassignCount = 0
        for interview in allInterviews {
            guard let currentCompany = interview.company else { continue }
            
            // If this interview references a company we're about to delete, reassign it
            if companiesToDelete.contains(where: { $0.persistentModelID == currentCompany.persistentModelID }) {
                // Find the replacement company (the one we're keeping with the same name)
                if let replacement = seenNames[currentCompany.name] {
                    interview.company = replacement
                    reassignCount += 1
                }
            }
        }
        
//        if reassignCount > 0 {
//            print("🔗 Reassigned \(reassignCount) interview(s) to deduplicated companies")
//        }
        
        // Delete duplicates
        for duplicate in companiesToDelete {
            context.delete(duplicate)
        }
        
        try context.save()
//        print("🧹 Cleaned up \(companiesToDelete.count) duplicate company(ies)")
    }
    
    /// Run all cleanup operations
    static func cleanupAll(context: ModelContext) throws {
//        print("🧹 Starting database cleanup...")
        try removeDuplicateStages(context: context)
        try removeDuplicateStageMethods(context: context)
        try removeDuplicateCompanies(context: context)
//        print("✅ Database cleanup complete")
    }
}

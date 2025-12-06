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
    static func removeDuplicateStages(context: ModelContext) throws {
        let descriptor = FetchDescriptor<Stage>()
        let allStages = try context.fetch(descriptor)
        
        guard !allStages.isEmpty else {
            print("⚠️ No stages found in database")
            return
        }
        
        print("📊 Found \(allStages.count) total stages")
        
        // Count stages with nil IDs
        let nilIdCount = allStages.filter { $0.id == nil }.count
        if nilIdCount > 0 {
            print("⚠️ Warning: \(nilIdCount) stage(s) have nil ID - this can cause UI issues")
        }
        
        // Group by name to find duplicates
        var stagesByName: [String: [Stage]] = [:]
        for stage in allStages {
            stagesByName[stage.stage, default: []].append(stage)
        }
        
        print("📊 Unique stage names: \(stagesByName.keys.sorted().joined(separator: ", "))")
        
        var duplicates: [Stage] = []
        
        // For each group, keep the one with an ID (if any), or the first one
        for (name, stages) in stagesByName {
            if stages.count > 1 {
                print("🔍 Found \(stages.count) duplicates of '\(name)'")
                
                // Prefer keeping stages with IDs
                let withIds = stages.filter { $0.id != nil }
                let withoutIds = stages.filter { $0.id == nil }
                
                if !withIds.isEmpty {
                    // Keep the first one with an ID, delete the rest
                    duplicates.append(contentsOf: withIds.dropFirst())
                    duplicates.append(contentsOf: withoutIds) // Delete all without IDs
                } else {
                    // All have nil IDs, just keep the first
                    duplicates.append(contentsOf: stages.dropFirst())
                }
            }
        }
        
        guard !duplicates.isEmpty else {
            print("✅ No duplicate stages found")
            return
        }
        
        // Delete duplicates
        print("🗑️ Deleting \(duplicates.count) duplicate stage(s)")
        for duplicate in duplicates {
            context.delete(duplicate)
        }
        
        try context.save()
        print("🧹 Cleaned up \(duplicates.count) duplicate stage(s)")
        
        // Verify what's left
        let remaining = try context.fetch(FetchDescriptor<Stage>())
        let remainingNilIds = remaining.filter { $0.id == nil }.count
        print("✅ \(remaining.count) unique stages remaining: \(remaining.map { $0.stage }.sorted().joined(separator: ", "))")
        if remainingNilIds > 0 {
            print("⚠️ Note: \(remainingNilIds) stage(s) still have nil ID")
        }
    }
    
    /// Remove duplicate stage methods from the database, keeping only the first occurrence of each unique name
    static func removeDuplicateStageMethods(context: ModelContext) throws {
        let descriptor = FetchDescriptor<StageMethod>(
            sortBy: [SortDescriptor(\.id)]
        )
        let allMethods = try context.fetch(descriptor)
        
        var seenNames = Set<String>()
        var duplicates: [StageMethod] = []
        
        for method in allMethods {
            if seenNames.contains(method.method) {
                duplicates.append(method)
            } else {
                seenNames.insert(method.method)
            }
        }
        
        // Delete duplicates
        for duplicate in duplicates {
            context.delete(duplicate)
        }
        
        if !duplicates.isEmpty {
            try context.save()
            print("🧹 Cleaned up \(duplicates.count) duplicate stage method(s)")
        }
    }
    
    /// Remove duplicate companies from the database, keeping only the first occurrence of each unique name
    static func removeDuplicateCompanies(context: ModelContext) throws {
        let descriptor = FetchDescriptor<Company>(
            sortBy: [SortDescriptor(\.id)]
        )
        let allCompanies = try context.fetch(descriptor)
        
        var seenNames = Set<String>()
        var duplicates: [Company] = []
        
        for company in allCompanies {
            if seenNames.contains(company.name) {
                duplicates.append(company)
            } else {
                seenNames.insert(company.name)
            }
        }
        
        // Delete duplicates
        for duplicate in duplicates {
            context.delete(duplicate)
        }
        
        if !duplicates.isEmpty {
            try context.save()
            print("🧹 Cleaned up \(duplicates.count) duplicate company(ies)")
        }
    }
    
    /// Run all cleanup operations
    static func cleanupAll(context: ModelContext) throws {
        print("🧹 Starting database cleanup...")
        try removeDuplicateStages(context: context)
        try removeDuplicateStageMethods(context: context)
        try removeDuplicateCompanies(context: context)
        print("✅ Database cleanup complete")
    }
}

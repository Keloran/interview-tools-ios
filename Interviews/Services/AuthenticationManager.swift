//
//  AuthenticationManager.swift
//  Interviews
//
//  Created by keloran on 07/12/2025.
//

import Foundation
import SwiftData
import Clerk

/// Manages authentication state and guest mode functionality
@MainActor
@Observable
class AuthenticationManager {
    static let shared = AuthenticationManager()
    
    private let clerk = Clerk.shared
    
    /// Whether the app is currently in guest mode (no authentication)
    var isGuestMode: Bool {
        !isAuthenticated
    }
    
    /// Whether the user is authenticated with Clerk
    var isAuthenticated: Bool {
        clerk.user != nil
    }
    
    /// Whether guest data is currently being migrated to the server
    var isMigrating = false
    
    /// The current Clerk user, if authenticated
    var user: User? {
        clerk.user
    }
    
    private init() {}
    
    // MARK: - Guest Data Migration
    
    /// Migrate all guest data to the server when a user signs in
    /// This uploads all local-only data (with nil IDs) to the server
    func migrateGuestDataToServer(using syncService: SyncService) async throws {
        guard isAuthenticated else {
            throw AuthenticationError.notAuthenticated
        }
        
        guard !isMigrating else {
            print("⚠️ Migration already in progress")
            return
        }
        
        isMigrating = true
        defer { isMigrating = false }
        
        print("🔄 Starting guest data migration to server...")
        
        let context = syncService.modelContext
        
        // Step 1: Push all local-only interviews to the server
        try await pushLocalInterviewsToServer(context: context, syncService: syncService)
        
        // Step 2: Sync all data from server (this is now the source of truth)
        await syncService.syncAll()
        
        // Step 3: Clean up any remaining duplicates
        try DatabaseCleanup.cleanupAll(context: context)
        
        print("✅ Guest data migration complete")
    }
    
    // MARK: - Private Helpers
    
    /// Push all local-only interviews (without server IDs) to the server
    private func pushLocalInterviewsToServer(context: ModelContext, syncService: SyncService) async throws {
        // Find all interviews without server IDs (guest mode interviews)
        let descriptor = FetchDescriptor<Interview>(
            predicate: #Predicate { interview in
                interview.id == nil
            }
        )
        
        let localInterviews = try context.fetch(descriptor)
        
        guard !localInterviews.isEmpty else {
            print("📭 No local interviews to push")
            return
        }
        
        print("📤 Pushing \(localInterviews.count) local interview(s) to server...")
        
        var successCount = 0
        var failureCount = 0
        
        for interview in localInterviews {
            do {
                // First, ensure the company exists on the server
                if let company = interview.company, company.id == nil {
                    try await pushCompanyIfNeeded(company, context: context, syncService: syncService)
                }
                
                // Push the interview to the server
                let apiInterview = try await syncService.pushInterview(interview)
                
                // Update the local interview with the server ID
                interview.id = apiInterview.id
                successCount += 1
                
                print("✅ Pushed interview: \(interview.jobTitle) at \(interview.company?.name ?? "Unknown")")
            } catch {
                failureCount += 1
                print("❌ Failed to push interview: \(interview.jobTitle) - \(error)")
                // Continue with other interviews even if one fails
            }
        }
        
        // Save the updated IDs
        try context.save()
        
        print("📊 Push complete: \(successCount) succeeded, \(failureCount) failed")
        
        if failureCount > 0 {
            throw AuthenticationError.partialMigrationFailure(
                succeeded: successCount,
                failed: failureCount
            )
        }
    }
    
    /// Push a company to the server if it doesn't exist yet
    private func pushCompanyIfNeeded(_ company: Company, context: ModelContext, syncService: SyncService) async throws {
        // Check if this company name already exists on the server
        let companies = try await APIService.shared.fetchCompanies()
        
        if let existingCompany = companies.first(where: { $0.name == company.name }) {
            // Company already exists on server, just update the local ID
            company.id = existingCompany.id
            print("🔗 Linked local company '\(company.name)' to server ID \(existingCompany.id)")
        } else {
            // Company doesn't exist on server yet - it will be created when we push the interview
            // The server will handle creating the company if it doesn't exist
            print("📝 Company '\(company.name)' will be created on server")
        }
    }
    
    // MARK: - Sign In/Out
    
    /// Called when user signs in - sets up authentication and starts migration
    func handleSignIn(token: String) async throws {
        await APIService.shared.setAuthToken(token)
        print("✅ Authentication token set")
    }
    
    /// Called when user signs out - clears authentication
    func handleSignOut() async {
        await APIService.shared.setAuthToken(nil)
        print("👋 Signed out - entering guest mode")
    }
}

// MARK: - Errors

enum AuthenticationError: LocalizedError {
    case notAuthenticated
    case partialMigrationFailure(succeeded: Int, failed: Int)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to perform this action"
        case .partialMigrationFailure(let succeeded, let failed):
            return "Migration partially completed: \(succeeded) succeeded, \(failed) failed"
        }
    }
}

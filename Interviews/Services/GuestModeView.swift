//
//  GuestModeView.swift
//  Interviews
//
//  Created by keloran on 07/12/2025.
//

import SwiftUI
import SwiftData
import Clerk

/// A view that shows guest mode status and allows users to sign in
struct GuestModeBanner: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.clerk) private var clerk
    @State private var showingSignIn = false
    @State private var showingMigrationStatus = false
    
    var body: some View {
        if clerk.user == nil {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .foregroundStyle(.blue)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Guest Mode")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("Sign in to sync across devices")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if clerk.user != nil {
                        // User is authenticated, show sync button
                        Button("Sync Now") {
                            showingMigrationStatus = true
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    } else {
                        Button("Sign In") {
                            showingSignIn = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemGroupedBackground))
                
                Divider()
            }
            .sheet(isPresented: $showingSignIn) {
                SignInView()
            }
            .sheet(isPresented: $showingMigrationStatus) {
                MigrationView()
            }
        }
    }
}

/// View for signing in
struct SignInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.clerk) private var clerk
    @State private var authIsPresented = true
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "person.circle")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                
                VStack(spacing: 8) {
                    Text("Sign In to Sync")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Your interviews will be synced to the cloud and available on all your devices")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                Button("Continue as Guest") {
                    dismiss()
                }
                .font(.subheadline)
            }
            .padding()
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $authIsPresented) {
                AuthView()
            }
            .onChange(of: clerk.user) { oldValue, newValue in
                // When user signs in, dismiss this view
                if oldValue == nil && newValue != nil {
                    authIsPresented = false
                    dismiss()
                }
            }
        }
    }
}

/// View showing migration progress
struct MigrationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.clerk) private var clerk
    @State private var syncService: SyncService?
    @State private var isProcessing = false
    @State private var error: Error?
    @State private var hasCompleted = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if isProcessing {
                    ProgressView()
                        .controlSize(.large)
                        .scaleEffect(1.5)
                    
                    Text("Syncing your data...")
                        .font(.headline)
                    
                    Text("This may take a moment")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if hasCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.green)
                    
                    Text("All Set!")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Your interviews are now synced")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.top)
                } else if let error = error {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.orange)
                    
                    Text("Sync Error")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Try Again") {
                        performMigration()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.top)
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "arrow.triangle.2.circlepath.circle")
                            .font(.system(size: 80))
                            .foregroundStyle(.blue)
                        
                        Text("Sync Your Data")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("We'll upload your interviews to the cloud so they're available everywhere")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Start Sync") {
                            performMigration()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.top)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Sync")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isProcessing {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                // Initialize sync service
                syncService = SyncService(modelContext: modelContext)
            }
        }
    }
    
    private func performMigration() {
        guard let syncService = syncService else { return }
        guard clerk.user != nil else {
            error = NSError(domain: "com.interviews", code: 401, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to sync"])
            return
        }
        
        isProcessing = true
        error = nil
        
        Task {
            do {
                // Push all local guest interviews to server
                try await pushLocalInterviewsToServer(syncService: syncService)
                
                // Sync all data from server (source of truth)
                await syncService.syncAll()
                
                // Clean up duplicates
                try DatabaseCleanup.cleanupAll(context: modelContext)
                
                hasCompleted = true
            } catch {
                self.error = error
            }
            isProcessing = false
        }
    }
    
    /// Push all local-only interviews (without server IDs) to the server
    private func pushLocalInterviewsToServer(syncService: SyncService) async throws {
        let descriptor = FetchDescriptor<Interview>(
            predicate: #Predicate { interview in
                interview.id == nil
            }
        )
        
        let localInterviews = try modelContext.fetch(descriptor)
        
        guard !localInterviews.isEmpty else {
//            print("📭 No local interviews to push")
            return
        }
        
        print("📤 Pushing \(localInterviews.count) local interview(s) to server...")
        
        var successCount = 0
        var failureCount = 0
        
        for interview in localInterviews {
            do {
                // Push the interview to the server (server will create company if needed)
                let apiInterview = try await syncService.pushInterview(interview)
                
                // Update the local interview with the server ID
                interview.id = apiInterview.id
                successCount += 1
                
//                print("✅ Pushed interview: \(interview.jobTitle) at \(interview.company?.name ?? "Unknown")")
            } catch {
                failureCount += 1
//                print("❌ Failed to push interview: \(interview.jobTitle) - \(error)")
            }
        }
        
        try modelContext.save()
        
//        print("📊 Push complete: \(successCount) succeeded, \(failureCount) failed")
        
        if failureCount > 0 {
            throw NSError(domain: "com.interviews", code: 500, userInfo: [
                NSLocalizedDescriptionKey: "Migration partially completed: \(successCount) succeeded, \(failureCount) failed"
            ])
        }
    }
}

#Preview("Guest Banner") {
    GuestModeBanner()
        .modelContainer(for: [Interview.self, Company.self], inMemory: true)
}

#Preview("Sign In") {
    SignInView()
}

#Preview("Migration") {
    MigrationView()
        .modelContainer(for: [Interview.self, Company.self], inMemory: true)
}

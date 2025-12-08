//
//  ContentView.swift
//  Interviews
//
//  Created by keloran on 05/12/2025.
//

import SwiftUI
import SwiftData
import Clerk

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var interviews: [Interview]

    @State private var showingSettings = false
    @State private var clerk = Clerk.shared
    @State private var hasPerformedInitialSync = false
    @State private var isSyncing = false
    @State private var isInitialLoad = true

    @State private var selectedDate: Date?
    @State private var searchText = ""
    @State private var showingSearch = false
    @State private var showingAddInterview = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Show guest mode banner if not authenticated
                GuestModeBanner()
                
                CalendarView(selectedDate: $selectedDate)
                    .frame(maxHeight: 400)

                Divider()

                InterviewListView(selectedDate: $selectedDate, searchText: searchText)
            }
            .navigationTitle("Interviews")
            .searchable(text: $searchText, isPresented: $showingSearch, prompt: "Search companies...")
            .overlay {
                // Full-screen loading overlay for initial sync
                if isInitialLoad && isSyncing {
                    ZStack {
                        Color(.systemBackground)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 24) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(Color.accentColor)
                            
                            VStack(spacing: 8) {
                                Text("Loading Your Interviews")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                Text("Syncing data from server...")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .transition(.opacity)
                }
                // Show small sync indicator in corner for subsequent syncs
                else if isSyncing {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Syncing...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.regularMaterial)
                            .cornerRadius(20)
                            .shadow(radius: 2)
                            .padding()
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(modelContext: modelContext)
            }
            .sheet(isPresented: $showingAddInterview) {
                AddInterviewView(initialDate: selectedDate ?? Date())
            }
            .environment(\.clerk, clerk)
            .onAppear {
                // Configure Clerk synchronously (this should be instant)
                clerk.configure(publishableKey: ClerkConfiguration.publishableKey)
                
                // Load Clerk and sync in the background
                Task {
                    try? await clerk.load()
                    await performInitialSyncIfNeeded()
                }
            }
            .onChange(of: clerk.user) { oldValue, newValue in
                // When user signs in, sync data
                if oldValue == nil && newValue != nil {
                    Task {
                        // User just signed in
                        if let session = clerk.session,
                           let token = try? await session.getToken() {
                            await APIService.shared.setAuthToken(token.jwt)
                            await performInitialSyncIfNeeded()
                        }
                    }
                } else if oldValue != nil && newValue == nil {
                    // User signed out
                    Task {
                        await APIService.shared.setAuthToken(nil)
                        hasPerformedInitialSync = false // Allow sync on next sign in
                    }
                }
            }
        }
    }
    
    private func performInitialSyncIfNeeded() async {
        // In guest mode (no user), just finish loading without syncing
        guard clerk.user != nil else {
            await MainActor.run {
                withAnimation {
                    isInitialLoad = false
                }
            }
            print("👋 Running in guest mode - no sync needed")
            return
        }
        
        // Only sync once per app launch and only if user is authenticated
        guard !hasPerformedInitialSync,
              let session = clerk.session else {
            // If no session, we're done loading
            await MainActor.run {
                withAnimation {
                    isInitialLoad = false
                }
            }
            return
        }
        
        hasPerformedInitialSync = true
        
        await MainActor.run {
            isSyncing = true
        }
        
        do {
            // Get the auth token and set it in APIService
            guard let token = try await session.getToken() else {
                print("Failed to get auth token")
                await MainActor.run {
                    withAnimation {
                        isSyncing = false
                        isInitialLoad = false
                    }
                }
                return
            }
            
            await APIService.shared.setAuthToken(token.jwt)
            
            // FIRST: Check if there are guest interviews to migrate
            let guestInterviews = try modelContext.fetch(FetchDescriptor<Interview>(
                predicate: #Predicate { interview in
                    interview.id == nil
                }
            ))
            
            if !guestInterviews.isEmpty {
                print("📤 Found \(guestInterviews.count) guest interview(s) - migrating to server first...")
                
                // Create sync service and push guest data
                let syncService = SyncService(modelContext: modelContext)
                
                for interview in guestInterviews {
                    do {
                        // Push the interview to the server
                        let apiInterview = try await syncService.pushInterview(interview)
                        
                        // Update the local interview with the server ID
                        interview.id = apiInterview.id
                        print("✅ Migrated guest interview: \(interview.jobTitle) at \(interview.company?.name ?? "Unknown")")
                    } catch {
                        print("❌ Failed to migrate interview: \(interview.jobTitle) - \(error)")
                    }
                }
                
                try modelContext.save()
                print("✅ Guest data migration complete")
            }
            
            // THEN: Sync all data from server (source of truth)
            let syncService = SyncService(modelContext: modelContext)
            await syncService.syncAll()
            
            // Clean up any duplicates that may have been created
            try? DatabaseCleanup.cleanupAll(context: modelContext)
            
            // Log summary
            let descriptor = FetchDescriptor<Interview>()
            if let allInterviews = try? modelContext.fetch(descriptor) {
                let withDates = allInterviews.filter { $0.displayDate != nil }
                print("✅ Sync complete: \(allInterviews.count) interviews (\(withDates.count) with scheduled dates)")
            } else {
                print("✅ Sync completed successfully")
            }
        } catch {
            print("Initial sync failed: \(error)")
        }
        
        await MainActor.run {
            withAnimation {
                isSyncing = false
                isInitialLoad = false
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Interview.self, Company.self, Stage.self, StageMethod.self,
        configurations: config
    )

    return ContentView()
        .modelContainer(container)
}

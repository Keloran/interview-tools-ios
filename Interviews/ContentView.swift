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

    @State private var selectedDate: Date?
    @State private var searchText = ""
    @State private var showingSearch = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CalendarView(selectedDate: $selectedDate)
                    .frame(maxHeight: 400)

                Divider()

                InterviewListView(selectedDate: $selectedDate, searchText: searchText)
            }
            .navigationTitle("Interviews")
            .searchable(text: $searchText, isPresented: $showingSearch, prompt: "Search companies...")
            .overlay {
                // Show sync indicator in the corner while syncing in background
                if isSyncing {
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
            .environment(\.clerk, clerk)
            .onAppear {
                // Configure Clerk synchronously (this should be instant)
                clerk.configure(publishableKey: ClerkConfiguration.publishableKey)
                
                // Load Clerk and sync in the background - fire and forget
                Task {
                    try? await clerk.load()
                    await performInitialSyncIfNeeded()
                }
            }
            .onChange(of: clerk.user) { oldValue, newValue in
                // Sync when user signs in (in background)
                if oldValue == nil && newValue != nil {
                    Task {
                        await performInitialSyncIfNeeded()
                    }
                }
            }
        }
    }
    
    private func performInitialSyncIfNeeded() async {
        // Only sync once per app launch and only if user is authenticated
        guard !hasPerformedInitialSync,
              let session = clerk.session else {
            return
        }
        
        hasPerformedInitialSync = true
        isSyncing = true
        
        do {
            // Get the auth token and set it in APIService
            guard let token = try await session.getToken() else {
                print("Failed to get auth token")
                isSyncing = false
                return
            }
            
            await APIService.shared.setAuthToken(token.jwt)
            
            // Create sync service and sync all data
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
        
        isSyncing = false
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

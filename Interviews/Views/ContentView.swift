//
//  ContentView.swift
//  Interviews
//
//  Created by keloran on 05/12/2025.
//

import SwiftUI
import SwiftData
import Clerk
import FlagsGG

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
    @State private var columnVisibility: NavigationSplitViewVisibility = .doubleColumn
    @State private var statsEnabled: Bool = false
    
    @Environment(\.flagsAgent) private var flagsAgent

    // MARK: - Subviews to reduce type-checking complexity
    @ViewBuilder
    private var iPadSidebar: some View {
        VStack(spacing: 0) {
            CalendarView(selectedDate: $selectedDate)
                .padding(.top)
            Divider()
                .padding(.vertical, 8)
            if statsEnabled {
                CompactStatsView()
                    .transition(.opacity)
            }
            Spacer()
        }
        .task {
            guard let client = flagsAgent else { return }
            let enabled = await client.is("stats").enabled()
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    statsEnabled = enabled
                }
            }
        }
    }

    @ViewBuilder
    private var iPadDetail: some View {
        NavigationStack {
            InterviewListView(selectedDate: $selectedDate, searchText: searchText)
                .navigationTitle("Interview Planner")
                .navigationBarTitleDisplayMode(.inline)
                .accessibilityIdentifier("interviewListView")
                .toolbar { iPadToolbar }
        }
    }

    @ToolbarContentBuilder
    private var iPadToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                showingSearch = true
            } label: {
                Label("Search", systemImage: "magnifyingglass")
            }
            .accessibilityIdentifier("searchButton")
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            if selectedDate != nil {
                Button {
                    showingAddInterview = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityIdentifier("addInterviewButton")
            }
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gear")
            }
        }
    }

    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    iPadSidebar
                } detail: {
                    iPadDetail
                }
                .navigationSplitViewStyle(.balanced)
            } else {
                NavigationStack {
                    VStack(spacing: 0) {
                        CalendarView(selectedDate: $selectedDate)
                            .frame(maxHeight: 300)
                        Divider()
                            .padding(.bottom, 8)
                        if statsEnabled {
                            CompactStatsView()
                                .padding(.bottom, 8)
                                .transition(.opacity)
                        }
                        InterviewListView(selectedDate: $selectedDate, searchText: searchText)
                    }
                    .navigationTitle("Interview Planner")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            if selectedDate != nil {
                                Button {
                                    showingAddInterview = true
                                } label: {
                                    Image(systemName: "plus")
                                }
                                .accessibilityIdentifier("addInterviewButton")
                            }
                            Button {
                                showingSettings = true
                            } label: {
                                Image(systemName: "gear")
                            }
                        }
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    FloatingSearchControl(isExpanded: $showingSearch, text: $searchText)
                        .padding(16)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityValue(selectedDate != nil ? "Date selected" : "No date selected")
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
        .sheet(isPresented: Binding(get: { UIDevice.current.userInterfaceIdiom == .pad && showingSearch }, set: { newValue in
            if UIDevice.current.userInterfaceIdiom == .pad {
                showingSearch = newValue
            }
        })) {
            NavigationStack {
                VStack {
                    TextField("Search companies...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .padding()
                    Spacer()
                }
                .navigationTitle("Search")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Cancel") {
                            searchText = ""
                            showingSearch = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(modelContext: modelContext)
        }
        .sheet(isPresented: $showingAddInterview) {
            // Capture the selected date at the moment the sheet is presented
            let dateToUse = selectedDate ?? Date()
            AddInterviewView(initialDate: dateToUse)
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
                    await MainActor.run {
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
        
        await MainActor.run {
            hasPerformedInitialSync = true
        }
        
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

private struct FloatingSearchControl: View {
    @Binding var isExpanded: Bool
    @Binding var text: String

    var body: some View {
        Group {
            if isExpanded {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search companies...", text: $text)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Button("Cancel") {
                        text = ""
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                            isExpanded = false
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.regularMaterial)
                .clipShape(Capsule())
                .shadow(radius: 3)
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .accessibilityIdentifier("searchFieldInline")
            } else {
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                        isExpanded = true
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .accessibilityIdentifier("searchButton")
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


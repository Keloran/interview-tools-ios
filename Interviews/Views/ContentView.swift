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
                .frame(maxHeight: 320)
                .padding(.top, 8)
                .padding(.bottom, 8)
//                .onChange(of: selectedDate) { oldValue, newValue in
//                    let oldStr = oldValue?.formatted(date: .abbreviated, time: .omitted) ?? "nil"
//                    let newStr = newValue?.formatted(date: .abbreviated, time: .omitted) ?? "nil"
//                }
            Divider()
                .padding(.vertical, 12)
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
                .overlay(alignment: .bottomTrailing) {
                    FloatingSearchControl(isExpanded: $showingSearch, text: $searchText)
                        .padding(16)
                }
                .foregroundStyle(.primary)
                .glassEffect()
        }
    }

    @ViewBuilder
    private var iPhoneMain: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CalendarView(selectedDate: $selectedDate)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .frame(maxHeight: 320)
                Divider()
                    .padding(.vertical, 12)
                InterviewListView(selectedDate: $selectedDate, searchText: searchText)
            }
            .navigationTitle("Interview Planner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { iPhoneToolbar }
            .foregroundStyle(.primary)
            .glassEffect()
        }
        .overlay(alignment: .bottomTrailing) {
            FloatingSearchControl(isExpanded: $showingSearch, text: $searchText)
                .padding(16)
        }
    }

    @ToolbarContentBuilder
    private var iPadToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            if selectedDate != nil {
                Button {
                    showingAddInterview = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(.primary)
                    
                }
                .accessibilityIdentifier("addInterviewButton")
            }
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gear")
                    .glassEffect()
            }
        }
    }
    
    @ToolbarContentBuilder
    private var iPhoneToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            if selectedDate != nil {
                Button {
                    showingAddInterview = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(.primary)
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
    
    @ViewBuilder
    private var syncOverlay: some View {
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

    var body: some View {
        mainScaffold
            .accessibilityElement(children: .contain)
            .accessibilityValue(selectedDate != nil ? "Date selected" : "No date selected")
            .overlay { syncOverlay }
            .sheet(isPresented: $showingSettings) { SettingsView(modelContext: modelContext) }
            .sheet(isPresented: $showingAddInterview) { AddInterviewSheet(selectedDate: selectedDate) }
            .onChange(of: showingAddInterview) { _, newValue in
                print("🪟 showingAddInterview changed -> \(newValue)")
            }
            .environment(\.clerk, clerk)
            .onAppear { configureClerkAndMaybeSync() }
            .onChange(of: clerk.user) { oldValue, newValue in
                handleClerkUserChange(oldValue: oldValue, newValue: newValue)
            }
    }

    @ViewBuilder
    private var mainScaffold: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                iPadSidebar
            } detail: {
                iPadDetail
            }
            .navigationSplitViewStyle(.balanced)
        } else {
            iPhoneMain
        }
    }

    private struct AddInterviewSheet: View {
        let selectedDate: Date?

        var body: some View {
            let dateToUse = selectedDate ?? Date()
            let formatted = dateToUse.formatted(date: .abbreviated, time: .omitted)

            return NavigationStack {
                AddInterviewView(initialDate: dateToUse)
                    .task {
                        // Keeping the debug print localized reduces inference in main body
                        print("🧾 Presenting AddInterviewView with initialDate=\(formatted). selectedDate was \(selectedDate?.formatted(date: .abbreviated, time: .omitted) ?? "nil")")
                    }
            }
        }
    }

    private func configureClerkAndMaybeSync() {
        clerk.configure(publishableKey: ClerkConfiguration.publishableKey)
        Task {
            try? await clerk.load()
            await performInitialSyncIfNeeded()
        }
    }

    private func handleClerkUserChange(oldValue: User?, newValue: User?) {
        if oldValue == nil && newValue != nil {
            Task {
                if let session = clerk.session,
                   let token = try? await session.getToken() {
                    await APIService.shared.setAuthToken(token.jwt)
                    await performInitialSyncIfNeeded()
                }
            }
        } else if oldValue != nil && newValue == nil {
            Task {
                await APIService.shared.setAuthToken(nil)
                await MainActor.run {
                    hasPerformedInitialSync = false
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
//            print("👋 Running in guest mode - no sync needed")
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
//                print("📤 Found \(guestInterviews.count) guest interview(s) - migrating to server first...")
                
                // Create sync service and push guest data
                let syncService = SyncService(modelContext: modelContext)
                
                for interview in guestInterviews {
                    do {
                        // Push the interview to the server
                        let apiInterview = try await syncService.pushInterview(interview)
                        
                        // Update the local interview with the server ID
                        interview.id = apiInterview.id
//                        print("✅ Migrated guest interview: \(interview.jobTitle) at \(interview.company?.name ?? "Unknown")")
                    } catch {
                        print("❌ Failed to migrate interview: \(interview.jobTitle) - \(error)")
                    }
                }
                
                try modelContext.save()
//                print("✅ Guest data migration complete")
            }
            
            // THEN: Sync all data from server (source of truth)
            let syncService = SyncService(modelContext: modelContext)
            await syncService.syncAll()
            
            // Clean up any duplicates that may have been created
            try? DatabaseCleanup.cleanupAll(context: modelContext)
            
            // Log summary
//            let descriptor = FetchDescriptor<Interview>()
//            if let allInterviews = try? modelContext.fetch(descriptor) {
//                let withDates = allInterviews.filter { $0.displayDate != nil }
//                print("✅ Sync complete: \(allInterviews.count) interviews (\(withDates.count) with scheduled dates)")
//            } else {
//                print("✅ Sync completed successfully")
//            }
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
                        .foregroundStyle(.primary)
                    TextField("Search companies...", text: $text)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .foregroundStyle(.primary)
                    Button("Cancel") {
                        text = ""
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                            isExpanded = false
                        }
                    }
                    .foregroundStyle(.primary)
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
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .accessibilityIdentifier("searchButton")
                .foregroundStyle(.primary)
                .glassEffect()
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


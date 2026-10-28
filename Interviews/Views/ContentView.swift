//
//  ContentView.swift
//  Interviews
//
//  Created by keloran on 05/12/2025.
//

import SwiftUI
import OSLog
import SwiftData
import ClerkKit
import FlagsGG

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext 
    @Query private var interviews: [Interview]

    @State private var showingSettings = false
    @Environment(Clerk.self) private var clerk: Clerk?
    @State private var hasPerformedInitialSync = false
    @State private var isSyncing = false
    @State private var isInitialLoad = true

    @State private var selectedDate: Date?

    @State private var searchText = ""
    @State private var showingSearch = false
    @State private var showingAddInterview = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .doubleColumn
    @State private var statsEnabled: Bool = false
    @State private var calendarHeight: CGFloat = 0
    @State private var guestInterviewCount = 0
    @State private var showingGuestImport = false
    
    @Environment(\.flagsAgent) private var flagsAgent

    // MARK: - Subviews to reduce type-checking complexity
    @ViewBuilder
    private var iPadSidebar: some View {
        VStack(spacing: 0) {
            CalendarView(selectedDate: $selectedDate)
                .frame(maxHeight: 320)
                .padding(.top, 8)
                .padding(.bottom, 8)
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
        }
    }

    @ViewBuilder
    private var iPhoneMain: some View {
        NavigationStack {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    // Calendar section
                    VStack(spacing: 0) {
                        CalendarView(selectedDate: $selectedDate)
                            .background(
                                GeometryReader { innerGeo in
                                    Color.clear
                                        .onAppear { calendarHeight = innerGeo.size.height }
                                        .onChange(of: innerGeo.size.height) { _, newValue in
                                            calendarHeight = newValue
                                        }
                                }
                            )
                            .padding(.top, 8)
                            .padding(.bottom, 8)
                        Divider()
                            .padding(.vertical, 12)
                    }
                    .accessibilityIdentifier("calendarSection")

                    // List section takes remaining space and scrolls
                    InterviewListView(selectedDate: $selectedDate, searchText: searchText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .accessibilityIdentifier("listSection")
                }
                .foregroundStyle(.primary)
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .navigationTitle("Interview Planner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { iPhoneToolbar }
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
                    .glassEffect()
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
            .onAppear { Task { await performInitialSyncIfNeeded() } }
            .alert("Add your guest interviews?", isPresented: $showingGuestImport) {
                Button("Add to this account") {
                    Task { await importGuestInterviews() }
                }
                Button("Not now", role: .cancel) { }
            } message: {
                Text("You added \(guestInterviewCount) interview(s) before signing in. Add them to this account? If you don't, they stay in guest mode on this phone.")
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
            NavigationStack {
                AddInterviewView(initialDate: selectedDate ?? Date())
            }
        }
    }

    private func performInitialSyncIfNeeded() async {
        // In guest mode (no user), just finish loading without syncing
        guard clerk?.user != nil else {
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
              clerk?.session != nil else {
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
            // syncAll sends this account's unsent changes first, then pulls
            let syncService = SyncService(modelContext: modelContext)
            await syncService.syncAll()
            
            // Clean up any duplicates that may have been created
            try? DatabaseCleanup.cleanupAll(context: modelContext)
            await DebriefReminders.schedule(interviews)

            // Guest-mode interviews only join the account if the person says so
            guestInterviewCount = AccountStore.guestInterviewCount()
            showingGuestImport = guestInterviewCount > 0
            
            // Log summary
//            let descriptor = FetchDescriptor<Interview>()
//            if let allInterviews = try? modelContext.fetch(descriptor) {
//                let withDates = allInterviews.filter { $0.displayDate != nil }
//                print("✅ Sync complete: \(allInterviews.count) interviews (\(withDates.count) with scheduled dates)")
//            } else {
//                print("✅ Sync completed successfully")
//            }
        } catch {
            appLog.error("Initial sync failed: \(String(describing: error))")
        }
        
        await MainActor.run {
            withAnimation {
                isSyncing = false
                isInitialLoad = false
            }
        }
    }

    private func importGuestInterviews() async {
        let syncService = SyncService(modelContext: modelContext)
        let failed = await AccountStore.importGuestInterviews(using: syncService)
        await syncService.syncAll()
        if failed > 0 {
            appLog.error("❌ \(failed) guest interview(s) couldn't be added; they're still in guest mode")
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


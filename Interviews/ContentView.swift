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
                if isSyncing {
                    VStack {
                        ProgressView()
                        Text("Syncing interviews...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(12)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSearch.toggle()
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }
                
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
            .task {
                // Let Clerk use the default redirect URL (bundle ID based)
                // This will use: tools.interviews.Interviews://callback
                clerk.configure(publishableKey: ClerkConfiguration.publishableKey)
                try? await clerk.load()
                
                // Perform initial sync if user is authenticated
                await performInitialSyncIfNeeded()
            }
            .onChange(of: clerk.user) { oldValue, newValue in
                // Sync when user signs in
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

struct InterviewDetailView: View {
    let interview: Interview

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Job Title (Always shown)
                Text(interview.jobTitle)
                    .font(.title)
                    .fontWeight(.bold)

                // Company (Always shown, with fallback)
                if let company = interview.company {
                    Label(company.name, systemImage: "building.2")
                        .font(.headline)
                } else {
                    Label("No company information", systemImage: "building.2")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                if let clientCompany = interview.clientCompany {
                    Label("Client: \(clientCompany)", systemImage: "briefcase")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // Interview Details Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Interview Details")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if let stage = interview.stage {
                        HStack {
                            Text("Stage:")
                                .foregroundStyle(.secondary)
                            Text(stage.stage)
                                .fontWeight(.medium)
                        }
                    } else {
                        HStack {
                            Text("Stage:")
                                .foregroundStyle(.secondary)
                            Text("Not specified")
                                .foregroundStyle(.tertiary)
                        }
                    }

                    if let method = interview.stageMethod {
                        HStack {
                            Text("Method:")
                                .foregroundStyle(.secondary)
                            Text(method.method)
                                .fontWeight(.medium)
                        }
                    } else {
                        HStack {
                            Text("Method:")
                                .foregroundStyle(.secondary)
                            Text("Not specified")
                                .foregroundStyle(.tertiary)
                        }
                    }

                    if let outcome = interview.outcome {
                        HStack {
                            Text("Outcome:")
                                .foregroundStyle(.secondary)
                            Text(outcome.displayName)
                                .fontWeight(.medium)
                                .foregroundStyle(colorForOutcome(outcome))
                        }
                    } else {
                        HStack {
                            Text("Outcome:")
                                .foregroundStyle(.secondary)
                            Text("Pending")
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                Divider()

                // Dates Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Important Dates")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Label(
                        "Applied: \(interview.applicationDate.formatted(date: .long, time: .omitted))",
                        systemImage: "calendar.badge.plus"
                    )
                    .font(.subheadline)

                    if let date = interview.date {
                        Label(
                            "Interview: \(date.formatted(date: .long, time: .shortened))",
                            systemImage: "calendar"
                        )
                        .font(.subheadline)
                    } else {
                        Label(
                            "Interview: Not scheduled",
                            systemImage: "calendar"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                    }

                    if let deadline = interview.deadline {
                        Label(
                            "Deadline: \(deadline.formatted(date: .long, time: .omitted))",
                            systemImage: "clock"
                        )
                        .font(.subheadline)
                    }
                }

                // Additional Information (only show if present)
                if interview.interviewer != nil || interview.link != nil || interview.notes != nil {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Additional Information")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        if let interviewer = interview.interviewer {
                            Label(interviewer, systemImage: "person")
                                .font(.subheadline)
                        }

                        if let link = interview.link {
                            Link(destination: URL(string: link) ?? URL(string: "https://")!) {
                                Label("Join Meeting", systemImage: "video")
                                    .font(.subheadline)
                            }
                        }

                        if let notes = interview.notes {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Notes", systemImage: "note.text")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(notes)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 4)
                            }
                        }
                    }
                } else {
                    Divider()
                    
                    ContentUnavailableView(
                        "No Additional Details",
                        systemImage: "info.circle",
                        description: Text("Add notes, interviewer name, or meeting link for this interview")
                    )
                    .padding(.vertical)
                }
                
                Spacer(minLength: 20)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private func colorForOutcome(_ outcome: InterviewOutcome) -> Color {
        switch outcome {
        case .scheduled: return .blue
        case .passed: return .green
        case .rejected: return .red
        case .awaitingResponse: return .yellow
        case .offerReceived: return .purple
        case .offerAccepted: return .green
        case .offerDeclined: return .orange
        case .withdrew: return .gray
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

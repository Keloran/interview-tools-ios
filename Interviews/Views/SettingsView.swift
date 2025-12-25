//
//  SettingsView.swift
//  Interviews
//
//  Created by keloran on 06/12/2025.
//

import SwiftUI
import SwiftData
import Clerk
import FlagsSwift

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.clerk) private var clerk

    @StateObject private var syncService: SyncService

    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var authIsPresented = false
    
    @State private var statsEnabled: Bool = false

    init(modelContext: ModelContext) {
        _syncService = StateObject(wrappedValue: SyncService(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            Form {
                authSection
                if statsEnabled {
                    statsSection
                }
                syncSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                do {
                    let client = try Client.builder().withAuth(Auth(
                        projectId: "198ba0bd-e7e1-4219-beee-9bd82de0e03c",
                        agentId: "8b98066c-9017-460f-8c0f-beb92392eb14",
                        environmentId: "07a3b112-3bdc-4b1f-a096-ae2bdf21ad67"
                    )).build()
                    let enabled = await client.is("stats").enabled()
                    statsEnabled = enabled
                } catch {
                    // If fetching the flag fails, default to false and optionally log
                    statsEnabled = false
                    #if DEBUG
                    print("Failed to fetch stats flag: \(error)")
                    #endif
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    @ViewBuilder
    private var authSection: some View {
        if clerk.user != nil {
            Section("Authentication") {
                HStack {
                    UserButton()
                        .frame(width: 36, height: 36)
                    
                    Text(clerk.user?.username ?? "Interviews")
                }
                .sheet(isPresented: $authIsPresented) {
                    AuthView()
                }
                .onChange(of: clerk.user) { oldValue, newValue in
                    handleAuthChange(oldValue: oldValue, newValue: newValue)
                }
            }
        }
    }

    private var syncSection: some View {
        Section("Sync") {
            if syncService.isSyncing {
                HStack {
                    ProgressView()
                        .progressViewStyle(.circular)
                    Text("Syncing...")
                        .foregroundStyle(.secondary)
                }
            } else {
                syncButton
                debugInfoButton
                lastSyncText
                syncErrorText
            }
        }
    }

    @ViewBuilder
    private var syncButton: some View {
        if clerk.user != nil {
            Button("Sync Now") {
                Task {
                    await performSync()
                }
            }
        }
    }
    
    private var debugInfoButton: some View {
        Button("Show Database Info") {
            Task {
                await showDatabaseInfo()
            }
        }
    }

    @ViewBuilder
    private var lastSyncText: some View {
        if let lastSync = syncService.lastSyncDate {
            Text("Last synced: \(lastSync.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var syncErrorText: some View {
        if let error = syncService.syncError {
            Text("Error: \(error.localizedDescription)")
                .font(.caption)
                .foregroundStyle(.red)
        }
    }

    private var aboutSection: some View {
        Section("About") {
            Link(destination: URL(string: "https://interviews.tools")!) {
                HStack {
                    Text("Visit interviews.tools")
                    Spacer()
                    Image(systemName: "arrow.up.forward")
                }
            }
        }
    }
    
    private var statsSection: some View {
        Section {
            NavigationLink {
                StatsView()
                    .navigationTitle("Statistics")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(.blue)
                    Text("View Statistics")
                }
            }
        } header: {
            Text("Statistics")
        } footer: {
            Text("View detailed statistics about your interview applications")
        }
    }

    private func handleAuthChange(oldValue: User?, newValue: User?) {
        if oldValue == nil && newValue != nil {
            authIsPresented = false
            Task {
                await performSync()
            }
        }
    }

    private func performSync() async {
        if let session = clerk.session,
           let token = try? await session.getToken() {
            await APIService.shared.setAuthToken(token.jwt)
            await syncService.syncAll()
            
            // Automatically clean up duplicates after sync
            try? DatabaseCleanup.cleanupAll(context: modelContext)
        }
    }
    
    private func showDatabaseInfo() async {
        do {
            let stages = try modelContext.fetch(FetchDescriptor<Stage>())
            let methods = try modelContext.fetch(FetchDescriptor<StageMethod>())
            let companies = try modelContext.fetch(FetchDescriptor<Company>())
            let interviews = try modelContext.fetch(FetchDescriptor<Interview>())
            
            var info = """
            📊 Database Contents:
            
            Stages (\(stages.count)):
            """
            
            // Group stages by name
            let stageGroups = Dictionary(grouping: stages, by: { $0.stage })
            for (name, group) in stageGroups.sorted(by: { $0.key < $1.key }) {
                info += "\n  • \(name): \(group.count) item(s)"
                if group.count > 1 {
                    info += " ⚠️ DUPLICATE"
                }
            }
            
            info += "\n\nStage Methods (\(methods.count)):"
            let methodGroups = Dictionary(grouping: methods, by: { $0.method })
            for (name, group) in methodGroups.sorted(by: { $0.key < $1.key }) {
                info += "\n  • \(name): \(group.count) item(s)"
                if group.count > 1 {
                    info += " ⚠️ DUPLICATE"
                }
            }
            
            info += "\n\nCompanies: \(companies.count)"
            info += "\nInterviews: \(interviews.count)"
            
            print(info)
            
            errorMessage = info
            showingError = true
        } catch {
            errorMessage = "Failed to fetch database info: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Interview.self, Company.self, Stage.self, StageMethod.self,
        configurations: config
    )

    return SettingsView(modelContext: container.mainContext)
}


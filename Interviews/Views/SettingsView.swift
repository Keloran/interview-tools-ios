//
//  SettingsView.swift
//  Interviews
//
//  Created by keloran on 06/12/2025.
//

import SwiftUI
import OSLog
import SwiftData
import ClerkKit
import ClerkKitUI
import FlagsGG

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(Clerk.self) private var clerk: Clerk?
    @Environment(\.flagsAgent) private var flagsAgent

    @StateObject private var syncService: SyncService

    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var authIsPresented = false
    
    @State private var statsEnabled: Bool = false

    @State private var exportFile: ExportFile?
    @State private var isExporting = false
    @State private var showingDeleteConfirm = false
    @State private var deleteConfirmText = ""
    @State private var isDeleting = false

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
                jobSearchSection
                yourDataSection
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
                guard let client = flagsAgent else { return }
                let enabled = await client.is("stats").enabled()
                statsEnabled = enabled
            }
            .sheet(item: $exportFile) { file in
                ShareSheet(items: [file.url])
            }
            .alert("Delete your account?", isPresented: $showingDeleteConfirm) {
                TextField(APIService.deleteConfirmation, text: $deleteConfirmText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Delete", role: .destructive) {
                    Task { await deleteAccount() }
                }
                .disabled(!deleteConfirmed)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This permanently deletes your interviews.tools account and everything in it: applications, interviews, notes, stories and availability links. Export your data first if you want a copy. Anything you added before signing in stays on this phone.\n\nType \"\(APIService.deleteConfirmation)\" to confirm.")
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
        if clerk?.user != nil {
            Section("Authentication") {
                HStack {
                    UserButton()
                        .frame(width: 36, height: 36)
                    
                    Text(clerk?.user?.username ?? "Interviews")
                }
                .sheet(isPresented: $authIsPresented) {
                    AuthView()
                }
                .onChange(of: clerk?.user) { oldValue, newValue in
                    handleAuthChange(oldValue: oldValue, newValue: newValue)
                }
            }
        } else {
            Section("Authentication") {
                Button("Sign in") {
                    authIsPresented = true
                }
                .foregroundStyle(.primary)
                .sheet(isPresented: $authIsPresented) {
                    AuthView()
                }
            }
        }
    }

    @ViewBuilder
    private var syncSection: some View {
        if clerk?.user != nil {
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
    }

    @ViewBuilder
    private var syncButton: some View {
        if clerk?.user != nil {
            Button("Sync Now") {
                Task {
                    await performSync()
                }
            }
            .foregroundStyle(.primary)
        }
    }
    
    private var debugInfoButton: some View {
        Button("Show Database Info") {
            Task {
                await showDatabaseInfo()
            }
        }
        .foregroundStyle(.primary)
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

    /// Screens for the parts of the job search that live on interviews.tools
    @ViewBuilder
    private var jobSearchSection: some View {
        if clerk?.user != nil {
            Section("Your job search") {
                NavigationLink {
                    FollowUpsView()
                } label: {
                    Label("Follow-ups", systemImage: "arrow.uturn.forward.circle")
                }
                NavigationLink {
                    NoResponseView()
                } label: {
                    Label("No response", systemImage: "questionmark.circle")
                }
                NavigationLink {
                    OffersView()
                } label: {
                    Label("Offers", systemImage: "envelope.open")
                }
                NavigationLink {
                    QuestionsView()
                } label: {
                    Label("Questions asked", systemImage: "questionmark.bubble")
                }
                NavigationLink {
                    StoriesView()
                } label: {
                    Label("STAR stories", systemImage: "text.book.closed")
                }
            }
        }
    }

    @ViewBuilder
    private var yourDataSection: some View {
        if clerk?.user != nil {
            Section {
                Button("Export applications (CSV)") {
                    Task { await export("applications") }
                }
                .disabled(isExporting || isDeleting)
                Button("Export STAR stories (CSV)") {
                    Task { await export("stories") }
                }
                .disabled(isExporting || isDeleting)
                if isDeleting {
                    HStack {
                        ProgressView()
                        Text("Deleting your account...")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button("Delete account", role: .destructive) {
                        deleteConfirmText = ""
                        showingDeleteConfirm = true
                    }
                }
            } header: {
                Text("Your data")
            } footer: {
                Text("Deleting your account removes it and all its data from interviews.tools. It can't be undone.")
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            Link(destination: URL(string: "https://interviews.tools")!) {
                HStack {
                    Text("Visit interviews.tools")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.forward")
                        .foregroundStyle(.primary)
                }
                .foregroundStyle(.primary)
            }
            .foregroundStyle(.primary)
            
            HStack {
                Text("Version")
                Spacer()
                Text(appVersionString)
                    .foregroundStyle(.secondary)
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
        if clerk?.session != nil {
            await syncService.syncAll()
            
            // Automatically clean up duplicates after sync
            try? DatabaseCleanup.cleanupAll(context: modelContext)
        }
    }
    
    private var deleteConfirmed: Bool {
        deleteConfirmText.trimmingCharacters(in: .whitespaces).lowercased() == APIService.deleteConfirmation
    }

    private func authorize() async throws {
        guard clerk?.session != nil else { throw APIError.unauthorized }
    }

    private func export(_ kind: String) async {
        isExporting = true
        defer { isExporting = false }
        do {
            try await authorize()
            let data = try await APIService.shared.exportData(kind: kind)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("interview-tools-\(kind).csv")
            try data.write(to: url, options: .atomic)
            exportFile = ExportFile(url: url)
        } catch {
            errorMessage = "Couldn't export your data: \(error.localizedDescription)"
            showingError = true
        }
    }

    private func deleteAccount() async {
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await authorize()
            try await APIService.shared.deleteAccount()
        } catch {
            // Nothing local is touched unless the server confirms; its message says which part failed, and retrying is safe
            errorMessage = error.localizedDescription
            showingError = true
            return
        }
        do {
            try DatabaseCleanup.removeSyncedData(context: modelContext)
        } catch {
            errorMessage = "Your account is deleted, but this phone's copy couldn't be cleared: \(error.localizedDescription)"
            showingError = true
        }
        // The login no longer exists on the server, so a failed sign-out just means the local session is already gone
        try? await clerk?.auth.signOut()
        if !showingError { dismiss() }
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
            
            appLog.notice("\(info)")
            
            errorMessage = info
            showingError = true
        } catch {
            errorMessage = "Failed to fetch database info: \(error.localizedDescription)"
            showingError = true
        }
    }
}

struct ExportFile: Identifiable {
    let url: URL
    var id: URL { url }
}

/// The system share sheet, so an export can be saved to Files, emailed or AirDropped
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

private extension SettingsView {
    var appVersionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        return build.isEmpty ? version : "\(version) (\(build))"
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


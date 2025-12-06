//
//  SettingsView.swift
//  Interviews
//
//  Created by keloran on 06/12/2025.
//

import SwiftUI
import SwiftData
import Clerk

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.clerk) private var clerk

    @StateObject private var syncService: SyncService

    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var authIsPresented = false

    init(modelContext: ModelContext) {
        _syncService = StateObject(wrappedValue: SyncService(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            Form {
                authSection
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
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var authSection: some View {
        Section("Authentication") {
            VStack {
                if clerk.user != nil {
                    UserButton()
                        .frame(width: 36, height: 36)
                } else {
                    Button("Sign in") {
                        authIsPresented = true
                    }
                }
            }
            .sheet(isPresented: $authIsPresented) {
                AuthView()
            }
            .onChange(of: clerk.user) { oldValue, newValue in
                handleAuthChange(oldValue: oldValue, newValue: newValue)
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
                lastSyncText
                syncErrorText
            }
        }
    }

    private var syncButton: some View {
        Button("Sync Now") {
            Task {
                await performSync()
            }
        }
        .disabled(clerk.user == nil)
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

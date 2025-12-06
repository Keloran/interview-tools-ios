//
//  SettingsView.swift
//  Interviews
//
//  Created by keloran on 06/12/2025.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var syncService: SyncService

    @State private var tokenInput = ""
    @State private var showingTokenInfo = false

    init(modelContext: ModelContext) {
        _syncService = StateObject(wrappedValue: SyncService(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Authentication") {
                    if authManager.isAuthenticated {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Connected to interviews.tools")
                        }

                        Button("Sign Out", role: .destructive) {
                            authManager.signOut()
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Connect to interviews.tools")
                                .font(.headline)

                            Text("Enter your API token to sync with interviews.tools")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            SecureField("API Token", text: $tokenInput)
                                .textContentType(.password)
                                .autocapitalization(.none)

                            Button("Connect") {
                                authManager.setToken(tokenInput)
                                tokenInput = ""
                            }
                            .disabled(tokenInput.isEmpty)

                            Button("How do I get a token?") {
                                showingTokenInfo = true
                            }
                            .font(.caption)
                        }
                    }
                }

                if authManager.isAuthenticated {
                    Section("Sync") {
                        if let lastSync = syncService.lastSyncDate {
                            HStack {
                                Text("Last synced")
                                Spacer()
                                Text(lastSync, style: .relative)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Button {
                            Task {
                                await syncService.syncAll()
                            }
                        } label: {
                            HStack {
                                if syncService.isSyncing {
                                    ProgressView()
                                        .padding(.trailing, 4)
                                }
                                Text(syncService.isSyncing ? "Syncing..." : "Sync Now")
                            }
                        }
                        .disabled(syncService.isSyncing)

                        if let error = syncService.syncError {
                            Text(error.localizedDescription)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }

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
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingTokenInfo) {
                TokenInfoView()
            }
        }
    }
}

struct TokenInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Getting Your API Token")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("To connect this app with interviews.tools, you'll need an API token from your account.")

                    VStack(alignment: .leading, spacing: 8) {
                        Label("1. Visit interviews.tools", systemImage: "1.circle.fill")
                        Label("2. Sign in to your account", systemImage: "2.circle.fill")
                        Label("3. Go to Settings", systemImage: "3.circle.fill")
                        Label("4. Find your API token", systemImage: "4.circle.fill")
                        Label("5. Copy and paste it here", systemImage: "5.circle.fill")
                    }
                    .font(.subheadline)

                    Divider()

                    Text("Note: API token support is coming soon to interviews.tools. For now, the app works in offline mode with local data storage.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding()
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding()
            }
            .navigationTitle("API Token Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
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

    return SettingsView(modelContext: container.mainContext)
}

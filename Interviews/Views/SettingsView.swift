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

    @State private var showingError = false
    @State private var errorMessage = ""

    init(modelContext: ModelContext) {
        _syncService = StateObject(wrappedValue: SyncService(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Authentication") {
                    if authManager.isAuthenticated {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Signed In")
                            }

                            if let email = authManager.userEmail {
                                Text(email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Button("Sign Out", role: .destructive) {
                            Task {
                                await authManager.signOut()
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Sign in to sync with interviews.tools")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Button {
                                Task {
                                    do {
                                        try await authManager.signIn()
                                        // Trigger initial sync after sign-in
                                        await syncService.syncAll()
                                    } catch {
                                        errorMessage = error.localizedDescription
                                        showingError = true
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                    Text("Sign In with Clerk")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
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
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
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

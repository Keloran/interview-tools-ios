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
                          // Dismiss auth sheet when user successfully signs in
                          if newValue != nil {
                              authIsPresented = false
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

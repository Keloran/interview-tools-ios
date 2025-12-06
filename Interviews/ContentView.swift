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

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CalendarView()
                    .frame(maxHeight: 400)

                Divider()

                InterviewListView()
            }
            .navigationTitle("Interviews")
            .toolbar {
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
            }
        }
    }
}

struct InterviewDetailView: View {
    let interview: Interview

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(interview.jobTitle)
                    .font(.title)
                    .fontWeight(.bold)

                if let company = interview.company {
                    Label(company.name, systemImage: "building.2")
                        .font(.headline)
                }

                if let clientCompany = interview.clientCompany {
                    Label("Client: \(clientCompany)", systemImage: "briefcase")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    if let stage = interview.stage {
                        HStack {
                            Text("Stage:")
                                .foregroundStyle(.secondary)
                            Text(stage.stage)
                                .fontWeight(.medium)
                        }
                    }

                    if let method = interview.stageMethod {
                        HStack {
                            Text("Method:")
                                .foregroundStyle(.secondary)
                            Text(method.method)
                                .fontWeight(.medium)
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
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Label(
                        interview.applicationDate.formatted(date: .long, time: .omitted),
                        systemImage: "calendar.badge.plus"
                    )
                    .font(.subheadline)

                    if let date = interview.date {
                        Label(
                            date.formatted(date: .long, time: .shortened),
                            systemImage: "calendar"
                        )
                        .font(.subheadline)
                    }

                    if let deadline = interview.deadline {
                        Label(
                            "Deadline: \(deadline.formatted(date: .long, time: .omitted))",
                            systemImage: "clock"
                        )
                        .font(.subheadline)
                    }
                }

                if let interviewer = interview.interviewer {
                    Divider()
                    Label(interviewer, systemImage: "person")
                        .font(.subheadline)
                }

                if let link = interview.link {
                    Divider()
                    Link(destination: URL(string: link) ?? URL(string: "https://")!) {
                        Label("Join Meeting", systemImage: "video")
                            .font(.subheadline)
                    }
                }

                if let notes = interview.notes {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.headline)
                        Text(notes)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
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

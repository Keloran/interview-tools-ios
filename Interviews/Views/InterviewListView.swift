//
//  InterviewListView.swift
//  Interviews
//
//  Created by keloran on 05/12/2025.
//

import SwiftUI
import SwiftData

struct InterviewListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var interviews: [Interview]

    @State private var selectedInterview: Interview?
    @State private var showingDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Upcoming Interviews")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)

            if sortedInterviews.isEmpty {
                ContentUnavailableView(
                    "No Interviews Scheduled",
                    systemImage: "calendar",
                    description: Text("Click the + button on a date to add an interview")
                )
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(sortedInterviews, id: \.id) { interview in
                            InterviewListRow(interview: interview)
                                .onTapGesture {
                                    selectedInterview = interview
                                    showingDetail = true
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .sheet(isPresented: $showingDetail) {
            if let interview = selectedInterview {
                NavigationStack {
                    InterviewDetailSheet(interview: interview)
                        .navigationTitle(interview.jobTitle)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    showingDetail = false
                                }
                            }
                        }
                }
            }
        }
    }

    private var sortedInterviews: [Interview] {
        interviews
            .filter { $0.displayDate != nil }
            .sorted { ($0.displayDate ?? Date()) < ($1.displayDate ?? Date()) }
    }
}

struct InterviewListRow: View {
    let interview: Interview

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Outcome indicator
            Circle()
                .fill(outcomeColor)
                .frame(width: 12, height: 12)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 8) {
                // Title and company
                VStack(alignment: .leading, spacing: 2) {
                    Text(interview.jobTitle)
                        .font(.headline)

                    HStack {
                        if let company = interview.company {
                            Text(company.name)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        if let clientCompany = interview.clientCompany {
                            Text("(for \(clientCompany))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Date
                if let date = interview.displayDate {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Stage and method badges
                HStack(spacing: 8) {
                    if let stage = interview.stage {
                        Text(stage.stage)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(4)
                    }

                    if let method = interview.stageMethod {
                        Text(method.method)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separator), lineWidth: 1)
        )
    }

    private var outcomeColor: Color {
        guard let outcome = interview.outcome else { return .blue }

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

struct InterviewDetailSheet: View {
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
    InterviewListView()
        .modelContainer(for: [Interview.self, Company.self, Stage.self, StageMethod.self], inMemory: true)
}

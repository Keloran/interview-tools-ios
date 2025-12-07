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
    
    @Binding var selectedDate: Date?
    var searchText: String

    @State private var selectedInterview: Interview?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(headerTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if selectedDate != nil {
                    Button(action: { selectedDate = nil }) {
                        Text("Clear")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .padding(.horizontal)

            if sortedInterviews.isEmpty {
                ContentUnavailableView(
                    emptyStateTitle,
                    systemImage: "calendar",
                    description: Text(emptyStateDescription)
                )
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(sortedInterviews, id: \.id) { interview in
                            InterviewListRow(interview: interview)
                                .onTapGesture {
                                    selectedInterview = interview
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .sheet(item: $selectedInterview) { interview in
            NavigationStack {
                InterviewDetailSheet(interview: interview)
                    .navigationTitle(interview.jobTitle)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                selectedInterview = nil
                            }
                        }
                    }
            }
        }
    }
    
    private var headerTitle: String {
        if !searchText.isEmpty {
            return "Search Results"
        } else if selectedDate != nil {
            return "Interviews on \(selectedDate!.formatted(date: .abbreviated, time: .omitted))"
        } else {
            return "Upcoming Interviews"
        }
    }
    
    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "No Companies Found"
        } else if selectedDate != nil {
            return "No Interviews This Day"
        } else {
            return "No Interviews Scheduled"
        }
    }
    
    private var emptyStateDescription: String {
        if !searchText.isEmpty {
            return "No interviews found with companies matching '\(searchText)'"
        } else if selectedDate != nil {
            return "Click the + button on the calendar to add an interview for this date"
        } else {
            return "Click the + button on a date to add an interview"
        }
    }

    private var sortedInterviews: [Interview] {
        let now = Date()
        let calendar = Calendar.current
        
        var filtered = interviews
        
        // If searching, show ALL interviews (ignore date filters)
        if !searchText.isEmpty {
            filtered = filtered.filter { interview in
                if let companyName = interview.company?.name {
                    return companyName.localizedCaseInsensitiveContains(searchText)
                }
                return false
            }
            // Sort by date (most recent first) when searching
            return filtered.sorted { ($0.displayDate ?? Date.distantPast) > ($1.displayDate ?? Date.distantPast) }
        }
        
        // If a date is selected, show interviews for that date only
        if let selectedDate = selectedDate {
            filtered = filtered.filter { interview in
                guard let displayDate = interview.displayDate else { return false }
                return calendar.isDate(displayDate, inSameDayAs: selectedDate)
            }
            // Sort by time
            return filtered.sorted { ($0.displayDate ?? Date()) < ($1.displayDate ?? Date()) }
        }
        
        // Default: Show only future interviews
        filtered = filtered.filter {
            guard let displayDate = $0.displayDate else { return false }
            return displayDate >= now
        }
        return filtered.sorted { ($0.displayDate ?? Date()) < ($1.displayDate ?? Date()) }
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
    InterviewListView(selectedDate: .constant(nil), searchText: "")
        .modelContainer(for: [Interview.self, Company.self, Stage.self, StageMethod.self], inMemory: true)
}

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
    @State private var interviewForNextStage: Interview?

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
                    .accessibilityIdentifier("clearDateButton")
                    .accessibilityLabel("Clear date selection")
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
                List {
                    ForEach(sortedInterviews, id: \.persistentModelID) { interview in
                        InterviewListRow(interview: interview)
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    interviewForNextStage = interview
                                } label: {
                                    Label("Next Stage", systemImage: "arrow.right.circle")
                                }
                                .tint(.green)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                // Only show reject if not already rejected
                                if interview.outcome != .rejected {
                                    Button(role: .destructive) {
                                        rejectInterview(interview)
                                    } label: {
                                        Label("Reject", systemImage: "xmark.circle")
                                    }
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                            .listRowSeparator(.hidden)
                            .onTapGesture {
                                selectedInterview = interview
                            }
                    }
                }
                .listStyle(.inset)
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
        .sheet(item: $interviewForNextStage) { interview in
            CreateNextStageView(interview: interview)
        }
    }
    
    private func rejectInterview(_ interview: Interview) {
        interview.outcome = .rejected
        interview.updatedAt = Date()
        try? modelContext.save()
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
            return "Choose a date and click the + to add a new Interview"
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
            return filtered.sorted { ($0.displayDate ?? $0.applicationDate) > ($1.displayDate ?? $1.applicationDate) }
        }
        
        // If a date is selected, show interviews for that date only
        if let selectedDate = selectedDate {
            filtered = filtered.filter { interview in
                // Check displayDate first, fallback to applicationDate
                let dateToCheck = interview.displayDate ?? interview.applicationDate
                return calendar.isDate(dateToCheck, inSameDayAs: selectedDate)
            }
            // Sort by time
            return filtered.sorted { 
                let date1 = $0.displayDate ?? $0.applicationDate
                let date2 = $1.displayDate ?? $1.applicationDate
                return date1 < date2
            }
        }
        
        // Default: Show only today and future interviews
        let startOfToday = calendar.startOfDay(for: now)
        filtered = filtered.filter { interview in
            let dateToCheck = interview.displayDate ?? interview.applicationDate
            return dateToCheck >= startOfToday
        }
        
        // Sort by date (earliest first)
        return filtered.sorted { interview1, interview2 in
            let date1 = interview1.displayDate ?? interview1.applicationDate
            let date2 = interview2.displayDate ?? interview2.applicationDate
            return date1 < date2
        }
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
        // If no outcome is set and stage is "Applied", show as awaiting response
        if interview.outcome == nil && interview.stage?.stage == "Applied" {
            return .yellow
        }
        
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
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditSheet = false
    @State private var showingOutcomeOptions = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
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

                    HStack {
                        Text("Outcome:")
                            .foregroundStyle(.secondary)
                        if let outcome = interview.outcome {
                            Text(outcome.displayName)
                                .fontWeight(.medium)
                                .foregroundStyle(colorForOutcome(outcome))
                        } else if interview.stage?.stage == "Applied" {
                            // All "Applied" interviews are awaiting response
                            Text("Awaiting Response")
                                .fontWeight(.medium)
                                .foregroundStyle(.yellow)
                        } else {
                            Text("Pending")
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        
                        // Add "Awaiting Outcome" button if interview is in the past and no outcome is set
                        if shouldShowAwaitingOutcomeButton {
                            Button {
                                showingOutcomeOptions = true
                            } label: {
                                Text("Set Outcome")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue)
                                    .foregroundStyle(.white)
                                    .cornerRadius(6)
                            }
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
                if interview.interviewer != nil || interview.link != nil || interview.jobListing != nil || interview.notes != nil {
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
                                Label("Join Interview", systemImage: "video")
                                    .font(.subheadline)
                            }
                        }
                        
                        if let jobPostingLink = interview.jobListing {
                            Link(destination: URL(string: jobPostingLink) ?? URL(string: "https://")!) {
                                Label("View Job Posting", systemImage: "doc.text")
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
                }
                
                Spacer(minLength: 20)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEditSheet = true
                } label: {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditInterviewView(interview: interview)
        }
        .confirmationDialog("Set Interview Outcome", isPresented: $showingOutcomeOptions, titleVisibility: .visible) {
            Button("Awaiting Response") {
                setOutcome(.awaitingResponse)
            }
            Button("Passed") {
                setOutcome(.passed)
            }
            Button("Rejected") {
                setOutcome(.rejected)
            }
            Button("Offer Received") {
                setOutcome(.offerReceived)
            }
            Button("Withdrew") {
                setOutcome(.withdrew)
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    private var shouldShowAwaitingOutcomeButton: Bool {
        // Show button if:
        // 1. Interview date has passed, AND
        // 2. No outcome is set yet OR outcome is still "scheduled"
        guard let interviewDate = interview.date else {
            return false
        }
        
        let hasPassed = interviewDate < Date()
        let needsOutcome = interview.outcome == nil || interview.outcome == .scheduled
        
        return hasPassed && needsOutcome
    }
    
    private func setOutcome(_ outcome: InterviewOutcome) {
        interview.outcome = outcome
        interview.updatedAt = Date()
        try? modelContext.save()
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

//
//  InterviewListView.swift
//  Interviews
//
//  Created by keloran on 05/12/2025.
//

import SwiftUI
import SwiftData
import ClerkKit

private struct InterviewItem: Identifiable, Equatable {
    let id: PersistentIdentifier
}

struct InterviewListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(Clerk.self) private var clerk: Clerk?
    @Query private var interviews: [Interview]
    
    @Binding var selectedDate: Date?
    var searchText: String

    @State private var selectedInterview: InterviewItem?
    @State private var interviewForNextStage: InterviewItem?
    @State private var isSyncing = false

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
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .glassEffect()
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
                                if interview.outcome != .awaitingResponse && interview.outcome != .passed && interview.outcome != .rejected && interview.outcome != .noResponse {
                                    Button {
                                        setAwaiting(interview)
                                    } label: {
                                        Label("Awaiting Response", systemImage: "timer.circle")
                                    }.tint(.purple)
                                }
                                
                                if interview.outcome != .passed {
                                    Button {
                                        interviewForNextStage = InterviewItem(id: interview.persistentModelID)
                                    } label: {
                                        Label("Next Stage", systemImage: "arrow.right.circle")
                                    }
                                    .tint(.green)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                // Only show reject if not already rejected
                                if interview.outcome != .rejected && interview.outcome != .passed {
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
                                selectedInterview = InterviewItem(id: interview.persistentModelID)
                            }
                    }
                }
                .refreshable {
                    // Immediately end the system spinner and show our own syncing popup
                    isSyncing = true
                    Task {
                        if clerk?.user != nil {
                            await SyncService(modelContext: modelContext).syncAll()
                        }
                        isSyncing = false
                    }
                }
                .listStyle(.inset)
            }
        }
        .overlay(alignment: .center) {
            if isSyncing {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Syncing…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(radius: 10)
                .transition(.opacity)
            }
        }
        .sheet(item: $selectedInterview) { item in
            NavigationStack {
                let interview: Interview? = modelContext.model(for: item.id) as? Interview
                if let interview {
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
                } else {
                    Text("Interview not found")
                        .padding()
                }
            }
        }
        .sheet(item: $interviewForNextStage) { item in
            if let interview = modelContext.model(for: item.id) as? Interview {
                CreateNextStageView(interview: interview)
            } else {
                Text("Interview not found")
                    .padding()
            }
        }
    }
    
    private func rejectInterview(_ interview: Interview) {
        setOutcome(.rejected, on: interview)
    }

    private func setAwaiting(_ interview: Interview) {
        setOutcome(.awaitingResponse, on: interview)
    }

    /// Saved locally and queued, so it reaches the server even if this attempt fails
    private func setOutcome(_ outcome: InterviewOutcome, on interview: Interview) {
        interview.outcome = outcome
        interview.markChanged()
        try? modelContext.save()
        guard clerk?.user != nil else { return }
        Task { await SyncService(modelContext: modelContext).pushPending() }
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
            return "Click the + button to add an interview"
        } else {
            return "Choose a date and click the + button to add an interview"
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

    /// Unsent changes: waiting, or failed with the reason
    @ViewBuilder
    private var syncBadge: some View {
        if let error = interview.syncError {
            Image(systemName: "exclamationmark.icloud")
                .foregroundStyle(.red)
                .accessibilityLabel("Not saved to interviews.tools: \(error)")
        } else if interview.pendingSince != nil {
            Image(systemName: "arrow.triangle.2.circlepath.icloud")
                .foregroundStyle(.secondary)
                .accessibilityLabel("Waiting to save to interviews.tools")
        }
    }

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
                    HStack(spacing: 6) {
                        Text(interview.jobTitle)
                            .font(.headline)
                        syncBadge
                    }

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
                            .background(Color.primary.opacity(0.2))
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
            return colorForOutcomeString("applied")
        }
        
        guard let outcome = interview.outcome else { return .blue }
        
        return colorForOutcomeInterview(outcome)
    }
}

struct InterviewDetailSheet: View {
    let interview: Interview
    @Environment(\.modelContext) private var modelContext
    @Environment(Clerk.self) private var clerk: Clerk?
    @State private var showingEditSheet = false
    @State private var showingOutcomeOptions = false
    @State private var showingDebrief = false
    @State private var showingPrep = false
    @State private var showingAvailability = false
    @State private var showingRecruiter = false

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

                if interview.applicationId != nil, clerk?.user != nil {
                    Button {
                        showingRecruiter = true
                    } label: {
                        if interview.viaRecruiter == true, let name = interview.recruiterName ?? interview.recruiterEmail {
                            Label("Recruiter: \(name)", systemImage: "person.badge.shield.checkmark")
                        } else {
                            Label(interview.viaRecruiter == true ? "Add recruiter details" : "Through a recruiter?", systemImage: "person.badge.plus")
                        }
                    }
                    .font(.subheadline)
                    .sheet(isPresented: $showingRecruiter) { RecruiterContactForm(interview: interview) }
                }

                if let id = interview.id, clerk?.user != nil {
                    let title = "\(interview.stage?.stage ?? "Interview") · \(interview.company?.name ?? "")"
                    HStack {
                        Button { showingPrep = true } label: { Label("Prepare", systemImage: "list.clipboard") }
                        Button { showingDebrief = true } label: { Label("Debrief", systemImage: "text.bubble") }
                    }
                    Button { showingAvailability = true } label: { Label("Share availability", systemImage: "calendar.badge.clock") }
                        .sheet(isPresented: $showingAvailability) { ShareAvailabilityView(interview: interview) }
                    .buttonStyle(.bordered)
                    .font(.subheadline)
                    .sheet(isPresented: $showingDebrief) { DebriefView(interviewId: id, title: title) }
                    .sheet(isPresented: $showingPrep) { PrepView(interviewId: id, title: title) }
                }

                if let applicationId = interview.applicationId, clerk?.user != nil {
                    NavigationLink {
                        ApplicationTimelineView(applicationId: applicationId)
                    } label: {
                        Label("Application timeline", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                            .font(.subheadline)
                    }
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
                                .foregroundStyle(colorForOutcomeString("applied"))
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
                                    .glassEffect()
                            }
                        }
                    }
                }

                let templates = MessageTemplate.templates(outcome: interview.outcome?.rawValue, stage: interview.stage?.stage, date: interview.date)
                if !templates.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Messages").font(.headline)
                        ForEach(templates) { template in
                            ShareLink(item: template.render(.init(interview))) {
                                Label(template.label, systemImage: "square.and.arrow.up")
                            }
                            .font(.subheadline)
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
                            "Interview: \(date.formatted(date: .long, time: .shortened)) · \(interview.durationMinutes ?? 60) min",
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

                        // A link that isn't a URL gets no button rather than one that opens nothing
                        if let link = interview.link, let url = URL(string: link) {
                            Link(destination: url) {
                                Label("Join Interview", systemImage: "video")
                                    .font(.subheadline)
                            }
                        }
                        
                        if let jobPostingLink = interview.jobListing, let url = URL(string: jobPostingLink) {
                            Link(destination: url) {
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
            Button("No Response (Ghosted)") {
                setOutcome(.noResponse)
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
        interview.markChanged()
        try? modelContext.save()
        guard clerk?.user != nil else { return }
        Task { await SyncService(modelContext: modelContext).pushPending() }
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
        case .noResponse: return .brown
        }
    }
}

#Preview {
    InterviewListView(selectedDate: .constant(nil), searchText: "")
        .modelContainer(for: [Interview.self, Company.self, Stage.self, StageMethod.self], inMemory: true)
}


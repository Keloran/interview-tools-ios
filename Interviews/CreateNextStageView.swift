//
//  CreateNextStageView.swift
//  Interviews
//
//  Created by keloran on 07/12/2025.
//

import SwiftUI
import SwiftData

struct CreateNextStageView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allStages: [Stage]
    @Query private var allMethods: [StageMethod]
    
    let interview: Interview
    
    @State private var selectedStage: Stage?
    @State private var selectedMethod: StageMethod?
    @State private var interviewDate: Date = Date()
    @State private var hasSpecificDate = false
    @State private var deadline: Date = Date()
    @State private var hasDeadline = false
    @State private var notes: String = ""
    @State private var interviewer: String = ""
    @State private var link: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Current Interview") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(interview.jobTitle)
                            .font(.headline)
                        if let company = interview.company {
                            Text(company.name)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let stage = interview.stage {
                            Text("Current Stage: \(stage.stage)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // Debug: Show if data is empty
                if allStages.isEmpty || allMethods.isEmpty {
                    Section {
                        if allStages.isEmpty {
                            Text("⚠️ No stages available. Please sync with server.")
                                .foregroundStyle(.orange)
                        }
                        if allMethods.isEmpty {
                            Text("⚠️ No methods available. Please sync with server.")
                                .foregroundStyle(.orange)
                        }
                    }
                }
                
                Section("New Interview Stage") {
                    Picker("Stage", selection: $selectedStage) {
                        Text("Select Stage").tag(nil as Stage?)
                        ForEach(nextStages, id: \.id) { stage in
                            Text(stage.stage).tag(stage as Stage?)
                        }
                    }
                    
                    Picker("Method", selection: $selectedMethod) {
                        Text("Select Method").tag(nil as StageMethod?)
                        ForEach(allMethods, id: \.id) { method in
                            Text(method.method).tag(method as StageMethod?)
                        }
                    }
                }
                
                Section("Interview Details") {
                    Toggle("Has Specific Date", isOn: $hasSpecificDate)
                    if hasSpecificDate {
                        DatePicker("Interview Date", selection: $interviewDate, displayedComponents: [.date, .hourAndMinute])
                    }
                    
                    Toggle("Has Deadline", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker("Deadline", selection: $deadline, displayedComponents: [.date])
                    }
                    
                    TextField("Interviewer (optional)", text: $interviewer)
                    TextField("Interview Link (optional)", text: $link)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
                
                Section {
                    Button {
                        createNextStage()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Create Next Stage")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(selectedStage == nil || selectedMethod == nil)
                }
            }
            .navigationTitle("Create Next Stage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var nextStages: [Stage] {
        // Filter stages to show logical next steps based on current stage
        guard let currentStage = interview.stage else {
            return allStages
        }
        
        // Define stage progression logic
        let stageProgression: [String: [String]] = [
            "Applied": ["Phone Screen", "Technical Interview", "Take Home", "In-Person Interview"],
            "Phone Screen": ["Technical Interview", "Take Home", "In-Person Interview", "Manager Interview"],
            "Technical Interview": ["Take Home", "In-Person Interview", "Manager Interview", "Final Interview"],
            "Take Home": ["Technical Interview", "In-Person Interview", "Manager Interview"],
            "In-Person Interview": ["Manager Interview", "Final Interview", "HR Interview"],
            "Manager Interview": ["Final Interview", "HR Interview"],
            "HR Interview": ["Final Interview"],
            "Final Interview": [] // Last stage
        ]
        
        if let nextStageNames = stageProgression[currentStage.stage] {
            return allStages.filter { nextStageNames.contains($0.stage) }
        }
        
        // If no specific progression defined, show all stages except current
        return allStages.filter { $0.id != currentStage.id }
    }
    
    private func createNextStage() {
        // Mark current interview as passed
        interview.outcome = .passed
        interview.updatedAt = Date()
        
        // Create new interview with next stage
        let newInterview = Interview(
            company: interview.company,
            clientCompany: interview.clientCompany,
            jobTitle: interview.jobTitle,
            applicationDate: interview.applicationDate, // Keep original application date
            interviewer: interviewer.isEmpty ? nil : interviewer,
            stage: selectedStage,
            stageMethod: selectedMethod,
            userId: interview.userId,
            date: hasSpecificDate ? interviewDate : nil,
            deadline: hasDeadline ? deadline : nil,
            outcome: .awaitingResponse, // New stage is awaiting response
            notes: notes.isEmpty ? nil : notes,
            link: link.isEmpty ? nil : link,
            jobPostingLink: interview.jobPostingLink // Carry over job posting link
        )
        
        modelContext.insert(newInterview)
        try? modelContext.save()
        
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Interview.self, Company.self, Stage.self, StageMethod.self,
        configurations: config
    )
    
    let context = ModelContext(container)
    
    // Create sample data
    let company = Company(id: 1, name: "Apple Inc.")
    let stage = Stage(id: 1, stage: "Phone Screen")
    context.insert(company)
    context.insert(stage)
    
    let interview = Interview(
        company: company,
        jobTitle: "Senior iOS Developer",
        applicationDate: Date(),
        stage: stage
    )
    
    return CreateNextStageView(interview: interview)
        .modelContainer(container)
}

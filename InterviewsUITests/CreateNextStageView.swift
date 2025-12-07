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
    @Query private var stages: [Stage]
    @Query private var stageMethods: [StageMethod]

    let interview: Interview

    @State private var clientCompany = ""
    @State private var jobTitle = ""
    @State private var selectedStage: Stage?
    @State private var selectedStageMethod: StageMethod?
    @State private var interviewDate: Date = Date()
    @State private var deadline: Date = Date()
    @State private var interviewer = ""
    @State private var notes = ""
    @State private var link = ""
    @State private var hasInitialized = false

    @State private var showError = false
    @State private var errorMessage = ""

    // Computed properties to match React logic
    private var selectedStageName: String {
        selectedStage?.stage ?? "Phone Screen"
    }

    private var isTechnicalTest: Bool {
        selectedStageName == "Technical Test"
    }

    private var requiresScheduling: Bool {
        selectedStageName != "Applied" && selectedStageName != "Offer"
    }
    
    // Filter out "Applied" stage for next stage selection
    private var availableStages: [Stage] {
        let uniqueStages = sortedUniqueStages.filter { $0.stage != "Applied" }
        return uniqueStages
    }
    
    // Deduplicate and sort stages
    private var sortedUniqueStages: [Stage] {
        // Group stages by name and keep only the first occurrence
        var seenNames = Set<String>()
        let uniqueStages = stages.filter { stage in
            let name = stage.stage
            if seenNames.contains(name) {
                return false
            }
            seenNames.insert(name)
            return true
        }
        
        // Define the preferred order for known stages
        let knownStageOrder = [
            "Applied",
            "Phone Screen", 
            "First Stage",
            "Second Stage",
            "Third Stage",
            "Fourth Stage",
            "Technical Test",
            "Technical Interview",
            "Final Stage",
            "Onsite",
            "Offer"
        ]
        
        return uniqueStages.sorted { stage1, stage2 in
            let index1 = knownStageOrder.firstIndex(of: stage1.stage) ?? Int.max
            let index2 = knownStageOrder.firstIndex(of: stage2.stage) ?? Int.max
            
            // If both stages are in known order, sort by position
            if index1 != Int.max && index2 != Int.max {
                return index1 < index2
            }
            
            // If only one is in known order, it comes first
            if index1 != Int.max {
                return true
            }
            if index2 != Int.max {
                return false
            }
            
            // If neither is in known order, sort alphabetically
            return stage1.stage < stage2.stage
        }
    }
    
    // Deduplicate and sort stage methods
    private var sortedUniqueStageMethods: [StageMethod] {
        // Group methods by name and keep only the first occurrence
        var seenMethods = Set<String>()
        let uniqueMethods = stageMethods.filter { method in
            let name = method.method
            if seenMethods.contains(name) {
                return false
            }
            seenMethods.insert(name)
            return true
        }
        
        // Sort alphabetically
        return uniqueMethods.sorted { $0.method < $1.method }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Interview Stage") {
                    if availableStages.isEmpty {
                        Text("No stages available. Please sync first.")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Stage", selection: $selectedStage) {
                            ForEach(availableStages, id: \.stage) { stage in
                                Text(stage.stage).tag(stage as Stage?)
                            }
                        }
                    }
                }

                Section("Company & Position") {
                    // Pre-filled, read-only
                    HStack {
                        Text("Company")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(interview.company?.name ?? "Unknown")
                    }

                    if let clientCompanyValue = interview.clientCompany {
                        HStack {
                            Text("Client Company")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(clientCompanyValue)
                        }
                    }

                    HStack {
                        Text("Job Title")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(interview.jobTitle)
                    }
                }

                // Scheduling section - always shown since "Applied" is not an option
                Section(isTechnicalTest ? "Test Details" : "Interview Details") {
                    if isTechnicalTest {
                        DatePicker("Deadline", selection: $deadline, displayedComponents: .date)

                        TextField("Notes", text: $notes, axis: .vertical)
                            .lineLimit(5...10)
                    } else {
                        DatePicker("Date & Time", selection: $interviewDate, displayedComponents: [.date, .hourAndMinute])

                        TextField("Interviewer", text: $interviewer)
                            .textContentType(.name)

                        Picker("Method", selection: $selectedStageMethod) {
                            Text("Select Method").tag(nil as StageMethod?)
                            ForEach(sortedUniqueStageMethods, id: \.method) { method in
                                Text(method.method).tag(method as StageMethod?)
                            }
                        }

                        if selectedStageMethod?.method.lowercased().contains("video") == true ||
                           selectedStageMethod?.method.lowercased().contains("call") == true {
                            TextField("Meeting Link (Optional)", text: $link)
                                .textContentType(.URL)
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                        }
                    }
                }
                
                Section {
                    Text("This will create a new interview for the next stage while keeping the previous interview record.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Next Stage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        saveNextStageInterview()
                    }
                    .disabled(!isValid)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                initializeDefaults()
            }
        }
    }
    
    private func initializeDefaults() {
        // Only set defaults once
        guard !hasInitialized else { return }
        hasInitialized = true
        
        // Pre-fill data from the previous interview
        clientCompany = interview.clientCompany ?? ""
        jobTitle = interview.jobTitle
        
        // Set default stage to first available (not "Applied")
        if selectedStage == nil {
            if let phoneScreen = availableStages.first(where: { $0.stage == "Phone Screen" }) {
                selectedStage = phoneScreen
            } else if let firstStage = availableStages.first {
                selectedStage = firstStage
            }
        }
        
        // Set the date to tomorrow as a reasonable default for next stage
        if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) {
            interviewDate = tomorrow
            deadline = tomorrow
        }
    }

    private var isValid: Bool {
        // Must have a stage selected
        guard selectedStage != nil else { return false }

        // For technical tests, we need a deadline
        if isTechnicalTest {
            return true // deadline is always set via DatePicker
        }

        // For other stages that require scheduling
        if requiresScheduling {
            let hasInterviewer = !interviewer.isEmpty
            let hasMethod = selectedStageMethod != nil
            return hasInterviewer && hasMethod
        }

        return true
    }

    private func saveNextStageInterview() {
        guard let stage = selectedStage else {
            errorMessage = "Please select a stage"
            showError = true
            return
        }
        
        // Mark the previous interview as "passed" (they progressed to next stage)
        interview.outcome = .passed
        interview.updatedAt = Date()

        // Create new interview with the same company and job details
        let newInterview = Interview(
            company: interview.company,
            clientCompany: clientCompany.isEmpty ? nil : clientCompany,
            jobTitle: jobTitle,
            applicationDate: interview.applicationDate, // Keep original application date
            interviewer: (requiresScheduling && !isTechnicalTest) ? (interviewer.isEmpty ? nil : interviewer) : nil,
            stage: stage,
            stageMethod: (requiresScheduling && !isTechnicalTest) ? selectedStageMethod : nil,
            date: (requiresScheduling && !isTechnicalTest) ? interviewDate : nil,
            deadline: isTechnicalTest ? deadline : nil,
            outcome: .scheduled,
            notes: isTechnicalTest ? (notes.isEmpty ? nil : notes) : nil,
            link: (requiresScheduling && !isTechnicalTest) ? (link.isEmpty ? nil : link) : nil,
            jobPostingLink: interview.jobPostingLink
        )

        // Copy metadata if it exists
        if let metadata = interview.metadataJSON {
            newInterview.metadataJSON = metadata
        }

        modelContext.insert(newInterview)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save interview: \(error.localizedDescription)"
            showError = true
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Interview.self, Company.self, Stage.self, StageMethod.self,
        configurations: config
    )

    let context = container.mainContext

    // Add some sample data
    let company = Company(name: "Apple Inc.")
    let appliedStage = Stage(stage: "Applied")
    let phoneStage = Stage(stage: "Phone Screen")
    let technicalStage = Stage(stage: "Technical Interview")
    let method1 = StageMethod(method: "Video Call")
    let method2 = StageMethod(method: "In Person")

    context.insert(company)
    context.insert(appliedStage)
    context.insert(phoneStage)
    context.insert(technicalStage)
    context.insert(method1)
    context.insert(method2)

    let interview = Interview(
        company: company,
        jobTitle: "iOS Engineer",
        applicationDate: Date(),
        stage: appliedStage
    )
    context.insert(interview)

    return CreateNextStageView(interview: interview)
        .modelContainer(container)
}

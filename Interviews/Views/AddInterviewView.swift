//
//  AddInterviewView.swift
//  Interviews
//
//  Created by keloran on 05/12/2025.
//

import SwiftUI
import SwiftData

struct AddInterviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var companies: [Company]
    @Query private var stages: [Stage]
    @Query private var stageMethods: [StageMethod]

    let initialDate: Date

    @State private var companyName = ""
    @State private var selectedCompany: Company?
    @State private var clientCompany = ""
    @State private var jobTitle = ""
    @State private var jobPostingLink = ""
    @State private var applicationDate = Date()
    @State private var interviewer = ""
    @State private var selectedStage: Stage?
    @State private var selectedStageMethod: StageMethod?
    @State private var interviewDate: Date?
    @State private var deadline: Date?
    @State private var outcome: InterviewOutcome?
    @State private var notes = ""
    @State private var link = ""

    @State private var showError = false
    @State private var errorMessage = ""

    // Computed properties to match React logic
    private var selectedStageName: String {
        selectedStage?.stage ?? "Applied"
    }

    private var isTechnicalTest: Bool {
        selectedStageName == "Technical Test"
    }

    private var requiresScheduling: Bool {
        selectedStageName != "Applied" && selectedStageName != "Offer"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Interview Stage") {
                    Picker("Stage", selection: $selectedStage) {
                        Text("Select Stage").tag(nil as Stage?)
                        ForEach(stages, id: \.id) { stage in
                            Text(stage.stage).tag(stage as Stage?)
                        }
                    }
                }

                Section("Company & Position") {
                    if companies.isEmpty {
                        TextField("Company Name", text: $companyName)
                    } else {
                        Picker("Company", selection: $selectedCompany) {
                            Text("New Company").tag(nil as Company?)
                            ForEach(companies, id: \.id) { company in
                                Text(company.name).tag(company as Company?)
                            }
                        }

                        if selectedCompany == nil {
                            TextField("Company Name", text: $companyName)
                        }
                    }

                    TextField("Client Company (Optional)", text: $clientCompany)
                        .textContentType(.organizationName)

                    TextField("Job Title", text: $jobTitle)
                        .textContentType(.jobTitle)

                    TextField("Job Posting Link (Optional)", text: $jobPostingLink)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }

                // Only show scheduling section if stage requires it
                if requiresScheduling {
                    Section(isTechnicalTest ? "Test Details" : "Interview Details") {
                        if isTechnicalTest {
                            DatePicker("Deadline", selection: Binding(
                                get: { deadline ?? initialDate },
                                set: { deadline = $0 }
                            ), displayedComponents: .date)

                            TextField("Notes", text: $notes, axis: .vertical)
                                .lineLimit(5...10)
                        } else {
                            DatePicker("Date & Time", selection: Binding(
                                get: { interviewDate ?? initialDate },
                                set: { interviewDate = $0 }
                            ), displayedComponents: [.date, .hourAndMinute])

                            TextField("Interviewer", text: $interviewer)
                                .textContentType(.name)

                            Picker("Method", selection: $selectedStageMethod) {
                                Text("Select Method").tag(nil as StageMethod?)
                                ForEach(stageMethods, id: \.id) { method in
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
                }
            }
            .navigationTitle("Add Interview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveInterview()
                    }
                    .disabled(!isValid)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var isValid: Bool {
        let hasCompany = selectedCompany != nil || !companyName.isEmpty
        let hasJobTitle = !jobTitle.isEmpty

        // For "Applied" stage, only company and job title are required
        if selectedStageName == "Applied" {
            return hasCompany && hasJobTitle
        }

        // For technical tests, we need company, job title, and deadline
        if isTechnicalTest {
            return hasCompany && hasJobTitle && deadline != nil
        }

        // For other stages that require scheduling
        if requiresScheduling {
            let hasInterviewer = !interviewer.isEmpty
            let hasMethod = selectedStageMethod != nil
            return hasCompany && hasJobTitle && hasInterviewer && hasMethod
        }

        return hasCompany && hasJobTitle
    }

    private func saveInterview() {
        // Get or create company
        let company: Company
        if let existing = selectedCompany {
            company = existing
        } else {
            company = Company(name: companyName)
            modelContext.insert(company)
        }

        // Default to "Applied" stage if none selected
        let stage: Stage
        if let selected = selectedStage {
            stage = selected
        } else {
            // Find or create "Applied" stage
            if let appliedStage = stages.first(where: { $0.stage == "Applied" }) {
                stage = appliedStage
            } else {
                stage = Stage(stage: "Applied")
                modelContext.insert(stage)
            }
        }

        // Create interview with conditional fields based on stage
        let interview = Interview(
            company: company,
            clientCompany: clientCompany.isEmpty ? nil : clientCompany,
            jobTitle: jobTitle,
            applicationDate: applicationDate,
            interviewer: (requiresScheduling && !isTechnicalTest) ? (interviewer.isEmpty ? nil : interviewer) : nil,
            stage: stage,
            stageMethod: (requiresScheduling && !isTechnicalTest) ? selectedStageMethod : nil,
            date: (requiresScheduling && !isTechnicalTest) ? (interviewDate ?? initialDate) : nil,
            deadline: isTechnicalTest ? (deadline ?? initialDate) : nil,
            outcome: selectedStageName == "Applied" ? .awaitingResponse : .scheduled,
            notes: isTechnicalTest ? (notes.isEmpty ? nil : notes) : nil,
            link: (requiresScheduling && !isTechnicalTest) ? (link.isEmpty ? nil : link) : nil
        )

        // Store job posting link in metadata
        if !jobPostingLink.isEmpty {
            interview.metadataJSON = "{\"jobListing\":\"\(jobPostingLink)\"}"
        }

        modelContext.insert(interview)

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
    let stage1 = Stage(stage: "Phone Screen")
    let stage2 = Stage(stage: "Technical Interview")
    let method1 = StageMethod(method: "Video Call")
    let method2 = StageMethod(method: "In Person")

    context.insert(stage1)
    context.insert(stage2)
    context.insert(method1)
    context.insert(method2)

    return AddInterviewView(initialDate: Date())
        .modelContainer(container)
}

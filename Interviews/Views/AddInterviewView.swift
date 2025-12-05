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
    @State private var applicationDate = Date()
    @State private var interviewer = ""
    @State private var selectedStage: Stage?
    @State private var selectedStageMethod: StageMethod?
    @State private var interviewDate: Date?
    @State private var deadline: Date?
    @State private var outcome: InterviewOutcome?
    @State private var notes = ""
    @State private var link = ""

    @State private var useInterviewDate = true
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Company") {
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
                }

                Section("Position") {
                    TextField("Job Title", text: $jobTitle)
                        .textContentType(.jobTitle)

                    DatePicker("Application Date", selection: $applicationDate, displayedComponents: .date)

                    TextField("Interviewer (Optional)", text: $interviewer)
                        .textContentType(.name)
                }

                Section("Interview Details") {
                    Picker("Stage", selection: $selectedStage) {
                        Text("Select Stage").tag(nil as Stage?)
                        ForEach(stages, id: \.id) { stage in
                            Text(stage.stage).tag(stage as Stage?)
                        }
                    }

                    Picker("Method", selection: $selectedStageMethod) {
                        Text("Select Method").tag(nil as StageMethod?)
                        ForEach(stageMethods, id: \.id) { method in
                            Text(method.method).tag(method as StageMethod?)
                        }
                    }

                    Toggle("Interview Date", isOn: $useInterviewDate)

                    if useInterviewDate {
                        DatePicker("Date & Time", selection: Binding(
                            get: { interviewDate ?? initialDate },
                            set: { interviewDate = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                    } else {
                        DatePicker("Deadline", selection: Binding(
                            get: { deadline ?? initialDate },
                            set: { deadline = $0 }
                        ), displayedComponents: .date)
                    }

                    TextField("Meeting Link (Optional)", text: $link)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }

                Section("Status & Notes") {
                    Picker("Outcome", selection: $outcome) {
                        Text("None").tag(nil as InterviewOutcome?)
                        ForEach(InterviewOutcome.allCases, id: \.self) { outcome in
                            Text(outcome.displayName).tag(outcome as InterviewOutcome?)
                        }
                    }

                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(5...10)
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
        let hasStage = selectedStage != nil
        let hasMethod = selectedStageMethod != nil
        return hasCompany && !jobTitle.isEmpty && hasStage && hasMethod
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

        // Validate stage and method
        guard let stage = selectedStage,
              let stageMethod = selectedStageMethod else {
            errorMessage = "Please select a stage and method"
            showError = true
            return
        }

        // Create interview
        let interview = Interview(
            company: company,
            clientCompany: clientCompany.isEmpty ? nil : clientCompany,
            jobTitle: jobTitle,
            applicationDate: applicationDate,
            interviewer: interviewer.isEmpty ? nil : interviewer,
            stage: stage,
            stageMethod: stageMethod,
            date: useInterviewDate ? (interviewDate ?? initialDate) : nil,
            deadline: useInterviewDate ? nil : (deadline ?? initialDate),
            outcome: outcome,
            notes: notes.isEmpty ? nil : notes,
            link: link.isEmpty ? nil : link
        )

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

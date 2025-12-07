//
//  EditInterviewView.swift
//  Interviews
//
//  Created by keloran on 07/12/2025.
//

import SwiftUI
import SwiftData

struct EditInterviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let interview: Interview
    
    @State private var jobTitle: String
    @State private var clientCompany: String
    @State private var interviewer: String
    @State private var link: String
    @State private var notes: String
    @State private var date: Date?
    @State private var deadline: Date?
    @State private var hasDate: Bool
    @State private var hasDeadline: Bool
    
    init(interview: Interview) {
        self.interview = interview
        _jobTitle = State(initialValue: interview.jobTitle)
        _clientCompany = State(initialValue: interview.clientCompany ?? "")
        _interviewer = State(initialValue: interview.interviewer ?? "")
        _link = State(initialValue: interview.link ?? "")
        _notes = State(initialValue: interview.notes ?? "")
        _date = State(initialValue: interview.date)
        _deadline = State(initialValue: interview.deadline)
        _hasDate = State(initialValue: interview.date != nil)
        _hasDeadline = State(initialValue: interview.deadline != nil)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Job Title", text: $jobTitle)
                    TextField("Client Company (optional)", text: $clientCompany)
                }
                
                Section("Interview Details") {
                    TextField("Interviewer Name (optional)", text: $interviewer)
                    TextField("Interview Link (optional)", text: $link)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                }
                
                Section("Dates") {
                    Toggle("Has Interview Date", isOn: $hasDate)
                    if hasDate {
                        DatePicker("Interview Date", selection: Binding(
                            get: { date ?? Date() },
                            set: { date = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                    }
                    
                    Toggle("Has Deadline", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker("Deadline", selection: Binding(
                            get: { deadline ?? Date() },
                            set: { deadline = $0 }
                        ), displayedComponents: [.date])
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Edit Interview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(jobTitle.isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        interview.jobTitle = jobTitle
        interview.clientCompany = clientCompany.isEmpty ? nil : clientCompany
        interview.interviewer = interviewer.isEmpty ? nil : interviewer
        interview.link = link.isEmpty ? nil : link
        interview.notes = notes.isEmpty ? nil : notes
        interview.date = hasDate ? date : nil
        interview.deadline = hasDeadline ? deadline : nil
        interview.updatedAt = Date()
        
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
    
    let interview = Interview(
        jobTitle: "Senior iOS Developer",
        applicationDate: Date(),
        link: "https://zoom.us/j/123456789"
    )
    
    return EditInterviewView(interview: interview)
        .modelContainer(container)
}

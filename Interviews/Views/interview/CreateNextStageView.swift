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
    
    // Restrict methods to three options
    private var allowedMethods: [StageMethod] {
        let allowedNames = ["Link", "In Person", "Phone"]
        var results: [StageMethod] = []
        for name in allowedNames {
            if let existing = allMethods.first(where: { $0.method.caseInsensitiveCompare(name) == .orderedSame }) {
                results.append(existing)
            } else {
                results.append(StageMethod(method: name))
            }
        }
        return results
    }
    
    @State private var selectedStage: Stage?
    @State private var selectedMethod: StageMethod?
    @State private var interviewDate: Date = Date()
    @State private var hasSpecificDate = false
    @State private var deadline: Date = Date()
    @State private var hasDeadline = false
    @State private var notes: String = ""
    @State private var interviewer: String = ""
    @State private var link: String = ""
    @State private var hasInitialized = false
    
    var body: some View {
        NavigationStack {
            if allStages.isEmpty && allMethods.isEmpty {
                // Show loading state if data isn't ready yet
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading interview data...")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("Create Next Stage")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            } else {
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
                    
                    Section("New Interview Stage") {
                        Picker("Stage", selection: $selectedStage) {
                            Text("Select Stage").tag(nil as Stage?)
                            ForEach(nextStages, id: \.persistentModelID) { stage in
                                Text(stage.stage).tag(stage as Stage?)
                            }
                        }
                        
                        Picker("Method", selection: $selectedMethod) {
                            Text("Select Method").tag(nil as StageMethod?)
                            ForEach(allowedMethods, id: \.method) { method in
                                Text(method.method).tag(method as StageMethod?)
                            }
                        }
                    }
                
                Section("Interview Details") {
                    // Technical Test has a deadline, everything else has a scheduled date
                    if selectedStage?.stage == "Technical Test" {
                        Toggle("Has Deadline", isOn: $hasDeadline)
                        if hasDeadline {
                            DatePicker("Deadline", selection: $deadline, displayedComponents: [.date])
                        }
                    } else {
                        Toggle("Has Specific Date", isOn: $hasSpecificDate)
                        if hasSpecificDate {
                            DatePicker("Interview Date", selection: $interviewDate, displayedComponents: [.date, .hourAndMinute])
                        }
                        
                        TextField("Interviewer (optional)", text: $interviewer)
                        
                        // Show link field for method exactly "Link"
                        if shouldShowLinkField {
                            TextField("Interview Link", text: $link)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.URL)
                                .onChange(of: link) { oldValue, newValue in
                                    // Auto-detect method from link
                                    if !newValue.isEmpty {
                                        autoDetectStageMethod(from: newValue)
                                    }
                                }
                            
                            if !link.isEmpty, let detectedMethod = inferStageMethodName(from: link) {
                                Text("Detected: \(detectedMethod)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
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
                    .disabled(!isFormValid)
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
            .onAppear {
                ensureDataExists()
            }
            } // End of else
        }
    }
    
    private func ensureDataExists() {
        guard !hasInitialized else { return }
        hasInitialized = true
        
        // Trigger seeding if data is missing (fallback)
        if allStages.isEmpty || allMethods.isEmpty {
            print("⚠️ CreateNextStageView: No stages/methods found - triggering fallback seeding")
            DataSeeder.seedDefaultData(context: modelContext)
        }
    }
    
    // Determine if link field should be shown
    private var shouldShowLinkField: Bool {
        guard let method = selectedMethod?.method else { return false }
        return method.caseInsensitiveCompare("Link") == .orderedSame
    }
    
    private var isFormValid: Bool {
        // Stage is always required
        guard selectedStage != nil else { return false }
        
        // Technical Test doesn't require a method
        if selectedStage?.stage == "Technical Test" {
            return true
        }
        
        // All other stages require a method
        return selectedMethod != nil
    }
    
    private var nextStages: [Stage] {
        // Show all stages except "Applied" (since they're moving past application)
        return allStages.filter { $0.stage != "Applied" }
    }
    
    private func createNextStage() {
        // Mark current interview as passed
        interview.outcome = .passed
        interview.updatedAt = Date()
        
        let newOutcome: InterviewOutcome?
        if hasSpecificDate {
            newOutcome = .scheduled
        } else {
            newOutcome = nil
        }
        
        // Prepare merged metadata dictionary by parsing existing metadataJSON (if any)
        var mergedMetadata: [String: Any] = [:]
        if let metadataJSON = interview.metadataJSON,
           let data = metadataJSON.data(using: .utf8) {
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    mergedMetadata = jsonObject
                }
            } catch {
                print("⚠️ createNextStage: Failed to parse previous metadataJSON: \(error.localizedDescription)")
            }
        }
        
        // Overwrite or add new metadata entries
        // Update jobListing if set
        if let jobListing = interview.jobListing {
            mergedMetadata["jobListing"] = jobListing
        }
        
        // Update method type if selectedMethod is set
        if let methodName = selectedMethod?.method {
            mergedMetadata["methodType"] = methodName
        }
        
        // Update current stage name
        if let stageName = selectedStage?.stage {
            mergedMetadata["stage"] = stageName
        }
        
        // Serialize merged metadata dictionary back to JSON string
        let newMetadataJSON: String?
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: mergedMetadata, options: [])
            newMetadataJSON = String(data: jsonData, encoding: .utf8)
        } catch {
            print("⚠️ createNextStage: Failed to serialize merged metadataJSON: \(error.localizedDescription)")
            newMetadataJSON = nil
        }
        
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
            outcome: newOutcome,
            notes: notes.isEmpty ? nil : notes,
            metadataJSON: newMetadataJSON, link: link.isEmpty ? nil : link,
            jobListing: interview.jobListing
        )
        
        modelContext.insert(newInterview)
        try? modelContext.save()
        
        dismiss()
    }
    
    // MARK: - Link Inference
    
    /// Infer the stage method name from a meeting link
    private func inferStageMethodName(from link: String) -> String? {
        guard !link.isEmpty else { return nil }
        
        let candidates: [(regex: String, name: String)] = [
            (#"zoom\.us|zoom\.com"#, "Zoom"),
            (#"zoomgov\.com"#, "ZoomGov"),
            (#"teams\.microsoft\.com|microsoft\.teams|live\.com/meet"#, "Teams"),
            (#"meet\.google\.com|hangouts\.google\.com|google\.com/hangouts|workspace\.google\.com/products/meet"#, "Google Meet"),
            (#"webex\.com|webex"#, "Webex"),
            (#"skype\.com"#, "Skype"),
            (#"bluejeans\.com"#, "BlueJeans"),
            (#"whereby\.com"#, "Whereby"),
            (#"jitsi\.org|meet\.jit\.si"#, "Jitsi"),
            (#"gotomeet|gotowebinar|goto\.com"#, "GoToMeeting"),
            (#"chime\.aws|amazonchime\.com"#, "Amazon Chime"),
            (#"slack\.com"#, "Slack"),
            (#"discord\.(gg|com)"#, "Discord"),
            (#"facetime|apple\.com/facetime"#, "FaceTime"),
            (#"whatsapp\.com"#, "WhatsApp"),
            (#"(^|\.)8x8\.vc"#, "8x8"),
            (#"telegram\.(me|org)|(^|/)t\.me/"#, "Telegram"),
            (#"signal\.org"#, "Signal"),
        ]
        
        // Try to extract hostname
        var host = ""
        if let url = URL(string: link) {
            host = url.host ?? ""
        } else if let url = URL(string: "https://\(link)") {
            host = url.host ?? ""
        }
        
        // Remove www. prefix
        let normalizedHost = host.replacingOccurrences(of: "^www\\.", with: "", options: .regularExpression)
        
        // Check each candidate
        for (pattern, name) in candidates {
            if link.range(of: pattern, options: .regularExpression) != nil ||
               normalizedHost.range(of: pattern, options: .regularExpression) != nil {
                return name
            }
        }
        
        return "Link"
    }
    
    /// Auto-detect and select stage method from link
    private func autoDetectStageMethod(from link: String) {
        if let linkMethod = allowedMethods.first(where: { $0.method.caseInsensitiveCompare("Link") == .orderedSame }) {
            selectedMethod = linkMethod
        }
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


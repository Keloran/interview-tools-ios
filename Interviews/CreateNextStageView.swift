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
                            ForEach(allMethods, id: \.persistentModelID) { method in
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
                    
                    // Show link field for all methods except "In Person" and "Phone"
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
        let lowercased = method.lowercased()
        // Don't show for "In Person" or "Phone"
        return !lowercased.contains("in person") && !lowercased.contains("phone")
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
        guard let detectedName = inferStageMethodName(from: link) else { return }
        
        // Try to find a matching stage method
        if let matchingMethod = allMethods.first(where: { method in
            method.method.lowercased() == detectedName.lowercased()
        }) {
            selectedMethod = matchingMethod
            print("✅ Auto-detected stage method: \(detectedName)")
        } else {
            // If no exact match found, keep current selection or default to generic video call
            print("⚠️ Detected \(detectedName) but no matching stage method in database")
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

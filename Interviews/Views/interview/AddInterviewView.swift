//
//  AddInterviewView.swift
//  Interviews
//
//  Created by keloran on 05/12/2025.
//

import SwiftUI
import SwiftData
import Clerk

struct AddInterviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.clerk) private var clerk
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
    @State private var hasInitialized = false

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
    
    // Determine if link field should be shown
    private var shouldShowLinkField: Bool {
        guard let method = selectedStageMethod?.method else { return false }
        let lowercased = method.lowercased()
        // Don't show for "In Person" or "Phone"
        return !lowercased.contains("in person") && !lowercased.contains("phone")
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
                    if sortedUniqueStages.isEmpty {
                        Text("No stages available. Please sync first.")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Stage", selection: $selectedStage) {
                            ForEach(sortedUniqueStages, id: \.stage) { stage in
                                Text(stage.stage).tag(stage as Stage?)
                            }
                        }
                        .onChange(of: selectedStage) { oldValue, newValue in
                            // Clear stage method if moving back to Applied or Offer
                            if newValue?.stage == "Applied" || newValue?.stage == "Offer" {
                                selectedStageMethod = nil
                            }
                        }
                        
                        // Debug info
                        if sortedUniqueStages.count == 1 {
                            Text("⚠️ Only \(sortedUniqueStages.count) stage available. Database may need sync.")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }

                Section("Company & Position") {
                    if companies.isEmpty {
                        TextField("Company Name", text: $companyName)
                    } else {
                        Picker("Company", selection: $selectedCompany) {
                            Text("New Company").tag(nil as Company?)
                            ForEach(companies, id: \.persistentModelID) { company in
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

                            if sortedUniqueStageMethods.isEmpty {
                                Text("No interview methods available. Please sync first.")
                                    .foregroundStyle(.secondary)
                            } else {
                                Picker("Method", selection: $selectedStageMethod) {
                                    Text("Select Method").tag(nil as StageMethod?)
                                    ForEach(sortedUniqueStageMethods, id: \.method) { method in
                                        Text(method.method).tag(method as StageMethod?)
                                    }
                                }
                            }

                            // Show link field for all methods except "In Person" and "Phone"
                            if shouldShowLinkField {
                                TextField("Meeting Link", text: $link)
                                    .textContentType(.URL)
                                    .keyboardType(.URL)
                                    .autocapitalization(.none)
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
            .onAppear {
                initializeDefaults()
            }
        }
    }
    
    private func initializeDefaults() {
        // Only set defaults once
        guard !hasInitialized else { return }
        hasInitialized = true
        
        // Check if we need to seed default data (fallback if app init didn't complete)
        if stages.isEmpty || stageMethods.isEmpty {
            print("⚠️ No stages/methods found - triggering fallback seeding")
            DataSeeder.seedDefaultData(context: modelContext)
        }
        
        // Debug: Log what stages we have
        print("📊 Total stages in database: \(stages.count)")
        print("📊 Unique stages after deduplication: \(sortedUniqueStages.count)")
        if !sortedUniqueStages.isEmpty {
            print("📊 Available stages: \(sortedUniqueStages.map { $0.stage }.joined(separator: ", "))")
        }
        
        // Set default stage to "Applied"
        if selectedStage == nil {
            if let appliedStage = sortedUniqueStages.first(where: { $0.stage == "Applied" }) {
                selectedStage = appliedStage
                print("✅ Default stage set to: Applied")
            } else if let firstStage = sortedUniqueStages.first {
                // Fallback to first available stage
                selectedStage = firstStage
                print("⚠️ 'Applied' not found, defaulting to: \(firstStage.stage)")
            } else {
                print("❌ No stages available!")
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
        print("🔵 Starting save interview...")
        
        // Get or create company
        let company: Company
        if let existing = selectedCompany {
            company = existing
            print("✅ Using existing company: \(company.name)")
        } else {
            company = Company(name: companyName)
            modelContext.insert(company)
            print("✅ Created new company: \(company.name)")
            
            // Save company immediately
            do {
                try modelContext.save()
                print("✅ Company saved to database")
            } catch {
                print("❌ Failed to save company: \(error)")
                errorMessage = "Failed to save company: \(error.localizedDescription)"
                showError = true
                return
            }
        }

        // Default to "Applied" stage if none selected
        let stage: Stage
        if let selected = selectedStage {
            stage = selected
            print("✅ Using selected stage: \(stage.stage)")
        } else {
            // Find or create "Applied" stage
            if let appliedStage = stages.first(where: { $0.stage == "Applied" }) {
                stage = appliedStage
                print("✅ Using existing Applied stage")
            } else {
                stage = Stage(stage: "Applied")
                modelContext.insert(stage)
                print("✅ Created new Applied stage")
                
                // Save stage immediately
                do {
                    try modelContext.save()
                    print("✅ Stage saved to database")
                } catch {
                    print("❌ Failed to save stage: \(error)")
                    errorMessage = "Failed to save stage: \(error.localizedDescription)"
                    showError = true
                    return
                }
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

        // Construct metadataJSON to always include 'applied' flag and optionally jobListing if present
        // This ensures we preserve info about whether the interview is at Applied stage even if jobPostingLink is empty
        var metadataDict: [String: Any] = ["applied": selectedStageName == "Applied"]
        if !jobPostingLink.isEmpty {
            metadataDict["jobListing"] = jobPostingLink
        }
        if let jsonData = try? JSONSerialization.data(withJSONObject: metadataDict, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            interview.metadataJSON = jsonString
        }

        print("✅ Created interview: \(company.name) - \(jobTitle)")
        modelContext.insert(interview)

        do {
            // Save immediately to ensure SwiftUI picks up the change
            try modelContext.save()
            print("✅ Successfully saved interview to local database")
            print("   Company: \(company.name)")
            print("   Job Title: \(jobTitle)")
            print("   Stage: \(stage.stage)")
            
            // Only push to API if user is authenticated
            if clerk.user != nil {
                // Keep a reference to the interview to update it after API push
                let savedInterview = interview
                
                // Push to API in background
                Task { @MainActor in
                    await pushToAPI(savedInterview)
                }
            } else {
                print("👋 Guest mode: Interview saved locally only (will sync when user signs in)")
            }
            
            dismiss()
        } catch {
            print("❌ Failed to save interview: \(error)")
            errorMessage = "Failed to save interview: \(error.localizedDescription)"
            showError = true
        }
    }
    
    @MainActor
    private func pushToAPI(_ interview: Interview) async {
        do {
            let syncService = SyncService(modelContext: modelContext)
            let apiInterview = try await syncService.pushInterview(interview)
            
            // Update the interview with the server ID
            // This happens on the main context, so SwiftUI will pick it up immediately
            interview.id = apiInterview.id
            interview.updatedAt = Date()
            try modelContext.save()
            
            print("✅ Successfully pushed interview to server with ID: \(apiInterview.id)")
        } catch {
            print("❌ Failed to push interview to API: \(error)")
            // Note: Interview is still saved locally, will sync later
        }
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
        if let matchingMethod = stageMethods.first(where: { method in
            method.method.lowercased() == detectedName.lowercased()
        }) {
            selectedStageMethod = matchingMethod
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

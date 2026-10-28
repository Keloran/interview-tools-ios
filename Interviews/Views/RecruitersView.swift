//
//  RecruitersView.swift
//  Interviews
//

import SwiftUI

/// Every agency and recruiter you've dealt with, and how they treated you
struct RecruitersView: View {
    @State private var records: [APIRecruiterRecord] = []
    @State private var loaded = false
    @State private var error: String?

    var body: some View {
        List {
            if let error { Text(error).foregroundStyle(.red) }
            ForEach(records) { record in
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.contact?.recruiterName ?? record.agency).font(.headline)
                    if record.contact != nil { Text(record.agency).font(.subheadline).foregroundStyle(.secondary) }
                    Text(RecruiterText.summary(record.stats)).font(.caption).foregroundStyle(.secondary)
                    if let contact = record.contact {
                        HStack {
                            if let email = contact.recruiterEmail, let url = URL(string: "mailto:\(email)") {
                                Link(destination: url) { Label("Email", systemImage: "envelope") }
                            }
                            if let profile = contact.recruiterLinkedIn, let url = URL(string: profile) {
                                Link(destination: url) { Label("LinkedIn", systemImage: "person.crop.square") }
                            }
                        }
                        .font(.caption)
                    }
                }
                .padding(.leading, record.contact == nil ? 0 : 12)
            }
        }
        .overlay {
            if loaded && records.isEmpty && error == nil {
                ContentUnavailableView("No agencies yet", systemImage: "person.2", description: Text("Applications made through a recruiter, or with a client company, show here with each agency's record."))
            }
        }
        .navigationTitle("Recruiters")
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        do { records = try await APIService.shared.fetchRecruiters(); error = nil } catch { self.error = error.localizedDescription }
        loaded = true
    }
}

enum RecruiterText {
    /// "4 roles, ghosted 3", as the website shows it when you pick an agency
    static func short(_ stats: APIRecruiterRecord.Stats) -> String {
        "\(stats.roles) role\(stats.roles == 1 ? "" : "s")" + (stats.ghosted > 0 ? ", ghosted \(stats.ghosted)" : "")
    }

    static func summary(_ stats: APIRecruiterRecord.Stats) -> String {
        var parts = [short(stats)]
        if let rate = stats.responseRate { parts.append("replied \(rate)%") }
        if let rate = stats.feedbackRate { parts.append("feedback \(rate)%") }
        if stats.waiting > 0 { parts.append("\(stats.waiting) waiting") }
        return parts.joined(separator: " · ")
    }

    /// The agency-level record for a company name, if you've applied through them before
    static func record(for company: String, in records: [APIRecruiterRecord]) -> APIRecruiterRecord? {
        let name = company.trimmingCharacters(in: .whitespaces).lowercased()
        guard !name.isEmpty else { return nil }
        return records.first { $0.contact == nil && $0.agency.lowercased() == name }
    }
}

/// Edit who the recruiter is on an application
struct RecruiterContactForm: View {
    let interview: Interview

    @Environment(\.dismiss) private var dismiss
    @State private var contact = RecruiterContactRequest(viaRecruiter: false, recruiterName: "", recruiterEmail: "", recruiterLinkedIn: "")
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Through a recruiter or agency", isOn: $contact.viaRecruiter)
                } footer: {
                    Text("The company is the agency; put the employer they're hiring for in Client Company.")
                }
                if contact.viaRecruiter {
                    Section("Recruiter") {
                        TextField("Name", text: $contact.recruiterName).textContentType(.name)
                        TextField("Email", text: $contact.recruiterEmail).textContentType(.emailAddress).keyboardType(.emailAddress).textInputAutocapitalization(.never)
                        TextField("LinkedIn profile URL", text: $contact.recruiterLinkedIn).keyboardType(.URL).textInputAutocapitalization(.never)
                    }
                }
                if let error { Text(error).foregroundStyle(.red) }
            }
            .navigationTitle("Recruiter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { Task { await save() } } }
            }
            .onAppear {
                contact = RecruiterContactRequest(viaRecruiter: interview.viaRecruiter ?? (interview.clientCompany != nil),
                                                  recruiterName: interview.recruiterName ?? "", recruiterEmail: interview.recruiterEmail ?? "",
                                                  recruiterLinkedIn: interview.recruiterLinkedIn ?? "")
            }
        }
    }

    private func save() async {
        guard let applicationId = interview.applicationId else { return }
        do {
            // The server checks these too (email shape, https linkedin.com); its message is shown if it says no
            try await APIService.shared.saveRecruiterContact(applicationId: applicationId, contact)
            interview.viaRecruiter = contact.viaRecruiter
            interview.recruiterName = contact.viaRecruiter && !contact.recruiterName.isEmpty ? contact.recruiterName : nil
            interview.recruiterEmail = contact.viaRecruiter && !contact.recruiterEmail.isEmpty ? contact.recruiterEmail : nil
            interview.recruiterLinkedIn = contact.viaRecruiter && !contact.recruiterLinkedIn.isEmpty ? contact.recruiterLinkedIn : nil
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

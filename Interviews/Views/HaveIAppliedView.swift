//
//  HaveIAppliedView.swift
//  Interviews
//

import SwiftUI

/// Before you apply: have you already, and does the listing have warning signs?
/// Same matching as the website (POST /api/check): job link, title variants, company and the end client.
struct HaveIAppliedView: View {
    @State private var input = CheckRequest()
    @State private var result: APICheck?
    @State private var checking = false
    @State private var error: String?
    @State private var adding = false

    var body: some View {
        Form {
            Section {
                TextField("Job link", text: $input.link).keyboardType(.URL).textInputAutocapitalization(.never)
                TextField("Job title", text: $input.title)
                TextField("Company or agency", text: $input.company)
                TextField("Client (if it's through an agency)", text: $input.client)
                Button { pasteLink() } label: { Label("Paste link", systemImage: "doc.on.clipboard") }
            } header: {
                Text("The job")
            }
            Section {
                TextField("Paste the job description to check it for warning signs", text: $input.description, axis: .vertical)
                    .lineLimit(3...10)
            } header: {
                Text("Description (optional)")
            }
            Section {
                Button(checking ? "Checking…" : "Check") { Task { await check() } }
                    .disabled(checking || !HaveIApplied.canCheck(input))
            }
            if let error { Text(error).foregroundStyle(.red) }

            if let result {
                Section(HaveIApplied.headline(result)) {
                    ForEach(result.matches) { match in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(match.jobTitle) at \(match.clientCompany ?? match.companyName)").font(.subheadline.weight(.medium))
                            Text(HaveIApplied.detail(match)).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                let employers = HaveIApplied.communityEmployers(result)
                if !employers.isEmpty {
                    Section {
                        ForEach(employers, id: \.id) { CommunityRecordView(employerId: $0.id, name: $0.name) }
                    }
                }
                if !result.flags.isEmpty {
                    Section("Worth knowing") {
                        ForEach(result.flags) { flag in
                            VStack(alignment: .leading, spacing: 2) {
                                Label(flag.title, systemImage: "exclamationmark.triangle").font(.subheadline.weight(.medium)).foregroundStyle(.orange)
                                Text(flag.explanation).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section {
                    Button { adding = true } label: { Label("Add application", systemImage: "plus") }
                }
            }
        }
        .navigationTitle("Have I applied?")
        .sheet(isPresented: $adding) {
            NavigationStack { AddInterviewView(initialDate: Date(), prefill: input) }
        }
    }

    private func pasteLink() {
        guard let text = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        // A link goes in the link field; a longer paste is most likely the description
        if URL(string: text)?.scheme?.hasPrefix("http") == true { input.link = text } else { input.description = text }
    }

    private func check() async {
        checking = true
        defer { checking = false }
        do {
            result = try await APIService.shared.check(input)
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
}

enum HaveIApplied {
    static func canCheck(_ input: CheckRequest) -> Bool {
        [input.link, input.company, input.client].contains { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    static func headline(_ result: APICheck) -> String {
        if result.matches.contains(where: \.samePosting) { return "You've applied for this job" }
        if result.matches.contains(where: \.sameTitle) { return "You've applied for this role there before" }
        if !result.matches.isEmpty { return "You've applied there before" }
        return "No previous applications"
    }

    /// Each confirmed employer once, for its community record
    static func communityEmployers(_ result: APICheck) -> [(id: String, name: String?)] {
        var seen = Set<String>()
        return result.matches.compactMap { match in
            guard let id = match.communityEmployerId, seen.insert(id).inserted else { return nil }
            return (id, match.communityEmployerName)
        }
    }

    static func detail(_ match: APICheck.Match) -> String {
        let applied = APIDates.day(match.applicationDate)?.formatted(date: .abbreviated, time: .omitted)
        return [match.samePosting ? "Same job link" : match.sameTitle ? "Same role" : nil,
                applied.map { "Applied \($0)" }, match.status, match.response == "ghosted" ? "Ghosted" : nil]
            .compactMap { $0 }.joined(separator: " · ")
    }
}

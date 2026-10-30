//
//  CSVImportView.swift
//  Interviews
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Import applications from a spreadsheet: map the columns, preview (nothing saved), then confirm.
/// The website's importer does the work, with its limits and duplicate checks.
struct CSVImportView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var picking = false
    @State private var fileName: String?
    @State private var csv = ""
    @State private var headers: [String] = []
    @State private var mapping = ImportMapping()
    @State private var plan: APIImportPlan?
    @State private var confirming = false
    @State private var working = false
    @State private var message: String?

    var body: some View {
        Form {
            Section {
                Button(fileName ?? "Choose a CSV file") { picking = true }
            } footer: {
                Text("Up to 2 MB. Company, job title and date applied are required; dates as 2026-10-28 or 28/10/2026.")
            }
            if !headers.isEmpty {
                Section("Columns") {
                    ForEach(CSVImport.fields, id: \.key) { field in
                        Picker(field.label, selection: CSVImport.binding(field.key, in: $mapping)) {
                            Text("—").tag(Int?.none)
                            ForEach(headers.indices, id: \.self) { Text(headers[$0]).tag(Int?.some($0)) }
                        }
                    }
                    Button("Preview") { Task { await run(commit: false) } }
                        .disabled(working || !CSVImport.requiredMapped(mapping))
                }
            }
            if let message { Text(message) }
            if let plan {
                Section("Preview") {
                    LabeledContent("Ready to import", value: "\(plan.ready)")
                    LabeledContent("Already recorded (skipped)", value: "\(plan.duplicates)")
                    LabeledContent("Can't import", value: "\(plan.errors)")
                    if plan.imported > 0 { LabeledContent("Imported", value: "\(plan.imported)") }
                    Button("Import \(plan.ready)") { confirming = true }
                        .disabled(working || plan.ready == 0 || plan.imported > 0)
                }
                Section("Rows") {
                    ForEach(plan.rows.filter { $0.status != "ready" }.prefix(200)) { row in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Line \(row.line): \(row.jobTitle) at \(row.company)").font(.subheadline)
                            Text(row.reason.isEmpty ? row.status : row.reason).font(.caption).foregroundStyle(row.status == "error" ? .red : .secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Import CSV")
        .fileImporter(isPresented: $picking, allowedContentTypes: [.commaSeparatedText, .plainText]) { result in load(result) }
        .confirmationDialog("Import \(plan?.ready ?? 0) applications?", isPresented: $confirming, titleVisibility: .visible) {
            Button("Import") { Task { await run(commit: true) } }
        } message: {
            Text("Duplicates are checked again as they're saved.")
        }
    }

    private func load(_ result: Result<URL, Error>) {
        plan = nil
        message = nil
        do {
            let url = try result.get()
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            guard data.count <= CSVImport.maxBytes else { message = "That file is over 2 MB."; return }
            guard let text = String(data: data, encoding: .utf8) else { message = "Save the file as UTF-8 CSV and try again."; return }
            csv = text
            headers = CSVImport.headers(text)
            mapping = CSVImport.guess(headers)
            fileName = url.lastPathComponent
            if headers.isEmpty { message = "The file has no header row." }
        } catch {
            message = error.localizedDescription
        }
    }

    private func run(commit: Bool) async {
        working = true
        defer { working = false }
        do {
            // The file and mapping stay put if this fails, so you can try again
            plan = try await APIService.shared.importCSV(csv, mapping: mapping, commit: commit)
            message = commit ? "Imported \(plan?.imported ?? 0). They'll appear after the sync." : nil
            if commit { await SyncService(modelContext: modelContext).syncAll() }
        } catch {
            message = error.localizedDescription
        }
    }
}

enum CSVImport {
    static let maxBytes = 2 * 1024 * 1024

    static let fields: [(key: WritableKeyPath<ImportMapping, Int?>, label: String, names: [String])] = [
        (\.company, "Company", ["company", "companyname", "employer"]),
        (\.jobTitle, "Job title", ["jobtitle", "title", "role"]),
        (\.applicationDate, "Date applied", ["applicationdate", "dateapplied", "applieddate", "date"]),
        (\.jobPostingLink, "Job link (optional)", ["jobpostinglink", "joblink", "link", "url"]),
        (\.outcome, "Status (optional)", ["outcome", "status"]),
        (\.clientCompany, "Client company (optional)", ["clientcompany", "endclient", "client"]),
    ]

    static func binding(_ key: WritableKeyPath<ImportMapping, Int?>, in mapping: Binding<ImportMapping>) -> Binding<Int?> {
        Binding(get: { mapping.wrappedValue[keyPath: key] }, set: { mapping.wrappedValue[keyPath: key] = $0 })
    }

    static func requiredMapped(_ mapping: ImportMapping) -> Bool {
        mapping.company != nil && mapping.jobTitle != nil && mapping.applicationDate != nil
    }

    /// The website's column guesses (lib/csvImport.ts guessMapping)
    static func guess(_ headers: [String]) -> ImportMapping {
        let keys = headers.map { $0.lowercased().filter { $0.isLetter || $0.isNumber } }
        var mapping = ImportMapping()
        for field in fields {
            mapping[keyPath: field.key] = keys.firstIndex { field.names.contains($0) }
        }
        return mapping
    }

    /// The header row, honouring quotes (a quoted header can contain commas, quotes or line breaks)
    static func headers(_ csv: String) -> [String] {
        var fields: [String] = []
        var field = ""
        var quoted = false
        var chars = Array(csv.hasPrefix("\u{FEFF}") ? String(csv.dropFirst()) : csv)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if quoted {
                if c == "\"" {
                    if i + 1 < chars.count && chars[i + 1] == "\"" { field.append("\""); i += 1 } else { quoted = false }
                } else { field.append(c) }
            } else if c == "\"" {
                quoted = true
            } else if c == "," {
                fields.append(field.trimmingCharacters(in: .whitespaces)); field = ""
            } else if c == "\n" || c == "\r" || c == "\r\n" {
                break
            } else {
                field.append(c)
            }
            i += 1
        }
        chars = []
        fields.append(field.trimmingCharacters(in: .whitespaces))
        return fields == [""] ? [] : fields
    }
}

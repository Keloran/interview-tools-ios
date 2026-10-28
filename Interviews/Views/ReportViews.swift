//
//  ReportViews.swift
//  Interviews
//

import SwiftUI

/// A period to report on, as whole local days
struct ReportPeriod: Equatable {
    var from: Date
    var through: Date

    /// The website's default: the last 90 days including today
    static func lastDays(_ days: Int, now: Date = Date(), calendar: Calendar = .current) -> ReportPeriod {
        let today = calendar.startOfDay(for: now)
        return ReportPeriod(from: calendar.date(byAdding: .day, value: -(days - 1), to: today) ?? today, through: today)
    }

    var fromString: String { APIDates.dayString(from) }
    var throughString: String { APIDates.dayString(through) }
}

private struct PeriodPicker: View {
    @Binding var period: ReportPeriod

    var body: some View {
        DatePicker("From", selection: $period.from, in: ...period.through, displayedComponents: .date)
        DatePicker("Through", selection: $period.through, in: period.from...Date(), displayedComponents: .date)
    }
}

/// How the job search is going, from the website's own report
struct ReportView: View {
    @State private var period = ReportPeriod.lastDays(90)
    @State private var report: APIReport?
    @State private var error: String?

    var body: some View {
        List {
            Section { PeriodPicker(period: $period) }
            if let error { Text(error).foregroundStyle(.red) }
            if let report {
                Section("Funnel") {
                    ForEach(report.funnel, id: \.label) { step in
                        LabeledContent(step.label) {
                            Text(step.conversion.map { "\(step.count) · \($0)%" } ?? "\(step.count)")
                        }
                    }
                }
                Section("Replies") {
                    LabeledContent("Replied", value: ReportText.percent(report.response.responseRate, of: report.response.responded))
                    LabeledContent("Ghosted", value: ReportText.percent(report.response.ghostRate, of: report.response.ghosted))
                    LabeledContent("Still waiting", value: "\(report.response.waiting)")
                    if let days = report.response.medianReplyDays {
                        LabeledContent("Typical reply time", value: ReportText.days(days))
                    }
                }
                Section("Direct vs agencies") {
                    ForEach(report.sources, id: \.source) { source in
                        LabeledContent(source.source, value: "\(source.roles) · replied \(source.responseRate.map { "\($0)%" } ?? "—")")
                    }
                }
                Section("By week") {
                    ForEach(report.weekly.filter { $0.applications + $0.interviews > 0 }, id: \.week) { week in
                        LabeledContent("Week of \(APIDates.day("\(week.week)T00:00:00.000Z")?.formatted(date: .abbreviated, time: .omitted) ?? week.week)",
                                       value: "\(week.applications) applied · \(week.interviews) interviews")
                    }
                }
            }
        }
        .navigationTitle("Job search report")
        .task(id: period) { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        do {
            report = try await APIService.shared.fetchReport(from: period.fromString, through: period.throughString)
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
}

enum ReportText {
    static func percent(_ rate: Int?, of count: Int) -> String {
        rate.map { "\(count) (\($0)%)" } ?? "\(count)"
    }

    static func days(_ days: Double) -> String {
        let rounded = Int(days.rounded())
        return "\(rounded) day\(rounded == 1 ? "" : "s")"
    }
}

/// Everything you did to find work in a period, ready to show a work coach (Universal Credit / JSA)
struct ActivityLogView: View {
    @State private var period = ReportPeriod.lastDays(14)
    @State private var log: APIActivityLog?
    @State private var exportFile: ExportFile?
    @State private var adding = false
    @State private var error: String?

    var body: some View {
        List {
            Section {
                PeriodPicker(period: $period)
            } footer: {
                Text("Applications, interviews, follow-ups and availability you sent, plus anything you add yourself.")
            }
            if let error { Text(error).foregroundStyle(.red) }
            if let log {
                Section("Totals") {
                    LabeledContent("Activities", value: "\(log.totals.total)")
                    LabeledContent("Applied", value: "\(log.totals.applied)")
                    LabeledContent("Interviews / deadlines", value: "\(log.totals.interviews)")
                    LabeledContent("Follow-ups", value: "\(log.totals.followUps)")
                    LabeledContent("Availability sent", value: "\(log.totals.availability)")
                    LabeledContent("Other", value: "\(log.totals.other)")
                }
                Section("Activities") {
                    ForEach(log.rows) { row in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.activity).font(.subheadline.weight(.medium))
                            Text([APIDates.day("\(row.date)T00:00:00.000Z")?.formatted(date: .abbreviated, time: .omitted), row.employer, row.role]
                                .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "))
                                .font(.caption).foregroundStyle(.secondary)
                            if !row.outcome.isEmpty { Text(row.outcome).font(.caption).foregroundStyle(.secondary) }
                        }
                        .deleteDisabled(row.entryId == nil)
                    }
                    .onDelete { offsets in
                        let ids = offsets.compactMap { log.rows[$0].entryId }
                        Task {
                            for id in ids { try? await APIService.shared.deleteActivity(id: id) }
                            await load()
                        }
                    }
                }
            }
        }
        .navigationTitle("Activity log")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button { adding = true } label: { Label("Add activity", systemImage: "plus") }
                    Button { Task { await export() } } label: { Label("Export CSV", systemImage: "square.and.arrow.up") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(item: $exportFile) { ShareSheet(items: [$0.url]) }
        .sheet(isPresented: $adding) { ActivityEntryForm { await load() } }
        .task(id: period) { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        do {
            log = try await APIService.shared.fetchActivityLog(from: period.fromString, through: period.throughString)
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func export() async {
        do {
            let data = try await APIService.shared.exportActivityLog(from: period.fromString, through: period.throughString)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("activity-log-\(period.fromString)-to-\(period.throughString).csv")
            try data.write(to: url, options: .atomic)
            exportFile = ExportFile(url: url)
        } catch {
            self.error = "Couldn't export: \(error.localizedDescription)"
        }
    }
}

private struct ActivityEntryForm: View {
    let onSaved: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var day = Date()
    @State private var entry = ActivityEntryInput(date: "")
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date", selection: $day, in: ...Date(), displayedComponents: .date)
                TextField("What you did, e.g. Careers fair", text: $entry.activity)
                TextField("Employer or organiser", text: $entry.employer)
                TextField("Role", text: $entry.role)
                TextField("How, e.g. In person", text: $entry.how)
                TextField("Outcome", text: $entry.outcome)
                TextField("Notes", text: $entry.notes, axis: .vertical)
                if let error { Text(error).foregroundStyle(.red) }
            }
            .navigationTitle("Add activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        entry.date = APIDates.dayString(day)
                        Task {
                            do {
                                try await APIService.shared.addActivity(entry)
                                await onSaved()
                                dismiss()
                            } catch { self.error = error.localizedDescription }
                        }
                    }
                    .disabled(entry.activity.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

/// The calendar subscription URL, for adding your interviews to any calendar app
struct CalendarFeedRow: View {
    @State private var url: String?
    @State private var copied = false

    var body: some View {
        Group {
            if let url {
                Button {
                    UIPasteboard.general.string = url
                    copied = true
                } label: {
                    LabeledContent("Calendar feed", value: copied ? "Copied" : "Copy link")
                }
            }
        }
        .task { url = try? await APIService.shared.fetchCalendarSettings().calendarUrl }
    }
}

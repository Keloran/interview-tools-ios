//
//  FollowUpsView.swift
//  Interviews
//

import SwiftUI
import SwiftData
import UserNotifications

/// Applications due a chase, with the follow-up message ready to send
struct FollowUpsView: View {
    @State private var due: [APIFollowUp] = []
    @State private var loaded = false
    @State private var error: String?

    var body: some View {
        List {
            if let error { Text(error).foregroundStyle(.red) }
            if loaded && due.isEmpty {
                ContentUnavailableView("Nothing to chase", systemImage: "checkmark.circle", description: Text("Applications show here when it's time to follow up, or when a reply-by date passes."))
            }
            ForEach(due) { item in
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(item.jobTitle) at \(item.clientCompany ?? item.company)").font(.headline)
                    Text(FollowUpText.reason(item)).font(.subheadline).foregroundStyle(.secondary)
                    if let next = item.nextStep { Text("Next step: \(next)").font(.caption).foregroundStyle(.secondary) }
                    HStack {
                        ShareLink(item: FollowUpText.message(item)) {
                            Label("Message", systemImage: "square.and.arrow.up")
                        }
                        Spacer()
                        Button("I've followed up") { Task { await record(item) } }
                            .buttonStyle(.bordered)
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Follow-ups")
        .task { await load() }
        .refreshable { await load() }
    }

    private func record(_ item: APIFollowUp) async {
        do {
            try await APIService.shared.recordFollowUp(applicationId: item.id)
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func load() async {
        do {
            due = try await APIService.shared.fetchFollowUps()
            error = nil
            await FollowUpReminder.schedule(count: due.count)
        } catch {
            self.error = error.localizedDescription
        }
        loaded = true
    }
}

enum FollowUpText {
    static func reason(_ item: APIFollowUp) -> String {
        if let replyBy = APIDates.instant(item.replyBy) {
            return "They said they'd reply by \(replyBy.formatted(date: .abbreviated, time: .omitted))"
        }
        if item.followUps > 0, let last = APIDates.instant(item.lastFollowUp) {
            return "Chased \(item.followUps == 1 ? "once" : "\(item.followUps) times"), last on \(last.formatted(date: .abbreviated, time: .omitted))"
        }
        return item.stage == "Applied" ? "No reply since you applied" : "No word since \(item.stage)"
    }

    static func message(_ item: APIFollowUp) -> String {
        MessageTemplate.followUp.render(.init(jobTitle: item.jobTitle, company: item.company, clientCompany: item.clientCompany,
                                              stage: item.stage, interviewer: item.interviewer, date: APIDates.instant(item.date)))
    }
}

/// One nudge at 9am tomorrow while anything is due; cleared when nothing is
enum FollowUpReminder {
    static let id = "follow-ups-due"

    static func schedule(count: Int) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])
        guard count > 0, (try? await center.requestAuthorization(options: [.alert, .sound])) == true,
              let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()),
              let nine = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) else { return }
        let content = UNMutableNotificationContent()
        content.title = "Time to follow up"
        content.body = count == 1 ? "1 application is due a chase." : "\(count) applications are due a chase."
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nine), repeats: false)
        try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}

/// Applications that have gone quiet: confirm and close them as ghosted
struct NoResponseView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var list: APIStaleList?
    @State private var selected = Set<Int>()
    @State private var confirming = false
    @State private var message: String?

    var body: some View {
        List {
            if let message { Text(message).font(.subheadline) }
            if let list {
                if list.candidates.isEmpty {
                    ContentUnavailableView("Nothing has gone quiet", systemImage: "checkmark.circle", description: Text("Applications with no activity for \(list.days) days show here."))
                } else {
                    Section {
                        ForEach(list.candidates) { candidate in
                            Button {
                                if !selected.insert(candidate.id).inserted { selected.remove(candidate.id) }
                            } label: {
                                HStack {
                                    Image(systemName: selected.contains(candidate.id) ? "checkmark.circle.fill" : "circle")
                                    VStack(alignment: .leading) {
                                        Text("\(candidate.jobTitle) at \(candidate.company)").foregroundStyle(.primary)
                                        Text("\(candidate.lastStage) · quiet for \(candidate.quietDays) days").font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    } footer: {
                        Text("Quiet for \(list.days)+ days. Closing records them as No response (ghosted); you can still change it later.")
                    }
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle("No response")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Close \(selected.count)") { confirming = true }.disabled(selected.isEmpty)
            }
        }
        .confirmationDialog("Close \(selected.count) as ghosted?", isPresented: $confirming, titleVisibility: .visible) {
            Button("Close as no response", role: .destructive) { Task { await close() } }
        }
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        do {
            list = try await APIService.shared.fetchStaleApplications()
            selected.formIntersection(Set(list?.candidates.map(\.id) ?? []))
        } catch {
            message = error.localizedDescription
        }
    }

    private func close() async {
        guard let list else { return }
        do {
            let result = try await APIService.shared.closeStaleApplications(ids: Array(selected), days: list.days)
            message = result.skipped.isEmpty ? "Closed \(result.closed.count)." : "Closed \(result.closed.count). \(result.skipped.count) changed since this list loaded, so they were left open."
            selected = []
            await load()
            await SyncService(modelContext: modelContext).syncAll()
        } catch {
            message = error.localizedDescription
        }
    }
}

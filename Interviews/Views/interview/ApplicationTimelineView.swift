//
//  ApplicationTimelineView.swift
//  Interviews
//

import SwiftUI

/// One application from applying to the latest stage, with follow-ups and availability links, as on the website
struct ApplicationTimelineView: View {
    let applicationId: Int

    @State private var timeline: APITimeline?
    @State private var error: String?

    var body: some View {
        List {
            if let timeline {
                let summary = ApplicationTimeline.summary(timeline)
                Section {
                    LabeledContent("Status", value: summary.outcome)
                    if let days = summary.days {
                        LabeledContent(summary.closed ? "Took" : "So far", value: "\(days) day\(days == 1 ? "" : "s")")
                    }
                } header: {
                    Text("\(timeline.jobTitle) at \(timeline.company.name)")
                } footer: {
                    if let client = timeline.clientCompany { Text("Client: \(client)") }
                }

                Section("Stages") {
                    ForEach(summary.stages, id: \.id) { stage in
                        let when = ApplicationTimeline.stageDate(stage, applied: timeline.applicationDate)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(stage.stage.stage).font(.headline)
                            Text("\(when.label) \(ApplicationTimeline.format(when.date))")
                                .font(.subheadline).foregroundStyle(.secondary)
                            if let outcome = stage.outcome {
                                Text(ApplicationTimeline.outcomeLabel(outcome))
                                    .font(.subheadline)
                                    .foregroundStyle(InterviewOutcome(rawValue: outcome).map(colorForOutcomeInterview) ?? .secondary)
                            }
                        }
                    }
                }

                let activity = ApplicationTimeline.activity(timeline)
                if !activity.isEmpty {
                    Section("Activity") {
                        ForEach(activity) { event in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.title).font(.subheadline.weight(.medium))
                                Text(ApplicationTimeline.format(event.date)).font(.caption).foregroundStyle(.secondary)
                                Text(event.detail).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            } else if let error {
                ContentUnavailableView("Couldn't load the timeline", systemImage: "exclamationmark.icloud", description: Text(error))
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Timeline")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        do {
            timeline = try await APIService.shared.fetchTimeline(applicationId: applicationId)
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
}

/// The website's timeline rules (lib/timeline.ts), so both show the same thing
enum ApplicationTimeline {
    static let terminal: Set<String> = ["REJECTED", "WITHDREW", "OFFER_ACCEPTED", "OFFER_DECLINED", "NO_RESPONSE"]

    static func outcomeLabel(_ outcome: String) -> String {
        outcome == "NO_RESPONSE" ? "No response (closed as ghosted)" : InterviewOutcome(rawValue: outcome)?.displayName ?? outcome
    }

    /// Parents before children whatever the dates say; otherwise oldest first. A malformed cycle is broken once,
    /// keeping every stage.
    static func ordered(_ stages: [APITimeline.Stage]) -> [APITimeline.Stage] {
        var pending = stages.sorted { (APIDates.instant($0.created_at) ?? .distantPast, $0.id) < (APIDates.instant($1.created_at) ?? .distantPast, $1.id) }
        let ids = Set(stages.map(\.id))
        var visited = Set<Int>()
        var result: [APITimeline.Stage] = []
        while !pending.isEmpty {
            let ready = pending.firstIndex { stage in
                guard let parent = stage.parentId else { return true }
                return !ids.contains(parent) || visited.contains(parent)
            } ?? 0
            let stage = pending.remove(at: ready)
            result.append(stage)
            visited.insert(stage.id)
        }
        return result
    }

    static func summary(_ timeline: APITimeline, now: Date = Date()) -> (stages: [APITimeline.Stage], closed: Bool, days: Int?, outcome: String) {
        let stages = ordered(timeline.interviews)
        let latest = stages.last
        let closed = latest?.outcome.map(terminal.contains) ?? false
        let through = closed ? (APIDates.instant(latest?.updated_at) ?? now) : now
        let days = APIDates.day(timeline.applicationDate).flatMap { applied in
            through >= applied ? Calendar.current.dateComponents([.day], from: applied, to: through).day : nil
        }
        return (stages, closed, days, latest?.outcome.map(outcomeLabel) ?? "Awaiting response")
    }

    static func stageDate(_ stage: APITimeline.Stage, applied: String) -> (date: String, label: String) {
        if APIDates.isOffer(stage.stage.stage) { return (stage.deadline ?? stage.created_at, stage.deadline != nil ? "Respond by" : "Offer recorded") }
        if stage.stage.stage == "Applied" { return (applied, "Applied") }
        if let date = stage.date { return (date, "Scheduled for") }
        if let deadline = stage.deadline { return (deadline, "Deadline") }
        return (stage.created_at, "Recorded")
    }

    struct Event: Identifiable, Equatable {
        let id: String
        let date: String
        let title: String
        let detail: String
    }

    static func activity(_ timeline: APITimeline) -> [Event] {
        var events = timeline.followUps.map { Event(id: "follow-up-\($0.id)", date: $0.sentAt, title: "Follow-up recorded", detail: "You recorded that you chased this application.") }
        for link in timeline.availabilityLinks {
            events.append(Event(id: "link-\(link.id)", date: link.created_at, title: "Availability link created", detail: "For \(link.stage.stage)."))
            if let opened = link.firstViewedAt {
                events.append(Event(id: "opened-\(link.id)", date: opened, title: "Availability link first opened", detail: "For \(link.stage.stage). \(link.viewCount) view\(link.viewCount == 1 ? "" : "s")."))
            }
            if let booked = link.bookedSlot {
                events.append(Event(id: "booked-\(link.id)", date: booked, title: "Booked interview slot", detail: "For \(link.stage.stage). This is the interview time, not when it was booked."))
            }
        }
        return events.sorted { (APIDates.instant($0.date) ?? .distantPast, $0.id) < (APIDates.instant($1.date) ?? .distantPast, $1.id) }
    }

    /// Days stay days (UTC-midnight values), real moments show their time
    static func format(_ string: String) -> String {
        guard let date = APIDates.day(string) else { return string }
        let isDay = APIDates.instant(string) != date || Calendar.current.dateComponents([.hour, .minute], from: date) == DateComponents(hour: 0, minute: 0)
        return date.formatted(date: .abbreviated, time: isDay ? .omitted : .shortened)
    }
}

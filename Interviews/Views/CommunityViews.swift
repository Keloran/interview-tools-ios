//
//  CommunityViews.swift
//  Interviews
//

import SwiftUI

/// Opting in (or out) of community sharing, worded as on the website. Separate from private tracking,
/// off by default, and only possible when the server has opened collection.
struct CommunitySharingView: View {
    @State private var state: APICommunityConsent?
    @State private var reviewing = false
    @State private var busy = false
    @State private var message: String?
    @State private var loadFailed = false

    private let notice = URL(string: "https://interviews.tools/privacy/community")!

    var body: some View {
        Form {
            Section {
                Text("Your private tracking works whether sharing is on or off. Contributing is optional.")
                Text("With your agreement, eligible employer outcomes from the past 24 months can contribute to coarse monthly summaries. Each account contributes at most one application per employer. Scores require at least 20 contributors; small outcome groups stay hidden.")
                    .font(.subheadline).foregroundStyle(.secondary)
                Text("Names of people, job titles, salaries, notes, contact details and individual application dates are excluded from public summaries. Sharing can still carry an inference risk; downloaded copies of past summaries cannot be recalled.")
                    .font(.subheadline).foregroundStyle(.secondary)
                Link("Read the community privacy notice", destination: notice)
            }
            Section {
                if loadFailed {
                    Button("Couldn't load sharing settings. Try again") { Task { await load() } }
                } else if let state {
                    Text(Community.status(state)).fontWeight(.medium)
                    if let agreed = state.agreedVersion { Text("Last agreed notice: \(agreed)").font(.caption).foregroundStyle(.secondary) }
                    if state.enabled || state.needsReview || state.purgePending {
                        Button(state.purgePending ? "Retry contribution removal" : "Stop sharing", role: .destructive) { Task { await save(enable: false) } }
                            .disabled(busy)
                    }
                    if Community.canOfferEnable(state) {
                        Button("Review and enable sharing") { reviewing = true }.disabled(busy || !state.canEnable)
                    }
                    if !state.canEnable && !state.enabled && !state.purgePending {
                        Text(state.verified ? "Community sharing is not open yet. Your data remains private." : "Verify your email address before contributing.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                } else {
                    ProgressView()
                }
                if let message { Text(message).font(.subheadline) }
            }
        }
        .navigationTitle("Community sharing")
        .task { await load() }
        .sheet(isPresented: $reviewing) {
            NavigationStack {
                Form {
                    Text("Notice version \(state?.noticeVersion ?? ""). This is a separate choice from using private tracking.").font(.caption)
                    Text("I agree to contribute eligible employer outcomes and known reply times as explained in the community privacy notice. I can stop sharing at any time from this page. Private tracking remains available.")
                    Link("Community privacy notice", destination: notice)
                    Button("I agree — enable sharing") { Task { await save(enable: true) } }.disabled(busy || state?.canEnable != true)
                    if let message { Text(message).foregroundStyle(.red) }
                }
                .navigationTitle("Agree to community sharing")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { reviewing = false }.disabled(busy) } }
            }
        }
    }

    private func load() async {
        do { state = try await APIService.shared.fetchCommunityConsent(); loadFailed = false } catch { loadFailed = true }
    }

    private func save(enable: Bool) async {
        busy = true
        message = nil
        defer { busy = false }
        do {
            // Agreeing sends the exact notice version that was on screen; the server refuses any other
            try await APIService.shared.setCommunityConsent(enable
                ? CommunityConsentRequest(enabled: true, noticeVersion: state?.noticeVersion, confirm: true)
                : CommunityConsentRequest(enabled: false))
            reviewing = false
            message = enable ? "Community sharing enabled." : "Community sharing is off. Your contributions have been removed."
        } catch {
            // Withdrawal can fail part-way; say so rather than claiming it's done
            message = error.localizedDescription
        }
        await load()
    }
}

/// An employer's community record, only from approved summaries and only this month's snapshot
struct CommunityRecordView: View {
    let employerId: String
    let name: String?

    @State private var summary: APICommunitySummary.Summary?
    @State private var loaded = false
    @State private var failed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Community\(name.map { " · \($0)" } ?? "")").font(.caption.weight(.medium))
            Group {
                if failed { Text("Community summary unavailable.") }
                else if !loaded { Text("Checking community summary…") }
                else if let line = summary.flatMap({ Community.recordLine($0) }) {
                    Text(line)
                    Text("Snapshot \(summary!.month) · smallest metric sample \(summary!.sampleBand) accounts. Voluntary reports; small groups and unknown history are omitted.")
                } else { Text("Insufficient community data to show a summary.") }
            }
            .font(.caption).foregroundStyle(.secondary)
        }
        .task {
            do { summary = try await APIService.shared.fetchCommunitySummary(employerId: employerId).summary } catch { failed = true }
            loaded = true
        }
    }
}

enum Community {
    static func status(_ state: APICommunityConsent) -> String {
        if state.purgePending { return "Sharing stopped; removal pending" }
        if state.restricted == true { return "Sharing paused — contribution review required" }
        if state.needsReview { return "Sharing paused — review the updated notice" }
        if state.enabled { return state.collectionPaused == true ? "Sharing on — collection paused" : "Sharing on" }
        return "Sharing off"
    }

    static func canOfferEnable(_ state: APICommunityConsent) -> Bool {
        if state.purgePending || state.restricted == true { return false }
        return !state.enabled || state.needsReview
    }

    /// Only the current month's snapshot is shown; an older one is stale
    static func recordLine(_ summary: APICommunitySummary.Summary, now: Date = Date()) -> String? {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        let month = String(format: "%04d-%02d", utc.component(.year, from: now), utc.component(.month, from: now))
        guard summary.month == month else { return nil }
        let parts = [summary.responseRate.map { "Replied at least once: about \($0)%" },
                     summary.ghostingRate.map { "Closed as No response: about \($0)%" },
                     summary.feedbackRate.map { "Recorded feedback: about \($0)%" },
                     summary.replyTimeBand.map { "Median first reply: \($0)" }].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

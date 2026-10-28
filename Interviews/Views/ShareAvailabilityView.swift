//
//  ShareAvailabilityView.swift
//  Interviews
//

import SwiftUI
import SwiftData

/// Pick free times for the next stage, make a booking link, and send the ready-made message from the phone
struct ShareAvailabilityView: View {
    let interview: Interview

    @Environment(\.dismiss) private var dismiss
    @Query private var interviews: [Interview]
    @Query(sort: \Stage.stage) private var stages: [Stage]

    @State private var stage = ""
    @State private var durationMinutes = 60
    @State private var day = Date()
    @State private var picked = Set<Date>()
    @State private var calendarBusy: [Availability.Busy] = []
    @State private var created: (message: String, linkId: String)?
    @State private var links: APIAvailabilityList?
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                if let created {
                    Section {
                        Text(created.message).font(.callout).textSelection(.enabled)
                        ShareLink(item: created.message) { Label("Send message", systemImage: "square.and.arrow.up") }
                        Button("I've sent it") {
                            Task {
                                try? await APIService.shared.markAvailabilitySent(linkId: created.linkId)
                                await loadLinks()
                                self.created = nil
                            }
                        }
                    } header: {
                        Text("Ready to send")
                    }
                } else {
                    Section("Next stage") {
                        Picker("Stage", selection: $stage) {
                            ForEach(stages.filter { $0.stage != "Applied" }, id: \.stage) { Text($0.stage).tag($0.stage) }
                        }
                        Stepper("Length: \(durationMinutes) min", value: $durationMinutes, in: 15...480, step: 15)
                    }
                    Section {
                        DatePicker("Day", selection: $day, in: Date()..., displayedComponents: .date)
                        let slots = Availability.suggestSlots(day: day, durationMinutes: durationMinutes, busy: busy)
                        if slots.isEmpty {
                            Text("No free times that day").foregroundStyle(.secondary)
                        }
                        ForEach(slots, id: \.self) { slot in
                            Button {
                                if !picked.insert(slot).inserted { picked.remove(slot) }
                            } label: {
                                HStack {
                                    Text(slot.formatted(date: .omitted, time: .shortened)).foregroundStyle(.primary)
                                    Spacer()
                                    if picked.contains(slot) { Image(systemName: "checkmark") }
                                }
                            }
                            .disabled(!picked.contains(slot) && picked.count >= Availability.maxSlots)
                        }
                    } header: {
                        Text("Times you're free")
                    } footer: {
                        Text("Leaves 45 minutes around your other interviews\(calendarBusy.isEmpty ? "" : " and Google Calendar events"), and nothing in the next 30 minutes. \(picked.count) picked, up to \(Availability.maxSlots).")
                    }
                    Section {
                        Button("Create link") { Task { await create() } }
                            .disabled(picked.isEmpty || stage.isEmpty)
                    }
                }

                if let links, !links.links.isEmpty {
                    Section("Links for this job") {
                        ForEach(links.links) { link in
                            LabeledContent(link.stage, value: Self.stateLabel(link))
                        }
                    }
                }
                if let error { Text(error).foregroundStyle(.red) }
            }
            .navigationTitle("Share availability")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .task {
                stage = Self.nextStage(after: interview.stage?.stage, in: stages.map(\.stage)) ?? ""
                await loadLinks()
            }
            .task(id: Calendar.current.startOfDay(for: day)) { await loadCalendarBusy() }
        }
    }

    /// Your scheduled interviews and (if connected) Google Calendar busy times
    private var busy: [Availability.Busy] {
        interviews.compactMap { other in
            guard let start = other.date, other.outcome == nil || other.outcome == .scheduled, !APIDates.isOffer(other.stage?.stage) else { return nil }
            return Availability.Busy(start: start, durationMinutes: other.durationMinutes ?? 60)
        } + calendarBusy
    }

    static func nextStage(after current: String?, in names: [String]) -> String? {
        let choices = names.filter { $0 != "Applied" }
        guard let current, let index = choices.firstIndex(of: current) else { return choices.first }
        return choices.indices.contains(index + 1) ? choices[index + 1] : choices.first
    }

    static func stateLabel(_ link: APIAvailabilityList.Link) -> String {
        switch Availability.state(of: link) {
        case .booked: "Booked \(APIDates.instant(link.bookedSlot)?.formatted(date: .abbreviated, time: .shortened) ?? "")"
        case .opened: "Opened \(link.viewCount)×"
        case .sent: "Sent, not opened yet"
        case .ignored: "Sent a week ago, never opened"
        case .created: "Created, not marked sent"
        }
    }

    private func loadCalendarBusy() async {
        let start = Calendar.current.startOfDay(for: day).addingTimeInterval(-86_400)
        calendarBusy = await APIService.shared.fetchBusy(from: start, to: start.addingTimeInterval(3 * 86_400)).compactMap { busy in
            APIDates.instant(busy.start).map { Availability.Busy(start: $0, durationMinutes: busy.durationMinutes) }
        }
    }

    private func loadLinks() async {
        guard let id = interview.id else { return }
        links = try? await APIService.shared.fetchAvailability(interviewId: id)
    }

    private func create() async {
        guard let id = interview.id else { return }
        do {
            let slots = picked.sorted()
            let link = try await APIService.shared.createAvailability(interviewId: id, stage: stage, durationMinutes: durationMinutes, slots: slots)
            var job = links
            if job == nil { job = try? await APIService.shared.fetchAvailability(interviewId: id) }
            let message = Availability.message(
                jobTitle: job?.jobTitle ?? interview.jobTitle,
                company: job?.company ?? interview.clientCompany ?? interview.company?.name ?? "",
                slots: slots,
                url: "https://interviews.tools\(link.path)"
            )
            created = (message, link.id)
            picked = []
            error = nil
            await loadLinks()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

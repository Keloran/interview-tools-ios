//
//  OffersView.swift
//  Interviews
//

import SwiftUI
import UserNotifications

/// Open offers side by side: respond-by dates, the details to compare, and recording your decision.
/// Private to you; nothing here is shared.
struct OffersView: View {
    @State private var offers: [APIOffer] = []
    @State private var loaded = false
    @State private var error: String?
    @State private var editing: APIOffer?
    @State private var deciding: (offer: APIOffer, decision: InterviewOutcome)?

    var body: some View {
        List {
            if let error {
                Text(error).foregroundStyle(.red)
            }
            if loaded && offers.isEmpty {
                ContentUnavailableView("No open offers", systemImage: "envelope.open", description: Text("When an application reaches the Offer stage, it shows here until you accept or decline."))
            }
            ForEach(offers) { offer in
                Section {
                    deadlineRow(offer)
                    ForEach(APIOffer.details, id: \.key) { detail in
                        LabeledContent(detail.label, value: offer[keyPath: detail.value] ?? "—")
                    }
                    Button("Edit details") { editing = offer }
                    HStack {
                        Button("Accept") { deciding = (offer, .offerAccepted) }
                            .buttonStyle(.borderedProminent)
                        Button("Decline", role: .destructive) { deciding = (offer, .offerDeclined) }
                            .buttonStyle(.bordered)
                    }
                } header: {
                    Text("\(offer.jobTitle) at \(offer.company)")
                } footer: {
                    if let agency = offer.agency { Text("Via \(agency)") }
                }
            }
        }
        .navigationTitle("Offers")
        .task { await load() }
        .refreshable { await load() }
        .sheet(item: $editing) { offer in
            OfferDetailsForm(offer: offer) { await load() }
        }
        .confirmationDialog(
            deciding.map { $0.decision == .offerAccepted ? "Accept \($0.offer.company)'s offer?" : "Decline \($0.offer.company)'s offer?" } ?? "",
            isPresented: Binding(get: { deciding != nil }, set: { if !$0 { deciding = nil } }),
            titleVisibility: .visible
        ) {
            if let deciding {
                Button(deciding.decision == .offerAccepted ? "Accept offer" : "Decline offer", role: deciding.decision == .offerDeclined ? ButtonRole.destructive : nil) {
                    Task { await save { try await APIService.shared.updateOffer(interviewId: deciding.offer.interviewId, decision: deciding.decision) } }
                }
            }
        } message: {
            Text("This records your decision. It doesn't contact the employer.")
        }
    }

    private func deadlineRow(_ offer: APIOffer) -> some View {
        let state = OfferDeadline.state(offer.deadline)
        return DatePickerRow(
            label: state.label,
            urgent: state.remind,
            day: offer.deadline.flatMap { APIDates.day("\($0)T00:00:00.000Z") },
            onChange: { day in
                Task { await save { try await APIService.shared.updateOffer(interviewId: offer.interviewId, deadline: .some(day.map { APIDates.dayString($0) })) } }
            }
        )
    }

    private func save(_ change: () async throws -> Void) async {
        do {
            try await change()
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func load() async {
        do {
            offers = try await APIService.shared.fetchOffers()
            error = nil
            await OfferReminders.schedule(for: offers)
        } catch {
            self.error = error.localizedDescription
        }
        loaded = true
    }
}

/// The respond-by line: a day you can set, change or clear
private struct DatePickerRow: View {
    let label: String
    let urgent: Bool
    let day: Date?
    let onChange: (Date?) -> Void

    @State private var picking = false
    @State private var picked = Date()

    var body: some View {
        HStack {
            Label(label, systemImage: urgent ? "exclamationmark.circle.fill" : "calendar")
                .foregroundStyle(urgent ? .red : .primary)
            Spacer()
            Button(day == nil ? "Set" : "Change") {
                picked = day ?? Date()
                picking = true
            }
            if day != nil {
                Button("Clear", role: .destructive) { onChange(nil) }
            }
        }
        .buttonStyle(.borderless)
        .sheet(isPresented: $picking) {
            NavigationStack {
                DatePicker("Respond by", selection: $picked, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("Cancel") { picking = false } }
                        ToolbarItem(placement: .confirmationAction) { Button("Save") { picking = false; onChange(picked) } }
                    }
            }
            .presentationDetents([.medium, .large])
        }
    }
}

/// Edit the salary and package details for one offer
private struct OfferDetailsForm: View {
    let offer: APIOffer
    let onSaved: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var values: [String: String] = [:]
    @State private var error: String?
    @State private var saving = false

    var body: some View {
        NavigationStack {
            Form {
                ForEach(APIOffer.details, id: \.key) { detail in
                    TextField(detail.label, text: Binding(get: { values[detail.key] ?? "" }, set: { values[detail.key] = $0 }), axis: .vertical)
                }
                if let error { Text(error).foregroundStyle(.red) }
            }
            .navigationTitle(offer.company)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }.disabled(saving)
                }
            }
            .onAppear {
                for detail in APIOffer.details { values[detail.key] = offer[keyPath: detail.value] ?? "" }
            }
        }
    }

    private func save() async {
        saving = true
        defer { saving = false }
        do {
            try await APIService.shared.updateCompensation(interviewId: offer.interviewId, values)
            await onSaved()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

/// The website's respond-by wording (lib/offers.ts offerDeadlineState)
enum OfferDeadline {
    static func state(_ deadline: String?, now: Date = Date(), calendar: Calendar = .current) -> (label: String, remind: Bool) {
        guard let deadline, let due = APIDates.day("\(deadline)T00:00:00.000Z", calendar: calendar) else { return ("No respond-by date", false) }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: due).day ?? 0
        switch days {
        case ..<0: return ("Overdue by \(-days) day\(days == -1 ? "" : "s")", true)
        case 0: return ("Respond today", true)
        case 1: return ("Respond tomorrow", true)
        default: return ("Respond in \(days) days", false)
        }
    }
}

/// A local reminder at 9am the day before each respond-by date, replaced whenever offers load
enum OfferReminders {
    static func reminderDate(for deadline: String, calendar: Calendar = .current) -> Date? {
        guard let due = APIDates.day("\(deadline)T00:00:00.000Z", calendar: calendar),
              let dayBefore = calendar.date(byAdding: .day, value: -1, to: due) else { return nil }
        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: dayBefore)
    }

    static func schedule(for offers: [APIOffer]) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix("offer-") }
        center.removePendingNotificationRequests(withIdentifiers: pending)

        let upcoming = offers.compactMap { offer in
            offer.deadline.flatMap { reminderDate(for: $0) }.flatMap { $0 > Date() ? (offer, $0) : nil }
        }
        guard !upcoming.isEmpty, (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return }
        for (offer, date) in upcoming {
            let content = UNMutableNotificationContent()
            content.title = "Offer from \(offer.company)"
            content.body = "You said you'd respond by tomorrow: \(offer.jobTitle)."
            let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date), repeats: false)
            try? await center.add(UNNotificationRequest(identifier: "offer-\(offer.interviewId)", content: content, trigger: trigger))
        }
    }
}

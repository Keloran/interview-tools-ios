//
//  Availability.swift
//  Interviews
//

import Foundation

/// When you can take an interview without bunching them up: the website's rules (lib/availability.ts).
/// Between two interviews: 30 minutes to get ready plus 15 for overruns. Nothing within 30 minutes of now.
enum Availability {
    static let prepMinutes = 30
    static let gapMinutes = 45
    static let dayStartHour = 9
    static let dayEndHour = 18
    static let maxSlots = 20

    struct Busy: Equatable {
        var start: Date
        var durationMinutes: Int
        var end: Date { start.addingTimeInterval(TimeInterval(durationMinutes * 60)) }
    }

    static func clashes(_ candidate: Busy, _ busy: [Busy]) -> Bool {
        let gap = TimeInterval(gapMinutes * 60)
        return busy.contains { candidate.start < $0.end.addingTimeInterval(gap) && $0.start < candidate.end.addingTimeInterval(gap) }
    }

    /// Free start times on a day, every 30 minutes from 9:00, finishing by 18:00
    static func suggestSlots(day: Date, durationMinutes: Int, busy: [Busy], now: Date = Date(), calendar: Calendar = .current) -> [Date] {
        let midnight = calendar.startOfDay(for: day)
        var slots: [Date] = []
        var minutes = dayStartHour * 60
        while minutes + durationMinutes <= dayEndHour * 60 {
            // Built from the day's own midnight so it stays right across clock changes
            if let start = calendar.date(byAdding: .minute, value: minutes, to: midnight),
               start >= now.addingTimeInterval(TimeInterval(prepMinutes * 60)),
               !clashes(Busy(start: start, durationMinutes: durationMinutes), busy) {
                slots.append(start)
            }
            minutes += 30
        }
        return slots
    }

    enum LinkState: String { case booked, opened, sent, ignored, created }

    /// How far a link got; an unopened one a week after sending is a ghosting signal
    static func state(of link: APIAvailabilityList.Link, now: Date = Date()) -> LinkState {
        if link.bookedSlot != nil { return .booked }
        if link.viewCount > 0 { return .opened }
        guard let sent = APIDates.instant(link.sentAt) else { return .created }
        return now.timeIntervalSince(sent) >= 7 * 86_400 ? .ignored : .sent
    }

    /// The note to paste into a reply, worded as on the website
    static func message(jobTitle: String, company: String, slots: [Date], url: String, timeZone: TimeZone = .current) -> String {
        let label = slots.first.flatMap { timeZone.abbreviation(for: $0) } ?? ""
        let format = Date.FormatStyle(date: .omitted, time: .omitted, timeZone: timeZone)
            .weekday(.wide).day().month(.wide).hour().minute()
        return (["Hi,", "", "Thanks for getting in touch about the \(jobTitle) role at \(company). I'm available at the following times (\(label)):", ""]
            + slots.sorted().map { "- \($0.formatted(format))" }
            + ["", "You can book whichever suits you here: \(url)", "", "Thanks"]).joined(separator: "\n")
    }
}

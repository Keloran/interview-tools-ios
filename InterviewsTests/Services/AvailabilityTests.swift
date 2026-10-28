//
//  AvailabilityTests.swift
//  InterviewsTests
//

import Foundation
import Testing
@testable import Interviews

@MainActor
struct AvailabilityTests {

    private static let london: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }()
    private static func at(_ d: Int, _ h: Int, _ m: Int = 0, month: Int = 11) -> Date {
        london.date(from: DateComponents(year: 2026, month: month, day: d, hour: h, minute: m))!
    }

    @Test("A free day offers 9:00 to 17:00 for an hour-long interview")
    func testFreeDay() {
        let slots = Availability.suggestSlots(day: Self.at(10, 12), durationMinutes: 60, busy: [], now: Self.at(1, 9), calendar: Self.london)
        #expect(slots.first == Self.at(10, 9))
        #expect(slots.last == Self.at(10, 17))
        #expect(slots.count == 17)
    }

    @Test("Keeps 45 minutes either side of another interview")
    func testGapAroundBusy() {
        let busy = [Availability.Busy(start: Self.at(10, 12), durationMinutes: 60)]
        let slots = Availability.suggestSlots(day: Self.at(10, 12), durationMinutes: 60, busy: busy, now: Self.at(1, 9), calendar: Self.london)
        #expect(!slots.contains(Self.at(10, 10, 30))) // would end 11:30, inside 12:00 - 45 min
        #expect(slots.contains(Self.at(10, 10)))       // ends 11:00, 45 before 12:00 is 11:15
        #expect(!slots.contains(Self.at(10, 13, 30)))
        #expect(slots.contains(Self.at(10, 14)))       // 13:00 + 45 = 13:45
    }

    @Test("Nothing within 30 minutes of now")
    func testTooSoon() {
        let slots = Availability.suggestSlots(day: Self.at(10, 12), durationMinutes: 30, busy: [], now: Self.at(10, 10, 10), calendar: Self.london)
        #expect(slots.first == Self.at(10, 11))
    }

    @Test("Slots stay on the hour across the clock change")
    func testDST() {
        let slots = Availability.suggestSlots(day: Self.at(25, 12, month: 10), durationMinutes: 60, busy: [], now: Self.at(1, 9, month: 10), calendar: Self.london)
        #expect(slots.first.map { Self.london.component(.hour, from: $0) } == 9)
    }

    @Test("Link states follow the website")
    func testLinkState() throws {
        func link(_ extra: String, views: Int = 0) throws -> APIAvailabilityList.Link {
            let json = #"{"id": "a", "slots": [], "durationMinutes": 60, "created_at": "2026-10-01T09:00:00Z", "stage": "Technical", "path": "/availability/a""# + ", \"viewCount\": \(views)" + extra + "}"
            return try JSONDecoder().decode(APIAvailabilityList.Link.self, from: Data(json.utf8))
        }
        let now = APIDates.instant("2026-10-20T09:00:00Z")!
        #expect(Availability.state(of: try link(#", "sentAt": null"#), now: now) == .created)
        #expect(Availability.state(of: try link(#", "sentAt": "2026-10-18T09:00:00Z""#), now: now) == .sent)
        #expect(Availability.state(of: try link(#", "sentAt": "2026-10-10T09:00:00Z""#), now: now) == .ignored)
        #expect(Availability.state(of: try link(#", "sentAt": "2026-10-10T09:00:00Z""#, views: 2), now: now) == .opened)
        #expect(Availability.state(of: try link(#", "bookedSlot": "2026-10-25T10:00:00Z""#), now: now) == .booked)
    }

    @Test("The message lists the times and the booking link")
    func testMessage() {
        let text = Availability.message(jobTitle: "iOS Engineer", company: "Acme", slots: [Self.at(10, 14), Self.at(10, 9)], url: "https://interviews.tools/availability/a", timeZone: Self.london.timeZone)
        #expect(text.hasPrefix("Hi,\n\nThanks for getting in touch about the iOS Engineer role at Acme. I'm available at the following times (GMT):"))
        #expect(text.contains("You can book whichever suits you here: https://interviews.tools/availability/a"))
        let lines = text.split(separator: "\n").filter { $0.hasPrefix("- ") }
        #expect(lines.count == 2 && lines[0].contains("9:00")) // sorted, so 9:00 comes before 14:00
    }

    @Test("The next stage follows the current one")
    func testNextStage() {
        let names = ["Applied", "Phone Screen", "First Stage", "Second Stage"]
        #expect(ShareAvailabilityView.nextStage(after: "Phone Screen", in: names) == "First Stage")
        #expect(ShareAvailabilityView.nextStage(after: "Applied", in: names) == "Phone Screen")
    }
}

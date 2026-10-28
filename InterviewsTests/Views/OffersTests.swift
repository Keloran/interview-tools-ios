//
//  OffersTests.swift
//  InterviewsTests
//

import Foundation
import Testing
@testable import Interviews

struct OffersTests {

    private static func london() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }

    private static func at(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12) -> Date {
        london().date(from: DateComponents(year: y, month: m, day: d, hour: h))!
    }

    @Test("Respond-by wording matches the website")
    func testDeadlineState() {
        let now = Self.at(2026, 11, 5)
        let state = { (d: String?) in OfferDeadline.state(d, now: now, calendar: Self.london()) }
        #expect(state(nil).label == "No respond-by date")
        #expect(state("2026-11-03") == ("Overdue by 2 days", true))
        #expect(state("2026-11-04") == ("Overdue by 1 day", true))
        #expect(state("2026-11-05") == ("Respond today", true))
        #expect(state("2026-11-06") == ("Respond tomorrow", true))
        #expect(state("2026-11-12") == ("Respond in 7 days", false))
    }

    @Test("Late in the evening, tomorrow is still tomorrow")
    func testLateEvening() {
        #expect(OfferDeadline.state("2026-11-06", now: Self.at(2026, 11, 5, 23), calendar: Self.london()).label == "Respond tomorrow")
    }

    @Test("The reminder is 9am the day before, across the clock change")
    func testReminderDate() throws {
        let reminder = try #require(OfferReminders.reminderDate(for: "2026-10-26", calendar: Self.london()))
        let parts = Self.london().dateComponents([.year, .month, .day, .hour], from: reminder)
        #expect(parts == DateComponents(year: 2026, month: 10, day: 25, hour: 9))
    }

    @Test("Offers decode from GET /api/offers and compare in the website's order")
    func testDecode() throws {
        let json = #"[{"applicationId": 1, "interviewId": 7, "jobTitle": "iOS Engineer", "company": "Acme", "agency": "Recruit Co", "interviewer": null, "deadline": "2026-11-06", "outcome": "OFFER_RECEIVED", "advertisedSalary": "£60-70k", "offerBase": "£68k"}]"#
        let offers = try JSONDecoder().decode([APIOffer].self, from: Data(json.utf8))
        #expect(offers.first?.id == 7)
        #expect(APIOffer.details.map(\.label).first == "Advertised salary")
        #expect(offers.first.map { $0[keyPath: APIOffer.details[1].value] } == "£68k")
        #expect(offers.first?.offerBonus == nil)
    }
}

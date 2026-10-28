//
//  APIDatesTests.swift
//  InterviewsTests
//

import Foundation
import Testing
@testable import Interviews

struct APIDatesTests {

    private static func calendar(_ zone: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone)!
        return calendar
    }

    @Test("An offer respond-by day stays the same day everywhere", arguments: ["America/New_York", "Europe/London", "Asia/Tokyo", "Pacific/Auckland"])
    func testDayStaysTheSameDay(zone: String) throws {
        let calendar = Self.calendar(zone)
        let day = try #require(APIDates.day("2026-11-06T00:00:00.000Z", calendar: calendar))
        #expect(calendar.dateComponents([.year, .month, .day], from: day) == DateComponents(year: 2026, month: 11, day: 6))
        // ...and goes back to the server as the same day
        #expect(APIDates.dayString(day, calendar: calendar) == "2026-11-06")
    }

    @Test("A day across the UK clock change is still that day")
    func testDayAcrossDST() throws {
        let london = Self.calendar("Europe/London")
        for (string, expected) in [("2026-03-29T00:00:00.000Z", 29), ("2026-10-25T00:00:00Z", 25)] {
            let day = try #require(APIDates.day(string, calendar: london))
            #expect(london.component(.day, from: day) == expected)
        }
    }

    @Test("A real moment (an application made at 23:30 UTC) isn't turned into a day")
    func testMomentStaysAMoment() throws {
        let moment = try #require(APIDates.instant("2026-11-05T23:30:00.000Z"))
        #expect(APIDates.day("2026-11-05T23:30:00.000Z", calendar: Self.calendar("Asia/Tokyo")) == moment)
    }

    @Test("Interview times convert to the local clock")
    func testMeetingInstant() throws {
        let meeting = try #require(APIDates.instant("2026-07-01T13:00:00Z"))
        let newYork = Self.calendar("America/New_York")
        #expect(newYork.component(.hour, from: meeting) == 9)
        #expect(Self.calendar("Europe/London").component(.hour, from: meeting) == 14)
    }

    @Test("Timestamps parse with or without fractional seconds; junk and nil don't")
    func testParsing() {
        #expect(APIDates.instant("2026-01-01T10:00:00Z") != nil)
        #expect(APIDates.instant("2026-01-01T10:00:00.123Z") != nil)
        #expect(APIDates.instant("yesterday") == nil)
        #expect(APIDates.instant(nil) == nil)
        #expect(APIDates.day(nil) == nil)
    }

    @Test("Offers are recognised however the stage is written")
    func testIsOffer() {
        #expect(APIDates.isOffer("Offer"))
        #expect(APIDates.isOffer(" offer "))
        #expect(!APIDates.isOffer("Final Stage"))
        #expect(!APIDates.isOffer(nil))
    }
}

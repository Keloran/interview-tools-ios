//
//  RecruitersTests.swift
//  InterviewsTests
//

import Foundation
import Testing
@testable import Interviews

@MainActor
struct RecruitersTests {

    private static let json = #"""
        [{"key": "agency-1", "agency": "Recruit Co", "contact": null, "applications": [],
          "stats": {"roles": 4, "responded": 1, "ghosted": 3, "waiting": 0, "responseRate": 25, "ghostRate": 75, "feedback": 0, "feedbackNoted": 0, "feedbackRate": null}},
         {"key": "contact-1-sam@recruit.co", "agency": "Recruit Co", "applications": [],
          "contact": {"id": 5, "jobTitle": "x", "recruiterName": "Sam", "recruiterEmail": "sam@recruit.co", "recruiterLinkedIn": null},
          "stats": {"roles": 2, "responded": 0, "ghosted": 2, "waiting": 0, "responseRate": 0, "ghostRate": 100, "feedback": 0, "feedbackNoted": 0, "feedbackRate": null}}]
        """#

    @Test("Records decode from GET /api/recruiters")
    func testDecode() throws {
        let records = try JSONDecoder().decode([APIRecruiterRecord].self, from: Data(Self.json.utf8))
        #expect(records.map(\.id) == ["agency-1", "contact-1-sam@recruit.co"])
        #expect(records[1].contact?.recruiterName == "Sam")
    }

    @Test("The agency's record reads as the website shows it")
    func testWording() throws {
        let records = try JSONDecoder().decode([APIRecruiterRecord].self, from: Data(Self.json.utf8))
        #expect(RecruiterText.short(records[0].stats) == "4 roles, ghosted 3")
        #expect(RecruiterText.summary(records[0].stats) == "4 roles, ghosted 3 · replied 25%")
    }

    @Test("Picking an agency finds its agency-level record, ignoring case")
    func testLookup() throws {
        let records = try JSONDecoder().decode([APIRecruiterRecord].self, from: Data(Self.json.utf8))
        #expect(RecruiterText.record(for: " recruit co ", in: records)?.key == "agency-1")
        #expect(RecruiterText.record(for: "Acme", in: records) == nil)
        #expect(RecruiterText.record(for: "", in: records) == nil)
    }

    @Test("Stages carry the application's recruiter contact")
    func testInterviewDecodesRecruiter() throws {
        let api = try JSONDecoder().decode(APIInterview.self, from: Data(#"{"id": 9, "jobTitle": "x", "company": {"id": 1, "name": "Recruit Co"}, "applicationDate": "2026-01-01T00:00:00Z", "viaRecruiter": true, "recruiterName": "Sam"}"#.utf8))
        #expect(api.viaRecruiter == true && api.recruiterName == "Sam" && api.recruiterEmail == nil)
    }
}

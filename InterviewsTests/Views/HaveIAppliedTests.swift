//
//  HaveIAppliedTests.swift
//  InterviewsTests
//

import Foundation
import Testing
@testable import Interviews

@MainActor
struct HaveIAppliedTests {

    private static func result(_ matches: String) throws -> APICheck {
        try JSONDecoder().decode(APICheck.self, from: Data(("{\"matches\": " + matches + #", "flags": [{"id": "ghosted", "title": "Previous applications went unanswered", "explanation": "1 matching application is recorded as ghosted."}]}"#).utf8))
    }
    private static func match(_ id: Int, samePosting: Bool = false, sameTitle: Bool = false, response: String = "responded") -> String {
        #"{"id": \#(id), "companyName": "Recruit Co", "jobTitle": "iOS Engineer", "clientCompany": "Acme", "applicationDate": "2026-09-01T00:00:00.000Z", "status": "Applied", "response": "\#(response)", "sameTitle": \#(sameTitle), "samePosting": \#(samePosting)}"#
    }

    @Test("The headline says how close a previous application was")
    func testHeadline() throws {
        #expect(HaveIApplied.headline(try Self.result("[]")) == "No previous applications")
        #expect(HaveIApplied.headline(try Self.result("[\(Self.match(1))]")) == "You've applied there before")
        #expect(HaveIApplied.headline(try Self.result("[\(Self.match(1)), \(Self.match(2, sameTitle: true))]")) == "You've applied for this role there before")
        #expect(HaveIApplied.headline(try Self.result("[\(Self.match(1, samePosting: true))]")) == "You've applied for this job")
    }

    @Test("Each match explains itself")
    func testDetail() throws {
        let check = try Self.result("[\(Self.match(1, samePosting: true, response: "ghosted"))]")
        let detail = HaveIApplied.detail(check.matches[0])
        #expect(detail.hasPrefix("Same job link · Applied "))
        #expect(detail.hasSuffix("· Applied · Ghosted"))
        #expect(check.flags.first?.id == "ghosted")
    }

    @Test("A check needs a link, a company or a client")
    func testCanCheck() {
        #expect(!HaveIApplied.canCheck(CheckRequest(title: "iOS Engineer")))
        #expect(HaveIApplied.canCheck(CheckRequest(company: "Acme")))
        #expect(HaveIApplied.canCheck(CheckRequest(link: "https://jobs.example.com/1")))
    }
}

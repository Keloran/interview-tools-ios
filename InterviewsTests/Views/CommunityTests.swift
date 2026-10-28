//
//  CommunityTests.swift
//  InterviewsTests
//

import Foundation
import Testing
@testable import Interviews

@MainActor
struct CommunityTests {

    private static func state(_ overrides: [String: Any] = [:]) throws -> APICommunityConsent {
        let base: [String: Any] = ["enabled": false, "needsReview": false, "purgePending": false, "canEnable": false, "verified": true, "noticeVersion": "2026-10-28-v1"]
        let json = try JSONSerialization.data(withJSONObject: base.merging(overrides) { $1 })
        return try JSONDecoder().decode(APICommunityConsent.self, from: json)
    }

    @Test("Off by default, and can't be enabled while the server has collection closed")
    func testDefaultOff() throws {
        let closed = try Self.state(["collectionPaused": true])
        #expect(Community.status(closed) == "Sharing off")
        #expect(Community.canOfferEnable(closed) && !closed.canEnable) // the button shows, disabled
    }

    @Test("Each state reads as on the website")
    func testStatuses() throws {
        #expect(Community.status(try Self.state(["purgePending": true])) == "Sharing stopped; removal pending")
        #expect(!Community.canOfferEnable(try Self.state(["purgePending": true])))
        #expect(Community.status(try Self.state(["restricted": true])) == "Sharing paused — contribution review required")
        #expect(!Community.canOfferEnable(try Self.state(["restricted": true])))
        #expect(Community.status(try Self.state(["enabled": true, "needsReview": true])) == "Sharing paused — review the updated notice")
        #expect(Community.canOfferEnable(try Self.state(["needsReview": true])))
        #expect(Community.status(try Self.state(["enabled": true])) == "Sharing on")
        #expect(Community.status(try Self.state(["enabled": true, "collectionPaused": true])) == "Sharing on — collection paused")
    }

    @Test("Agreeing sends the shown notice version and a confirm; stopping sends neither")
    func testRequests() throws {
        let on = try JSONSerialization.jsonObject(with: JSONEncoder().encode(CommunityConsentRequest(enabled: true, noticeVersion: "2026-10-28-v1", confirm: true))) as? [String: Any]
        #expect(on?["noticeVersion"] as? String == "2026-10-28-v1" && on?["confirm"] as? Bool == true)
        let off = try JSONSerialization.jsonObject(with: JSONEncoder().encode(CommunityConsentRequest(enabled: false))) as? [String: Any]
        #expect(off?.keys.sorted() == ["enabled"])
    }

    @Test("Only this month's snapshot is shown; suppressed or stale stays generic")
    func testRecordLine() throws {
        let now = ISO8601DateFormatter().date(from: "2026-10-28T12:00:00Z")!
        let current = try JSONDecoder().decode(APICommunitySummary.self, from: Data(#"{"summary": {"month": "2026-10", "sampleBand": "20–49", "responseRate": 60, "ghostingRate": null, "feedbackRate": 30, "replyTimeBand": "8–14 days"}}"#.utf8))
        #expect(Community.recordLine(current.summary!, now: now) == "Replied at least once: about 60% · Recorded feedback: about 30% · Median first reply: 8–14 days")
        let stale = try JSONDecoder().decode(APICommunitySummary.self, from: Data(#"{"summary": {"month": "2026-09", "sampleBand": "20–49", "responseRate": 60, "ghostingRate": null, "feedbackRate": null, "replyTimeBand": null}}"#.utf8))
        #expect(Community.recordLine(stale.summary!, now: now) == nil)
        let suppressed = try JSONDecoder().decode(APICommunitySummary.self, from: Data(#"{"summary": null}"#.utf8))
        #expect(suppressed.summary == nil)
    }
}

//
//  ApplicationTimelineTests.swift
//  InterviewsTests
//

import Foundation
import Testing
import SwiftData
@testable import Interviews

struct ApplicationTimelineTests {

    // The shape GET /api/applications/{id}/timeline returns
    private static func timeline(stages: String, followUps: String = "[]", links: String = "[]") throws -> APITimeline {
        let json = """
        {"id": 3, "jobTitle": "iOS Engineer", "clientCompany": null, "applicationDate": "2026-10-01T00:00:00.000Z",
         "company": {"name": "Apple"}, "interviews": \(stages), "followUps": \(followUps), "availabilityLinks": \(links)}
        """
        return try JSONDecoder().decode(APITimeline.self, from: Data(json.utf8))
    }

    private static func stage(_ id: Int, parent: Int?, name: String, created: String, outcome: String? = nil, date: String? = nil, deadline: String? = nil) -> String {
        let q = { (v: String?) in v.map { "\"\($0)\"" } ?? "null" }
        return """
        {"id": \(id), "parentId": \(parent.map(String.init) ?? "null"), "date": \(q(date)), "deadline": \(q(deadline)),
         "created_at": "\(created)", "updated_at": "2026-10-20T10:00:00.000Z", "outcome": \(q(outcome)), "interviewer": null,
         "stage": {"stage": "\(name)"}}
        """
    }

    @Test("Stages run parent first even when a child was recorded earlier")
    func testParentsFirst() throws {
        let t = try Self.timeline(stages: "[\(Self.stage(2, parent: 1, name: "Technical", created: "2026-10-02T00:00:00Z")), \(Self.stage(1, parent: nil, name: "Applied", created: "2026-10-05T00:00:00Z"))]")
        #expect(ApplicationTimeline.ordered(t.interviews).map(\.id) == [1, 2])
    }

    @Test("A malformed cycle still shows every stage once")
    func testCycle() throws {
        let t = try Self.timeline(stages: "[\(Self.stage(1, parent: 2, name: "A", created: "2026-10-01T00:00:00Z")), \(Self.stage(2, parent: 1, name: "B", created: "2026-10-02T00:00:00Z"))]")
        #expect(ApplicationTimeline.ordered(t.interviews).map(\.id) == [1, 2])
    }

    @Test("A rejected application is closed and counts days up to the rejection")
    func testSummaryClosed() throws {
        let t = try Self.timeline(stages: "[\(Self.stage(1, parent: nil, name: "Applied", created: "2026-10-01T00:00:00Z", outcome: "REJECTED"))]")
        let summary = ApplicationTimeline.summary(t)
        #expect(summary.closed)
        #expect(summary.outcome == "Rejected")
        #expect(summary.days == 19)
    }

    @Test("Ghosted applications read as closed as ghosted")
    func testGhostedLabel() {
        #expect(ApplicationTimeline.outcomeLabel("NO_RESPONSE") == "No response (closed as ghosted)")
        #expect(ApplicationTimeline.outcomeLabel("SOMETHING_NEW") == "SOMETHING_NEW")
    }

    @Test("Each kind of stage shows the right date")
    func testStageDates() throws {
        let t = try Self.timeline(stages: "[\(Self.stage(1, parent: nil, name: "Offer", created: "2026-10-10T09:00:00Z", deadline: "2026-11-06T00:00:00.000Z")), \(Self.stage(2, parent: nil, name: "Technical", created: "2026-10-03T00:00:00Z", date: "2026-10-08T14:00:00Z"))]")
        let offer = ApplicationTimeline.stageDate(t.interviews[0], applied: t.applicationDate)
        #expect(offer.label == "Respond by" && offer.date == "2026-11-06T00:00:00.000Z")
        #expect(ApplicationTimeline.stageDate(t.interviews[1], applied: t.applicationDate).label == "Scheduled for")
    }

    @Test("Follow-ups and link events come in date order")
    func testActivity() throws {
        let t = try Self.timeline(
            stages: "[]",
            followUps: #"[{"id": 1, "sentAt": "2026-10-12T09:00:00Z"}]"#,
            links: #"[{"id": 4, "created_at": "2026-10-05T09:00:00Z", "bookedSlot": "2026-10-15T10:00:00Z", "viewCount": 2, "firstViewedAt": "2026-10-06T09:00:00Z", "stage": {"stage": "Technical"}}]"#
        )
        #expect(ApplicationTimeline.activity(t).map(\.id) == ["link-4", "opened-4", "follow-up-1", "booked-4"])
    }

    @Test("Stages carry their application id and length from the API")
    func testInterviewDecodesApplication() throws {
        let json = #"{"id": 9, "jobTitle": "x", "company": {"id": 1, "name": "Co"}, "applicationDate": "2026-01-01T00:00:00Z", "applicationId": 3, "durationMinutes": 45}"#
        let api = try JSONDecoder().decode(APIInterview.self, from: Data(json.utf8))
        #expect(api.applicationId == 3 && api.durationMinutes == 45)
    }

    @Test @MainActor func testEditSendsJobLinkAndLength() throws {
        let container = try ModelContainer(for: AccountStore.schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
        let interview = Interview(id: 5, jobTitle: "x", applicationDate: Date())
        container.mainContext.insert(interview)
        interview.durationMinutes = 45

        let sync = SyncService(modelContext: container.mainContext)
        var body = try JSONSerialization.jsonObject(with: JSONEncoder().encode(sync.updateRequest(for: interview))) as? [String: Any]
        #expect(body?["durationMinutes"] as? Int == 45)
        #expect((body?["metadata"] as? [String: Any])?["jobListing"] is NSNull) // cleared link is sent as cleared

        interview.jobListing = "https://jobs.example.com/1"
        body = try JSONSerialization.jsonObject(with: JSONEncoder().encode(sync.updateRequest(for: interview))) as? [String: Any]
        #expect((body?["metadata"] as? [String: Any])?["jobListing"] as? String == "https://jobs.example.com/1")
    }
}

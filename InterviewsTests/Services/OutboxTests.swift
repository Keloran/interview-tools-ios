//
//  OutboxTests.swift
//  InterviewsTests
//

import Foundation
import Testing
import SwiftData
@testable import Interviews

@MainActor
struct OutboxTests {

    private struct Offline: Error {}

    private static func api(_ id: Int, title: String = "iOS Engineer", stage: String = "Applied", date: String? = nil) throws -> APIInterview {
        let dateJSON = date.map { "\"\($0)\"" } ?? "null"
        let json = """
        {"id": \(id), "jobTitle": "\(title)", "company": {"id": 1, "name": "Apple"}, "stage": {"id": 1, "stage": "\(stage)"},
         "applicationDate": "2026-01-01T00:00:00.000Z", "date": \(dateJSON)}
        """
        return try JSONDecoder().decode(APIInterview.self, from: Data(json.utf8))
    }

    @MainActor
    private struct Fixture {
        let container: ModelContainer
        let company = Company(id: 1, name: "Apple")
        let stage = Stage(id: 1, stage: "Applied")
        var context: ModelContext { container.mainContext }
    }

    private static func setup() throws -> Fixture {
        let fixture = Fixture(container: try ModelContainer(for: AccountStore.schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]))
        fixture.context.insert(fixture.company)
        fixture.context.insert(fixture.stage)
        try fixture.context.save()
        return fixture
    }

    @Test("A failed save stays queued with its reason, and the retry sends it")
    func testFailedPutIsRetried() async throws {
        let f = try Self.setup()
        let (context, company, stage) = (f.context, f.company, f.stage)
        let interview = Interview(id: 5, company: company, jobTitle: "iOS Engineer", applicationDate: Date(), stage: stage)
        context.insert(interview)
        interview.outcome = .rejected
        interview.markChanged()
        try context.save()

        let sync = SyncService(modelContext: context)
        sync.sendUpdate = { _, _ in throw APIError.serverError("Internal Server Error") }
        await sync.pushPending()
        #expect(interview.pendingSince != nil)
        #expect(interview.syncError == "Server error: Internal Server Error")

        var sent: UpdateInterviewRequest?
        sync.sendUpdate = { id, request in sent = request; return try Self.api(id) }
        await sync.pushPending()
        #expect(sent?.outcome == "REJECTED")
        #expect(interview.pendingSince == nil)
        #expect(interview.syncError == nil)
    }

    @Test("A refresh never overwrites or deletes an unsent edit")
    func testPullKeepsPendingEdits() async throws {
        let f = try Self.setup()
        let (context, company, stage) = (f.context, f.company, f.stage)
        let edited = Interview(id: 5, company: company, jobTitle: "Edited offline", applicationDate: Date(), stage: stage)
        let removed = Interview(id: 6, company: company, jobTitle: "Removed on the web", applicationDate: Date(), stage: stage)
        let pendingButGone = Interview(id: 7, company: company, jobTitle: "Edited, then removed on the web", applicationDate: Date(), stage: stage)
        [edited, removed, pendingButGone].forEach { context.insert($0) }
        edited.markChanged()
        pendingButGone.markChanged()
        try context.save()

        try SyncService(modelContext: context).apply([try Self.api(5, title: "Old server title")])

        let titles = Set(try context.fetch(FetchDescriptor<Interview>()).map(\.jobTitle))
        #expect(titles == ["Edited offline", "Edited, then removed on the web"])
    }

    @Test("An edit made while a save is in flight stays queued")
    func testEditDuringFlightStaysPending() async throws {
        let f = try Self.setup()
        let (context, company, stage) = (f.context, f.company, f.stage)
        let interview = Interview(id: 5, company: company, jobTitle: "iOS Engineer", applicationDate: Date(), stage: stage)
        context.insert(interview)
        interview.markChanged()
        try context.save()

        let sync = SyncService(modelContext: context)
        sync.sendUpdate = { id, _ in
            interview.notes = "typed while saving"
            interview.pendingSince = Date().addingTimeInterval(1)
            return try Self.api(id)
        }
        await sync.pushPending()
        #expect(interview.pendingSince != nil)
    }

    @Test("A create with no answer isn't sent twice; the next full sync adopts the server's copy")
    func testUncertainCreateIsMatchedNotResent() async throws {
        let f = try Self.setup()
        let (context, company, stage) = (f.context, f.company, f.stage)
        let interview = Interview(company: company, jobTitle: "iOS Engineer", applicationDate: Date(), stage: stage)
        context.insert(interview)
        try context.save()

        let sync = SyncService(modelContext: context)
        var creates = 0
        sync.sendCreate = { _ in creates += 1; throw URLError(.timedOut) }
        await sync.pushPending()
        await sync.pushPending()
        #expect(creates == 1)
        #expect(interview.createUncertain == true)

        try sync.apply([try Self.api(42)])
        #expect(interview.id == 42)
        #expect(interview.createUncertain == nil)
        #expect(try context.fetch(FetchDescriptor<Interview>()).count == 1)
    }

    @Test("A create with no answer that the server doesn't have is sent again")
    func testUncertainCreateNotOnServerIsRetried() async throws {
        let f = try Self.setup()
        let (context, company, stage) = (f.context, f.company, f.stage)
        let interview = Interview(company: company, jobTitle: "iOS Engineer", applicationDate: Date(), stage: stage)
        context.insert(interview)
        interview.createUncertain = true
        try context.save()

        let sync = SyncService(modelContext: context)
        try sync.apply([])
        #expect(interview.createUncertain == nil)

        sync.sendCreate = { _ in try Self.api(43) }
        await sync.pushPending()
        #expect(interview.id == 43)
    }

    @Test("Cleared fields are sent as cleared, not left out")
    func testClearedFieldsAreSent() throws {
        let f = try Self.setup()
        let (context, company, stage) = (f.context, f.company, f.stage)
        let interview = Interview(id: 5, company: company, jobTitle: "Renamed", applicationDate: Date(), stage: stage)
        context.insert(interview)

        let request = SyncService(modelContext: context).updateRequest(for: interview)
        let body = try JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any]
        #expect(body?["jobTitle"] as? String == "Renamed")
        #expect(body?["notes"] as? String == "")
        for key in ["date", "deadline", "interviewer", "link", "clientCompany"] {
            #expect(body?[key] is NSNull, "\(key) should be sent as null")
        }
        #expect(body?["outcome"] == nil) // unknown or unset outcomes are never overwritten
    }

    @Test("An offer's respond-by goes up as the local day, both on create and on edit")
    func testOfferDeadlineIsSentAsADay() throws {
        let f = try Self.setup()
        let offer = Stage(id: 2, stage: "Offer")
        f.context.insert(offer)
        var parts = DateComponents(year: 2026, month: 11, day: 6)
        let respondBy = try #require(Calendar.current.date(from: parts))
        parts.hour = 0
        let interview = Interview(id: 5, company: f.company, jobTitle: "iOS Engineer", applicationDate: Date(), stage: offer, deadline: respondBy)
        f.context.insert(interview)

        let sync = SyncService(modelContext: f.context)
        #expect(sync.updateRequest(for: interview).deadline == "2026-11-06")
        let create = try sync.createRequest(for: interview)
        #expect(create.offerDeadline == "2026-11-06")
        #expect(create.deadline == nil)
    }
}

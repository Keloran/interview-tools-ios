//
//  AfterInterviewTests.swift
//  InterviewsTests
//

import Foundation
import Testing
@testable import Interviews

struct AfterInterviewTests {

    @Test("The debrief nudge comes half an hour after the interview ends")
    func testReminderTime() {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        #expect(DebriefReminders.reminderDate(start: start, durationMinutes: nil) == start.addingTimeInterval(90 * 60))
        #expect(DebriefReminders.reminderDate(start: start, durationMinutes: 45) == start.addingTimeInterval(75 * 60))
    }

    @Test("Saving a debrief never sends prepNotes, so preparation isn't wiped")
    func testDebriefLeavesPrepAlone() throws {
        let request = DebriefRequest(
            debrief: .init(rating: 4, debriefNotes: "Went well", peopleMet: "", questionsAsked: "Tell me about a conflict", nextStep: "Final", replyBy: "2026-11-06T00:00:00.000Z"),
            feedback: .init(type: "SPECIFIC", text: "More system design")
        )
        let body = try JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any]
        let debrief = body?["debrief"] as? [String: Any]
        #expect(debrief?["rating"] as? Int == 4)
        #expect(debrief?["prepNotes"] == nil)
        #expect((body?["feedback"] as? [String: Any])?["type"] as? String == "SPECIFIC")
    }

    @Test("Question search covers questions, company, stage and notes")
    func testQuestionSearch() throws {
        let json = #"""
            [{"interviewId": 1, "company": "Acme", "recruiter": null, "stage": "Technical", "date": "2026-10-01T10:00:00Z", "jobTitle": "iOS", "questions": ["Tell me about a conflict"], "notes": null},
            {"interviewId": 2, "company": "Beta", "recruiter": "Recruit Co", "stage": "Final", "date": "2026-10-02T10:00:00Z", "jobTitle": "iOS", "questions": ["Why us?"], "notes": "Panel of three"}]
            """#
        let entries = try JSONDecoder().decode([APIQuestionEntry].self, from: Data(json.utf8))
        #expect(QuestionBank.filter(entries, search: "").count == 2)
        #expect(QuestionBank.filter(entries, search: "CONFLICT").map(\.id) == [1])
        #expect(QuestionBank.filter(entries, search: "recruit co").map(\.id) == [2])
        #expect(QuestionBank.filter(entries, search: "panel").map(\.id) == [2])
    }

    @Test("Stories decode from GET /api/stories")
    func testStoryDecode() throws {
        let json = #"[{"id": 3, "title": "Shipped under pressure", "situation": "s", "task": "t", "action": "a", "result": "r", "tags": ["delivery"], "usedIn": [{"interviewId": 9, "company": "Acme", "stage": "Final"}]}]"#
        let stories = try JSONDecoder().decode([APIStory].self, from: Data(json.utf8))
        #expect(stories.first?.usedIn.first?.company == "Acme")
    }
}

//
//  ReportTests.swift
//  InterviewsTests
//

import Foundation
import Testing
@testable import Interviews

@MainActor
struct ReportTests {

    @Test("The default period is the last 90 days including today")
    func testDefaultPeriod() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 28, hour: 23))!
        let period = ReportPeriod.lastDays(90, now: now, calendar: calendar)
        #expect(APIDates.dayString(period.through, calendar: calendar) == "2026-10-28")
        #expect(APIDates.dayString(period.from, calendar: calendar) == "2026-07-31")
    }

    @Test("Report decodes from /api/report/summary")
    func testReportDecodes() throws {
        let json = #"{"from": "2026-10-01", "through": "2026-10-28",
          "funnel": [{"label": "Applied", "count": 10, "conversion": null}, {"label": "Heard back", "count": 4, "conversion": 40}],
          "response": {"roles": 10, "responded": 4, "ghosted": 3, "waiting": 3, "responseRate": 57, "ghostRate": 43, "feedback": 1, "feedbackNoted": 2, "feedbackRate": 50, "medianReplyDays": 4.5, "replyDates": 4, "furthestStage": "Final", "ignoredLinks": 0},
          "weekly": [{"week": "2026-09-28", "applications": 3, "interviews": 1}],
          "sources": [{"source": "Direct", "roles": 6, "responseRate": 60, "ghostRate": 40}, {"source": "Recruiter / agency", "roles": 4, "responseRate": null, "ghostRate": null}]}"#
        let report = try JSONDecoder().decode(APIReport.self, from: Data(json.utf8))
        #expect(report.funnel[1].conversion == 40)
        #expect(ReportText.percent(report.response.responseRate, of: report.response.responded) == "4 (57%)")
        #expect(ReportText.days(report.response.medianReplyDays!) == "5 days" || ReportText.days(report.response.medianReplyDays!) == "4 days")
        #expect(report.sources[1].responseRate == nil)
    }

    @Test("Only your own entries can be deleted from the log")
    func testEntryIds() throws {
        let json = #"{"from": "2026-10-01", "through": "2026-10-14", "totals": {"total": 2, "applied": 1, "interviews": 0, "followUps": 0, "availability": 0, "other": 1},
          "rows": [{"id": "applied-3", "date": "2026-10-02", "kind": "applied", "activity": "Applied", "employer": "Acme", "role": "iOS", "how": "Online", "outcome": "Applied", "notes": ""},
                   {"id": "entry-12", "date": "2026-10-05", "kind": "other", "activity": "Careers fair", "employer": "", "role": "", "how": "In person", "outcome": "", "notes": ""}]}"#
        let log = try JSONDecoder().decode(APIActivityLog.self, from: Data(json.utf8))
        #expect(log.rows.map(\.entryId) == [nil, 12])
    }

    @Test("A new activity is sent as the website expects")
    func testEntryEncoding() throws {
        let body = try JSONSerialization.jsonObject(with: JSONEncoder().encode(ActivityEntryInput(date: "2026-10-05", activity: "Jobcentre appointment"))) as? [String: Any]
        #expect(body?["date"] as? String == "2026-10-05")
        #expect(body?["activity"] as? String == "Jobcentre appointment")
        #expect(body?["employer"] as? String == "")
    }
}

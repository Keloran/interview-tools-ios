//
//  MessageTemplateTests.swift
//  InterviewsTests
//

import Foundation
import Testing
@testable import Interviews

struct MessageTemplateTests {

    private static let date = Date(timeIntervalSince1970: 1_772_524_800) // Tuesday 3 March 2026
    private static func ctx(client: String? = nil, stage: String? = "Technical", interviewer: String? = "Sam Jones") -> MessageTemplate.Context {
        .init(jobTitle: "iOS Engineer", company: "Recruit Co", clientCompany: client, stage: stage, interviewer: interviewer, date: date, formatDate: { _ in "Tuesday 3 March" })
    }

    @Test("Thank-you matches the website word for word")
    func testThankYou() {
        #expect(MessageTemplate.thankYou.render(Self.ctx()) == """
        Hi Sam,

        Thank you for taking the time to speak with me in my Technical interview on Tuesday 3 March about the iOS Engineer role at Recruit Co. I enjoyed our conversation and learning more about the team.

        I'm very interested in the role and look forward to hearing about next steps.

        Thanks
        """)
    }

    @Test("Through an agency it's about the client's role; no interviewer means a plain greeting")
    func testAgencyAndGreeting() {
        let text = MessageTemplate.followUp.render(Self.ctx(client: "Acme", stage: "Applied", interviewer: nil))
        #expect(text.hasPrefix("Hi,\n\nI wanted to follow up on my application for the iOS Engineer role with Acme."))
    }

    @Test("Only the messages that fit where the application is")
    func testWhichTemplates() {
        let past = Date().addingTimeInterval(-3600), future = Date().addingTimeInterval(3600)
        #expect(MessageTemplate.templates(outcome: "NO_RESPONSE", stage: "Technical", date: past).isEmpty)
        #expect(MessageTemplate.templates(outcome: "REJECTED", stage: "Technical", date: past) == [.askFeedback])
        #expect(MessageTemplate.templates(outcome: "OFFER_RECEIVED", stage: "Offer", date: nil) == [.acceptOffer, .declineOffer])
        #expect(MessageTemplate.templates(outcome: "SCHEDULED", stage: "Technical", date: past) == [.thankYou, .followUp, .withdraw])
        #expect(MessageTemplate.templates(outcome: "SCHEDULED", stage: "Technical", date: future) == [.followUp, .withdraw])
    }

    @Test("Follow-ups explain why they're due")
    func testFollowUpReason() throws {
        let json = #"""
            [{"id": 1, "jobTitle": "x", "clientCompany": null, "company": "Co", "stage": "Applied", "interviewer": null, "date": null, "nextStep": null, "replyBy": null, "followUps": 0, "lastFollowUp": null, "dueAt": "2026-10-01T00:00:00Z"},
            {"id": 2, "jobTitle": "x", "clientCompany": null, "company": "Co", "stage": "Technical", "interviewer": null, "date": null, "nextStep": null, "replyBy": null, "followUps": 2, "lastFollowUp": "2026-10-10T09:00:00Z", "dueAt": "2026-10-20T00:00:00Z"}]
            """#
        let items = try JSONDecoder().decode([APIFollowUp].self, from: Data(json.utf8))
        #expect(FollowUpText.reason(items[0]) == "No reply since you applied")
        #expect(FollowUpText.reason(items[1]).hasPrefix("Chased 2 times"))
    }
}

//
//  MessageTemplates.swift
//  Interviews
//

import Foundation

/// Ready-to-send messages, pre-filled from the application, worded exactly as on the website (lib/messages.ts)
enum MessageTemplate: String, CaseIterable, Identifiable {
    case thankYou = "thank-you", followUp = "follow-up", withdraw, acceptOffer = "accept-offer", declineOffer = "decline-offer", askFeedback = "ask-feedback"

    var id: String { rawValue }

    struct Context {
        var jobTitle: String
        var company: String
        var clientCompany: String?
        var stage: String?
        var interviewer: String?
        var date: Date?
        var formatDate: (Date) -> String = { $0.formatted(.dateTime.weekday(.wide).day().month(.wide)) }
    }

    var label: String {
        switch self {
        case .thankYou: "Thank you"
        case .followUp: "Follow up"
        case .withdraw: "Withdraw"
        case .acceptOffer: "Accept offer"
        case .declineOffer: "Decline offer"
        case .askFeedback: "Ask for feedback"
        }
    }

    func render(_ ctx: Context) -> String {
        // Through an agency you're writing to the agency about the client's role
        let role = ctx.clientCompany.map { "the \(ctx.jobTitle) role with \($0)" } ?? "the \(ctx.jobTitle) role at \(ctx.company)"
        let first = ctx.interviewer?.trimmingCharacters(in: .whitespaces).split(separator: " ").first
        let greeting = first.map { "Hi \($0)," } ?? "Hi,"
        let interview = ["my", ctx.stage.flatMap { $0 == "Applied" ? nil : $0 }, "interview", ctx.date.map { "on \(ctx.formatDate($0))" }]
            .compactMap { $0 }.joined(separator: " ")
        let letter = { (body: [String]) in ([greeting, ""] + body + ["", "Thanks"]).joined(separator: "\n") }

        switch self {
        case .thankYou:
            return letter(["Thank you for taking the time to speak with me in \(interview) about \(role). I enjoyed our conversation and learning more about the team.", "", "I'm very interested in the role and look forward to hearing about next steps."])
        case .followUp:
            let opening = ctx.stage.map { $0 != "Applied" } == true ? "I wanted to follow up after \(interview) for \(role)." : "I wanted to follow up on my application for \(role)."
            return letter([opening, "", "I'm still very interested and would be grateful for an update on where things are."])
        case .withdraw:
            return letter(["Thank you for considering me for \(role). I've decided to withdraw my application.", "", "I appreciate the time you've spent on this and hope our paths cross again."])
        case .acceptOffer:
            return letter(["Thank you for the offer for \(role). I'm delighted to accept.", "", "Please let me know what you need from me and the next steps."])
        case .declineOffer:
            return letter(["Thank you for the offer for \(role). After careful thought I've decided to decline.", "", "I really appreciate the time everyone spent with me and hope we stay in touch."])
        case .askFeedback:
            return letter(["Thank you for letting me know about \(role). I'm disappointed, but I appreciate you getting back to me.", "", "If you have a moment, I'd be grateful for any feedback on how I could improve."])
        }
    }

    /// The messages that make sense for where this interview is
    static func templates(outcome: String?, stage: String?, date: Date?, now: Date = Date()) -> [MessageTemplate] {
        let state = (outcome ?? "").uppercased()
        if ["OFFER_ACCEPTED", "OFFER_DECLINED", "WITHDREW", "NO_RESPONSE"].contains(state) { return [] }
        if state == "REJECTED" { return [.askFeedback] }
        if state == "OFFER_RECEIVED" || stage == "Offer" { return [.acceptOffer, .declineOffer] }
        let happened = stage != "Applied" && (date.map { $0 < now } ?? false)
        return happened ? [.thankYou, .followUp, .withdraw] : [.followUp, .withdraw]
    }
}

extension MessageTemplate.Context {
    init(_ interview: Interview) {
        self.init(jobTitle: interview.jobTitle, company: interview.company?.name ?? "", clientCompany: interview.clientCompany,
                  stage: interview.stage?.stage, interviewer: interview.interviewer, date: interview.date)
    }
}

//
//  InterviewOutcome.swift
//  Interviews
//
//  Created by keloran on 05/12/2025.
//

import Foundation

enum InterviewOutcome: String, Codable, CaseIterable {
    case scheduled = "SCHEDULED"
    case passed = "PASSED"
    case rejected = "REJECTED"
    case awaitingResponse = "AWAITING_RESPONSE"
    case offerReceived = "OFFER_RECEIVED"
    case offerAccepted = "OFFER_ACCEPTED"
    case offerDeclined = "OFFER_DECLINED"
    case withdrew = "WITHDREW"

    var displayName: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .passed: return "Passed"
        case .rejected: return "Rejected"
        case .awaitingResponse: return "Awaiting Response"
        case .offerReceived: return "Offer Received"
        case .offerAccepted: return "Offer Accepted"
        case .offerDeclined: return "Offer Declined"
        case .withdrew: return "Withdrew"
        }
    }

    var color: String {
        switch self {
        case .scheduled: return "blue"
        case .passed: return "green"
        case .rejected: return "red"
        case .awaitingResponse: return "yellow"
        case .offerReceived: return "purple"
        case .offerAccepted: return "green"
        case .offerDeclined: return "orange"
        case .withdrew: return "gray"
        }
    }
}

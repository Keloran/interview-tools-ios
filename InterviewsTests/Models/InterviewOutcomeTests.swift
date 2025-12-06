//
//  InterviewOutcomeTests.swift
//  InterviewsTests
//
//  Created by keloran on 05/12/2025.
//

import Foundation
import Testing
@testable import Interviews

struct InterviewOutcomeTests {
    @Test @MainActor func testDisplayNames() async throws {
        #expect(InterviewOutcome.scheduled.displayName == "Scheduled")
        #expect(InterviewOutcome.passed.displayName == "Passed")
        #expect(InterviewOutcome.rejected.displayName == "Rejected")
        #expect(InterviewOutcome.awaitingResponse.displayName == "Awaiting Response")
        #expect(InterviewOutcome.offerReceived.displayName == "Offer Received")
        #expect(InterviewOutcome.offerAccepted.displayName == "Offer Accepted")
        #expect(InterviewOutcome.offerDeclined.displayName == "Offer Declined")
        #expect(InterviewOutcome.withdrew.displayName == "Withdrew")
    }

    @Test func testRawValues() async throws {
        #expect(InterviewOutcome.scheduled.rawValue == "SCHEDULED")
        #expect(InterviewOutcome.passed.rawValue == "PASSED")
        #expect(InterviewOutcome.rejected.rawValue == "REJECTED")
        #expect(InterviewOutcome.awaitingResponse.rawValue == "AWAITING_RESPONSE")
        #expect(InterviewOutcome.offerReceived.rawValue == "OFFER_RECEIVED")
        #expect(InterviewOutcome.offerAccepted.rawValue == "OFFER_ACCEPTED")
        #expect(InterviewOutcome.offerDeclined.rawValue == "OFFER_DECLINED")
        #expect(InterviewOutcome.withdrew.rawValue == "WITHDREW")
    }

    @Test @MainActor func testColors() async throws {
        #expect(InterviewOutcome.scheduled.color == "blue")
        #expect(InterviewOutcome.passed.color == "green")
        #expect(InterviewOutcome.rejected.color == "red")
        #expect(InterviewOutcome.awaitingResponse.color == "yellow")
        #expect(InterviewOutcome.offerReceived.color == "purple")
        #expect(InterviewOutcome.offerAccepted.color == "green")
        #expect(InterviewOutcome.offerDeclined.color == "orange")
        #expect(InterviewOutcome.withdrew.color == "gray")
    }

    @Test func testCodable() async throws {
        let outcome = InterviewOutcome.scheduled
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(outcome)
        let decoded = try decoder.decode(InterviewOutcome.self, from: encoded)

        #expect(decoded == outcome)
    }

    @Test func testAllCases() async throws {
        #expect(InterviewOutcome.allCases.count == 8)
        #expect(InterviewOutcome.allCases.contains(.scheduled))
        #expect(InterviewOutcome.allCases.contains(.passed))
        #expect(InterviewOutcome.allCases.contains(.rejected))
        #expect(InterviewOutcome.allCases.contains(.awaitingResponse))
        #expect(InterviewOutcome.allCases.contains(.offerReceived))
        #expect(InterviewOutcome.allCases.contains(.offerAccepted))
        #expect(InterviewOutcome.allCases.contains(.offerDeclined))
        #expect(InterviewOutcome.allCases.contains(.withdrew))
    }
}

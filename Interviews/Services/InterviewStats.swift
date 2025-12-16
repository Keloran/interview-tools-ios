//
//  InterviewStats.swift
//  Interviews
//
//  Created by keloran on 09/12/2025.
//

import Foundation
import SwiftData

/// Represents computed statistics about interviews
struct InterviewStats {
    let totalInterviews: Int
    let applied: Int
    let scheduled: Int
    let awaitingResponse: Int
    let passed: Int
    let rejected: Int
    let offerReceived: Int
    let offerAccepted: Int
    let offerDeclined: Int
    let withdrew: Int
    
    /// Success rate as a percentage (passed / (passed + rejected))
    var successRate: Double {
        let total = passed + rejected
        guard total > 0 else { return 0.0 }
        return (Double(passed) / Double(total)) * 100.0
    }
    
    /// Response rate as a percentage (outcomes set / total that should have outcomes)
    var responseRate: Double {
        // Count interviews that should have had a response (not in "Applied" stage)
        let shouldHaveResponse = totalInterviews - applied
        guard shouldHaveResponse > 0 else { return 0.0 }
        
        let responded = passed + rejected + offerReceived + offerAccepted + offerDeclined
        return (Double(responded) / Double(shouldHaveResponse)) * 100.0
    }
    
    /// Active interviews (scheduled or awaiting response)
    var activeInterviews: Int {
        scheduled + awaitingResponse
    }
    
    /// Compute statistics from a list of interviews
    static func compute(from interviews: [Interview]) -> InterviewStats {
        var stats = InterviewStats(
            totalInterviews: interviews.count,
            applied: 0,
            scheduled: 0,
            awaitingResponse: 0,
            passed: 0,
            rejected: 0,
            offerReceived: 0,
            offerAccepted: 0,
            offerDeclined: 0,
            withdrew: 0
        )
        
        for interview in interviews {
            // Special case: "Applied" stage with no outcome
            if interview.stage?.stage == "Applied" && interview.outcome == nil {
                stats = InterviewStats(
                    totalInterviews: stats.totalInterviews,
                    applied: stats.applied + 1,
                    scheduled: stats.scheduled,
                    awaitingResponse: stats.awaitingResponse,
                    passed: stats.passed,
                    rejected: stats.rejected,
                    offerReceived: stats.offerReceived,
                    offerAccepted: stats.offerAccepted,
                    offerDeclined: stats.offerDeclined,
                    withdrew: stats.withdrew
                )
                continue
            }
            
            // Count by outcome
            switch interview.outcome {
            case .scheduled:
                stats = InterviewStats(
                    totalInterviews: stats.totalInterviews,
                    applied: stats.applied,
                    scheduled: stats.scheduled + 1,
                    awaitingResponse: stats.awaitingResponse,
                    passed: stats.passed,
                    rejected: stats.rejected,
                    offerReceived: stats.offerReceived,
                    offerAccepted: stats.offerAccepted,
                    offerDeclined: stats.offerDeclined,
                    withdrew: stats.withdrew
                )
            case .passed:
                stats = InterviewStats(
                    totalInterviews: stats.totalInterviews,
                    applied: stats.applied,
                    scheduled: stats.scheduled,
                    awaitingResponse: stats.awaitingResponse,
                    passed: stats.passed + 1,
                    rejected: stats.rejected,
                    offerReceived: stats.offerReceived,
                    offerAccepted: stats.offerAccepted,
                    offerDeclined: stats.offerDeclined,
                    withdrew: stats.withdrew
                )
            case .rejected:
                stats = InterviewStats(
                    totalInterviews: stats.totalInterviews,
                    applied: stats.applied,
                    scheduled: stats.scheduled,
                    awaitingResponse: stats.awaitingResponse,
                    passed: stats.passed,
                    rejected: stats.rejected + 1,
                    offerReceived: stats.offerReceived,
                    offerAccepted: stats.offerAccepted,
                    offerDeclined: stats.offerDeclined,
                    withdrew: stats.withdrew
                )
            case .awaitingResponse:
                stats = InterviewStats(
                    totalInterviews: stats.totalInterviews,
                    applied: stats.applied,
                    scheduled: stats.scheduled,
                    awaitingResponse: stats.awaitingResponse + 1,
                    passed: stats.passed,
                    rejected: stats.rejected,
                    offerReceived: stats.offerReceived,
                    offerAccepted: stats.offerAccepted,
                    offerDeclined: stats.offerDeclined,
                    withdrew: stats.withdrew
                )
            case .offerReceived:
                stats = InterviewStats(
                    totalInterviews: stats.totalInterviews,
                    applied: stats.applied,
                    scheduled: stats.scheduled,
                    awaitingResponse: stats.awaitingResponse,
                    passed: stats.passed,
                    rejected: stats.rejected,
                    offerReceived: stats.offerReceived + 1,
                    offerAccepted: stats.offerAccepted,
                    offerDeclined: stats.offerDeclined,
                    withdrew: stats.withdrew
                )
            case .offerAccepted:
                stats = InterviewStats(
                    totalInterviews: stats.totalInterviews,
                    applied: stats.applied,
                    scheduled: stats.scheduled,
                    awaitingResponse: stats.awaitingResponse,
                    passed: stats.passed,
                    rejected: stats.rejected,
                    offerReceived: stats.offerReceived,
                    offerAccepted: stats.offerAccepted + 1,
                    offerDeclined: stats.offerDeclined,
                    withdrew: stats.withdrew
                )
            case .offerDeclined:
                stats = InterviewStats(
                    totalInterviews: stats.totalInterviews,
                    applied: stats.applied,
                    scheduled: stats.scheduled,
                    awaitingResponse: stats.awaitingResponse,
                    passed: stats.passed,
                    rejected: stats.rejected,
                    offerReceived: stats.offerReceived,
                    offerAccepted: stats.offerAccepted,
                    offerDeclined: stats.offerDeclined + 1,
                    withdrew: stats.withdrew
                )
            case .withdrew:
                stats = InterviewStats(
                    totalInterviews: stats.totalInterviews,
                    applied: stats.applied,
                    scheduled: stats.scheduled,
                    awaitingResponse: stats.awaitingResponse,
                    passed: stats.passed,
                    rejected: stats.rejected,
                    offerReceived: stats.offerReceived,
                    offerAccepted: stats.offerAccepted,
                    offerDeclined: stats.offerDeclined,
                    withdrew: stats.withdrew + 1
                )
            case .none:
                // If no outcome and not in "Applied" stage, count as scheduled
                stats = InterviewStats(
                    totalInterviews: stats.totalInterviews,
                    applied: stats.applied,
                    scheduled: stats.scheduled + 1,
                    awaitingResponse: stats.awaitingResponse,
                    passed: stats.passed,
                    rejected: stats.rejected,
                    offerReceived: stats.offerReceived,
                    offerAccepted: stats.offerAccepted,
                    offerDeclined: stats.offerDeclined,
                    withdrew: stats.withdrew
                )
            }
        }
        
        return stats
    }
}

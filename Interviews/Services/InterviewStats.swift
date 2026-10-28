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
    var totalInterviews: Int
    var applied: Int
    var scheduled: Int
    var awaitingResponse: Int
    var passed: Int
    var rejected: Int
    var offerReceived: Int
    var offerAccepted: Int
    var offerDeclined: Int
    var withdrew: Int
    /// Closed as ghosted: they never replied
    var noResponse: Int = 0
    
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
        var stats = InterviewStats(totalInterviews: interviews.count, applied: 0, scheduled: 0, awaitingResponse: 0,
                                   passed: 0, rejected: 0, offerReceived: 0, offerAccepted: 0, offerDeclined: 0, withdrew: 0)
        for interview in interviews {
            switch interview.outcome {
            // "Applied" stage with no outcome yet; any other stage without one counts as scheduled
            case .none where interview.stage?.stage == "Applied": stats.applied += 1
            case .none, .scheduled: stats.scheduled += 1
            case .awaitingResponse: stats.awaitingResponse += 1
            case .passed: stats.passed += 1
            case .rejected: stats.rejected += 1
            case .offerReceived: stats.offerReceived += 1
            case .offerAccepted: stats.offerAccepted += 1
            case .offerDeclined: stats.offerDeclined += 1
            case .withdrew: stats.withdrew += 1
            case .noResponse: stats.noResponse += 1
            }
        }
        return stats
    }
}

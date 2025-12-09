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
            // Check if this is an "Applied" stage interview
            // We check the stage name case-insensitively and look for "applied" or "application"
            let stageName = interview.stage?.stage.lowercased() ?? ""
            let isAppliedStage = stageName.contains("appl")
            
            // Count by outcome first, if set
            if let outcome = interview.outcome {
                switch outcome {
                case .scheduled:
                    stats = incrementStat(stats, \.scheduled)
                case .passed:
                    stats = incrementStat(stats, \.passed)
                case .rejected:
                    stats = incrementStat(stats, \.rejected)
                case .awaitingResponse:
                    stats = incrementStat(stats, \.awaitingResponse)
                case .offerReceived:
                    stats = incrementStat(stats, \.offerReceived)
                case .offerAccepted:
                    stats = incrementStat(stats, \.offerAccepted)
                case .offerDeclined:
                    stats = incrementStat(stats, \.offerDeclined)
                case .withdrew:
                    stats = incrementStat(stats, \.withdrew)
                }
            } else {
                // No outcome set - categorize by stage
                if isAppliedStage {
                    // If in "Applied" stage with no outcome, count as applied
                    stats = incrementStat(stats, \.applied)
                } else {
                    // Otherwise, count as scheduled (they have an interview scheduled but no outcome yet)
                    stats = incrementStat(stats, \.scheduled)
                }
            }
        }
        
        return stats
    }
    
    /// Helper to increment a stat field immutably
    private static func incrementStat(_ stats: InterviewStats, _ keyPath: KeyPath<InterviewStats, Int>) -> InterviewStats {
        var applied = stats.applied
        var scheduled = stats.scheduled
        var awaitingResponse = stats.awaitingResponse
        var passed = stats.passed
        var rejected = stats.rejected
        var offerReceived = stats.offerReceived
        var offerAccepted = stats.offerAccepted
        var offerDeclined = stats.offerDeclined
        var withdrew = stats.withdrew
        
        switch keyPath {
        case \InterviewStats.applied:
            applied += 1
        case \InterviewStats.scheduled:
            scheduled += 1
        case \InterviewStats.awaitingResponse:
            awaitingResponse += 1
        case \InterviewStats.passed:
            passed += 1
        case \InterviewStats.rejected:
            rejected += 1
        case \InterviewStats.offerReceived:
            offerReceived += 1
        case \InterviewStats.offerAccepted:
            offerAccepted += 1
        case \InterviewStats.offerDeclined:
            offerDeclined += 1
        case \InterviewStats.withdrew:
            withdrew += 1
        default:
            break
        }
        
        return InterviewStats(
            totalInterviews: stats.totalInterviews,
            applied: applied,
            scheduled: scheduled,
            awaitingResponse: awaitingResponse,
            passed: passed,
            rejected: rejected,
            offerReceived: offerReceived,
            offerAccepted: offerAccepted,
            offerDeclined: offerDeclined,
            withdrew: withdrew
        )
    }
}

//
//  InterviewStats.swift
//  Interviews
//
//  Created by keloran on 09/12/2025.
//

import Foundation
import SwiftData
#if canImport(Interviews)
@testable import Interviews
#endif

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
        var applied = 0
        var scheduled = 0
        var awaitingResponse = 0
        var passedAppliedStage = 0
        var rejected = 0
        var offerReceived = 0
        var offerAccepted = 0
        var offerDeclined = 0
        var withdrew = 0
        
        for interview in interviews {
            // Check if this job is still at the "Applied" stage
            let stageName = interview.stage?.stage.lowercased() ?? ""
            let isStillAtAppliedStage = stageName.contains("appl")
            
            // Count jobs currently at Applied stage
            if isStillAtAppliedStage {
                applied += 1
            } else {
                // If not at applied stage anymore, they've progressed
                passedAppliedStage += 1
            }
            
            // Count specific outcomes (these can overlap with stage-based counts)
            if let outcome = interview.outcome {
                switch outcome {
                case .scheduled:
                    scheduled += 1
                case .passed:
                    // This is just an outcome status, doesn't affect stage progression count
                    break
                case .rejected:
                    rejected += 1
                case .awaitingResponse:
                    awaitingResponse += 1
                case .offerReceived:
                    offerReceived += 1
                case .offerAccepted:
                    offerAccepted += 1
                case .offerDeclined:
                    offerDeclined += 1
                case .withdrew:
                    withdrew += 1
                }
            }
        }
        
        return InterviewStats(
            totalInterviews: interviews.count,
            applied: applied,
            scheduled: scheduled,
            awaitingResponse: awaitingResponse,
            passed: passedAppliedStage,
            rejected: rejected,
            offerReceived: offerReceived,
            offerAccepted: offerAccepted,
            offerDeclined: offerDeclined,
            withdrew: withdrew
        )
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


import SwiftUI

// Centralized color mapping for outcome/stage labels (string-based for server-driven states)
public func colorForOutcomeString(_ label: String) -> Color {
    let key = label.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    switch key {
    case "scheduled":
        return .blue
    case "awaiting", "awaiting response", "applied":
        return .yellow
    case "passed", "offer accepted", "accepted", "success":
        return .green
    case "rejected", "declined", "offer declined":
        return .red
    case "withdrew", "withdrawn":
        return .gray
    case "offer received", "offers":
        return .purple
    case "active":
        return .orange
    case "total":
        return .primary
    default:
        return .accentColor
    }
}

func colorForOutcomeInterview(_ outcome: InterviewOutcome) -> Color {
    switch outcome {
    case .scheduled:
        return .blue
    case .passed:
        return .green
    case .rejected:
        return .red
    case .offerReceived:
        return .purple
    case .offerAccepted:
        return .green
    case .offerDeclined:
        return .orange
    case .withdrew:
        return .gray
    case .awaitingResponse:
        return .yellow
    }
}

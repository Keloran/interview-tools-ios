//
//  StatsView.swift
//  Interviews
//
//  Created by keloran on 09/12/2025.
//

import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var interviews: [Interview]
    
    private var stats: InterviewStats {
        InterviewStats.compute(from: interviews)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Overview stats
            VStack(alignment: .leading, spacing: 8) {
                Text("Overview")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 16) {
                    StatCard(
                        title: "Total",
                        value: "\(stats.totalInterviews)",
                        color: .primary
                    )
                    
                    StatCard(
                        title: "Active",
                        value: "\(stats.activeInterviews)",
                        color: .secondary
                    )
                }
            }
            
            Divider()
            
            // Application stages
            VStack(alignment: .leading, spacing: 8) {
                Text("Application Stages")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 12) {
                    StatRow(
                        label: "Applied",
                        value: stats.applied,
                        color: .yellow,
                        icon: "paperplane.fill"
                    )
                    
                    StatRow(
                        label: "Scheduled",
                        value: stats.scheduled,
                        color: .blue,
                        icon: "calendar"
                    )
                    
                    StatRow(
                        label: "Awaiting Response",
                        value: stats.awaitingResponse,
                        color: .yellow,
                        icon: "clock.fill"
                    )
                }
            }
            
            Divider()
            
            // Outcomes
            VStack(alignment: .leading, spacing: 8) {
                Text("Outcomes")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 12) {
                    StatRow(
                        label: "Passed",
                        value: stats.passed,
                        color: .green,
                        icon: "checkmark.circle.fill"
                    )
                    
                    StatRow(
                        label: "Rejected",
                        value: stats.rejected,
                        color: .red,
                        icon: "xmark.circle.fill"
                    )
                    
                    StatRow(
                        label: "Withdrew",
                        value: stats.withdrew,
                        color: .gray,
                        icon: "arrow.uturn.backward.circle.fill"
                    )
                }
            }
            
            Divider()
            
            // Offers
            VStack(alignment: .leading, spacing: 8) {
                Text("Offers")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 12) {
                    StatRow(
                        label: "Offer Received",
                        value: stats.offerReceived,
                        color: .purple,
                        icon: "gift.fill"
                    )
                    
                    StatRow(
                        label: "Offer Accepted",
                        value: stats.offerAccepted,
                        color: .green,
                        icon: "hand.thumbsup.fill"
                    )
                    
                    StatRow(
                        label: "Offer Declined",
                        value: stats.offerDeclined,
                        color: .orange,
                        icon: "hand.thumbsdown.fill"
                    )
                }
            }
            
            // Success metrics (only show if there's data)
            if stats.passed > 0 || stats.rejected > 0 {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Success Metrics")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    VStack(spacing: 12) {
                        MetricRow(
                            label: "Success Rate",
                            value: stats.successRate,
                            total: stats.passed + stats.rejected,
                            subtitle: "\(stats.passed) passed of \(stats.passed + stats.rejected)"
                        )
                    }
                }
            }
        }
        .padding()
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct StatRow: View {
    let label: String
    let value: Int
    let color: Color
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            
            Text(label)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Text("\(value)")
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(color)
        }
        .padding(.vertical, 4)
    }
}

struct MetricRow: View {
    let label: String
    let value: Double
    let total: Int
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text(String(format: "%.1f%%", value))
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(colorForPercentage(value))
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(colorForPercentage(value))
                        .frame(width: geometry.size.width * (value / 100.0), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func colorForPercentage(_ percentage: Double) -> Color {
        switch percentage {
        case 0..<25:
            return .red
        case 25..<50:
            return .orange
        case 50..<75:
            return .yellow
        default:
            return .green
        }
    }
}

// MARK: - Compact Version for iPad

struct CompactStatsView: View {
    @Query private var interviews: [Interview]
    
    private var stats: InterviewStats {
        InterviewStats.compute(from: interviews)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Interview Statistics")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 12) {
                    // Quick stats
                    HStack(spacing: 8) {
                        CompactStatCard(
                            title: "Total",
                            value: "\(stats.totalInterviews)",
                            color: .blue
                        )
                        
                        CompactStatCard(
                            title: "Active",
                            value: "\(stats.activeInterviews)",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)
                    
                    // Key metrics in compact rows
                    VStack(spacing: 8) {
                        CompactStatRow(label: "Applied", value: stats.applied, color: .yellow)
                        CompactStatRow(label: "Passed", value: stats.passed, color: .green)
                        CompactStatRow(label: "Rejected", value: stats.rejected, color: .red)
                        CompactStatRow(label: "Awaiting", value: stats.awaitingResponse, color: .yellow)
                        
                        if stats.offerReceived > 0 {
                            CompactStatRow(label: "Offers", value: stats.offerReceived, color: .purple)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Success rate
                    if stats.passed > 0 || stats.rejected > 0 {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Success Rate")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                Text(String(format: "%.0f%%", stats.successRate))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.green)
                            }
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.secondary.opacity(0.2))
                                        .frame(height: 4)
                                        .cornerRadius(2)
                                    
                                    Rectangle()
                                        .fill(Color.green)
                                        .frame(width: geometry.size.width * (stats.successRate / 100.0), height: 4)
                                        .cornerRadius(2)
                                }
                            }
                            .frame(height: 4)
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)
                    }
                }
            }
        }
        .frame(maxHeight: 300)
    }
}

struct CompactStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct CompactStatRow: View {
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text("\(value)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .padding(.vertical, 2)
    }
}

#Preview("Full Stats") {
    StatsView()
        .modelContainer(for: [Interview.self, Company.self, Stage.self, StageMethod.self], inMemory: true)
}

#Preview("Compact Stats") {
    CompactStatsView()
        .modelContainer(for: [Interview.self, Company.self, Stage.self, StageMethod.self], inMemory: true)
}

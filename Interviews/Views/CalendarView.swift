//
//  CalendarView.swift
//  Interviews
//
//  Created by keloran on 05/12/2025.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var interviews: [Interview]

    @State private var currentDate = Date()
    @State private var selectedDate: Date?
    @State private var showingAddInterview = false

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekDays = ["M", "T", "W", "T", "F", "S", "S"]
    private let monthNames = ["January", "February", "March", "April", "May", "June",
                              "July", "August", "September", "October", "November", "December"]

    var body: some View {
        VStack(spacing: 16) {
            // Header with month/year and navigation
            HStack {
                Text("\(monthNames[calendar.component(.month, from: currentDate) - 1]) \(calendar.component(.year, from: currentDate))")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                HStack(spacing: 8) {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .buttonStyle(.plain)

                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)

            // Weekday headers
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)

            // Calendar grid
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(calendarDays, id: \.self) { day in
                    if day > 0 {
                        CalendarDayCell(
                            day: day,
                            interviews: getInterviewsForDay(day),
                            isToday: isToday(day),
                            isSelected: isSelected(day),
                            onTap: { handleDateClick(day) },
                            onAddInterview: { handleAddInterview(day) }
                        )
                    } else {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.vertical)
        .sheet(isPresented: $showingAddInterview) {
            if let date = selectedDate {
                AddInterviewView(initialDate: date)
            }
        }
    }

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday
        return cal
    }

    private var calendarDays: [Int] {
        let year = calendar.component(.year, from: currentDate)
        let month = calendar.component(.month, from: currentDate)

        let firstDayOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstDayOfMonth)!.count

        // Adjust for Monday start (2 = Monday)
        var startingDayOfWeek = calendar.component(.weekday, from: firstDayOfMonth)
        startingDayOfWeek = (startingDayOfWeek + 5) % 7 // Convert to 0 = Monday, 6 = Sunday

        var days: [Int] = []
        for _ in 0..<startingDayOfWeek {
            days.append(0) // Empty cells
        }
        for day in 1...daysInMonth {
            days.append(day)
        }
        return days
    }

    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentDate) {
            currentDate = newDate
        }
    }

    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentDate) {
            currentDate = newDate
        }
    }

    private func isToday(_ day: Int) -> Bool {
        let today = Date()
        let year = calendar.component(.year, from: currentDate)
        let month = calendar.component(.month, from: currentDate)

        return day == calendar.component(.day, from: today) &&
               month == calendar.component(.month, from: today) &&
               year == calendar.component(.year, from: today)
    }

    private func isSelected(_ day: Int) -> Bool {
        guard let selectedDate = selectedDate else { return false }
        let year = calendar.component(.year, from: currentDate)
        let month = calendar.component(.month, from: currentDate)

        return day == calendar.component(.day, from: selectedDate) &&
               month == calendar.component(.month, from: selectedDate) &&
               year == calendar.component(.year, from: selectedDate)
    }

    private func getInterviewsForDay(_ day: Int) -> [Interview] {
        let year = calendar.component(.year, from: currentDate)
        let month = calendar.component(.month, from: currentDate)
        guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
            return []
        }

        return interviews.filter { interview in
            guard let interviewDate = interview.displayDate else { return false }
            return calendar.isDate(interviewDate, inSameDayAs: date)
        }
    }

    private func handleDateClick(_ day: Int) {
        let year = calendar.component(.year, from: currentDate)
        let month = calendar.component(.month, from: currentDate)
        if let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) {
            selectedDate = date
        }
    }

    private func handleAddInterview(_ day: Int) {
        let year = calendar.component(.year, from: currentDate)
        let month = calendar.component(.month, from: currentDate)
        if let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) {
            selectedDate = date
            showingAddInterview = true
        }
    }
}

struct CalendarDayCell: View {
    let day: Int
    let interviews: [Interview]
    let isToday: Bool
    let isSelected: Bool
    let onTap: () -> Void
    let onAddInterview: () -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(day)")
                    .font(.caption)
                    .fontWeight(isToday ? .bold : .medium)
                    .foregroundStyle(isToday ? .white : .primary)

                Spacer()

                if isHovering {
                    Button(action: onAddInterview) {
                        Image(systemName: "plus")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            if !interviews.isEmpty {
                HStack(spacing: 2) {
                    ForEach(interviews.prefix(2), id: \.id) { interview in
                        Circle()
                            .fill(colorForInterview(interview))
                            .frame(width: 4, height: 4)
                    }
                }
            }
        }
        .padding(4)
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(isToday ? Color.accentColor : (isSelected ? Color.accentColor.opacity(0.2) : Color.clear))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .onTapGesture(perform: onTap)
        .onHover { hovering in
            isHovering = hovering
        }
    }

    private func colorForInterview(_ interview: Interview) -> Color {
        if let outcome = interview.outcome {
            return colorForOutcome(outcome)
        }
        return .blue
    }

    private func colorForOutcome(_ outcome: InterviewOutcome) -> Color {
        switch outcome {
        case .scheduled: return .blue
        case .passed: return .green
        case .rejected: return .red
        case .awaitingResponse: return .yellow
        case .offerReceived: return .purple
        case .offerAccepted: return .green
        case .offerDeclined: return .orange
        case .withdrew: return .gray
        }
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [Interview.self, Company.self, Stage.self, StageMethod.self], inMemory: true)
}

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
    
    @Binding var selectedDate: Date?

    @State private var currentDate = Date()
    @State private var showingAddInterview = false
    @State private var dragTranslation: CGFloat = 0

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private let monthNames = ["January", "February", "March", "April", "May", "June",
                              "July", "August", "September", "October", "November", "December"]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 4) {
                // Header with month/year and navigation
                HStack {
                    Text("\(monthNames[calendar.component(.month, from: currentDate) - 1]) \(String(calendar.component(.year, from: currentDate)))")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .accessibilityIdentifier("monthYearLabel")

                    Spacer()

                    HStack(spacing: 8) {
                        // Show "Today" button only when viewing a different month
                        if !isCurrentMonth {
                            Button(action: returnToToday) {
                                Text("Today")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .glassEffect()
                                    .foregroundStyle(Color.accentColor)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("todayButton")
                        }
                        
                        Button(action: previousMonth) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .glassEffect()
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("previousMonthButton")

                        Button(action: nextMonth) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                                .glassEffect()
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("nextMonthButton")
                    }
                }
                .padding(.horizontal)

            // Weekday headers
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            .padding(.top, 2)

            // Calendar grid
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(calendarCells) { cell in
                    if cell.day > 0 {
                        CalendarDayCell(
                            day: cell.day,
                            interviews: getInterviewsForDay(cell.day),
                            isToday: isToday(cell.day),
                            isSelected: isSelected(cell.day),
                            onTap: { handleDateClick(cell.day) },
                            onAddInterview: { handleAddInterview(cell.day) }
                        )
                    } else {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
            .padding(.horizontal)

            }
            .offset(x: dragTranslation / 10)
            .padding(.top, 0)

        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onChanged { value in
                    dragTranslation = value.translation.width
                }
                .onEnded { value in
                    let threshold: CGFloat = 50
                    let horizontal = value.translation.width
                    if horizontal < -threshold {
                        withAnimation(.easeInOut) { nextMonth() }
                    } else if horizontal > threshold {
                        withAnimation(.easeInOut) { previousMonth() }
                    }
                    dragTranslation = 0
                }
        )
        .sheet(isPresented: $showingAddInterview) {
            AddInterviewView(initialDate: selectedDate ?? Date())
        }
    }

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday
        return cal
    }
    
    // Struct to represent each calendar cell with a unique ID
    private struct CalendarCell: Identifiable {
        let id: Int // Position in grid (0-based index)
        let day: Int // Day number (0 for empty cells)
    }
    
    private var calendarCells: [CalendarCell] {
        let year = calendar.component(.year, from: currentDate)
        let month = calendar.component(.month, from: currentDate)

        let firstDayOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstDayOfMonth)!.count

        // Adjust for Monday start (2 = Monday)
        var startingDayOfWeek = calendar.component(.weekday, from: firstDayOfMonth)
        startingDayOfWeek = (startingDayOfWeek + 5) % 7 // Convert to 0 = Monday, 6 = Sunday

        var cells: [CalendarCell] = []
        var index = 0
        
        // Empty cells before month starts
        for _ in 0..<startingDayOfWeek {
            cells.append(CalendarCell(id: index, day: 0))
            index += 1
        }
        
        // Actual days of the month
        for day in 1...daysInMonth {
            cells.append(CalendarCell(id: index, day: day))
            index += 1
        }
        
        return cells
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
    
    private func returnToToday() {
        currentDate = Date()
    }
    
    private var isCurrentMonth: Bool {
        let today = Date()
        let currentYear = calendar.component(.year, from: currentDate)
        let currentMonth = calendar.component(.month, from: currentDate)
        let todayYear = calendar.component(.year, from: today)
        let todayMonth = calendar.component(.month, from: today)
        
        return currentYear == todayYear && currentMonth == todayMonth
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
            let interviewDate = interview.displayDate ?? interview.applicationDate
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
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(day)")
                        .font(.system(size: 13, weight: isToday ? .semibold : .medium))
                        .foregroundStyle(isToday ? .primary : .primary)
                }

                Spacer()

                // Always reserve space for dots to maintain alignment
                HStack(spacing: 2) {
                    if !interviews.isEmpty {
                        ForEach(interviews.prefix(2), id: \.persistentModelID) { interview in
                            Circle()
                                .fill(colorForInterview(interview))
                                .frame(width: 4, height: 4)
                        }
                        if interviews.count > 2 {
                            Text("+\(interviews.count - 2)")
                                .font(.system(size: 5))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(height: 4) // Reserve consistent height for dot area
            }
            .padding(3)
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(
                isSelected ? Color.accentColor.opacity(0.08) : Color.clear
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : (isToday ? Color.accentColor : Color.clear), lineWidth: isSelected ? 2 : (isToday ? 1 : 0))
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("\(day)")
        .accessibilityLabel("Day \(day)")
        .accessibilityValue(isSelected ? "selected" : "")
        .contextMenu {
            Button(action: onAddInterview) {
                Label("Add Interview", systemImage: "plus.circle")
            }
        }
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
    CalendarView(selectedDate: .constant(nil))
        .modelContainer(for: [Interview.self, Company.self, Stage.self, StageMethod.self], inMemory: true)
}


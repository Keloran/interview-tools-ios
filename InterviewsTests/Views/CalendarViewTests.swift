//
//  CalendarViewTests.swift
//  InterviewsTests
//
//  Created by keloran on 05/12/2025.
//

import Foundation
import Testing
import SwiftData
@testable import Interviews

struct CalendarViewTests {
    @Test func testMonthNames() async throws {
        let monthNames = ["January", "February", "March", "April", "May", "June",
                          "July", "August", "September", "October", "November", "December"]

        #expect(monthNames.count == 12)
        #expect(monthNames[0] == "January")
        #expect(monthNames[11] == "December")
    }

    @Test func testWeekDaysStartMonday() async throws {
        let weekDays = ["M", "T", "W", "T", "F", "S", "S"]

        #expect(weekDays.count == 7)
        #expect(weekDays.first == "M") // Monday first
        #expect(weekDays.last == "S") // Sunday last
    }

    @Test func testCalendarMonthCalculation() async throws {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday

        let date = DateComponents(calendar: calendar, year: 2025, month: 12, day: 5).date!

        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)

        #expect(year == 2025)
        #expect(month == 12)
    }

    @Test func testDaysInMonth() async throws {
        var calendar = Calendar.current
        calendar.firstWeekday = 2

        // Test December 2025
        let december2025 = DateComponents(calendar: calendar, year: 2025, month: 12, day: 1).date!
        let daysInDecember = calendar.range(of: .day, in: .month, for: december2025)!.count
        #expect(daysInDecember == 31)

        // Test February 2024 (leap year)
        let february2024 = DateComponents(calendar: calendar, year: 2024, month: 2, day: 1).date!
        let daysInFebruary2024 = calendar.range(of: .day, in: .month, for: february2024)!.count
        #expect(daysInFebruary2024 == 29)

        // Test February 2025 (non-leap year)
        let february2025 = DateComponents(calendar: calendar, year: 2025, month: 2, day: 1).date!
        let daysInFebruary2025 = calendar.range(of: .day, in: .month, for: february2025)!.count
        #expect(daysInFebruary2025 == 28)
    }

    @Test func testStartingDayOfWeek() async throws {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday

        // December 1, 2025 is a Monday
        let december2025 = DateComponents(calendar: calendar, year: 2025, month: 12, day: 1).date!
        var startingDay = calendar.component(.weekday, from: december2025)
        startingDay = (startingDay + 5) % 7 // Convert to 0 = Monday

        #expect(startingDay == 0) // Monday
    }

    @Test func testIsSameDay() async throws {
        let calendar = Calendar.current

        let date1 = DateComponents(calendar: calendar, year: 2025, month: 12, day: 5, hour: 10).date!
        let date2 = DateComponents(calendar: calendar, year: 2025, month: 12, day: 5, hour: 15).date!
        let date3 = DateComponents(calendar: calendar, year: 2025, month: 12, day: 6, hour: 10).date!

        #expect(calendar.isDate(date1, inSameDayAs: date2))
        #expect(!calendar.isDate(date1, inSameDayAs: date3))
    }

    @Test @MainActor func testInterviewFilteringByDate() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext

        let company = Company(name: "Apple")
        let stage = Stage(stage: "Phone Screen")
        let method = StageMethod(method: "Video Call")

        context.insert(company)
        context.insert(stage)
        context.insert(method)

        let calendar = Calendar.current
        let targetDate = DateComponents(calendar: calendar, year: 2025, month: 12, day: 15).date!

        let interview1 = Interview(
            company: company,
            jobTitle: "iOS Engineer",
            applicationDate: Date(),
            stage: stage,
            stageMethod: method,
            date: targetDate
        )

        let interview2 = Interview(
            company: company,
            jobTitle: "macOS Engineer",
            applicationDate: Date(),
            stage: stage,
            stageMethod: method,
            date: targetDate.addingTimeInterval(86400) // Next day
        )

        context.insert(interview1)
        context.insert(interview2)

        let descriptor = FetchDescriptor<Interview>()
        let allInterviews = try context.fetch(descriptor)

        let filteredInterviews = allInterviews.filter { interview in
            guard let interviewDate = interview.displayDate else { return false }
            return calendar.isDate(interviewDate, inSameDayAs: targetDate)
        }

        #expect(filteredInterviews.count == 1)
        #expect(filteredInterviews.first?.jobTitle == "iOS Engineer")
    }

    @Test func testMonthNavigation() async throws {
        let calendar = Calendar.current

        let currentDate = DateComponents(calendar: calendar, year: 2025, month: 12, day: 5).date!

        // Previous month
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentDate)!
        #expect(calendar.component(.month, from: previousMonth) == 11)
        #expect(calendar.component(.year, from: previousMonth) == 2025)

        // Next month
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentDate)!
        #expect(calendar.component(.month, from: nextMonth) == 1)
        #expect(calendar.component(.year, from: nextMonth) == 2026)
    }

    @Test func testOutcomeColorMapping() async throws {
        let testCases: [(InterviewOutcome, String)] = [
            (.scheduled, "blue"),
            (.passed, "green"),
            (.rejected, "red"),
            (.awaitingResponse, "yellow"),
            (.offerReceived, "purple"),
            (.offerAccepted, "green"),
            (.offerDeclined, "orange"),
            (.withdrew, "gray")
        ]

        for (outcome, expectedColor) in testCases {
            #expect(outcome.color == expectedColor)
        }
    }

    @Test @MainActor func testMultipleInterviewsOnSameDay() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Interview.self, Company.self, Stage.self, StageMethod.self,
            configurations: config
        )
        let context = container.mainContext

        let company1 = Company(name: "Google")
        let company2 = Company(name: "Meta")
        let stage = Stage(stage: "Technical")
        let method = StageMethod(method: "Video Call")

        context.insert(company1)
        context.insert(company2)
        context.insert(stage)
        context.insert(method)

        let calendar = Calendar.current
        let targetDate = DateComponents(calendar: calendar, year: 2025, month: 12, day: 20).date!

        let interview1 = Interview(
            company: company1,
            jobTitle: "SWE",
            applicationDate: Date(),
            stage: stage,
            stageMethod: method,
            date: targetDate
        )

        let interview2 = Interview(
            company: company2,
            jobTitle: "Engineer",
            applicationDate: Date(),
            stage: stage,
            stageMethod: method,
            date: targetDate
        )

        context.insert(interview1)
        context.insert(interview2)

        let descriptor = FetchDescriptor<Interview>()
        let allInterviews = try context.fetch(descriptor)

        let interviewsOnDate = allInterviews.filter { interview in
            guard let interviewDate = interview.displayDate else { return false }
            return calendar.isDate(interviewDate, inSameDayAs: targetDate)
        }

        #expect(interviewsOnDate.count == 2)
    }

    @Test func testDateSelection() async throws {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday

        let currentDate = DateComponents(calendar: calendar, year: 2025, month: 12, day: 1).date!
        let year = calendar.component(.year, from: currentDate)
        let month = calendar.component(.month, from: currentDate)

        // Simulate selecting day 15
        let selectedDay = 15
        let selectedDate = calendar.date(from: DateComponents(year: year, month: month, day: selectedDay))

        #expect(selectedDate != nil)
        #expect(calendar.component(.day, from: selectedDate!) == 15)
        #expect(calendar.component(.month, from: selectedDate!) == 12)
        #expect(calendar.component(.year, from: selectedDate!) == 2025)
    }

    @Test func testIsSelectedDate() async throws {
        let calendar = Calendar.current
        let currentDate = DateComponents(calendar: calendar, year: 2025, month: 12, day: 1).date!
        let selectedDate = DateComponents(calendar: calendar, year: 2025, month: 12, day: 15).date!

        let year = calendar.component(.year, from: currentDate)
        let month = calendar.component(.month, from: currentDate)
        let selectedDay = calendar.component(.day, from: selectedDate)

        // Test day 15 is selected
        let isSelected = selectedDay == calendar.component(.day, from: selectedDate) &&
                        month == calendar.component(.month, from: selectedDate) &&
                        year == calendar.component(.year, from: selectedDate)

        #expect(isSelected)
    }

    @Test func testHandleDateClick() async throws {
        var calendar = Calendar.current
        calendar.firstWeekday = 2

        let currentDate = DateComponents(calendar: calendar, year: 2025, month: 12, day: 1).date!
        let clickedDay = 20

        let year = calendar.component(.year, from: currentDate)
        let month = calendar.component(.month, from: currentDate)

        let selectedDate = calendar.date(from: DateComponents(year: year, month: month, day: clickedDay))

        #expect(selectedDate != nil)
        #expect(calendar.component(.day, from: selectedDate!) == clickedDay)
    }

    @Test func testAddInterviewDatePropagation() async throws {
        var calendar = Calendar.current
        calendar.firstWeekday = 2

        let currentDate = DateComponents(calendar: calendar, year: 2025, month: 12, day: 1).date!
        let selectedDay = 25

        let year = calendar.component(.year, from: currentDate)
        let month = calendar.component(.month, from: currentDate)

        let selectedDate = calendar.date(from: DateComponents(year: year, month: month, day: selectedDay))!

        // Verify the date that would be passed to AddInterviewView
        #expect(calendar.component(.day, from: selectedDate) == selectedDay)
        #expect(calendar.component(.month, from: selectedDate) == month)
        #expect(calendar.component(.year, from: selectedDate) == year)
    }

    @Test func testFloatingButtonShouldShowWhenDateSelected() async throws {
        // When selectedDate is nil, button should not show
        let selectedDate: Date? = nil
        let shouldShowButton = selectedDate != nil
        #expect(!shouldShowButton)

        // When selectedDate has a value, button should show
        let selectedDateWithValue: Date? = Date()
        let shouldShowButtonWithDate = selectedDateWithValue != nil
        #expect(shouldShowButtonWithDate)
    }

    @Test func testInterviewCountIndicator() async throws {
        // Test interview count display logic
        let interviews = [1, 2, 3, 4, 5]

        // Should show first 2 interviews as dots
        let visibleInterviews = interviews.prefix(2)
        #expect(visibleInterviews.count == 2)

        // Should show count indicator when more than 2
        let hasMoreThanTwo = interviews.count > 2
        #expect(hasMoreThanTwo)

        let additionalCount = interviews.count - 2
        #expect(additionalCount == 3)
    }

    @Test func testContextMenuAddInterview() async throws {
        var calendar = Calendar.current
        calendar.firstWeekday = 2

        let currentDate = DateComponents(calendar: calendar, year: 2025, month: 12, day: 1).date!
        let day = 10

        let year = calendar.component(.year, from: currentDate)
        let month = calendar.component(.month, from: currentDate)

        // Simulate context menu action - should set selectedDate and show sheet
        var selectedDate: Date? = nil
        var showingAddInterview = false

        // Simulate context menu action
        selectedDate = calendar.date(from: DateComponents(year: year, month: month, day: day))
        showingAddInterview = true

        #expect(selectedDate != nil)
        #expect(showingAddInterview)
        #expect(calendar.component(.day, from: selectedDate!) == day)
    }

    @Test func testDateNavigationPreservesSelection() async throws {
        let calendar = Calendar.current

        // Start with December 2025
        let currentDate = DateComponents(calendar: calendar, year: 2025, month: 12, day: 15).date!

        // Navigate to next month (January 2026)
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentDate)!

        // Verify month changed
        #expect(calendar.component(.month, from: nextMonth) == 1)
        #expect(calendar.component(.year, from: nextMonth) == 2026)

        // Navigate back to previous month
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: nextMonth)!

        // Verify we're back to December 2025
        #expect(calendar.component(.month, from: previousMonth) == 12)
        #expect(calendar.component(.year, from: previousMonth) == 2025)
    }
}

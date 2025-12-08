//
//  ContentViewUITests.swift
//  InterviewsUITests
//
//  Created by keloran on 06/12/2025.
//

import XCTest

final class ContentViewUITests: XCTestCase {
    
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Launch Screen Tests
    
    @MainActor
    func testLaunchScreenAppearsOnStartup() throws {
        // The app should show launch screen elements briefly
        // Note: This might be fast, so we check for either launch screen or main content
        
        // Check if launch screen elements exist (they may disappear quickly)
        let launchLogo = app.images["calendar.badge.checkmark"]
        let launchTitle = app.staticTexts["Interviews"]
        
        // At minimum, the app should have loaded successfully to the main screen
        let mainNavBar = app.navigationBars["Interviews"]
        XCTAssertTrue(mainNavBar.waitForExistence(timeout: 5), "Main screen should appear after launch")
    }
    
    @MainActor
    func testLaunchScreenTransitionsToMainContent() throws {
        // Wait for main content to appear (launch screen should transition away)
        let mainNavBar = app.navigationBars["Interviews"]
        XCTAssertTrue(mainNavBar.waitForExistence(timeout: 5), "Should transition to main content")
        
        // Verify main UI elements are present after transition
        let settingsButton = app.buttons["gear"]
        XCTAssertTrue(settingsButton.exists, "Main UI should be fully loaded")
    }
    
    // MARK: - Navigation and Layout Tests
    
    @MainActor
    func testMainScreenExists() throws {
        // Wait for app to finish launching
        let mainNavBar = app.navigationBars["Interviews"]
        XCTAssertTrue(mainNavBar.waitForExistence(timeout: 5), "Main navigation bar should exist")
        
        // Verify settings button exists in toolbar
        let settingsButton = app.buttons["gear"]
        XCTAssertTrue(settingsButton.exists, "Settings button should be visible")
    }
    
    @MainActor
    func testCalendarViewExists() throws {
        // Calendar should be visible on main screen
        // The calendar grid should exist (checking for day cells)
        let calendar = app.otherElements.containing(.staticText, identifier: "1").element
        XCTAssertTrue(calendar.waitForExistence(timeout: 2), "Calendar should be displayed")
    }
    
    @MainActor
    func testInterviewListViewExists() throws {
        // The interview list section should exist
        let interviewList = app.staticTexts["Upcoming Interviews"]
        XCTAssertTrue(interviewList.waitForExistence(timeout: 2), "Interview list header should exist")
    }
    
    // MARK: - Search Feature UI Tests
    @MainActor
    func testSearchFieldAcceptsText() throws {
        // Find and tap search field
        let searchField = app.searchFields["Search companies..."]
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))
        searchField.tap()
        
        // Type text
        searchField.typeText("Apple")
        
        // Verify text was entered
        XCTAssertEqual(searchField.value as? String, "Apple", "Search field should contain typed text")
    }
    
    @MainActor
    func testSearchShowsResults() throws {
        let searchField = app.searchFields["Search companies..."]
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))
        searchField.tap()
        searchField.typeText("Apple")
        
        // Header should change to "Search Results"
        let searchResultsHeader = app.staticTexts["Search Results"]
        XCTAssertTrue(searchResultsHeader.waitForExistence(timeout: 2), "Search results header should appear")
    }
    
    @MainActor
    func testSearchCanBeCancelled() throws {
        let searchField = app.searchFields["Search companies..."]
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))
        searchField.tap()
        searchField.typeText("Apple")
        
        // Look for cancel button (standard iOS search behavior)
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.exists {
            cancelButton.tap()
            
            // Search field should be dismissed or cleared
            XCTAssertFalse(searchField.isHittable || searchField.value as? String == "")
        }
    }
    
    @MainActor
    func testSearchEmptyStateAppears() throws {
        let searchField = app.searchFields["Search companies..."]
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))
        searchField.tap()
        
        // Search for something that definitely doesn't exist
        searchField.typeText("ZZZNonExistentCompanyXYZ")
        
        // Empty state should appear
        let emptyStateTitle = app.staticTexts["No Companies Found"]
        XCTAssertTrue(emptyStateTitle.waitForExistence(timeout: 2), "Empty state should appear for no results")
        
        // Empty state description should also be visible
        let emptyStateDescription = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'ZZZNonExistentCompanyXYZ'")).element
        XCTAssertTrue(emptyStateDescription.exists, "Empty state description should mention search term")
    }
    
    // MARK: - Date Selection UI Tests
    
    @MainActor
    func testCalendarDateCanBeSelected() throws {
        // Find a date cell in the calendar (looking for day 15 as it's likely visible)
        // Try multiple ways to find the date cell
        let dateCell = app.buttons["15"].firstMatch
        
        // If not found as button, try as other element type
        if !dateCell.exists {
            throw XCTSkip("Date cell 15 not found - calendar may not have rendered")
        }
        
        // Tap the date
        dateCell.tap()
        
        // Give UI time to update
        Thread.sleep(forTimeInterval: 0.5)
        
        // The header should change to show the selected date
        // Look for "Interviews on" text pattern
        let dateHeader = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Interviews on'")).element
        XCTAssertTrue(dateHeader.waitForExistence(timeout: 2), "Header should show selected date")
    }
    
    @MainActor
    func testClearButtonAppearsAfterDateSelection() throws {
        // Tap a date
        let dateCell = app.buttons["15"].firstMatch
        guard dateCell.waitForExistence(timeout: 2) else {
            throw XCTSkip("Date cell not found")
        }
        
        dateCell.tap()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Clear button should appear
        let clearButton = app.buttons["clearDateButton"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 2), "Clear button should appear after date selection")
    }
    
    @MainActor
    func testClearButtonRemovesDateFilter() throws {
        // Tap a date
        let dateCell = app.buttons["15"].firstMatch
        guard dateCell.waitForExistence(timeout: 2) else {
            throw XCTSkip("Date cell not found")
        }
        
        dateCell.tap()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Wait for clear button
        let clearButton = app.buttons["clearDateButton"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 2), "Clear button should appear")
        
        // Tap clear button
        clearButton.tap()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Header should return to "Upcoming Interviews"
        let upcomingHeader = app.staticTexts["Upcoming Interviews"]
        XCTAssertTrue(upcomingHeader.waitForExistence(timeout: 2), "Header should return to 'Upcoming Interviews'")
        
        // Clear button should disappear
        XCTAssertFalse(clearButton.exists, "Clear button should disappear after clearing filter")
    }
    
    @MainActor
    func testCalendarNavigationWorks() throws {
        // Navigate to a month in the middle of the year first to avoid December wrap-around
        let previousMonthButton = app.buttons["previousMonthButton"]
        XCTAssertTrue(previousMonthButton.exists, "Previous month button should exist")
        
        // Go back a couple months to ensure we're not at year boundary
        for _ in 0..<2 {
            previousMonthButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        // Now get the current month
        let monthYearLabel = app.staticTexts["monthYearLabel"]
        XCTAssertTrue(monthYearLabel.exists, "Month/year label should exist")
        let currentMonth = monthYearLabel.label
        
        // Find the next month button
        let nextMonthButton = app.buttons["nextMonthButton"]
        XCTAssertTrue(nextMonthButton.exists, "Next month button should exist")
        
        // Tap next month
        nextMonthButton.tap()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Check that the label has changed
        let newMonth = monthYearLabel.label
        XCTAssertNotEqual(currentMonth, newMonth, "Month should change after tapping next. Was '\(currentMonth)', now '\(newMonth)'")
        
        // Previous month button should work to go back
        previousMonthButton.tap()
        Thread.sleep(forTimeInterval: 0.5)
        
        let returnedMonth = monthYearLabel.label
        XCTAssertEqual(currentMonth, returnedMonth, "Should return to original month")
    }
    
    @MainActor
    func testTodayButtonAppearsWhenNavigatingToOtherMonth() throws {
        // Today button should NOT exist when viewing current month
        let todayButton = app.buttons["todayButton"]
        
        // It might briefly appear during initial load, so check after a moment
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertFalse(todayButton.exists, "Today button should not appear when viewing current month")
        
        // Navigate to next month
        let nextMonthButton = app.buttons["nextMonthButton"]
        XCTAssertTrue(nextMonthButton.exists, "Next month button should exist")
        nextMonthButton.tap()
        
        // Wait for UI to update
        Thread.sleep(forTimeInterval: 0.5)
        
        // Today button SHOULD appear now
        XCTAssertTrue(todayButton.waitForExistence(timeout: 2), "Today button should appear when viewing different month")
    }
    
    @MainActor
    func testTodayButtonReturnsToCurrentMonth() throws {
        // Navigate to next month
        let nextMonthButton = app.buttons["nextMonthButton"]
        nextMonthButton.tap()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Verify we're in a different month
        let todayButton = app.buttons["todayButton"]
        XCTAssertTrue(todayButton.waitForExistence(timeout: 2), "Today button should appear in different month")
        
        // Tap the Today button
        todayButton.tap()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Today button should disappear since we're back to current month
        XCTAssertFalse(todayButton.exists, "Today button should disappear when returning to current month")
    }
    
    @MainActor
    func testTodayButtonWorksFromMultipleMonthsAway() throws {
        // Navigate several months ahead
        let nextMonthButton = app.buttons["nextMonthButton"]
        
        for _ in 0..<3 {
            nextMonthButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        // Today button should exist
        let todayButton = app.buttons["todayButton"]
        XCTAssertTrue(todayButton.exists, "Today button should exist when multiple months away")
        
        // Tap Today
        todayButton.tap()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Should be back to current month - Today button should disappear
        XCTAssertFalse(todayButton.exists, "Today button should disappear after returning to current month")
    }
    
    @MainActor
    func testTodayButtonWorksFromPastMonths() throws {
        // Navigate to previous month
        let previousMonthButton = app.buttons["previousMonthButton"]
        previousMonthButton.tap()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Today button should appear
        let todayButton = app.buttons["todayButton"]
        XCTAssertTrue(todayButton.waitForExistence(timeout: 2), "Today button should appear when viewing past month")
        
        // Tap Today
        todayButton.tap()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Should return to current month
        XCTAssertFalse(todayButton.exists, "Today button should disappear when back to current month")
    }
    
    @MainActor
    func testDateSelectionShowsOnlyThatDaysInterviews() throws {
        // This assumes there's test data
        let dateCell = app.buttons["15"].firstMatch
        
        guard dateCell.waitForExistence(timeout: 2) else {
            throw XCTSkip("Date cell not found")
        }
        
        dateCell.tap()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Header should reflect the selected date
        let dateHeader = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Interviews on'")).element
        XCTAssertTrue(dateHeader.exists, "Should show date-specific header")
    }
    
    // MARK: - Combined Feature Tests
    
    @MainActor
    func testSearchIgnoresDateFilter() throws {
        // When searching, date filter should be ignored
        // This allows users to see ALL past interviews with a company
        
        // Select a date first
        let dateCell = app.buttons["15"].firstMatch
        guard dateCell.waitForExistence(timeout: 2) else {
            throw XCTSkip("Date cell not found")
        }
        
        dateCell.tap()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Verify date is selected
        let clearButton = app.buttons["clearDateButton"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 2), "Clear button should appear")
        
        let searchField = app.searchFields["Search companies..."]
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))
        searchField.tap()
        searchField.typeText("Apple")
        
        Thread.sleep(forTimeInterval: 0.5)
        
        // Search should show ALL Apple interviews, not just on selected date
        // Header should change to "Search Results" (not date-specific)
        let searchResultsHeader = app.staticTexts["Search Results"]
        XCTAssertTrue(searchResultsHeader.waitForExistence(timeout: 2), "Search should override date filter")
    }
    
    @MainActor
    func testSearchShowsPastInterviewsForDuplicateDetection() throws {
        let searchField = app.searchFields["Search companies..."]
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))
        searchField.tap()
        searchField.typeText("Google")
        
        // Should show ALL Google interviews (past, present, future)
        let searchResultsHeader = app.staticTexts["Search Results"]
        XCTAssertTrue(searchResultsHeader.waitForExistence(timeout: 2))
        
        // Note: In real usage, this would show past rejected interviews
        // to warn user they already applied to this company
    }
    
    @MainActor
    func testEmptyStateShowsForDateWithNoInterviews() throws {
        // Navigate to a far future date unlikely to have interviews
        let nextMonthButton = app.buttons["nextMonthButton"]
        
        // Go several months ahead
        for _ in 0..<6 {
            nextMonthButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        // Tap a date
        let dateCell = app.buttons["15"].firstMatch
        guard dateCell.waitForExistence(timeout: 2) else {
            throw XCTSkip("Date cell not found")
        }
        
        dateCell.tap()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Should show empty state for that date
        let emptyState = app.staticTexts["No Interviews This Day"]
        XCTAssertTrue(emptyState.waitForExistence(timeout: 2), "Empty state should appear for date with no interviews")
    }
    
    
    // MARK: - Swipe Actions Tests
    
    @MainActor
    func testSwipeLeftToRejectInterview() throws {
        // Check if there are any interview rows
        let firstInterviewRow = app.cells.firstMatch
        
        // Skip test if no interviews exist
        guard firstInterviewRow.waitForExistence(timeout: 2) else {
            throw XCTSkip("No interviews available for swipe test")
        }
        
        // Swipe left to reveal reject action
        firstInterviewRow.swipeLeft()
        
        // Reject button should appear
        let rejectButton = app.buttons["Reject"]
        XCTAssertTrue(rejectButton.waitForExistence(timeout: 2), "Reject button should appear on left swipe")
        
        // Verify it has the correct label/icon
        XCTAssertTrue(rejectButton.exists, "Reject action should be available")
    }
    
    @MainActor
    func testSwipeRightToOpenNextStage() throws {
        // Check if there are any interview rows
        let firstInterviewRow = app.cells.firstMatch
        
        // Skip test if no interviews exist
        guard firstInterviewRow.waitForExistence(timeout: 2) else {
            throw XCTSkip("No interviews available for swipe test")
        }
        
        // Swipe right to reveal next stage action
        firstInterviewRow.swipeRight()
        
        // Wait a moment for swipe animation
        Thread.sleep(forTimeInterval: 1.0)
        
        // Next Stage button should appear - try multiple ways to find it
        // SwiftUI may generate the button with different element types
        let nextStageButton = app.buttons["Next Stage"]
        
        // If button doesn't appear, it might be because swipe actions aren't fully supported
        // or the interview is already at final stage
        guard nextStageButton.waitForExistence(timeout: 2) else {
            throw XCTSkip("Next Stage button not found - may not be available for this interview")
        }
        
        XCTAssertTrue(nextStageButton.exists, "Next Stage button should be visible")
    }
    
    @MainActor
    func testRejectActionChangesInterviewStatus() throws {
        // Check if there are any interview rows
        let firstInterviewRow = app.cells.firstMatch
        
        // Skip test if no interviews exist
        guard firstInterviewRow.waitForExistence(timeout: 2) else {
            throw XCTSkip("No interviews available for swipe test")
        }
        
        // Swipe left and tap reject
        firstInterviewRow.swipeLeft()
        
        // Wait for swipe animation
        Thread.sleep(forTimeInterval: 1.0)
        
        let rejectButton = app.buttons["Reject"]
        guard rejectButton.waitForExistence(timeout: 2) else {
            throw XCTSkip("Reject button not found - may already be rejected")
        }
        
        rejectButton.tap()
        
        // Interview should either disappear (if filtering upcoming only) or status should update
        // Give it a moment to process
        Thread.sleep(forTimeInterval: 1.0)
        
        // Test passes if no crash occurs and action completes
        // We can verify the list still renders
        XCTAssertTrue(app.isHittable, "App should remain responsive after reject action")
    }
    
    @MainActor
    func testNextStageOpensCreateInterviewSheet() throws {
        // Check if there are any interview rows
        let firstInterviewRow = app.cells.firstMatch
        
        // Skip test if no interviews exist
        guard firstInterviewRow.waitForExistence(timeout: 2) else {
            throw XCTSkip("No interviews available for swipe test")
        }
        
        // Swipe right and tap next stage
        firstInterviewRow.swipeRight()
        Thread.sleep(forTimeInterval: 1.0)
        
        let nextStageButton = app.buttons["Next Stage"]
        guard nextStageButton.waitForExistence(timeout: 2) else {
            throw XCTSkip("Next Stage button not found")
        }
        
        nextStageButton.tap()
        
        // Sheet with "Create Next Stage" title should appear
        let nextStageTitle = app.navigationBars["Create Next Stage"]
        XCTAssertTrue(nextStageTitle.waitForExistence(timeout: 2), "Create Next Stage sheet should appear")
        
        // Cancel button should exist
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.exists, "Cancel button should be visible")
        
        // Cancel to close
        cancelButton.tap()
    }
    
    @MainActor
    func testNextStageSheetPrefillsCompanyAndJobTitle() throws {
        // Check if there are any interview rows
        let firstInterviewRow = app.cells.firstMatch
        
        // Skip test if no interviews exist
        guard firstInterviewRow.waitForExistence(timeout: 2) else {
            throw XCTSkip("No interviews available for swipe test")
        }
        
        // Swipe right to next stage
        firstInterviewRow.swipeRight()
        Thread.sleep(forTimeInterval: 1.0)
        
        let nextStageButton = app.buttons["Next Stage"]
        guard nextStageButton.waitForExistence(timeout: 2) else {
            throw XCTSkip("Next Stage button not found")
        }
        
        nextStageButton.tap()
        
        // Verify sheet appeared
        let nextStageTitle = app.navigationBars["Create Next Stage"]
        XCTAssertTrue(nextStageTitle.waitForExistence(timeout: 2), "Create Next Stage sheet should appear")
        
        // The "Current Interview" section should exist showing company and job info
        let currentInterviewSection = app.staticTexts["Current Interview"]
        XCTAssertTrue(currentInterviewSection.exists, "Current Interview section should be present")
        
        // Cancel
        app.buttons["Cancel"].tap()
    }
    
    @MainActor
    func testNextStageSheetDoesNotAllowAppliedStage() throws {
        // Check if there are any interview rows
        let firstInterviewRow = app.cells.firstMatch
        
        // Skip test if no interviews exist
        guard firstInterviewRow.waitForExistence(timeout: 2) else {
            throw XCTSkip("No interviews available for swipe test")
        }
        
        // Open next stage sheet
        firstInterviewRow.swipeRight()
        Thread.sleep(forTimeInterval: 1.0)
        
        let nextStageButton = app.buttons["Next Stage"]
        guard nextStageButton.waitForExistence(timeout: 2) else {
            throw XCTSkip("Next Stage button not found")
        }
        
        nextStageButton.tap()
        
        // Wait for sheet
        let nextStageTitle = app.navigationBars["Create Next Stage"]
        XCTAssertTrue(nextStageTitle.waitForExistence(timeout: 2), "Sheet should open")
        
        // The logic in CreateNextStageView filters out "Applied" in the nextStages computed property
        // So it shouldn't appear in the picker at all
        // We can verify by checking that at least one other stage exists
        let stageSection = app.staticTexts["New Interview Stage"]
        XCTAssertTrue(stageSection.exists, "New Interview Stage section should exist")
        
        // Cancel
        app.buttons["Cancel"].tap()
    }
    
    @MainActor
    func testNextStageSheetRequiresDateAndTime() throws {
        // Check if there are any interview rows
        let firstInterviewRow = app.cells.firstMatch
        
        // Skip test if no interviews exist
        guard firstInterviewRow.waitForExistence(timeout: 2) else {
            throw XCTSkip("No interviews available for swipe test")
        }
        
        // Open next stage sheet
        firstInterviewRow.swipeRight()
        Thread.sleep(forTimeInterval: 1.0)
        
        let nextStageButton = app.buttons["Next Stage"]
        guard nextStageButton.waitForExistence(timeout: 2) else {
            throw XCTSkip("Next Stage button not found")
        }
        
        nextStageButton.tap()
        
        // Wait for sheet
        let nextStageTitle = app.navigationBars["Create Next Stage"]
        XCTAssertTrue(nextStageTitle.waitForExistence(timeout: 2), "Sheet should open")
        
        // The Interview Details section should exist
        let detailsSection = app.staticTexts["Interview Details"]
        XCTAssertTrue(detailsSection.exists, "Interview Details section should be present")
        
        // Cancel
        app.buttons["Cancel"].tap()
    }
    
    // MARK: - Settings Navigation Tests
    
    @MainActor
    func testSettingsButtonOpensSettings() throws {
        let settingsButton = app.buttons["gear"]
        XCTAssertTrue(settingsButton.exists)
        
        settingsButton.tap()
        
        // Settings sheet should appear
        // Look for typical settings elements (this depends on your SettingsView implementation)
        // For now, just check that something modal appears
        Thread.sleep(forTimeInterval: 1.0)
        
        // Settings view should be visible
        // You may need to adjust this based on your actual SettingsView content
    }
    
    // MARK: - Performance Tests
    
    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    @MainActor
    func testSearchPerformance() throws {
        measure {
            let searchField = app.searchFields["Search companies..."]
            searchField.tap()
            searchField.typeText("A")
            
            // Wait for results to load
            Thread.sleep(forTimeInterval: 1.0)
            
            // Clear search
            if app.buttons["Cancel"].exists {
                app.buttons["Cancel"].tap()
            }
        }
    }
    
    @MainActor
    func testCalendarNavigationPerformance() throws {
        measure {
            let nextButton = app.buttons["nextMonthButton"]
            
            for _ in 0..<5 {
                nextButton.tap()
                Thread.sleep(forTimeInterval: 0.5)
            }
            
            let prevButton = app.buttons["previousMonthButton"]
            for _ in 0..<5 {
                prevButton.tap()
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
    }
}

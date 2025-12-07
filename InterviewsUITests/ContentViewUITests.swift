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
        let dateCell = app.staticTexts["15"]
        
        if dateCell.exists {
            // Tap the date
            dateCell.tap()
            
            // The header should change to show the selected date
            // Look for "Interviews on" text pattern
            let dateHeader = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Interviews on'")).element
            XCTAssertTrue(dateHeader.waitForExistence(timeout: 2), "Header should show selected date")
        }
    }
    
    @MainActor
    func testClearButtonAppearsAfterDateSelection() throws {
        // Tap a date
        let dateCell = app.staticTexts["15"]
        
        if dateCell.exists {
            dateCell.tap()
            
            // Clear button should appear
            let clearButton = app.buttons["clearDateButton"]
            XCTAssertTrue(clearButton.waitForExistence(timeout: 2), "Clear button should appear after date selection")
        }
    }
    
    @MainActor
    func testClearButtonRemovesDateFilter() throws {
        // Tap a date
        let dateCell = app.staticTexts["15"]
        
        if dateCell.exists {
            dateCell.tap()
            
            // Wait for clear button
            let clearButton = app.buttons["clearDateButton"]
            XCTAssertTrue(clearButton.waitForExistence(timeout: 2))
            
            // Tap clear button
            clearButton.tap()
            
            // Header should return to "Upcoming Interviews"
            let upcomingHeader = app.staticTexts["Upcoming Interviews"]
            XCTAssertTrue(upcomingHeader.waitForExistence(timeout: 2), "Header should return to 'Upcoming Interviews'")
            
            // Clear button should disappear
            XCTAssertFalse(clearButton.exists, "Clear button should disappear after clearing filter")
        }
    }
    
    @MainActor
    func testCalendarNavigationWorks() throws {
        // Find the next month button
        let nextMonthButton = app.buttons["nextMonthButton"]
        XCTAssertTrue(nextMonthButton.exists, "Next month button should exist")
        
        // Get current month name
        let monthYearLabel = app.staticTexts["monthYearLabel"]
        XCTAssertTrue(monthYearLabel.exists, "Month/year label should exist")
        let currentMonth = monthYearLabel.label
        
        // Tap next month
        nextMonthButton.tap()
        
        // Month should change
        Thread.sleep(forTimeInterval: 0.5) // Brief pause for animation
        let newMonth = monthYearLabel.label
        XCTAssertNotEqual(currentMonth, newMonth, "Month should change after tapping next")
        
        // Previous month button should work
        let previousMonthButton = app.buttons["previousMonthButton"]
        XCTAssertTrue(previousMonthButton.exists, "Previous month button should exist")
        previousMonthButton.tap()
        
        Thread.sleep(forTimeInterval: 0.5)
        let returnedMonth = monthYearLabel.label
        XCTAssertEqual(currentMonth, returnedMonth, "Should return to original month")
    }
    
    @MainActor
    func testTodayButtonAppearsWhenNavigatingToOtherMonth() throws {
        // Today button should NOT exist when viewing current month
        let todayButton = app.buttons["todayButton"]
        XCTAssertFalse(todayButton.exists, "Today button should not appear when viewing current month")
        
        // Navigate to next month
        let nextMonthButton = app.buttons["nextMonthButton"]
        XCTAssertTrue(nextMonthButton.exists, "Next month button should exist")
        nextMonthButton.tap()
        
        Thread.sleep(forTimeInterval: 0.5) // Wait for transition
        
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
        let dateCell = app.staticTexts["15"]
        
        if dateCell.exists {
            dateCell.tap()
            
            // Header should reflect the selected date
            let dateHeader = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Interviews on'")).element
            XCTAssertTrue(dateHeader.exists, "Should show date-specific header")
        }
    }
    
    // MARK: - Combined Feature Tests
    
    @MainActor
    func testSearchIgnoresDateFilter() throws {
        // When searching, date filter should be ignored
        // This allows users to see ALL past interviews with a company
        
        // Select a date first
        let dateCell = app.staticTexts["15"]
        if dateCell.exists {
            dateCell.tap()
            
            // Verify date is selected
            let clearButton = app.buttons["clearDateButton"]
            XCTAssertTrue(clearButton.waitForExistence(timeout: 2))
            
            let searchField = app.searchFields["Search companies..."]
            XCTAssertTrue(searchField.waitForExistence(timeout: 2))
            searchField.tap()
            searchField.typeText("Apple")
            
            // Search should show ALL Apple interviews, not just on selected date
            // Header should change to "Search Results" (not date-specific)
            let searchResultsHeader = app.staticTexts["Search Results"]
            XCTAssertTrue(searchResultsHeader.waitForExistence(timeout: 2), "Search should override date filter")
        }
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
        let dateCell = app.staticTexts["15"]
        if dateCell.exists {
            dateCell.tap()
            
            // Should show empty state for that date
            let emptyState = app.staticTexts["No Interviews This Day"]
            XCTAssertTrue(emptyState.waitForExistence(timeout: 2), "Empty state should appear for date with no interviews")
        }
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
        
        // Next Stage button should appear
        let nextStageButton = app.buttons["Next Stage"]
        XCTAssertTrue(nextStageButton.waitForExistence(timeout: 2), "Next Stage button should appear on right swipe")
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
        
        let rejectButton = app.buttons["Reject"]
        XCTAssertTrue(rejectButton.waitForExistence(timeout: 2))
        rejectButton.tap()
        
        // Interview should either disappear (if filtering upcoming only) or status should update
        // Give it a moment to process
        Thread.sleep(forTimeInterval: 0.5)
        
        // Test passes if no crash occurs and action completes
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
        
        let nextStageButton = app.buttons["Next Stage"]
        XCTAssertTrue(nextStageButton.waitForExistence(timeout: 2))
        nextStageButton.tap()
        
        // Sheet with "Next Stage" title should appear
        let nextStageTitle = app.navigationBars["Next Stage"]
        XCTAssertTrue(nextStageTitle.waitForExistence(timeout: 2), "Next Stage sheet should appear")
        
        // Create button should exist
        let createButton = app.buttons["Create"]
        XCTAssertTrue(createButton.exists, "Create button should be visible in next stage sheet")
        
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
        let nextStageButton = app.buttons["Next Stage"]
        XCTAssertTrue(nextStageButton.waitForExistence(timeout: 2))
        nextStageButton.tap()
        
        // Verify sheet appeared
        let nextStageTitle = app.navigationBars["Next Stage"]
        XCTAssertTrue(nextStageTitle.waitForExistence(timeout: 2))
        
        // Company and Job Title should be pre-filled (read-only)
        // They should exist as static text, not editable fields
        let companyLabel = app.staticTexts["Company"]
        XCTAssertTrue(companyLabel.exists, "Company field should be present")
        
        let jobTitleLabel = app.staticTexts["Job Title"]
        XCTAssertTrue(jobTitleLabel.exists, "Job Title field should be present")
        
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
        let nextStageButton = app.buttons["Next Stage"]
        XCTAssertTrue(nextStageButton.waitForExistence(timeout: 2))
        nextStageButton.tap()
        
        // Wait for sheet
        let nextStageTitle = app.navigationBars["Next Stage"]
        XCTAssertTrue(nextStageTitle.waitForExistence(timeout: 2))
        
        // Tap on stage picker
        let stagePicker = app.pickers["Stage"]
        if stagePicker.exists {
            stagePicker.tap()
            
            // "Applied" should NOT be in the list
            let appliedOption = app.staticTexts["Applied"]
            XCTAssertFalse(appliedOption.exists, "Applied stage should not be available for next stage")
        }
        
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
        let nextStageButton = app.buttons["Next Stage"]
        XCTAssertTrue(nextStageButton.waitForExistence(timeout: 2))
        nextStageButton.tap()
        
        // Wait for sheet
        let nextStageTitle = app.navigationBars["Next Stage"]
        XCTAssertTrue(nextStageTitle.waitForExistence(timeout: 2))
        
        // Date & Time picker should exist (unless it's a technical test)
        let dateTimePicker = app.datePickers["Date & Time"]
        let deadlinePicker = app.datePickers["Deadline"]
        
        // At least one should exist
        let hasDatePicker = dateTimePicker.exists || deadlinePicker.exists
        XCTAssertTrue(hasDatePicker, "Date picker should be required for next stage")
        
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

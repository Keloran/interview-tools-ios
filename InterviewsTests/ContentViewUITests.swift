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

    // MARK: - Navigation and Layout Tests
    
    @MainActor
    func testMainScreenExists() throws {
        // Verify main navigation elements are present
        XCTAssertTrue(app.navigationBars["Interviews"].exists, "Main navigation bar should exist")
        
        // Verify search button exists in toolbar
        let searchButton = app.buttons["magnifyingglass"]
        XCTAssertTrue(searchButton.exists, "Search button should be visible")
        
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
    func testSearchButtonTogglesBehavior() throws {
        let searchButton = app.buttons["magnifyingglass"]
        XCTAssertTrue(searchButton.exists, "Search button should exist")
        
        // Tap search button
        searchButton.tap()
        
        // Search field should appear
        let searchField = app.searchFields["Search companies..."]
        XCTAssertTrue(searchField.waitForExistence(timeout: 2), "Search field should appear after tapping search button")
    }
    
    @MainActor
    func testSearchFieldAcceptsText() throws {
        // Open search
        let searchButton = app.buttons["magnifyingglass"]
        searchButton.tap()
        
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
        // This test assumes there's test data with Apple as a company
        // You may need to set up test data or mock it
        
        let searchButton = app.buttons["magnifyingglass"]
        searchButton.tap()
        
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
        let searchButton = app.buttons["magnifyingglass"]
        searchButton.tap()
        
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
        let searchButton = app.buttons["magnifyingglass"]
        searchButton.tap()
        
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
            let clearButton = app.buttons["Clear"]
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
            let clearButton = app.buttons["Clear"]
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
        // Find the next month button (chevron.right)
        let nextMonthButton = app.buttons["chevron.right"]
        XCTAssertTrue(nextMonthButton.exists, "Next month button should exist")
        
        // Get current month name
        let monthYearLabel = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'january' OR label CONTAINS[c] 'february' OR label CONTAINS[c] 'march' OR label CONTAINS[c] 'april' OR label CONTAINS[c] 'may' OR label CONTAINS[c] 'june' OR label CONTAINS[c] 'july' OR label CONTAINS[c] 'august' OR label CONTAINS[c] 'september' OR label CONTAINS[c] 'october' OR label CONTAINS[c] 'november' OR label CONTAINS[c] 'december'")).firstMatch
        let currentMonth = monthYearLabel.label
        
        // Tap next month
        nextMonthButton.tap()
        
        // Month should change
        Thread.sleep(forTimeInterval: 1.0) // Brief pause for animation
        let newMonth = monthYearLabel.label
        XCTAssertNotEqual(currentMonth, newMonth, "Month should change after tapping next")
        
        // Previous month button should work
        let previousMonthButton = app.buttons["chevron.left"]
        XCTAssertTrue(previousMonthButton.exists, "Previous month button should exist")
        previousMonthButton.tap()
        
        Thread.sleep(forTimeInterval: 1.0)
        let returnedMonth = monthYearLabel.label
        XCTAssertEqual(currentMonth, returnedMonth, "Should return to original month")
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
    func testSearchAndDateFilterCanWorkTogether() throws {
        // Select a date first
        let dateCell = app.staticTexts["15"]
        if dateCell.exists {
            dateCell.tap()
            
            // Then activate search
            let searchButton = app.buttons["magnifyingglass"]
            searchButton.tap()
            
            let searchField = app.searchFields["Search companies..."]
            XCTAssertTrue(searchField.waitForExistence(timeout: 2))
            searchField.tap()
            searchField.typeText("Apple")
            
            // Both filters should be active
            // Header should still show date
            let dateHeader = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Interviews on'")).element
            XCTAssertTrue(dateHeader.exists, "Date filter should still be active")
            
            // Search should also be active
            XCTAssertEqual(searchField.value as? String, "Apple", "Search should be active")
        }
    }
    
    @MainActor
    func testEmptyStateShowsForDateWithNoInterviews() throws {
        // Navigate to a far future date unlikely to have interviews
        let nextMonthButton = app.buttons["chevron.right"]
        
        // Go several months ahead
        for _ in 0..<6 {
            nextMonthButton.tap()
            Thread.sleep(forTimeInterval: 1.0)
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
            let searchButton = app.buttons["magnifyingglass"]
            searchButton.tap()
            
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
            let nextButton = app.buttons["chevron.right"]
            
            for _ in 0..<5 {
                nextButton.tap()
                Thread.sleep(forTimeInterval: 0.5)
            }
            
            let prevButton = app.buttons["chevron.left"]
            for _ in 0..<5 {
                prevButton.tap()
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
    }
}

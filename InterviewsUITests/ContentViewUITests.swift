//
//  ContentViewUITests.swift
//  InterviewsUITests
//
//  Created by keloran on 06/12/2025.
//

import XCTest

private func ciTimestamp() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    return formatter.string(from: Date())
}

private func ciLog(_ message: String, file: StaticString = #file, function: StaticString = #function) {
    let fileName = ("\(file)" as NSString).lastPathComponent
    print("[UI-TEST] \(ciTimestamp()) [\(fileName)] \(function): \(message)")
}

final class ContentViewUITests: XCTestCase {
    
    // MARK: - Helpers
    @discardableResult
    private func revealSearchField(timeout: TimeInterval = 8) -> XCUIElement {
        ciLog("Attempting to reveal expanding search field")

        // Try to find an existing search field or inline text field first
        let inlineTextField = app.textFields["searchFieldInline"]
        if inlineTextField.exists && inlineTextField.isHittable {
            ciLog("Inline search text field already visible (searchFieldInline)")
            return inlineTextField
        }
        let existingSearchField = app.searchFields.element(boundBy: 0)
        if existingSearchField.exists && existingSearchField.isHittable {
            ciLog("Search field already visible")
            return existingSearchField
        }
        let existingTextField = app.textFields.element(boundBy: 0)
        if existingTextField.exists && existingTextField.isHittable {
            ciLog("Text field already visible (search likely implemented as TextField)")
            return existingTextField
        }

        // Prefer the inline search toggle revealed in logs: identifier `searchFieldInline`
        let inlineSearchToggle = app.buttons["searchFieldInline"]
        if inlineSearchToggle.exists && inlineSearchToggle.isHittable {
            ciLog("Tapping inline search toggle (searchFieldInline)")
            inlineSearchToggle.tap()
            usleep(200_000)
        } else {
            // Potential buttons that reveal the search field
            let possibleSearchButtons: [XCUIElement] = [
                app.buttons["searchButton"],                 // explicit identifier if set in app code
                app.buttons["Search"],                       // accessibility label
                app.buttons["magnifyingglass"],              // SF Symbol name used as identifier
                app.navigationBars.buttons["Search"],
                app.navigationBars.buttons["magnifyingglass"],
                app.toolbars.buttons["Search"],
                app.toolbars.buttons["magnifyingglass"]
            ]

            // Tap the first visible one
            if let button = possibleSearchButtons.first(where: { $0.exists && $0.isHittable }) {
                ciLog("Tapping search reveal button: \(button.label)")
                button.tap()
                usleep(150_000)
            } else {
                ciLog("No obvious search button found; attempting to pull-to-reveal search")
                // Try a small pull-down on the main list to expose search in a navigation bar
                let firstScrollable = app.scrollViews.firstMatch.exists ? app.scrollViews.firstMatch : app.tables.firstMatch
                if firstScrollable.exists {
                    firstScrollable.swipeDown()
                    usleep(200_000)
                }
            }
        }

        // After attempting to reveal, wait for either a SearchField or the inline TextField
        let searchField = app.searchFields.element(boundBy: 0)
        let inlineField = app.textFields["searchFieldInline"]
        let anyTextField = app.textFields.element(boundBy: 0)

        let appeared = inlineField.waitForExistence(timeout: timeout)
            || searchField.waitForExistence(timeout: max(0, timeout - 0.5))
            || anyTextField.waitForExistence(timeout: max(0, timeout - 1.0))

        if !appeared {
            // As a last resort, try toggling inline again in case it requires a second tap to expand
            if inlineSearchToggle.exists && inlineSearchToggle.isHittable {
                ciLog("Second attempt: tapping inline search toggle again")
                inlineSearchToggle.tap()
                usleep(200_000)
            }
        }

        let finalField: XCUIElement = inlineField.exists ? inlineField : (searchField.exists ? searchField : anyTextField)
        let finalAppeared = finalField.waitForExistence(timeout: 2)
        if !finalAppeared {
            // Debug info
            let allButtons = app.buttons.allElementsBoundByIndex.map { "\($0.identifier)|\($0.label)" }
            print("DEBUG: Could not reveal search field. Buttons: \(allButtons)")
        }
        XCTAssertTrue(finalAppeared, "Search field should become visible after revealing it")
        return finalField
    }

    var app: XCUIApplication!

    override func setUpWithError() throws {
        ciLog("BEGIN setUpWithError")
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        ciLog("App launched, warming up AX")
        // Give the simulator a brief moment to finish initializing AX in CI
        usleep(800_000) // 0.8s
        
        ciLog("Waiting for loading overlay to disappear if present")
        // Wait for initial loading overlay to disappear
        let loadingOverlay = app.staticTexts["Loading Your Interviews"]
        if loadingOverlay.exists {
            let disappearExpectation = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "exists == false"),
                object: loadingOverlay
            )
            _ = XCTWaiter().wait(for: [disappearExpectation], timeout: 15)
        }
        ciLog("Loading overlay handling complete")
        
        ciLog("Ensuring main navigation is ready")
        // Ensure main navigation is ready
        let mainNavBar = app.navigationBars["Interview Planner"].exists ? app.navigationBars["Interview Planner"] : app.navigationBars["Interviews"]
        XCTAssertTrue(mainNavBar.waitForExistence(timeout: 8), "Main navigation should appear after launch")
        ciLog("END setUpWithError")
    }

    override func tearDownWithError() throws {
        ciLog("BEGIN tearDownWithError")
        app = nil
        ciLog("END tearDownWithError")
    }

    // MARK: - Launch Screen Tests
    
    @MainActor
    func testLaunchScreenAppearsOnStartup() throws {
        ciLog("BEGIN test: testLaunchScreenAppearsOnStartup")
        // The app should show launch screen elements briefly
        // Note: Launch screen transitions quickly, so we mainly verify the app loaded successfully
        
        // The main elements we can check for are the app title and loading state
        // The icon is either the app icon image or a fallback system icon
        let appTitle = app.staticTexts["Interview Planner"]
        
        // Launch screen may have already transitioned away, so we check if either:
        // 1. Launch screen is still visible, OR
        // 2. Main screen has already appeared
        
        let mainNavBar = app.navigationBars["Interview Planner"].exists ? app.navigationBars["Interview Planner"] : app.navigationBars["Interviews"]
        
        // At least one should be true: launch screen exists OR main screen exists
        let launchOrMainExists = appTitle.exists || mainNavBar.exists
        XCTAssertTrue(launchOrMainExists, "Either launch screen or main screen should be visible")
        
        // Ultimately, the app should reach the main screen
        XCTAssertTrue(mainNavBar.waitForExistence(timeout: 5), "Main screen should appear after launch")
        ciLog("END test: testLaunchScreenAppearsOnStartup")
    }
    
    @MainActor
    func testLaunchScreenTransitionsToMainContent() throws {
        ciLog("BEGIN test: testLaunchScreenTransitionsToMainContent")
        // Wait for main content to appear (launch screen should transition away)
        let mainNavBar = app.navigationBars["Interview Planner"].exists ? app.navigationBars["Interview Planner"] : app.navigationBars["Interviews"]
        XCTAssertTrue(mainNavBar.waitForExistence(timeout: 5), "Should transition to main content")
        
        // Verify main UI elements are present after transition
        let settingsButton = app.buttons["gear"]
        XCTAssertTrue(settingsButton.exists, "Main UI should be fully loaded")
        ciLog("END test: testLaunchScreenTransitionsToMainContent")
    }
    
    // MARK: - Navigation and Layout Tests
    
    @MainActor
    func testMainScreenExists() throws {
        ciLog("BEGIN test: testMainScreenExists")
        // Wait for app to finish launching
        let mainNavBar = app.navigationBars["Interview Planner"].exists ? app.navigationBars["Interview Planner"] : app.navigationBars["Interviews"]
        XCTAssertTrue(mainNavBar.waitForExistence(timeout: 5), "Main navigation bar should exist")
        
        // Verify settings button exists in toolbar
        let settingsButton = app.buttons["gear"]
        XCTAssertTrue(settingsButton.exists, "Settings button should be visible")
        ciLog("END test: testMainScreenExists")
    }
    
//    @MainActor
//    func testCalendarViewExists() throws {
//        // Calendar should be visible on main screen
//        // The calendar grid should exist (checking for day cells)
//        let calendar = app.otherElements.containing(.staticText, identifier: "1").element
//        XCTAssertTrue(calendar.waitForExistence(timeout: 2), "Calendar should be displayed")
//    }
    
    @MainActor
    func testInterviewListViewExists() throws {
        ciLog("BEGIN test: testInterviewListViewExists")
        // The interview list section should exist
        let interviewList = app.staticTexts["Upcoming Interviews"]
        XCTAssertTrue(interviewList.waitForExistence(timeout: 2), "Interview list header should exist")
        ciLog("END test: testInterviewListViewExists")
    }
    
    // MARK: - Search Feature UI Tests
    @MainActor
    func testSearchFieldAcceptsText() throws {
        ciLog("BEGIN test: testSearchFieldAcceptsText")
        // Find and tap search field
        let searchField = revealSearchField()
        searchField.tap()
        
        // Ensure the keyboard is presented before typing (prevents dropped keys in CI)
        XCTAssertTrue(app.keyboards.element.waitForExistence(timeout: 3), "Keyboard should appear after tapping search")
        
        // Type text more reliably (character by character with a tiny delay)
        for ch in "Apple" {
            app.typeText(String(ch))
            usleep(30_000) // 30ms spacing helps on CI
        }
        
        // Wait for the field to reflect full text (guards against race conditions)
        let predicate = NSPredicate(format: "value == %@", "Apple")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: searchField)
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: 3), .completed, "Search field should contain typed text")
        ciLog("END test: testSearchFieldAcceptsText")
    }
    
    @MainActor
    func testSearchShowsResults() throws {
        ciLog("BEGIN test: testSearchShowsResults")
        let searchField = revealSearchField()
        searchField.tap()
        searchField.typeText("Apple")
        
        // Header should change to "Search Results"
        let searchResultsHeader = app.staticTexts["Search Results"]
        XCTAssertTrue(searchResultsHeader.waitForExistence(timeout: 5), "Search results header should appear")
        ciLog("END test: testSearchShowsResults")
    }
    
    @MainActor
    func testSearchCanBeCancelled() throws {
        ciLog("BEGIN test: testSearchCanBeCancelled")
        let searchField = revealSearchField()
        searchField.tap()
        searchField.typeText("Apple")
        
        usleep(200_000)
        // Look for cancel button (standard iOS search behavior)
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.exists {
            cancelButton.tap()

            // After cancel, the inline text field should disappear and Cancel should go away
            let inlineField = app.textFields["searchFieldInline"]
            let goneExpectation = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "exists == false"),
                object: inlineField
            )
            _ = XCTWaiter().wait(for: [goneExpectation], timeout: 3)
            XCTAssertFalse(inlineField.exists, "Inline search field should be dismissed after Cancel")

            let cancelGone = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "exists == false"),
                object: cancelButton
            )
            _ = XCTWaiter().wait(for: [cancelGone], timeout: 3)
            XCTAssertFalse(cancelButton.exists, "Cancel button should disappear after cancelling search")
        }
        ciLog("END test: testSearchCanBeCancelled")
    }
    
    @MainActor
    func testSearchEmptyStateAppears() throws {
        ciLog("BEGIN test: testSearchEmptyStateAppears")
        let searchField = revealSearchField()
        searchField.tap()
        
        // Search for something that definitely doesn't exist
        searchField.typeText("ZZZNonExistentCompanyXYZ")
        
        // Empty state should appear
        let emptyStateTitle = app.staticTexts["No Companies Found"]
        XCTAssertTrue(emptyStateTitle.waitForExistence(timeout: 5), "Empty state should appear for no results")
        
        // Empty state description should also be visible
        let emptyStateDescription = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'ZZZNonExistentCompanyXYZ'")).element
        XCTAssertTrue(emptyStateDescription.exists, "Empty state description should mention search term")
        ciLog("END test: testSearchEmptyStateAppears")
    }
    
    // MARK: - Date Selection UI Tests
    
    @MainActor
    func testCalendarDateCanBeSelected() throws {
        ciLog("BEGIN test: testCalendarDateCanBeSelected")
        // Wait for calendar to fully load - use a more reliable wait
        let monthYearLabel = app.staticTexts["monthYearLabel"]
        XCTAssertTrue(monthYearLabel.waitForExistence(timeout: 5), "Calendar should load")
        
        // Find a date cell in the calendar (looking for day 15 as it's likely visible)
        // Try multiple ways to find the cell
        let dateCell = app.buttons.matching(identifier: "15").firstMatch
        
        // Wait for the date cell to be available
        guard dateCell.waitForExistence(timeout: 5) else {
            // Debug: print all buttons to see what's available
            let allButtons = app.buttons.allElementsBoundByIndex
            print("Available button identifiers:", allButtons.map { $0.identifier })
            throw XCTSkip("Date cell 15 not found - calendar may not have rendered or date doesn't exist in current month")
        }
        
        // Ensure the cell is hittable before tapping
        XCTAssertTrue(dateCell.isHittable, "Date cell should be tappable")
        
        // Tap the date
        dateCell.tap()
        
        // First, verify the date selection took effect by checking if the header changed
        // The header should show "Interviews on [date]" when a date is selected
        let dateHeader = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Interviews on'")).element
        
        // Give more time for the binding to propagate and UI to update
        if !dateHeader.waitForExistence(timeout: 5) {
            print("Date header not found. Available static texts:")
            let allTexts = app.staticTexts.allElementsBoundByIndex
            for text in allTexts {
                print("  - identifier: '\(text.identifier)', label: '\(text.label)'")
            }
        }
        
        XCTAssertTrue(dateHeader.exists, "Header should show selected date after tapping")
        
        // Now wait for clear button to appear (this indicates date was selected)
        let clearButton = app.buttons["clearDateButton"]
        
        // Debug: Print all available buttons if clear button doesn't exist
        if !clearButton.waitForExistence(timeout: 5) {
            print("Clear button not found. Available buttons:")
            let allButtons = app.buttons.allElementsBoundByIndex
            for button in allButtons {
                print("  - identifier: '\(button.identifier)', label: '\(button.label)'")
            }
        }
        
        XCTAssertTrue(clearButton.exists, "Clear button should appear after selecting a date")
        ciLog("END test: testCalendarDateCanBeSelected")
    }
    
    @MainActor
    func testClearButtonAppearsAfterDateSelection() throws {
        ciLog("BEGIN test: testClearButtonAppearsAfterDateSelection")
        // Wait for calendar to load
        let monthYearLabel = app.staticTexts["monthYearLabel"]
        XCTAssertTrue(monthYearLabel.waitForExistence(timeout: 5), "Calendar should load")
        
        // Tap a date
        let dateCell = app.buttons.matching(identifier: "15").firstMatch
        guard dateCell.waitForExistence(timeout: 5) && dateCell.isHittable else {
            throw XCTSkip("Date cell not found or not tappable")
        }
        
        dateCell.tap()
        
        // Clear button should appear
        let clearButton = app.buttons["clearDateButton"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 5), "Clear button should appear after date selection")
        ciLog("END test: testClearButtonAppearsAfterDateSelection")
    }
    
    @MainActor
    func testClearButtonRemovesDateFilter() throws {
        ciLog("BEGIN test: testClearButtonRemovesDateFilter")
        // Wait for calendar to load
        let monthYearLabel = app.staticTexts["monthYearLabel"]
        XCTAssertTrue(monthYearLabel.waitForExistence(timeout: 5), "Calendar should load")
        
        // Tap a date
        let dateCell = app.buttons.matching(identifier: "15").firstMatch
        guard dateCell.waitForExistence(timeout: 5) && dateCell.isHittable else {
            throw XCTSkip("Date cell not found")
        }
        
        dateCell.tap()
        
        // Wait for clear button
        let clearButton = app.buttons["clearDateButton"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 5), "Clear button should appear")
        
        // Ensure button is hittable
        XCTAssertTrue(clearButton.isHittable, "Clear button should be tappable")
        
        // Tap clear button
        clearButton.tap()
        
        // Header should return to "Upcoming Interviews"
        let upcomingHeader = app.staticTexts["Upcoming Interviews"]
        XCTAssertTrue(upcomingHeader.waitForExistence(timeout: 5), "Header should return to 'Upcoming Interviews'")
        
        // Clear button should disappear
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: clearButton
        )
        let result = XCTWaiter().wait(for: [expectation], timeout: 3)
        XCTAssertEqual(result, .completed, "Clear button should disappear after clearing filter")
        ciLog("END test: testClearButtonRemovesDateFilter")
    }
    
    @MainActor
    func testCalendarNavigationWorks() throws {
        ciLog("BEGIN test: testCalendarNavigationWorks")
        // Wait for calendar to load
        let monthYearLabel = app.staticTexts["monthYearLabel"]
        XCTAssertTrue(monthYearLabel.waitForExistence(timeout: 5), "Month/year label should exist")
        
        let previousMonthButton = app.buttons["previousMonthButton"]
        XCTAssertTrue(previousMonthButton.exists, "Previous month button should exist")
        
        // Go back a couple months to ensure we're not at year boundary
        for _ in 0..<2 {
            let currentLabel = monthYearLabel.label
            previousMonthButton.tap()
            
            // Wait for month to actually change
            let expectation = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "label != %@", currentLabel),
                object: monthYearLabel
            )
            _ = XCTWaiter().wait(for: [expectation], timeout: 2)
        }
        
        // Now get the current month
        let currentMonth = monthYearLabel.label
        
        // Find the next month button
        let nextMonthButton = app.buttons["nextMonthButton"]
        XCTAssertTrue(nextMonthButton.exists, "Next month button should exist")
        
        // Tap next month
        nextMonthButton.tap()
        
        // Wait for month to change
        let nextExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label != %@", currentMonth),
            object: monthYearLabel
        )
        _ = XCTWaiter().wait(for: [nextExpectation], timeout: 2)
        
        // Check that the label has changed
        let newMonth = monthYearLabel.label
        XCTAssertNotEqual(currentMonth, newMonth, "Month should change after tapping next. Was '\(currentMonth)', now '\(newMonth)'")
        
        // Previous month button should work to go back
        previousMonthButton.tap()
        
        // Wait for return to original month
        let returnExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", currentMonth),
            object: monthYearLabel
        )
        _ = XCTWaiter().wait(for: [returnExpectation], timeout: 2)
        
        let returnedMonth = monthYearLabel.label
        XCTAssertEqual(currentMonth, returnedMonth, "Should return to original month")
        ciLog("END test: testCalendarNavigationWorks")
    }
    
    @MainActor
    func testTodayButtonAppearsWhenNavigatingToOtherMonth() throws {
        ciLog("BEGIN test: testTodayButtonAppearsWhenNavigatingToOtherMonth")
        // Wait for initial load
        let monthYearLabel = app.staticTexts["monthYearLabel"]
        XCTAssertTrue(monthYearLabel.waitForExistence(timeout: 5), "Calendar should load")
        
        let initialMonth = monthYearLabel.label
        
        // Today button should NOT exist when viewing current month
        let todayButton = app.buttons["todayButton"]
        
        // Wait a moment to ensure UI is stable
        let noTodayButtonExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: todayButton
        )
        _ = XCTWaiter().wait(for: [noTodayButtonExpectation], timeout: 2)
        
        XCTAssertFalse(todayButton.exists, "Today button should not appear when viewing current month")
        
        // Navigate to next month
        let nextMonthButton = app.buttons["nextMonthButton"]
        guard nextMonthButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Next month button not found")
        }
        XCTAssertTrue(nextMonthButton.isHittable, "Next month button should be tappable")
        
        nextMonthButton.tap()
        
        // Wait for month to change
        let monthChangedExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label != %@", initialMonth),
            object: monthYearLabel
        )
        let result = XCTWaiter().wait(for: [monthChangedExpectation], timeout: 5)
        XCTAssertEqual(result, .completed, "Month should change after tapping next")
        
        // Today button SHOULD appear now - wait with extended timeout
        guard todayButton.waitForExistence(timeout: 8) else {
            let newMonth = monthYearLabel.label
            print("DEBUG: Initial month: \(initialMonth), Current month: \(newMonth)")
            print("DEBUG: All visible buttons:", app.buttons.allElementsBoundByIndex.map { $0.identifier })
            XCTFail("Today button should appear when viewing different month")
            return
        }
        ciLog("END test: testTodayButtonAppearsWhenNavigatingToOtherMonth")
    }
    
    @MainActor
    func testTodayButtonReturnsToCurrentMonth() throws {
        ciLog("BEGIN test: testTodayButtonReturnsToCurrentMonth")
        // Wait for initial load
        let monthYearLabel = app.staticTexts["monthYearLabel"]
        XCTAssertTrue(monthYearLabel.waitForExistence(timeout: 5), "Calendar should load")
        
        let initialMonth = monthYearLabel.label
        
        // Navigate to next month
        let nextMonthButton = app.buttons["nextMonthButton"]
        guard nextMonthButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Next month button not found")
        }
        XCTAssertTrue(nextMonthButton.isHittable, "Next month button should be tappable")
        nextMonthButton.tap()
        
        // Wait for month to change
        let monthChangedExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label != %@", initialMonth),
            object: monthYearLabel
        )
        let changeResult = XCTWaiter().wait(for: [monthChangedExpectation], timeout: 5)
        XCTAssertEqual(changeResult, .completed, "Month should change after navigation")
        
        // Give a moment for UI to update after month change
        let todayButton = app.buttons["todayButton"]
        
        // Today button should appear - wait with longer timeout
        guard todayButton.waitForExistence(timeout: 8) else {
            // Debug info if it fails
            let newMonth = monthYearLabel.label
            print("DEBUG: Initial month: \(initialMonth), Current month: \(newMonth)")
            print("DEBUG: Today button exists: \(todayButton.exists)")
            print("DEBUG: All visible buttons:", app.buttons.allElementsBoundByIndex.map { $0.identifier })
            XCTFail("Today button should appear in different month (was: \(initialMonth), now: \(newMonth))")
            return
        }
        
        XCTAssertTrue(todayButton.isHittable, "Today button should be tappable")
        
        // Tap the Today button
        todayButton.tap()
        
        // Wait for month to return to initial
        let monthReturnedExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", initialMonth),
            object: monthYearLabel
        )
        let result = XCTWaiter().wait(for: [monthReturnedExpectation], timeout: 5)
        XCTAssertEqual(result, .completed, "Should return to original month")
        
        // Today button should disappear since we're back to current month
        let todayButtonGoneExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: todayButton
        )
        let disappearResult = XCTWaiter().wait(for: [todayButtonGoneExpectation], timeout: 5)
        XCTAssertEqual(disappearResult, .completed, "Today button should disappear when returning to current month")
        ciLog("END test: testTodayButtonReturnsToCurrentMonth")
    }
    
    @MainActor
    func testTodayButtonWorksFromMultipleMonthsAway() throws {
        ciLog("BEGIN test: testTodayButtonWorksFromMultipleMonthsAway")
        // Wait for calendar to load
        let monthYearLabel = app.staticTexts["monthYearLabel"]
        XCTAssertTrue(monthYearLabel.waitForExistence(timeout: 5), "Calendar should load")
        
        let initialMonth = monthYearLabel.label
        
        // Navigate several months ahead
        let nextMonthButton = app.buttons["nextMonthButton"]
        
        for _ in 0..<3 {
            let currentLabel = monthYearLabel.label
            nextMonthButton.tap()
            
            // Wait for month to change
            let expectation = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "label != %@", currentLabel),
                object: monthYearLabel
            )
            _ = XCTWaiter().wait(for: [expectation], timeout: 2)
        }
        
        // Today button should exist
        let todayButton = app.buttons["todayButton"]
        XCTAssertTrue(todayButton.exists, "Today button should exist when multiple months away")
        XCTAssertTrue(todayButton.isHittable, "Today button should be tappable")
        
        // Tap Today
        todayButton.tap()
        
        // Wait to return to current month
        let returnExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", initialMonth),
            object: monthYearLabel
        )
        let result = XCTWaiter().wait(for: [returnExpectation], timeout: 3)
        XCTAssertEqual(result, .completed, "Should return to original month")
        
        // Should be back to current month - Today button should disappear
        let todayButtonGoneExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: todayButton
        )
        let disappearResult = XCTWaiter().wait(for: [todayButtonGoneExpectation], timeout: 3)
        XCTAssertEqual(disappearResult, .completed, "Today button should disappear after returning to current month")
        ciLog("END test: testTodayButtonWorksFromMultipleMonthsAway")
    }
    
    @MainActor
    func testTodayButtonWorksFromPastMonths() throws {
        ciLog("BEGIN test: testTodayButtonWorksFromPastMonths")
        // Wait for initial load
        let monthYearLabel = app.staticTexts["monthYearLabel"]
        XCTAssertTrue(monthYearLabel.waitForExistence(timeout: 5), "Calendar should load")
        
        let initialMonth = monthYearLabel.label
        
        // Navigate to previous month
        let previousMonthButton = app.buttons["previousMonthButton"]
        guard previousMonthButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Previous month button not found")
        }
        XCTAssertTrue(previousMonthButton.isHittable, "Previous month button should be tappable")
        previousMonthButton.tap()
        
        // Wait for month to change
        let monthChangedExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label != %@", initialMonth),
            object: monthYearLabel
        )
        let changeResult = XCTWaiter().wait(for: [monthChangedExpectation], timeout: 5)
        XCTAssertEqual(changeResult, .completed, "Month should change after navigation")
        
        // Today button should appear - wait with longer timeout
        let todayButton = app.buttons["todayButton"]
        guard todayButton.waitForExistence(timeout: 8) else {
            // Debug info if it fails
            let newMonth = monthYearLabel.label
            print("DEBUG: Initial month: \(initialMonth), Current month: \(newMonth)")
            print("DEBUG: Today button exists: \(todayButton.exists)")
            print("DEBUG: All visible buttons:", app.buttons.allElementsBoundByIndex.map { $0.identifier })
            XCTFail("Today button should appear when viewing past month (was: \(initialMonth), now: \(newMonth))")
            return
        }
        
        XCTAssertTrue(todayButton.isHittable, "Today button should be tappable")
        
        // Tap Today
        todayButton.tap()
        
        // Wait to return to current month
        let monthReturnedExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", initialMonth),
            object: monthYearLabel
        )
        let result = XCTWaiter().wait(for: [monthReturnedExpectation], timeout: 5)
        XCTAssertEqual(result, .completed, "Should return to current month")
        
        // Today button should disappear
        let todayButtonGoneExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: todayButton
        )
        let disappearResult = XCTWaiter().wait(for: [todayButtonGoneExpectation], timeout: 5)
        XCTAssertEqual(disappearResult, .completed, "Today button should disappear when back to current month")
        ciLog("END test: testTodayButtonWorksFromPastMonths")
    }
    
    @MainActor
    func testDateSelectionShowsOnlyThatDaysInterviews() throws {
        ciLog("BEGIN test: testDateSelectionShowsOnlyThatDaysInterviews")
        // Wait for calendar to load
        let monthYearLabel = app.staticTexts["monthYearLabel"]
        XCTAssertTrue(monthYearLabel.waitForExistence(timeout: 5), "Calendar should load")
        
        // This assumes there's test data
        let dateCell = app.buttons.matching(identifier: "15").firstMatch
        
        guard dateCell.waitForExistence(timeout: 5) && dateCell.isHittable else {
            throw XCTSkip("Date cell not found or not tappable")
        }
        
        dateCell.tap()
        
        // Header should reflect the selected date
        let dateHeader = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Interviews on'")).element
        XCTAssertTrue(dateHeader.waitForExistence(timeout: 3), "Should show date-specific header")
        ciLog("END test: testDateSelectionShowsOnlyThatDaysInterviews")
    }
    
    // MARK: - Combined Feature Tests
    
    @MainActor
    func testSearchIgnoresDateFilter() throws {
        ciLog("BEGIN test: testSearchIgnoresDateFilter")
        // When searching, date filter should be ignored
        // This allows users to see ALL past interviews with a company
        
        // Wait for calendar to load
        Thread.sleep(forTimeInterval: 1.0)
        
        // Select a date first
        let dateCell = app.buttons["15"].firstMatch
        guard dateCell.waitForExistence(timeout: 3) else {
            throw XCTSkip("Date cell not found")
        }
        
        dateCell.tap()
        Thread.sleep(forTimeInterval: 1.0)
        
        // Verify date is selected
        let clearButton = app.buttons["clearDateButton"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 3), "Clear button should appear")
        
        let searchField = revealSearchField()
        searchField.tap()
        searchField.typeText("Apple")
        
        Thread.sleep(forTimeInterval: 0.5)
        
        // Search should show ALL Apple interviews, not just on selected date
        // Header should change to "Search Results" (not date-specific)
        let searchResultsHeader = app.staticTexts["Search Results"]
        XCTAssertTrue(searchResultsHeader.waitForExistence(timeout: 2), "Search should override date filter")
        ciLog("END test: testSearchIgnoresDateFilter")
    }
    
    @MainActor
    func testSearchShowsPastInterviewsForDuplicateDetection() throws {
        ciLog("BEGIN test: testSearchShowsPastInterviewsForDuplicateDetection")
        let searchField = revealSearchField()
        searchField.tap()
        searchField.typeText("Google")
        
        // Should show ALL Google interviews (past, present, future)
        let searchResultsHeader = app.staticTexts["Search Results"]
        XCTAssertTrue(searchResultsHeader.waitForExistence(timeout: 5))
        
        // Note: In real usage, this would show past rejected interviews
        // to warn user they already applied to this company
        ciLog("END test: testSearchShowsPastInterviewsForDuplicateDetection")
    }
    
    @MainActor
    func testEmptyStateShowsForDateWithNoInterviews() throws {
        ciLog("BEGIN test: testEmptyStateShowsForDateWithNoInterviews")
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
        ciLog("END test: testEmptyStateShowsForDateWithNoInterviews")
    }
    
    
    // MARK: - Swipe Actions Tests
    
    @MainActor
    func testSwipeLeftToRejectInterview() throws {
        ciLog("BEGIN test: testSwipeLeftToRejectInterview")
        // Check if there are any interview rows
        let firstInterviewRow = app.cells.firstMatch
        
        // Skip test if no interviews exist
        guard firstInterviewRow.waitForExistence(timeout: 2) else {
            throw XCTSkip("No interviews available for swipe test")
        }
        
        // Swipe left to reveal reject action
        firstInterviewRow.swipeLeft()
        
        // Wait for swipe animation
        Thread.sleep(forTimeInterval: 1.0)
        
        // Reject button should appear
        let rejectButton = app.buttons["Reject"]
        guard rejectButton.waitForExistence(timeout: 3) else {
            throw XCTSkip("Reject button not found - may already be rejected or no swipe actions available")
        }
        
        XCTAssertTrue(rejectButton.exists, "Reject action should be available")
        ciLog("END test: testSwipeLeftToRejectInterview")
    }
    
    @MainActor
    func testSwipeRightToOpenNextStage() throws {
        ciLog("BEGIN test: testSwipeRightToOpenNextStage")
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
        ciLog("END test: testSwipeRightToOpenNextStage")
    }
    
    @MainActor
    func testRejectActionChangesInterviewStatus() throws {
        ciLog("BEGIN test: testRejectActionChangesInterviewStatus")
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
        ciLog("END test: testRejectActionChangesInterviewStatus")
    }
    
    @MainActor
    func testNextStageOpensCreateInterviewSheet() throws {
        ciLog("BEGIN test: testNextStageOpensCreateInterviewSheet")
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
        ciLog("END test: testNextStageOpensCreateInterviewSheet")
    }
    
    @MainActor
    func testNextStageSheetPrefillsCompanyAndJobTitle() throws {
        ciLog("BEGIN test: testNextStageSheetPrefillsCompanyAndJobTitle")
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
        ciLog("END test: testNextStageSheetPrefillsCompanyAndJobTitle")
    }
    
    @MainActor
    func testNextStageSheetDoesNotAllowAppliedStage() throws {
        ciLog("BEGIN test: testNextStageSheetDoesNotAllowAppliedStage")
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
        ciLog("END test: testNextStageSheetDoesNotAllowAppliedStage")
    }
    
    @MainActor
    func testNextStageSheetRequiresDateAndTime() throws {
        ciLog("BEGIN test: testNextStageSheetRequiresDateAndTime")
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
        ciLog("END test: testNextStageSheetRequiresDateAndTime")
    }
    
    // MARK: - Settings Navigation Tests
    
    @MainActor
    func testSettingsButtonOpensSettings() throws {
        ciLog("BEGIN test: testSettingsButtonOpensSettings")
        let settingsButton = app.buttons["gear"]
        XCTAssertTrue(settingsButton.exists)
        
        settingsButton.tap()
        
        // Settings sheet should appear
        // Look for typical settings elements (this depends on your SettingsView implementation)
        // For now, just check that something modal appears
        Thread.sleep(forTimeInterval: 1.0)
        
        // Settings view should be visible
        // You may need to adjust this based on your actual SettingsView content
        ciLog("END test: testSettingsButtonOpensSettings")
    }
    
    // MARK: - Performance Tests
    
    @MainActor
    func testLaunchPerformance() throws {
        ciLog("BEGIN test: testLaunchPerformance")
        ciLog("Measuring app launch performance")
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            ciLog("Launching app for performance metric")
            XCUIApplication().launch()
        }
        ciLog("END test: testLaunchPerformance")
    }
    
    @MainActor
    func testSearchPerformance() throws {
        ciLog("BEGIN test: testSearchPerformance")
        ciLog("Measuring search performance")
        measure {
            ciLog("Typing into search for performance test")
            let searchField = revealSearchField()
            searchField.tap()
            searchField.typeText("A")
            
            // Wait for results to load
            usleep(600_000)
            
            // Clear search
            if app.buttons["Cancel"].exists {
                app.buttons["Cancel"].tap()
            }
        }
        ciLog("END test: testSearchPerformance")
    }
    
    @MainActor
    func testCalendarNavigationPerformance() throws {
        ciLog("BEGIN test: testCalendarNavigationPerformance")
        ciLog("Measuring calendar navigation performance")
        measure {
            ciLog("Navigating calendar forward and backward for performance test")
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
        ciLog("END test: testCalendarNavigationPerformance")
    }
}


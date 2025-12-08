//
//  UITestingHelpers.swift
//  InterviewsUITests
//
//  Created on 08/12/2025.
//

import XCTest

/// Helper extensions for UI testing to make tests more reliable and readable
extension XCUIElement {
    
    /// Waits for the element to exist and be hittable before returning
    /// - Parameter timeout: Maximum time to wait (default: 5 seconds)
    /// - Returns: true if element is ready for interaction
    func waitForHittable(timeout: TimeInterval = 5) -> Bool {
        guard waitForExistence(timeout: timeout) else { return false }
        
        // Wait for element to become hittable
        let predicate = NSPredicate(format: "isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        
        return result == .completed
    }
    
    /// Waits for the element to disappear
    /// - Parameter timeout: Maximum time to wait (default: 3 seconds)
    /// - Returns: true if element disappeared within timeout
    @discardableResult
    func waitForDisappearance(timeout: TimeInterval = 3) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        
        return result == .completed
    }
    
    /// Safely taps the element only if it's hittable
    /// - Parameter timeout: Maximum time to wait for element to be ready
    /// - Returns: true if tap was performed
    @discardableResult
    func safeTap(timeout: TimeInterval = 5) -> Bool {
        guard waitForHittable(timeout: timeout) else { return false }
        tap()
        return true
    }
}

extension XCUIApplication {
    
    /// Waits for the initial loading overlay to disappear before proceeding with tests
    func waitForInitialLoadToComplete(timeout: TimeInterval = 10) {
        let loadingOverlay = staticTexts["Loading Your Interviews"]
        if loadingOverlay.exists {
            loadingOverlay.waitForDisappearance(timeout: timeout)
        }
        
        // Ensure main navigation is ready
        let mainNavBar = navigationBars["Interviews"]
        _ = mainNavBar.waitForExistence(timeout: timeout)
    }
}

/// Helper for waiting for label changes on elements
extension XCUIElement {
    
    /// Waits for the element's label to change from the current value
    /// - Parameters:
    ///   - previousValue: The old label value
    ///   - timeout: Maximum time to wait
    /// - Returns: true if label changed
    @discardableResult
    func waitForLabelToChangeTo(_ expectedValue: String, timeout: TimeInterval = 3) -> Bool {
        let predicate = NSPredicate(format: "label == %@", expectedValue)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        
        return result == .completed
    }
    
    /// Waits for the element's label to change from a specific value
    /// - Parameters:
    ///   - previousValue: The old label value to wait to change from
    ///   - timeout: Maximum time to wait
    /// - Returns: true if label changed
    @discardableResult
    func waitForLabelToChangeFrom(_ previousValue: String, timeout: TimeInterval = 3) -> Bool {
        let predicate = NSPredicate(format: "label != %@", previousValue)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        
        return result == .completed
    }
}

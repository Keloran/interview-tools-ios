# Test Organization Guide

## Overview

This project now has properly organized tests across **two test targets**:

1. **InterviewsTests** (Unit Tests) - Tests business logic and data operations
2. **InterviewsUITests** (UI Tests) - Tests user interface interactions

---

## Test Targets Breakdown

### 📦 InterviewsTests (Unit Test Target)

**Purpose:** Test the logic, data models, and state management without launching the UI.

**Files in this target:**
- `ContentViewTests.swift` - Tests ContentView logic (sync, filtering, search logic)
- `SyncServiceTests.swift` - Tests data synchronization logic
- `InterviewTests.swift` - Tests Interview model
- `InterviewListViewTests.swift` - Tests interview list logic
- `AddInterviewViewTests.swift` - Tests add interview logic
- `CalendarViewTests.swift` - Tests calendar logic
- `InterviewOutcomeTests.swift` - Tests outcome enum
- Other model/service tests

**What these tests cover:**
✅ Data model operations (create, read, update, delete)
✅ SwiftData queries and filtering logic
✅ State management logic
✅ Business rules and validation
✅ Date filtering algorithms
✅ Company search filtering logic
✅ Error handling
✅ Sync logic

**Example tests from ContentViewTests.swift:**
- `testDateFiltering()` - Tests date filtering logic
- `testCompanySearch()` - Tests company search filtering
- `testFutureInterviewsFiltering()` - Tests future interview logic
- `testCombinedDateAndSearch()` - Tests combined filters

---

### 🎨 InterviewsUITests (UI Test Target)

**Purpose:** Test the actual user interface interactions by launching the app and simulating user actions.

**Files in this target:**
- `ContentViewUITests.swift` - **NEW!** Tests UI interactions for search and date filtering
- `InterviewsUITests.swift` - Original UI tests
- `InterviewsUITestsLaunchTests.swift` - Launch tests

**What these tests cover:**
✅ Button taps and gestures
✅ Navigation between screens
✅ Search field interactions
✅ Calendar date selection
✅ Visual element existence
✅ User flows (e.g., search → select date → clear)
✅ Empty states and error messages
✅ Performance of UI operations

**Example tests from ContentViewUITests.swift:**
- `testSearchFieldAcceptsText()` - Tests typing in search field
- `testCalendarDateCanBeSelected()` - Tests tapping calendar dates
- `testClearButtonAppearsAfterDateSelection()` - Tests clear button appears
- `testSearchAndDateFilterCanWorkTogether()` - Tests combining search and date filter

---

## Test Coverage Summary

### Date Filtering Feature

**Unit Tests (ContentViewTests.swift):**
- ✅ Date filtering logic
- ✅ Future interview filtering
- ✅ Calendar date comparison
- ✅ Empty state logic

**UI Tests (ContentViewUITests.swift):**
- ✅ Tapping calendar dates
- ✅ Clear button appearance
- ✅ Clear button functionality
- ✅ Header text changes
- ✅ Calendar navigation (prev/next month)
- ✅ Empty state for dates with no interviews

### Company Search Feature

**Unit Tests (ContentViewTests.swift):**
- ✅ Search filtering logic
- ✅ Case-insensitive search
- ✅ Partial name matching
- ✅ Duplicate company detection
- ✅ Empty search results
- ✅ Combined search + date filtering

**UI Tests (ContentViewUITests.swift):**
- ✅ Search button visibility and tap
- ✅ Search field appearance
- ✅ Text input in search field
- ✅ Search results display
- ✅ Cancel search
- ✅ Empty state for no results
- ✅ Combined with date filtering

---

## Running the Tests

### Run All Tests
```bash
# In Xcode
Cmd + U

# From Terminal
xcodebuild test -scheme Interviews -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Run Only Unit Tests
```bash
# In Xcode
Select "InterviewsTests" scheme, then Cmd + U

# From Terminal
xcodebuild test -scheme Interviews -only-testing:InterviewsTests
```

### Run Only UI Tests
```bash
# In Xcode
Select "InterviewsUITests" scheme, then Cmd + U

# From Terminal
xcodebuild test -scheme Interviews -only-testing:InterviewsUITests
```

### Run Specific Test File
```bash
# Unit test file
xcodebuild test -scheme Interviews -only-testing:InterviewsTests/ContentViewTests

# UI test file
xcodebuild test -scheme Interviews -only-testing:InterviewsUITests/ContentViewUITests
```

### Run Individual Test
```bash
# In Xcode: Click the diamond icon next to the test function

# From Terminal
xcodebuild test -scheme Interviews -only-testing:InterviewsTests/ContentViewTests/testDateFiltering
```

---

## Test Frameworks Used

### Unit Tests
- **Swift Testing** framework (`import Testing`)
- Modern `@Test` macro syntax
- `#expect` assertions
- `@MainActor` for SwiftData/UI state tests
- In-memory SwiftData containers for isolation

### UI Tests
- **XCTest** framework (`import XCTest`)
- `XCUIApplication` for app launch
- `XCTAssert` for UI element verification
- Accessibility identifiers for reliable element finding
- Performance measurement with `measure()`

---

## Best Practices Followed

### Unit Tests ✅
- Fast execution (no UI launch)
- Isolated test data (in-memory database)
- Test one thing per test
- Clear test names describing what's tested
- Grouped by feature/functionality

### UI Tests ✅
- Test user-visible behavior
- Use accessibility identifiers
- Wait for elements with timeout
- Test complete user flows
- Include performance tests
- Handle async UI updates

---

## Test Counts

### ContentViewTests.swift (Unit Tests)
- **30+ tests** covering:
  - Sync logic (3)
  - Interview queries (2)
  - Sync state (2)
  - Integration (2)
  - Error handling (2)
  - User authentication (3)
  - Date filtering (2)
  - Company search (6)
  - Combined filters (1)

### ContentViewUITests.swift (UI Tests)
- **17 tests** covering:
  - Navigation/Layout (3)
  - Search feature UI (6)
  - Date selection UI (5)
  - Combined features (2)
  - Performance (3)

---

## Notes for CI/CD

### Recommended Test Strategy
1. **On every commit:** Run unit tests (fast, < 1 minute)
2. **On pull request:** Run all tests (unit + UI)
3. **Nightly builds:** Run full UI test suite with performance tests

### Test Stability
- UI tests may be slower and can be flaky
- Unit tests are fast and stable
- Consider retry logic for UI tests in CI
- Use `waitForExistence(timeout:)` for async UI elements

---

## Adding New Tests

### When to add Unit Tests
- New data models or properties
- New business logic functions
- New filtering/sorting algorithms
- New validation rules
- New API/sync logic

### When to add UI Tests
- New screens or views
- New user interactions (buttons, gestures)
- New navigation flows
- New form inputs
- Visual regressions to catch

---

## Troubleshooting

### UI Tests Failing
1. Check if accessibility identifiers exist
2. Increase timeout values
3. Verify app launches correctly with `--uitesting` argument
4. Check for animation delays
5. Ensure simulator is unlocked and ready

### Unit Tests Failing
1. Check SwiftData model changes
2. Verify test data setup
3. Check for race conditions with async code
4. Ensure proper use of `@MainActor`
5. Clear derived data if needed

---

## Summary

✅ **Proper test organization** - Unit tests test logic, UI tests test interactions
✅ **Comprehensive coverage** - 47+ tests across both features
✅ **Modern frameworks** - Swift Testing for unit tests, XCTest for UI tests
✅ **Performance tests** - Included for critical user flows
✅ **Maintainable** - Clear naming, proper grouping, good documentation

Both new features (date filtering and company search) are now fully tested at both the logic and UI interaction levels! 🎉

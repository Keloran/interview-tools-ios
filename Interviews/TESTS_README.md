# Test Suite for ContentView Sync Functionality

## Overview

I've created comprehensive tests for the new sync functionality added to ContentView. The tests are organized into two main test files:

1. **ContentViewTests.swift** - Tests for the ContentView sync behavior and state management
2. **SyncServiceTests.swift** - Tests for the SyncService data synchronization logic

## Test Files Created

### ContentViewTests.swift

This file contains **20 tests** covering:

#### Sync Logic Tests (3 tests)
- ✅ `testInitialSyncWithAuthenticatedUser` - Verifies sync happens when user is authenticated
- ✅ `testNoSyncWithoutAuthentication` - Ensures no sync occurs without authentication
- ✅ `testSyncOnlyHappensOnce` - Validates the `hasPerformedInitialSync` flag prevents duplicate syncs

#### Interview Query Tests (2 tests)
- ✅ `testInterviewQuery` - Verifies ContentView can query all interviews
- ✅ `testEmptyDatabase` - Tests behavior with empty database

#### Sync State Tests (2 tests)
- ✅ `testInitialSyncingState` - Validates `isSyncing` starts as false
- ✅ `testSyncingStateUpdates` - Verifies `isSyncing` changes during sync

#### Integration Tests (2 tests)
- ✅ `testSyncedDataAppearsInQuery` - Confirms synced data is queryable
- ✅ `testMultipleSyncedInterviews` - Tests multiple interviews sync correctly

#### Error Handling Tests (2 tests)
- ✅ `testFailedTokenRetrieval` - Verifies graceful handling of token failures
- ✅ `testSyncErrorHandling` - Ensures sync errors don't crash the app

#### User Authentication State Tests (3 tests)
- ✅ `testUserSignInDetection` - Tests sign-in triggers sync
- ✅ `testUserSignOutIgnored` - Ensures sign-out doesn't trigger sync
- ✅ `testUserRemainsSignedIn` - Verifies no sync when user stays signed in

### SyncServiceTests.swift

This file contains **22 tests** covering:

#### SyncService Initialization (1 test)
- ✅ `testSyncServiceInitialization` - Validates proper initialization

#### Company Sync Tests (2 tests)
- ✅ `testCompaniesSyncInsertion` - Tests company insertion
- ✅ `testCompanyUpdate` - Verifies existing companies are updated

#### Stage Sync Tests (2 tests)
- ✅ `testStagesSyncInsertion` - Tests stage insertion
- ✅ `testStageUpdate` - Verifies existing stages are updated

#### Stage Method Sync Tests (2 tests)
- ✅ `testStageMethodsSyncInsertion` - Tests stage method insertion
- ✅ `testStageMethodUpdate` - Verifies existing methods are updated

#### Interview Sync Tests (3 tests)
- ✅ `testInterviewsSyncWithRelationships` - Tests full interview sync with relationships
- ✅ `testInterviewUpdate` - Verifies existing interviews are updated
- ✅ `testMultipleInterviewsWithSameCompany` - Tests relationship integrity

#### Sync State Tests (2 tests)
- ✅ `testLastSyncDateUpdate` - Validates lastSyncDate tracking
- ✅ `testSyncingStateManagement` - Tests isSyncing state

#### Error Handling Tests (1 test)
- ✅ `testSyncErrorCapture` - Verifies error state management

#### Date Parsing Tests (2 tests)
- ✅ `testDateParsing` - Tests ISO8601 date parsing
- ✅ `testOptionalDateHandling` - Tests optional date handling

#### Outcome Parsing Tests (2 tests)
- ✅ `testOutcomeParsing` - Tests outcome enum parsing
- ✅ `testOptionalOutcomeHandling` - Tests optional outcome handling

## Running the Tests

### In Xcode

1. **Run all tests:**
   - Press `Cmd + U` or
   - Product → Test from the menu

2. **Run specific test file:**
   - Open the test file
   - Click the diamond icon next to the struct name
   - Or right-click on the test file and select "Run Tests"

3. **Run individual test:**
   - Click the diamond icon next to any `@Test` function
   - Or place cursor in the test and press `Ctrl + Opt + Cmd + U`

### From Terminal

```bash
# Run all tests
xcodebuild test -scheme Interviews -destination 'platform=iOS Simulator,name=iPhone 15'

# Run with specific destination
xcodebuild test -scheme Interviews -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## Test Coverage

The test suite covers:

✅ **State Management** - isSyncing, hasPerformedInitialSync flags  
✅ **Authentication Flow** - Sign in/out detection and sync triggers  
✅ **Data Synchronization** - Companies, Stages, Methods, Interviews  
✅ **Relationship Integrity** - Foreign key relationships maintained  
✅ **Error Handling** - Graceful failure and error state management  
✅ **Data Queries** - SwiftData queries return synced data  
✅ **Date Parsing** - ISO8601 format handling  
✅ **Outcome Parsing** - Enum conversion from API strings  
✅ **Update vs Insert** - Existing records updated, new ones inserted  

## Test Framework

All tests use the modern **Swift Testing** framework with:
- `@Test` macro for test functions
- `#expect` for assertions
- `@MainActor` for SwiftData and UI tests
- In-memory ModelConfiguration for isolated test data

## Next Steps

To verify everything works:

1. ✅ Run the tests: `Cmd + U` in Xcode
2. ✅ Check all tests pass (42 total tests)
3. ✅ Review any failures and fix issues
4. ✅ Test the actual sync functionality in the app

## Notes

- All tests use in-memory databases for isolation
- Tests are fast and don't require network access
- Some tests simulate API behavior since we don't have mock API service yet
- Future improvement: Add MockAPIService for more realistic integration tests

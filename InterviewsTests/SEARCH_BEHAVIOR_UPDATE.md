# Company Search Behavior Update

## Issue
The company search feature was incorrectly applying date filters, which prevented users from seeing their complete interview history with a company.

## Why This Matters
The **primary purpose** of the company search is to:
- ✅ Check if you've EVER interviewed with a company before
- ✅ Avoid applying to the same company multiple times
- ✅ See past rejections or outcomes
- ✅ Track your complete history with each company

## Previous Behavior ❌

```swift
// OLD: Search was combined with date filters
if !searchText.isEmpty {
    filtered = filtered.filter { /* search filter */ }
}

// Then date filter was applied, limiting results
if let selectedDate = selectedDate {
    filtered = filtered.filter { /* date filter */ }
} else {
    filtered = filtered.filter { /* only future */ }
}
```

**Problem:** If you searched for "Apple" while:
- A date was selected → Only showed Apple interviews on THAT date
- No date was selected → Only showed FUTURE Apple interviews

This meant you couldn't see past interviews, defeating the purpose of duplicate checking!

## New Behavior ✅

```swift
// NEW: Search ignores all date filters
if !searchText.isEmpty {
    // Show ALL interviews matching search (past, present, future)
    filtered = filtered.filter { /* search filter */ }
    return filtered.sorted { /* most recent first */ }
}

// Date filters only apply when NOT searching
if let selectedDate = selectedDate {
    // Show interviews for selected date
}
// Default: show future interviews
```

**Solution:** When searching, you see ALL interviews with that company, sorted by date (most recent first).

## Use Cases

### ✅ Use Case 1: Checking Before Applying
**Scenario:** You found a job posting at "Google" and want to check if you've applied before.

**Action:** Search for "Google"

**Result:** Shows ALL your Google interviews:
- ✅ Last year's rejection
- ✅ Upcoming scheduled interview
- ✅ Previous offers (accepted or declined)

**Benefit:** You can see you were rejected last year, so maybe wait before reapplying.

---

### ✅ Use Case 2: Company History
**Scenario:** You want to review your complete history with "Apple"

**Action:** Search for "Apple"

**Result:** Shows chronologically (most recent first):
- 2025-06: Senior iOS Engineer - Scheduled
- 2024-12: iOS Engineer - Rejected  
- 2024-06: Junior iOS Engineer - Withdrew
- 2023-10: Intern - Offer Declined

**Benefit:** Full context of your relationship with the company.

---

### ✅ Use Case 3: Date-Specific Browsing
**Scenario:** You want to see what interviews you have next Tuesday

**Action:** Click Tuesday on the calendar (no search)

**Result:** Shows only interviews on Tuesday:
- 10:00 AM - Google - Android Engineer
- 2:00 PM - Apple - iOS Engineer

**Benefit:** Focused view of a specific day.

---

## Code Changes

### InterviewListView.swift

```swift
private var sortedInterviews: [Interview] {
    let now = Date()
    let calendar = Calendar.current
    
    var filtered = interviews
    
    // 🔍 If searching, show ALL interviews (ignore date filters)
    if !searchText.isEmpty {
        filtered = filtered.filter { interview in
            if let companyName = interview.company?.name {
                return companyName.localizedCaseInsensitiveContains(searchText)
            }
            return false
        }
        // Sort by date (most recent first) when searching
        return filtered.sorted { 
            ($0.displayDate ?? Date.distantPast) > ($1.displayDate ?? Date.distantPast) 
        }
    }
    
    // 📅 If a date is selected, show interviews for that date only
    if let selectedDate = selectedDate {
        filtered = filtered.filter { interview in
            guard let displayDate = interview.displayDate else { return false }
            return calendar.isDate(displayDate, inSameDayAs: selectedDate)
        }
        return filtered.sorted { ($0.displayDate ?? Date()) < ($1.displayDate ?? Date()) }
    }
    
    // 🔮 Default: Show only future interviews
    filtered = filtered.filter {
        guard let displayDate = $0.displayDate else { return false }
        return displayDate >= now
    }
    return filtered.sorted { ($0.displayDate ?? Date()) < ($1.displayDate ?? Date()) }
}
```

### Key Points

1. **Search takes priority** - When searching, date filters are completely ignored
2. **Sort order changes** - Search results show newest first (most relevant)
3. **Date filter works normally** - When not searching, date filters work as before
4. **Default view unchanged** - Still shows future interviews when no search/date selected

---

## Updated Tests

### Unit Tests (ContentViewTests.swift)

**Removed:** `testCombinedDateAndSearch` - This tested the old, incorrect behavior

**Added:** 
- ✅ `testSearchIgnoresDateFilter` - Verifies search shows past and future interviews
- ✅ `testSearchShowsPastInterviews` - Verifies past interviews appear in search

```swift
@Test("Search ignores date filters and shows all results")
func testSearchIgnoresDateFilter() async throws {
    // Creates past and future Apple interviews
    // Searches for "apple"
    // Expects BOTH past and future to be found
    #expect(filtered.count == 2)
    #expect(filtered.contains(where: { $0.jobTitle.contains("Past") }))
    #expect(filtered.contains(where: { $0.jobTitle.contains("Future") }))
}

@Test("Search shows past interviews to detect duplicates")
func testSearchShowsPastInterviews() async throws {
    // Creates an old rejected interview from last year
    // Searches for company
    // Expects to find the old rejection
    #expect(filtered.count == 1)
    #expect(filtered.first?.outcome == .rejected)
}
```

### UI Tests (ContentViewUITests.swift)

**Updated:**
- ✅ `testSearchIgnoresDateFilter` - Verifies UI behavior when search overrides date
- ✅ `testSearchShowsPastInterviewsForDuplicateDetection` - Tests the main use case

```swift
@MainActor
func testSearchIgnoresDateFilter() throws {
    // Select a date
    dateCell.tap()
    
    // Activate search
    searchButton.tap()
    searchField.typeText("Apple")
    
    // Header should show "Search Results", not date-specific text
    XCTAssertTrue(searchResultsHeader.exists, 
                  "Search should override date filter")
}
```

---

## User Experience Flow

### Scenario: Before Applying to Apple

1. **User finds Apple job posting** 📄
2. **Opens Interviews app** 📱
3. **Taps search button** 🔍
4. **Types "Apple"** ⌨️
5. **Sees ALL Apple history:**
   ```
   Search Results
   
   📅 2024-12-15 - iOS Engineer - Rejected ❌
   📅 2024-06-20 - iOS Intern - Withdrew 🚫
   ```
6. **Decides:** "I was rejected 6 months ago, maybe wait a bit longer" 💭
7. **Avoids wasting time on duplicate application** ✅

### Scenario: Checking Tuesday's Schedule

1. **User wants to prep for Tuesday** 📅
2. **Taps Tuesday on calendar** 🗓️
3. **Sees only that day:**
   ```
   Interviews on Dec 10, 2024
   
   📅 10:00 AM - Google - Android Engineer
   📅 2:00 PM - Apple - iOS Engineer
   ```
4. **Prepares for those two interviews** ✅

---

## Summary

| Feature | Behavior | Purpose |
|---------|----------|---------|
| **Search** | Shows ALL interviews (past + future) | Check complete company history |
| **Date Filter** | Shows only selected date | Focus on specific day |
| **Default** | Shows only future interviews | See upcoming schedule |

**Key Principle:** Search is for historical lookup, dates are for scheduling focus.

---

## Migration Notes

### For Existing Users
- ✅ No data migration needed
- ✅ No breaking changes
- ✅ Just improved behavior

### For Developers
- ✅ Update any tests expecting combined filters
- ✅ Document this behavior for future features
- ✅ Consider adding "Show Past" toggle for non-search views

---

## Future Enhancements

Possible improvements based on this pattern:

1. **Sort options in search:**
   - Most recent first (current)
   - By outcome (rejections first as warnings)
   - By stage (furthest progress first)

2. **Search suggestions:**
   - Show count: "Apple (3 interviews)"
   - Show last outcome: "Apple (Last: Rejected)"

3. **Warning indicators:**
   - 🚫 "You applied here 2 months ago and were rejected"
   - ⏰ "You have a pending interview here"
   - ✅ "You previously received an offer here"

4. **Filter combinations:**
   - Search + Outcome filter: "Show all Google rejections"
   - Search + Date range: "Show all Apple interviews in 2024"

---

## Conclusion

This change makes the company search feature work as intended: **a complete historical lookup to prevent duplicate applications and provide context before applying to companies.**

The date filtering remains useful for daily scheduling, but doesn't interfere with the primary purpose of search.

✅ Search = Historical company lookup (all time)
📅 Date filter = Daily scheduling (specific day)
🔮 Default = Upcoming interviews (future only)

Each mode serves a distinct purpose! 🎉

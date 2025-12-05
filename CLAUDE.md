# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an iOS interview tracker application that integrates with interviews.tools. It allows users to:
- Track job interviews and their current stages
- Add new interviews
- Manage interview pipeline and status
- View interview history and progress

Built with SwiftUI and SwiftData using Xcode's default project structure.

## Technology Stack

- **Language**: Swift
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData (Apple's modern data persistence framework)
- **Testing Framework**: Swift Testing (using the new Testing framework, not XCTest)
- **Build System**: Xcode project

## Project Structure

- `Interviews/`: Main application source code
  - `InterviewsApp.swift`: App entry point with SwiftData ModelContainer setup
  - `ContentView.swift`: Main UI view with navigation and list functionality
  - `Item.swift`: SwiftData model definitions
  - `Assets.xcassets/`: App assets and icons
- `InterviewsTests/`: Unit tests
- `InterviewsUITests/`: UI tests
- `Interviews.xcodeproj/`: Xcode project configuration

## Data Architecture

The app uses **SwiftData** for data persistence:
- ModelContainer is configured in `InterviewsApp.swift` with persistent storage (not in-memory)
- Models are defined using the `@Model` macro
- Views access data via `@Query` property wrapper and `@Environment(\.modelContext)`
- Schema includes: `Item.self` (currently a simple timestamp model - to be expanded for interview tracking)

### Integration with interviews.tools

The app syncs with **interviews.tools**, which uses a PostgreSQL database with the following schema:

**Core Models:**
- `User`: Clerk authentication, email, calendar UUID
- `Company`: Company name (unique per user)
- `Interview`: Main tracking entity with:
  - Company relationship (required)
  - `clientCompany` (optional - for recruitment agencies tracking end client)
  - `jobTitle` (required - role applying for)
  - `applicationDate` (required - when applied)
  - `interviewer` (optional - interviewer name)
  - `stage` and `stageMethod` (required - current interview stage and method)
  - `date` (optional - scheduled interview time, nullable for technical tests)
  - `deadline` (optional - for take-home tests)
  - `outcome` (optional - see InterviewOutcome enum)
  - `notes` (optional - text field for notes)
  - `metadata` (optional - JSON for job URL, salary, etc.)
  - `link` (optional - Teams/Google Meet links)
- `Stage`: Interview stages (e.g., "Phone Screen", "Technical", "Final")
- `StageMethod`: Methods (e.g., "In Person", "Video Call", "Take Home Test")

**InterviewOutcome Enum:**
- `SCHEDULED`, `PASSED`, `REJECTED`, `AWAITING_RESPONSE`
- `OFFER_RECEIVED`, `OFFER_ACCEPTED`, `OFFER_DECLINED`, `WITHDREW`

**Unique Constraints:**
- Companies: unique per `(userId, name)`
- Interviews: unique per `(userId, companyId, jobTitle, applicationDate, clientCompany)`

When implementing SwiftData models, mirror this structure for proper sync compatibility.

## Development Commands

### Building and Running
```bash
# Open in Xcode
open Interviews.xcodeproj

# Build from command line (requires xcodebuild)
xcodebuild -project Interviews.xcodeproj -scheme Interviews build

# Run tests
xcodebuild test -project Interviews.xcodeproj -scheme Interviews -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Running Tests
The project uses the **Swift Testing framework** (not XCTest):
- Tests use `@Test` attribute instead of `func testExample()`
- Use `#expect(...)` for assertions instead of `XCTAssert...`
- Tests can be async with `async throws`

To run a single test in Xcode: Click the diamond icon next to the test function.

## Key Patterns

### SwiftData Usage
- Models use `@Model` macro (see `Item.swift`)
- ModelContainer initialized in app entry point with schema configuration
- Views inject modelContainer via `.modelContainer()` scene modifier
- CRUD operations performed through `modelContext.insert()`, `modelContext.delete()`, etc.

### UI Architecture
- Uses `NavigationSplitView` for master-detail layout
- List-based navigation with SwiftUI's declarative syntax
- State management via SwiftData's `@Query` for reactive updates

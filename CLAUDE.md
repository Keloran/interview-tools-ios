# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an iOS interview tracker application that integrates with interviews.tools. It allows users to:
- Track job interviews and their current stages
- Add new interviews
- Manage interview pipeline and status
- View interview history and progress
- Sync data with interviews.tools API (optional)

Built with SwiftUI and SwiftData using Xcode's default project structure.

### Modes of Operation

1. **Offline Mode** (Default): All data stored locally in SwiftData
2. **Online Mode**: Sync with interviews.tools API when authenticated

## Technology Stack

- **Language**: Swift
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData (Apple's modern data persistence framework)
- **API Integration**: URLSession with async/await
- **Authentication**: Keychain storage for API tokens
- **Testing Framework**: Swift Testing (using the new Testing framework, not XCTest)
- **Build System**: Xcode project

## API Integration

The app integrates with the interviews.tools API (https://interviews.tools/api):

### Authentication
- Uses Clerk-based authentication tokens from the web app
- Tokens stored securely in iOS Keychain
- Users must obtain token from interviews.tools website

### API Endpoints

**GET /api/companies** - Fetch user's companies
**GET /api/stages** - Fetch all interview stages
**GET /api/stage-methods** - Fetch all interview methods
**GET /api/interviews** - Fetch interviews with optional filters:
- `date`, `dateFrom`, `dateTo` - Date filtering
- `includePast` - Include past interviews
- `companyId`, `company` - Company filtering
- `outcome` - Filter by outcome

**POST /api/interview** - Create new interview
**PUT /api/interview/[id]** - Update existing interview

### Sync Service

`SyncService` handles bidirectional sync between local SwiftData and remote API:
- Pull: Fetches data from API and updates local database
- Push: Creates new interviews on API when user adds them
- Conflict resolution: API is source of truth for synced data

### Service Architecture

- `APIService`: Actor-based API client with async/await
- `APIModels`: Codable DTOs for API requests/responses
- `SyncService`: @MainActor class that coordinates sync operations
- `AuthenticationManager`: Manages auth tokens and keychain storage

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
- make sure we always add tests for any features, and run tests to make sure that the code worked before saying a task is finished
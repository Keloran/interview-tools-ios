# Interviews - iOS App

An iOS interview tracker that syncs with [interviews.tools](https://interviews.tools).

## Features

- 📅 **Calendar View**: Monthly calendar showing all scheduled interviews
- 📝 **Interview Tracking**: Track interviews across multiple companies and stages
- 🔄 **Cloud Sync**: Sync with interviews.tools API (requires Clerk authentication)
- 📴 **Offline Mode**: Works fully offline with local SwiftData storage
- ✅ **Stage Management**: Pre-defined interview stages (Applied, Phone Screen, Technical Test, etc.)

## Quick Start

### Option 1: Offline Mode (No Setup Required)

1. Open `Interviews.xcodeproj` in Xcode
2. Build and run (Cmd+R)
3. App works fully offline with local data storage

### Option 2: With API Sync (Requires Clerk Setup)

1. **Add Clerk iOS SDK**:
   - In Xcode: `File → Add Package Dependencies`
   - URL: `https://github.com/clerk/clerk-ios`
   - Version: Up to Next Major (1.0.0+)

2. **Configure Clerk**:
   - Get publishable key from [Clerk Dashboard](https://dashboard.clerk.com)
   - Update `Interviews/ClerkConfiguration.swift` with your key

3. **Build and run**:
   - Build the app (Cmd+R)
   - Tap gear icon → Settings
   - Sign in with Clerk
   - Data will sync with interviews.tools

See **[CLERK_INTEGRATION.md](CLERK_INTEGRATION.md)** for detailed setup instructions.

## Architecture

- **SwiftUI + SwiftData**: Modern Apple stack for UI and persistence
- **Clerk Authentication**: Seamless sign-in with interviews.tools accounts
- **Bidirectional Sync**: Local-first with optional cloud sync
- **Swift Concurrency**: Async/await throughout for performance

## Project Structure

```
Interviews/
├── Models/              # SwiftData models (Interview, Company, Stage, etc.)
├── Views/               # UI components (Calendar, List, Forms, Settings)
├── Services/            # API client, Sync service, Auth manager
├── ClerkConfiguration.swift
└── DataSeeder.swift     # Seeds default stages/methods

InterviewsTests/         # Unit tests using Swift Testing framework
CLERK_INTEGRATION.md     # Complete Clerk setup guide
CLAUDE.md                # Development documentation
```

## Development

### Requirements

- Xcode 15+
- iOS 16+ deployment target
- Swift 5.9+

### Running Tests

```bash
# In Xcode
Cmd+U

# Or via command line
xcodebuild test -project Interviews.xcodeproj -scheme Interviews \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Mock Authentication (Development)

For testing without Clerk:

```swift
AuthenticationManager.shared.mockSignIn(email: "test@example.com")
```

## API Integration

The app integrates with interviews.tools API:

- **GET /api/interviews** - Fetch user's interviews
- **POST /api/interview** - Create new interview
- **PUT /api/interview/[id]** - Update interview
- **GET /api/companies** - Fetch companies
- **GET /api/stages** - Fetch stages
- **GET /api/stage-methods** - Fetch methods

All endpoints require Clerk authentication (session token in Authorization header).

## Contributing

See [CLAUDE.md](CLAUDE.md) for development guidelines and architecture details.

## License

[Your License Here]

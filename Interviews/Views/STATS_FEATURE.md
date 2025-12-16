# Interview Statistics Feature

## Overview
I've created a comprehensive statistics component for your interview tracking app that displays key metrics about your job applications. The feature adapts to different devices and contexts.

## Files Created

### 1. `InterviewStats.swift`
A model struct that computes statistics from interview data:
- **Total interviews**: Count of all interviews
- **By stage**: Applied, Scheduled, Awaiting Response
- **By outcome**: Passed, Rejected, Withdrew
- **By offer status**: Offer Received, Accepted, Declined
- **Success rate**: Percentage of passed vs rejected interviews
- **Active interviews**: Count of scheduled and awaiting response

### 2. `StatsView.swift`
Two view variants for displaying statistics:

#### `StatsView` (Full version for iPhone)
A detailed statistics dashboard with:
- Overview cards showing total and active interviews
- Application stages section (Applied, Scheduled, Awaiting Response)
- Outcomes section (Passed, Rejected, Withdrew)
- Offers section (Received, Accepted, Declined)
- Success metrics with progress bars and percentages

#### `CompactStatsView` (iPad version)
A compact version that fits under the calendar:
- Quick stat cards (Total, Active)
- Condensed list of key metrics with color-coded indicators
- Success rate progress bar
- Fits nicely in the sidebar

### 3. `InterviewStatsTests.swift`
Comprehensive test suite covering:
- Empty state handling
- Individual outcome counting
- Success rate calculations
- Mixed outcome scenarios
- Offer outcome tracking

## Integration

### iPhone (Settings)
On iPhone, statistics appear in the Settings view as a navigation link:
- Navigate to Settings > Statistics
- View full detailed statistics
- Accessible through the gear icon

### iPad (Under Calendar)
On iPad, the compact stats view appears in the sidebar:
- Positioned directly under the calendar
- Always visible while browsing interviews
- Provides at-a-glance insights
- Updates automatically as you modify interviews

## Features

### Automatic Calculations
- Statistics compute automatically from your interviews
- No manual tracking required
- Updates in real-time as you add/modify interviews

### Color-Coded Insights
Each outcome has its own color:
- 🔵 Blue: Scheduled, Total
- 🟡 Yellow: Applied, Awaiting Response
- 🟢 Green: Passed, Offer Accepted
- 🔴 Red: Rejected
- 🟣 Purple: Offer Received
- 🟠 Orange: Active, Offer Declined
- ⚪ Gray: Withdrew

### Success Metrics
- **Success Rate**: Percentage of interviews passed (excludes applications still in progress)
- **Progress Bars**: Visual representation with color coding
  - Red (0-25%): Needs improvement
  - Orange (25-50%): Below average
  - Yellow (50-75%): Good
  - Green (75-100%): Excellent

### Smart Categorization
- Interviews in "Applied" stage with no outcome are counted as "Applied"
- Scheduled interviews without outcomes are counted as "Scheduled"
- Active interviews include both scheduled and awaiting response

## Usage

The statistics automatically pull from your SwiftData database using `@Query`, so they always reflect the current state of your interviews.

### On iPhone:
1. Open Settings (gear icon)
2. Tap "View Statistics"
3. Scroll through detailed breakdown

### On iPad:
1. Stats are always visible in the left sidebar
2. Scroll within the stats section to see all metrics
3. Focus on what matters with the compact display

## Example Stats Scenarios

### Job Seeker Starting Out
- Total: 10
- Applied: 8
- Scheduled: 2
- Success Rate: N/A (no outcomes yet)

### Active Job Search
- Total: 25
- Applied: 10
- Scheduled: 5
- Awaiting Response: 3
- Passed: 4
- Rejected: 3
- Success Rate: 57%

### After Successful Search
- Total: 50
- Passed: 15
- Rejected: 20
- Offer Received: 3
- Offer Accepted: 1
- Success Rate: 43%

## Technical Details

- **SwiftUI + SwiftData**: Fully integrated with your existing models
- **Sendable**: Thread-safe statistics calculations
- **Computed Properties**: Efficient real-time calculations
- **Responsive Design**: Adapts to iPhone and iPad layouts
- **Accessible**: Clear labels and semantic colors
- **Tested**: Comprehensive test coverage

## Future Enhancements

Potential additions you might want to consider:
- Time-based statistics (this month, last 3 months, etc.)
- Charts and graphs (using Swift Charts)
- Company-specific success rates
- Average time from application to offer
- Export statistics as PDF/CSV
- Stage conversion rates (applied → scheduled → passed)

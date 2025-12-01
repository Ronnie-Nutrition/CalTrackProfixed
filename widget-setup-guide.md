# CalTrackPro Widget Extension Setup Guide

This guide walks you through adding the widget extension to display nutrition and fasting data on your home screen.

## Widget Files Created

The following widget files have been created in `/CalTrackWidget/`:

1. **CalTrackWidgetBundle.swift** - Main widget bundle entry point
2. **CalorieProgressWidget.swift** - Shows daily calorie intake progress (small/medium)
3. **FastingTimerWidget.swift** - Shows fasting timer and status (small/medium)
4. **NutritionSummaryWidget.swift** - Shows full macro breakdown (medium/large)
5. **Info.plist** - Widget extension configuration
6. **CalTrackWidget.entitlements** - App Group capability for data sharing

## Setup Instructions

### Step 1: Add Widget Extension Target in Xcode

1. Open `CalTrackProFixed.xcodeproj` in Xcode
2. Go to **File → New → Target**
3. Select **iOS → Widget Extension**
4. Configure:
   - **Product Name**: CalTrackWidget
   - **Team**: Your Apple Developer Team
   - **Bundle Identifier**: `easyaiflows.com.CalTrackProFixed.CalTrackWidget`
   - **Embed in Application**: CalTrackProFixed
   - Uncheck "Include Live Activity"
   - Uncheck "Include Configuration App Intent"
5. Click **Finish**
6. When prompted to activate the scheme, click **Activate**

### Step 2: Replace Default Widget Files

1. Delete all the auto-generated files in the CalTrackWidget folder that Xcode created
2. In Finder, navigate to `/Users/ronniecraig/CalTrackProfixed/CalTrackWidget/`
3. Drag all the Swift files into the CalTrackWidget target in Xcode:
   - CalTrackWidgetBundle.swift
   - CalorieProgressWidget.swift
   - FastingTimerWidget.swift
   - NutritionSummaryWidget.swift
4. Make sure "Copy items if needed" is unchecked
5. Ensure they're added to the CalTrackWidget target

### Step 3: Configure App Groups

**For the Widget Extension:**
1. Select the CalTrackWidget target
2. Go to **Signing & Capabilities**
3. Click **+ Capability**
4. Add **App Groups**
5. Add the group: `group.easyaiflows.com.CalTrackProFixed`

**For the Main App:**
1. Select the CalTrackProFixed target
2. Go to **Signing & Capabilities**
3. Click **+ Capability**
4. Add **App Groups**
5. Add the same group: `group.easyaiflows.com.CalTrackProFixed`

### Step 4: Build and Test

1. Select the CalTrackProFixed scheme (not CalTrackWidget)
2. Build and run on your device or simulator
3. Go to your iPhone home screen
4. Long press to enter edit mode
5. Tap the **+** button (top left)
6. Search for "CalTrackPro"
7. You should see three widgets:
   - **Calorie Progress** - Small and Medium sizes
   - **Fasting Timer** - Small and Medium sizes
   - **Nutrition Summary** - Medium and Large sizes

## Widget Features

### Calorie Progress Widget
- **Small**: Circular progress ring with calories consumed
- **Medium**: Progress ring with detailed stats (consumed/remaining)

### Fasting Timer Widget
- **Small**: Timer display when fasting, status when not
- **Medium**: Full timer with current fasting benefit and progress bar
- Shows different states: Fasting, Eating Window, Ready to Fast

### Nutrition Summary Widget
- **Medium**: Compact macro circles (protein, carbs, fat)
- **Large**: Full nutrition dashboard with calorie ring and detailed macro bars

## Data Synchronization

The widgets receive data through the App Group shared UserDefaults. The main app automatically syncs data when:

- Food entries are logged
- Fasting state changes
- Goals are updated

To manually refresh widgets, the app calls `WidgetCenter.shared.reloadAllTimelines()`.

## Troubleshooting

### Widgets not showing data
1. Ensure App Groups are configured identically in both targets
2. Check that the group identifier matches: `group.easyaiflows.com.CalTrackProFixed`
3. Try logging food or starting a fast in the main app
4. Force refresh by removing and re-adding the widget

### Widget not appearing in widget gallery
1. Clean build folder (Cmd+Shift+K)
2. Delete the app from your device
3. Rebuild and reinstall

### Build errors
1. Ensure all Swift files are added to the CalTrackWidget target
2. Check that WidgetKit framework is linked
3. Verify deployment target matches main app (iOS 17.0)

## File Reference

| File | Purpose |
|------|---------|
| CalTrackWidgetBundle.swift | Entry point, registers all widgets |
| CalorieProgressWidget.swift | Calorie tracking widget |
| FastingTimerWidget.swift | Fasting timer widget |
| NutritionSummaryWidget.swift | Full nutrition overview widget |
| WidgetDataProvider.swift | (In main app) Syncs data to widgets |

The widgets use `TimelineProvider` for periodic updates:
- Calorie widgets update every hour
- Fasting timer updates every minute for accurate countdown

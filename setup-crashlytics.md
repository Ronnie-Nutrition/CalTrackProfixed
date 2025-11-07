# Firebase Crashlytics Setup Guide for CalTrackPro

## Overview
This guide will help you integrate Firebase Crashlytics for crash reporting in your CalTrackPro app.

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Create a project"
3. Name it "CalTrackPro"
4. Follow the setup wizard (you can disable Google Analytics for now)

## Step 2: Add iOS App to Firebase

1. In Firebase Console, click "Add app" → iOS
2. Enter your Bundle ID: `easyaiflows.com.CalTrackProFixed`
3. App nickname: "CalTrackPro"
4. Download the `GoogleService-Info.plist` file
5. Save it for later (we'll add it to Xcode)

## Step 3: Add Firebase SDK via Swift Package Manager

1. Open your project in Xcode
2. Go to File → Add Package Dependencies
3. Enter URL: `https://github.com/firebase/firebase-ios-sdk`
4. Click "Add Package"
5. Select these packages:
   - FirebaseCrashlytics
   - FirebaseAnalytics (required dependency)
6. Click "Add Package"

## Step 4: Add GoogleService-Info.plist to Xcode

1. Drag the downloaded `GoogleService-Info.plist` into your Xcode project
2. Make sure to:
   - Check "Copy items if needed"
   - Add to target: CalTrackProFixed
   - Place it in the main app folder (next to Info.plist)

## Step 5: Configure Crashlytics in Code

The code changes are already prepared in the following files:
- `CalTrackProApp+Crashlytics.swift` - Main configuration
- `CrashlyticsManager.swift` - Crash reporting utilities

## Step 6: Add Build Phase Script

1. In Xcode, select your project
2. Select the CalTrackProFixed target
3. Go to Build Phases tab
4. Click + → New Run Script Phase
5. Add this script:
```bash
"${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
```
6. In Input Files, add:
   - `${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${TARGET_NAME}`
   - `$(SRCROOT)/$(BUILT_PRODUCTS_DIR)/$(INFOPLIST_PATH)`

## Step 7: Enable dSYM Generation

1. In Build Settings for your target
2. Search for "Debug Information Format"
3. Set to "DWARF with dSYM File" for Release configuration

## Step 8: Test Crashlytics

1. Build and run the app
2. In `SettingsView`, you'll see a "Test Crash" button (DEBUG only)
3. Tap it to force a crash
4. Relaunch the app
5. Check Firebase Console → Crashlytics to see the crash report

## Important Notes

- Crashlytics only sends reports when the app is restarted after a crash
- It may take up to 5 minutes for the first crash to appear in Firebase Console
- The test crash button is only visible in DEBUG builds for safety
- Real crashes in production will be automatically reported

## Privacy Considerations

Add to your privacy policy:
- "This app uses Firebase Crashlytics to collect crash reports to improve app stability"
- "Crash reports may include device information but no personal data"

## Production Checklist

- [ ] GoogleService-Info.plist added to project
- [ ] Firebase SDK packages added
- [ ] Build phase script configured
- [ ] dSYM generation enabled for Release
- [ ] Test crash verified in Firebase Console
- [ ] Privacy policy updated
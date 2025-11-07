#!/bin/bash

echo "🔥 Firebase Crashlytics Setup Script for CalTrackPro"
echo "===================================================="
echo ""

# Check if we're in the right directory
if [ ! -f "CalTrackProFixed.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Please run this script from the CalTrackPro project root directory"
    exit 1
fi

echo "✅ Step 1: Prerequisites"
echo "Before running this script, make sure you have:"
echo "1. Created a Firebase project at https://console.firebase.google.com"
echo "2. Downloaded the GoogleService-Info.plist file"
echo ""
read -p "Press Enter to continue..."

echo ""
echo "📦 Step 2: Opening Xcode to add Firebase SDK"
echo "In Xcode:"
echo "1. Go to File → Add Package Dependencies"
echo "2. Enter: https://github.com/firebase/firebase-ios-sdk"
echo "3. Select FirebaseCrashlytics and FirebaseAnalytics"
echo ""
read -p "Press Enter after adding the packages..."

echo ""
echo "📄 Step 3: Add GoogleService-Info.plist"
echo "1. Drag your downloaded GoogleService-Info.plist into Xcode"
echo "2. Place it next to Info.plist in the project navigator"
echo "3. Make sure to check 'Copy items if needed'"
echo "4. Add to target: CalTrackProFixed"
echo ""
read -p "Press Enter after adding the file..."

echo ""
echo "🔧 Step 4: Creating Firebase configuration files"
echo "The following files have been created:"
echo "- CalTrackProApp+Crashlytics.swift"
echo "- CrashlyticsManager.swift"
echo "- Updated CalTrackProApp.swift"
echo "- Updated SettingsView.swift with test crash button"

echo ""
echo "📝 Step 5: Build Phase Script"
echo "In Xcode:"
echo "1. Select your project in the navigator"
echo "2. Select the CalTrackProFixed target"
echo "3. Go to Build Phases tab"
echo "4. Click + → New Run Script Phase"
echo "5. Paste this script:"
echo '${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run'
echo ""
echo "6. Add these Input Files:"
echo '${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${TARGET_NAME}'
echo '$(SRCROOT)/$(BUILT_PRODUCTS_DIR)/$(INFOPLIST_PATH)'
echo ""
read -p "Press Enter after adding the build phase..."

echo ""
echo "🏗️ Step 6: Enable dSYM Generation"
echo "In Build Settings:"
echo "1. Search for 'Debug Information Format'"
echo "2. Set Release configuration to 'DWARF with dSYM File'"
echo ""
read -p "Press Enter after updating build settings..."

echo ""
echo "✅ Setup Complete!"
echo ""
echo "To test Crashlytics:"
echo "1. Build and run the app (Cmd+R)"
echo "2. Go to Settings in the app"
echo "3. Scroll to Debug section (only visible in DEBUG builds)"
echo "4. Tap 'Test Crash'"
echo "5. Relaunch the app"
echo "6. Check Firebase Console → Crashlytics after 5 minutes"
echo ""
echo "🚀 Your app now has production-ready crash reporting!"
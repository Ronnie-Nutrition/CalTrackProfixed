# CalTrackPro - Production Ready Setup Guide

This package contains all files needed to make CalTrackPro production-ready for the iOS App Store.

## 📁 File Overview

```
CalTrackPro/
├── Services/
│   ├── FoodRecognitionService.swift    # AI food recognition + USDA/OpenFoodFacts APIs
│   ├── AuthenticationService.swift      # Sign in with Apple
│   ├── HealthKitService.swift          # Apple Health integration
│   └── CloudSyncService.swift          # iCloud/CloudKit sync
├── Resources/
│   ├── PrivacyInfo.xcprivacy           # REQUIRED: Privacy manifest for App Store
│   └── privacy-policy.html             # Host on easyaiflows.com/caltrackpro/privacy
├── Config/
│   ├── ExportOptions.plist             # App Store build export config
│   ├── InfoPlistAdditions.plist        # Privacy permission strings
│   └── AppStoreMetadata.md             # Description, keywords, screenshots guide
├── CalTrackPro.entitlements            # HealthKit, Sign in with Apple, CloudKit
├── build_for_appstore.sh               # One-command App Store build script
└── README.md                           # This file
```

---

## 🚀 Quick Setup (15 minutes)

### Step 1: Add Service Files
Copy the `Services/` folder into your Xcode project:
1. Drag the folder into Xcode
2. Select "Copy items if needed"
3. Add to target: CalTrackPro

### Step 2: Add Privacy Manifest (REQUIRED)
1. Copy `Resources/PrivacyInfo.xcprivacy` to your project root
2. In Xcode: File → Add Files → Select `PrivacyInfo.xcprivacy`
3. Ensure it's added to your target

### Step 3: Update Info.plist
Add these keys from `Config/InfoPlistAdditions.plist`:
- NSCameraUsageDescription
- NSPhotoLibraryUsageDescription
- NSHealthShareUsageDescription
- NSHealthUpdateUsageDescription
- UIBackgroundModes

### Step 4: Add Capabilities in Xcode
Select your target → Signing & Capabilities → + Capability:
- [x] HealthKit (check "Background Delivery")
- [x] Sign in with Apple
- [x] iCloud (select CloudKit, create container)
- [x] Push Notifications

### Step 5: Host Privacy Policy
Upload `privacy-policy.html` to: `https://easyaiflows.com/caltrackpro/privacy`

### Step 6: Update Bundle ID & Team
In `Config/ExportOptions.plist`:
- Replace `YOUR_TEAM_ID` with your Apple Developer Team ID
- Verify bundle ID: `com.ronnienutrition.CalTrackPro`

---

## 📱 Service Integration Guide

### FoodRecognitionService
```swift
// In your view or view model:
@StateObject private var foodService = FoodRecognitionService()

// Recognize food from photo:
let results = try await foodService.recognizeFood(from: image)

// Results include:
// - name: "Grilled Chicken"
// - confidence: 0.87
// - calories: 165
// - protein: 31.0
// - carbs: 0.0
// - fat: 3.6
```

### AuthenticationService
```swift
@StateObject private var authService = AuthenticationService()

// In your login view:
SignInWithAppleButtonView()
    .environmentObject(authService)

// Check auth state:
switch authService.authState {
case .authenticated(let user):
    // Show main app
case .unauthenticated:
    // Show login
}
```

### HealthKitService
```swift
@StateObject private var healthKit = HealthKitService()

// Request authorization:
try await healthKit.requestAuthorization()

// Save food entry:
try await healthKit.saveFoodEntry(
    calories: 450,
    protein: 30,
    carbs: 45,
    fat: 15
)

// Get today's summary:
await healthKit.fetchTodaySummary()
let calories = healthKit.todaySummary.calories
```

### CloudSyncService
```swift
@StateObject private var cloudSync = CloudSyncService()

// Save entry to iCloud:
try await cloudSync.saveFoodEntry(entry)

// Fetch entries for date:
let entries = try await cloudSync.fetchFoodEntries(for: Date())
```

---

## 🔑 API Keys Needed

### USDA FoodData Central (Free)
1. Go to: https://fdc.nal.usda.gov/api-key-signup.html
2. Sign up for free API key
3. Add to your project:
   ```swift
   // In FoodRecognitionService, replace:
   private let apiKey = "YOUR_USDA_API_KEY"
   ```

### Open Food Facts (No key needed)
Barcode lookup works without API key.

---

## 🏗️ Building for App Store

### Option 1: Xcode GUI
1. Product → Archive
2. Window → Organizer
3. Distribute App → App Store Connect → Upload

### Option 2: Command Line
```bash
# Make script executable
chmod +x build_for_appstore.sh

# Run build (update TEAM_ID first)
./build_for_appstore.sh 1.0.0 1
```

---

## ✅ Pre-Submission Checklist

### Code & Build
- [ ] All services integrated and tested
- [ ] No compiler warnings
- [ ] App launches in < 3 seconds
- [ ] Tested on real device (not just simulator)
- [ ] Tested camera + barcode on device

### App Store Connect
- [ ] App created in App Store Connect
- [ ] Privacy manifest (PrivacyInfo.xcprivacy) included
- [ ] Privacy policy URL active and accessible
- [ ] Screenshots prepared (see AppStoreMetadata.md)
- [ ] App icon 1024x1024 uploaded
- [ ] Description and keywords filled
- [ ] Age rating questionnaire completed
- [ ] App Privacy section completed

### Capabilities
- [ ] HealthKit enabled + usage descriptions
- [ ] Sign in with Apple enabled
- [ ] CloudKit container created
- [ ] Push notifications enabled

---

## 🐛 Common Issues

### "HealthKit not available"
- HealthKit doesn't work in Simulator
- Test on real device

### "Sign in with Apple failed"
- Verify capability is enabled
- Check entitlements file is included in build

### "CloudKit sync not working"
- Create container in Xcode capabilities
- Container name: `iCloud.com.ronnienutrition.CalTrackPro`
- Deploy schema to production in CloudKit Console

### "App rejected for privacy"
- Verify PrivacyInfo.xcprivacy is in app bundle
- Check all usage descriptions are filled
- Ensure privacy policy URL is accessible

---

## 📞 Support

Questions? Email: support@easyaiflows.com

---

Built for CalTrackPro by Ronnie Nutrition

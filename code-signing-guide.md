# Code Signing Configuration Guide - CalTrackPro

## Overview
This guide will help you set up proper code signing and provisioning profiles for App Store distribution.

## Prerequisites

### ✅ Apple Developer Account
- [ ] Active Apple Developer Program membership ($99/year)
- [ ] Access to Apple Developer Portal (developer.apple.com)
- [ ] Two-factor authentication enabled on Apple ID

### ✅ Xcode Setup  
- [ ] Latest Xcode version installed (15.0+)
- [ ] Signed in with Apple Developer account
- [ ] Command Line Tools installed

## Step-by-Step Configuration

### Phase 1: Apple Developer Portal Setup

#### 1. Create App ID
1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Identifiers** → **+** (Add new)
4. Select **App IDs** → **App**
5. Fill in details:
   ```
   Description: CalTrackPro
   Bundle ID: easyaiflows.com.CalTrackProFixed
   Platform: iOS
   ```
6. **Capabilities** (check these):
   - [x] HealthKit (if using health data)
   - [x] Push Notifications (for future updates)
   - [x] Associated Domains (for deep linking)
7. Click **Continue** → **Register**

#### 2. Create Distribution Certificate
1. In **Certificates** section → **+** (Add new)
2. Select **iOS Distribution (App Store and Ad Hoc)**
3. **Certificate Signing Request (CSR)**:
   - Open **Keychain Access** on Mac
   - Keychain Access → Certificate Assistant → Request Certificate from CA
   - Fill in your email and name
   - Select "Saved to disk"
   - Save as `CalTrackPro_CSR.certSigningRequest`
4. Upload the CSR file
5. Download the certificate
6. Double-click to install in Keychain

#### 3. Create Distribution Provisioning Profile
1. In **Profiles** section → **+** (Add new)  
2. Select **App Store** under Distribution
3. Select your App ID: `easyaiflows.com.CalTrackProFixed`
4. Select your Distribution Certificate
5. Name: `CalTrackPro App Store Distribution`
6. Download the `.mobileprovision` file
7. Double-click to install in Xcode

### Phase 2: Xcode Project Configuration

#### 1. Open Project Settings
```bash
# Open your project
open /Users/ronniecraig/CalTrackPro/CalTrackProFixed.xcodeproj
```

#### 2. Configure Target Settings
1. Select **CalTrackProFixed** project in navigator
2. Select **CalTrackProFixed** target
3. Go to **Signing & Capabilities** tab

#### 3. Signing Configuration
**For Release/Distribution:**
```
Team: [Your Apple Developer Team]
Provisioning Profile: CalTrackPro App Store Distribution
Signing Certificate: iOS Distribution
Bundle Identifier: easyaiflows.com.CalTrackProFixed
```

**For Debug/Development:**
```
Team: [Your Apple Developer Team] 
Provisioning Profile: Automatic
Signing Certificate: Apple Development
Bundle Identifier: easyaiflows.com.CalTrackProFixed
```

### Phase 3: Build Settings Verification

#### 1. Code Signing Settings
In **Build Settings** tab, verify these settings:

**For Release Configuration:**
```
Code Signing Style: Manual
Code Signing Identity: iOS Distribution
Provisioning Profile: CalTrackPro App Store Distribution
Development Team: [Your Team ID]
```

**For Debug Configuration:**
```
Code Signing Style: Automatic
Code Signing Identity: Apple Development  
Provisioning Profile: Automatic
Development Team: [Your Team ID]
```

#### 2. Additional Build Settings
```
PRODUCT_BUNDLE_IDENTIFIER = easyaiflows.com.CalTrackProFixed
MARKETING_VERSION = 1.0
CURRENT_PROJECT_VERSION = 1
IPHONEOS_DEPLOYMENT_TARGET = 17.0
TARGETED_DEVICE_FAMILY = 1,2 (iPhone and iPad)
SUPPORTS_MACCATALYST = NO
```

### Phase 4: Capabilities Configuration

#### Required Capabilities
1. **Camera Usage** (for barcode scanning)
   - Already configured in Info.plist
2. **Network Access** (for API calls)
   - Enabled by default
3. **Local Storage** (for SwiftData)
   - Enabled by default

#### Optional Future Capabilities
1. **HealthKit** (for nutrition data sync)
2. **Push Notifications** (for meal reminders)
3. **App Groups** (for widget support)

### Phase 5: Testing Code Signing

#### 1. Archive for Testing
```bash
# In Xcode:
Product → Archive

# Or via command line:
cd /Users/ronniecraig/CalTrackPro
xcodebuild -scheme CalTrackProFixed -configuration Release archive \
  -archivePath build/CalTrackPro.xcarchive \
  -allowProvisioningUpdates
```

#### 2. Validate Archive
1. In **Xcode Organizer**:
2. Select your archive
3. Click **Validate App**
4. Choose **App Store Connect**
5. Select your Distribution Certificate
6. Run validation checks

#### 3. Common Issues & Solutions

**Issue: "No matching provisioning profiles found"**
```bash
Solution: 
1. Delete derived data: rm -rf ~/Library/Developer/Xcode/DerivedData
2. Refresh profiles: Xcode → Preferences → Accounts → Download Manual Profiles
3. Clean and rebuild: Product → Clean Build Folder
```

**Issue: "Code signing identity not found"**
```bash
Solution:
1. Check Keychain Access for certificates
2. Ensure private key is present
3. Re-download certificate if needed
```

**Issue: "Bundle identifier mismatch"**
```bash
Solution:
1. Verify Bundle ID matches App ID exactly
2. Check for typos: easyaiflows.com.CalTrackProFixed
3. Update provisioning profile if changed
```

## Automated Code Signing Script

Create this script for streamlined signing:

```bash
#!/bin/bash
# code-signing-setup.sh

echo "🔐 CalTrackPro Code Signing Setup"
echo "================================"

# Set variables
PROJECT_NAME="CalTrackProFixed"
BUNDLE_ID="easyaiflows.com.CalTrackProFixed"
SCHEME_NAME="CalTrackProFixed"

# Clean project
echo "🧹 Cleaning project..."
xcodebuild clean -project ${PROJECT_NAME}.xcodeproj -scheme $SCHEME_NAME

# Update provisioning profiles
echo "📝 Updating provisioning profiles..."
xcodebuild -downloadAllPlatforms

# Build for testing
echo "🔨 Building for testing..."
xcodebuild build -project ${PROJECT_NAME}.xcodeproj \
  -scheme $SCHEME_NAME \
  -configuration Release \
  -destination generic/platform=iOS

if [ $? -eq 0 ]; then
    echo "✅ Code signing configured successfully!"
    echo "   Ready for Archive and Distribution"
else
    echo "❌ Code signing failed. Check error messages above."
    exit 1
fi
```

## Distribution Preparation

### For App Store Submission
1. **Archive** the app (Product → Archive)
2. **Validate** the archive
3. **Distribute** → App Store Connect
4. **Upload** and wait for processing

### For TestFlight
1. Same archive as App Store
2. Upload to App Store Connect
3. Add TestFlight information
4. Invite beta testers

## Security Best Practices

### Certificate Management
- [ ] Keep certificates and private keys secure
- [ ] Back up certificates and profiles
- [ ] Rotate certificates before expiration
- [ ] Use separate certificates for different apps

### Profile Management
- [ ] Use specific provisioning profiles (not wildcard)
- [ ] Update profiles when adding capabilities
- [ ] Remove unused/expired profiles
- [ ] Monitor profile expiration dates

## Troubleshooting Checklist

### Before Submission
- [ ] Archive builds successfully
- [ ] Validation passes without errors
- [ ] Correct Bundle ID and Version
- [ ] All required capabilities included
- [ ] Distribution certificate not expired
- [ ] Provisioning profile not expired

### Common Commands
```bash
# List all certificates
security find-identity -v -p codesigning

# List all provisioning profiles  
ls ~/Library/MobileDevice/Provisioning\ Profiles/

# Clean Xcode derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Refresh provisioning profiles
xcodebuild -downloadPlatform iOS
```

## Next Steps After Code Signing

1. **Physical Device Testing**
   - Install on iPhone/iPad via Xcode
   - Test all features thoroughly
   - Verify proper signing and permissions

2. **TestFlight Distribution**
   - Upload first build
   - Add beta testers
   - Gather feedback

3. **App Store Submission**
   - Final archive with all assets
   - Complete App Store Connect listing
   - Submit for review

Remember: Code signing is critical for App Store acceptance. Take time to set it up correctly!
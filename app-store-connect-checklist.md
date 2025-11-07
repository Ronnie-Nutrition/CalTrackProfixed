# App Store Connect Submission Checklist

## Pre-Submission Requirements

### ✅ App Information
- [ ] App Name: "CalTrackPro"
- [ ] Subtitle: "Smart Nutrition Tracking" 
- [ ] Primary Category: Health & Fitness
- [ ] Secondary Category: Food & Drink (optional)
- [ ] Content Rights: Own or licensed all content
- [ ] Age Rating: 4+ (completed in App Store Connect)

### ✅ App Version Information  
- [ ] Version Number: 1.0
- [ ] Copyright: 2025 [Your Name/Company]
- [ ] Trade Representative Contact: [Your contact info]
- [ ] App Review Information: Contact details for Apple review team
- [ ] Demo Account: Not applicable (no login required)

### ✅ Pricing and Availability
- [ ] Price: Free
- [ ] Availability: All territories
- [ ] Pre-order: Not applicable for first release

### ✅ App Privacy
- [ ] Privacy Policy URL: https://caltrackpro.app/privacy
- [ ] Data Collection: Nutrition data stored locally only
- [ ] Third-party Analytics: Firebase Crashlytics (crashes/performance only)
- [ ] Location Services: Not used
- [ ] Health Data: Not collected (nutrition tracking only)

## Required Assets

### 📱 App Screenshots
**iPhone 6.7" (Primary - Required)**
- [ ] Screenshot 1: Home screen with nutrition summary
- [ ] Screenshot 2: Food search functionality  
- [ ] Screenshot 3: Barcode scanner interface
- [ ] Screenshot 4: Food details/entry screen
- [ ] Screenshot 5: Daily food diary view
- [ ] Size: 1290x2796 pixels (portrait)
- [ ] Format: PNG or JPEG, sRGB color space

**iPhone 6.5" (Required)**  
- [ ] Same 5 screenshots as above
- [ ] Size: 1242x2688 pixels (portrait)
- [ ] Format: PNG or JPEG, sRGB color space

**iPhone 5.5" (Required)**
- [ ] Same 5 screenshots as above  
- [ ] Size: 1242x2208 pixels (portrait)
- [ ] Format: PNG or JPEG, sRGB color space

**iPad 12.9" (Optional - if supporting iPad)**
- [ ] Same 5 screenshots adapted for iPad
- [ ] Size: 2048x2732 pixels (portrait) 
- [ ] Format: PNG or JPEG, sRGB color space

### 🎨 App Icon
- [ ] App Store Icon: 1024x1024 pixels
- [ ] Format: PNG, no transparency, no rounded corners
- [ ] File size: Under 500KB recommended
- [ ] High quality, recognizable at small sizes

### 📝 App Description
- [ ] App description (up to 4000 characters)
- [ ] Promotional text (up to 170 characters)
- [ ] Keywords (100 characters max, comma-separated)
- [ ] Support URL: mailto:support@caltrackpro.com
- [ ] Marketing URL: https://caltrackpro.app (optional)

## Technical Requirements

### 🔧 Build Configuration
- [ ] iOS Deployment Target: 17.0 or later
- [ ] Built with latest Xcode version
- [ ] Archive built in Release configuration
- [ ] App Transport Security properly configured
- [ ] All privacy usage descriptions included in Info.plist

### 🛡️ Security & Privacy
- [ ] API keys stored securely (not in binary)
- [ ] No hardcoded sensitive information
- [ ] Input validation implemented
- [ ] HTTPS-only network requests
- [ ] Crash reporting configured (Firebase Crashlytics)

### 🧪 Testing
- [ ] Tested on physical iOS device (iPhone/iPad)
- [ ] All core features working (search, scan, diary, manual entry)
- [ ] Offline mode tested and working
- [ ] App launches without crashes
- [ ] Memory leaks checked with Instruments
- [ ] No accessibility issues

## App Store Connect Upload Process

### 📤 Upload Steps
1. **Archive the app:**
   ```bash
   # In Xcode:
   Product → Archive
   # Wait for archive to complete
   ```

2. **Distribute to App Store:**
   ```bash
   # In Organizer:
   Distribute App → App Store Connect → Upload
   # Follow authentication prompts
   ```

3. **Wait for processing:**
   - Binary processing: 5-15 minutes
   - TestFlight availability: 1-2 hours
   - App Store review: 1-7 days

### 🎯 Submission in App Store Connect
1. **Go to App Store Connect** (appstoreconnect.apple.com)
2. **Select your app** from the apps list
3. **Create new version** (1.0) if not already created
4. **Fill in all required information:**
   - App Information
   - Pricing and Availability  
   - App Privacy
   - App Review Information
5. **Add screenshots** for all required device sizes
6. **Upload app icon** (1024x1024)
7. **Select the uploaded build**
8. **Submit for App Review**

## Review Guidelines Compliance

### ✅ Content Requirements
- [ ] App functions as described
- [ ] No misleading information
- [ ] Appropriate content rating (4+)
- [ ] No intellectual property violations
- [ ] Privacy policy clearly explains data use

### ✅ Technical Requirements  
- [ ] App launches without crashing
- [ ] All advertised features work correctly
- [ ] Handles network connectivity issues gracefully
- [ ] Proper error handling and user feedback
- [ ] Follows iOS Human Interface Guidelines

### ✅ Business Requirements
- [ ] App provides sufficient value for users
- [ ] No spam or low-quality content
- [ ] Honest and transparent about app functionality
- [ ] Appropriate metadata and descriptions

## Post-Submission

### 📊 Monitor Status
- [ ] Check App Store Connect for review status
- [ ] Respond promptly to any reviewer questions
- [ ] Monitor crash reports in Firebase Crashlytics
- [ ] Track app performance metrics

### 🚀 Launch Preparation
- [ ] Prepare marketing materials
- [ ] Set up app website/landing page
- [ ] Plan social media announcements
- [ ] Gather user feedback collection strategy

### 🔄 Update Planning
- [ ] Plan first update based on user feedback
- [ ] Monitor App Store reviews and ratings
- [ ] Track feature usage analytics
- [ ] Prepare bug fix releases if needed

## Quick Reference

**Minimum iOS Version:** 17.0  
**App Size:** ~15-25MB (estimated)  
**Required Permissions:** Camera (for barcode scanning), Photos (for food images)  
**Optional Features:** Health app integration (future update)  
**Monetization:** None (free app)  
**In-App Purchases:** None  

## Emergency Contacts

**Apple Developer Support:** developer.apple.com/support  
**App Store Review:** Use App Store Connect messaging  
**Technical Issues:** Firebase Console for crash monitoring  

Remember: First-time app submissions typically take 2-7 days for review. Plan accordingly!
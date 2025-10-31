# Edamam API Setup Instructions

## Quick Setup Steps:

1. **Get Your API Credentials:**
   - Go to https://www.edamam.com/
   - Click "Sign Up" or "Start Now"
   - Choose "Food Database API" 
   - Select the FREE "Developer" plan (up to 10,000 calls/month)
   - You'll receive an App ID and App Key

2. **Update Your API Credentials:**
   
   Open `/Users/ronniecraig/CalTrackPro/Models/Utilities/APIConfig.swift` and update lines 22 and 41:
   
   ```swift
   // Line 22 - Replace with your App ID
   return "YOUR_APP_ID_HERE"
   
   // Line 41 - Replace with your App Key  
   return "YOUR_APP_KEY_HERE"
   ```

3. **Rebuild the App:**
   - In Xcode, press Cmd+Shift+K to clean
   - Press Cmd+R to rebuild and run
   - The food search should now work!

## Alternative: Use Info.plist (More Secure)

Add these to your Info.plist:
```xml
<key>EDAMAM_APP_ID</key>
<string>YOUR_APP_ID_HERE</string>
<key>EDAMAM_APP_KEY</key>
<string>YOUR_APP_KEY_HERE</string>
```

## Testing
After updating, search for "chicken" again and it should return results!
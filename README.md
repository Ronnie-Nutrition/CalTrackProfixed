# CalTrackPro

An AI-powered calorie tracking iOS app built with SwiftUI, competing with Cal AI.

## Features

- **AI-Powered Food Recognition**: Take a photo and instantly get nutrition information
- **Barcode Scanning**: Quick product lookup with barcode scanner
- **Manual Entry**: Add custom foods and recipes
- **Nutrition Tracking**: Track calories, protein, carbs, and fat
- **Progress Analytics**: Visualize your nutrition trends with charts
- **Meal Planning**: AI suggestions based on remaining daily macros
- **Recipe Builder**: Create and save custom recipes
- **Apple Health Integration**: Sync with other fitness apps
- **Offline Mode**: Track without internet using on-device ML

## Project Structure

```
CalTrackPro/
├── App/
│   └── CalTrackProApp.swift      # Main app entry point
├── Models/
│   ├── FoodEntry.swift           # Food entry data model
│   ├── UserProfile.swift         # User profile model
│   └── Recipe.swift              # Recipe model
├── Views/
│   ├── ContentView.swift         # Root view
│   ├── HomeView.swift            # Main tracking screen
│   ├── DiaryView.swift           # Food diary
│   ├── InsightsView.swift        # Analytics & insights
│   ├── ProfileView.swift         # User profile
│   ├── CameraView.swift          # Camera for food recognition
│   ├── BarcodeScannerView.swift  # Barcode scanner
│   └── ...                       # Other views
├── Services/                     # (To be implemented)
│   └── FoodRecognitionService.swift
├── Utilities/                    # (To be implemented)
└── Resources/                    # (To be implemented)
```

## Setup Instructions

1. **Open in Xcode**
   - Open Xcode
   - Select "Create a new Xcode project"
   - Choose "App" under iOS
   - Configure:
     - Product Name: CalTrackPro
     - Team: Your Apple Developer Team
     - Organization Identifier: com.yourcompany
     - Interface: SwiftUI
     - Language: Swift
     - Use SwiftData: Yes

2. **Copy Project Files**
   - Replace the default project files with the ones in this directory
   - Make sure to maintain the folder structure

3. **Configure Capabilities**
   - Add Camera capability for food scanning
   - Add HealthKit capability for Apple Health integration
   - Configure App Groups if needed for widgets

4. **Add Dependencies** (if needed)
   - Charts framework is built into iOS 16+
   - Vision and CoreML are system frameworks

## Next Steps

1. **Implement ML Models**
   - Integrate food recognition models (Vision API or custom Core ML)
   - Train or find pre-trained models for food classification
   - Implement portion size estimation using depth data

2. **Backend Integration**
   - Set up Firebase/CloudKit for user data sync
   - Integrate food database API (USDA, Nutritionix, etc.)
   - Implement user authentication

3. **App Store Preparation**
   - Create app icons and screenshots
   - Write App Store description
   - Prepare privacy policy
   - Submit for review

## Testing

- Test camera functionality on real device
- Test barcode scanning with various products
- Verify SwiftData persistence
- Test all meal tracking flows
- Verify nutrition calculations

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- iPhone with camera for full functionality
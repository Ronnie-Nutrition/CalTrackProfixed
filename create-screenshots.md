# Screenshot Creation Guide for CalTrackPro

## Setup for Professional Screenshots

### 1. Prepare the App with Sample Data

Before taking screenshots, populate your app with realistic sample data:

#### Sample Food Entries to Add:
```
Breakfast:
- Oatmeal with Banana (350 cal)
- Greek Yogurt (120 cal)
- Orange Juice (110 cal)

Lunch: 
- Chicken Salad Sandwich (480 cal)
- Apple (80 cal)
- Sparkling Water (0 cal)

Dinner:
- Grilled Salmon (250 cal)
- Brown Rice (220 cal)
- Steamed Broccoli (55 cal)
- Mixed Salad (45 cal)

Snacks:
- Almonds (160 cal)
- Green Tea (2 cal)
```

### 2. iOS Simulator Setup

#### Device Selection for Screenshots:
1. **iPhone 15 Pro Max** (6.7") - PRIMARY
2. **iPhone 14 Pro Max** (6.7") - BACKUP
3. **iPad Pro 12.9"** (if supporting iPad)

#### Simulator Settings:
1. Open Xcode
2. Product → Destination → iPhone 15 Pro Max
3. Build and Run (⌘R)
4. Once app loads, press ⌘S to take screenshot
5. Screenshots auto-saved to Desktop

### 3. Screenshot Sequence

#### Screenshot 1: Home Screen
**Setup:**
- Make sure it's a new day with some meals logged
- Show today's progress (maybe 65% of calorie goal)
- Ensure all tabs are visible at bottom

**Capture:**
- Show main dashboard
- Include nutrition summary
- Display progress rings/charts
- Show "Scan Barcode" prominent button

#### Screenshot 2: Food Search
**Setup:**
- Tap on Search tab
- Search for "chicken breast"
- Let results load

**Capture:**
- Search bar with "chicken breast" 
- List of search results
- Show nutrition info for each result
- Clean, organized food list

#### Screenshot 3: Barcode Scanner
**Setup:**
- Tap on Home → Scan Barcode
- Camera view will appear

**Capture:**
- Barcode scanning interface
- Camera viewfinder
- Scanning overlay graphics
- "Point camera at barcode" instruction

#### Screenshot 4: Food Details/Entry
**Setup:**
- From search results, tap on a food item
- Show the food details screen

**Capture:**
- Food name and brand
- Nutrition facts display
- Serving size controls
- "Add to Diary" button
- Clean nutrition layout

#### Screenshot 5: Daily Diary
**Setup:**
- Go to Diary tab
- Make sure current day has several meals

**Capture:**
- Today's date prominently shown
- Breakfast, lunch, dinner sections
- Food items listed under each meal
- Total calories for day
- Nutrition breakdown

### 4. Taking Professional Screenshots

#### iOS Simulator Method:
```bash
# Open simulator
open -a Simulator

# Take screenshot (⌘S in simulator)
# Screenshots saved to ~/Desktop

# Or use command line:
xcrun simctl io booted screenshot screenshot.png
```

#### Physical Device Method:
```bash
# Connect iPhone via USB
# Use QuickTime Player:
# File → New Movie Recording → Select iPhone as camera
# Record screen interactions, then extract frames
```

### 5. Screenshot Post-Processing

#### Required Edits:
1. **Crop to exact dimensions** (1290x2796 for iPhone 6.7")
2. **Add marketing text overlays**
3. **Ensure consistent lighting/contrast**
4. **Remove any debug/test elements**

#### Marketing Text Overlays:
- Screenshot 1: "Track Your Nutrition Effortlessly"
- Screenshot 2: "Comprehensive Food Database"  
- Screenshot 3: "Instant Barcode Scanning"
- Screenshot 4: "Detailed Nutrition Information"
- Screenshot 5: "Daily Progress Tracking"

### 6. Required Screenshot Dimensions

#### iPhone 6.7" (iPhone 15 Pro Max, 14 Pro Max)
- **Portrait**: 1290x2796px
- **Landscape**: 2796x1290px

#### iPhone 6.5" (iPhone 11 Pro Max, XS Max)  
- **Portrait**: 1242x2688px
- **Landscape**: 2688x1242px

#### iPhone 5.5" (iPhone 8 Plus)
- **Portrait**: 1242x2208px  
- **Landscape**: 2208x1242px

### 7. Screenshot Organization

Create this folder structure:
```
Screenshots/
├── iPhone-6.7/
│   ├── 01-home.png (1290x2796)
│   ├── 02-search.png
│   ├── 03-scanner.png
│   ├── 04-details.png
│   └── 05-diary.png
├── iPhone-6.5/
│   ├── 01-home.png (1242x2688)
│   └── ... (same sequence)
└── iPhone-5.5/
    ├── 01-home.png (1242x2208)
    └── ... (same sequence)
```

### 8. Quality Checklist

Before submitting screenshots:

#### Technical:
- [ ] Exact pixel dimensions for each device
- [ ] PNG format with sRGB color profile
- [ ] No compression artifacts
- [ ] No status bar showing sensitive info

#### Content:
- [ ] App shows realistic, appealing data
- [ ] All text is readable at thumbnail size
- [ ] Marketing messages are clear and compelling
- [ ] Screenshots tell a story of app flow
- [ ] Consistent visual design across all shots

#### App Store Requirements:
- [ ] Family-friendly content
- [ ] No trademarked content without permission
- [ ] Accurate representation of app functionality
- [ ] No misleading claims or features

## Quick Start Command

Run this to set up everything:
```bash
# 1. Build app with sample data
open -a Xcode CalTrackProFixed.xcodeproj

# 2. Run on iPhone 15 Pro Max simulator  
# 3. Populate with sample data above
# 4. Take 5 screenshots using ⌘S
# 5. Screenshots will be on Desktop

# 6. Resize for different devices using sips:
sips -z 2688 1242 screenshot.png --out iPhone-6.5-screenshot.png
sips -z 2208 1242 screenshot.png --out iPhone-5.5-screenshot.png
```
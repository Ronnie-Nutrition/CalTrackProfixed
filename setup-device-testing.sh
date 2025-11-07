#!/bin/bash

echo "📱 CalTrackPro Device Testing Setup"
echo "===================================="

# Check if we're in the right directory
if [ ! -f "CalTrackProFixed.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Please run this script from the CalTrackPro project root directory"
    exit 1
fi

echo ""
echo "🔧 This script will prepare your environment for comprehensive device testing."
echo ""

# Check if Xcode is available
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: Xcode command line tools not found"
    echo "   Please install Xcode and command line tools first"
    exit 1
fi

echo "✅ Step 1: Checking Xcode setup"

# Check if project builds
echo "   Testing project build..."
BUILD_TEST=$(xcodebuild -project CalTrackProFixed.xcodeproj -scheme CalTrackProFixed -configuration Debug -destination generic/platform=iOS clean build 2>&1)
BUILD_STATUS=$?

if [ $BUILD_STATUS -eq 0 ]; then
    echo "   ✅ Project builds successfully"
else
    echo "   ⚠️  Build issues detected - you may need to fix code signing first"
    echo "   Run: ./verify-code-signing.sh"
fi

echo ""
echo "📱 Step 2: Checking connected devices"

# List connected devices
DEVICES=$(xcrun xctrace list devices 2>/dev/null | grep -v "Simulator" | grep "iPhone\|iPad")
if [ -n "$DEVICES" ]; then
    echo "   ✅ Connected devices found:"
    echo "$DEVICES" | head -5
    DEVICE_COUNT=$(echo "$DEVICES" | wc -l | xargs)
    echo "   📊 Total devices: $DEVICE_COUNT"
else
    echo "   ⚠️  No physical devices connected"
    echo "   Please connect an iPhone or iPad via USB"
fi

echo ""
echo "🧪 Step 3: Creating test materials"

# Create a test materials directory
TEST_DIR="TestMaterials"
mkdir -p "$TEST_DIR"

# Create barcode test images (placeholder - you'll need real barcodes)
echo "   📋 Creating test materials folder: $TEST_DIR"

# Create test data file
cat > "$TEST_DIR/test-foods.txt" << 'EOF'
# CalTrackPro Test Foods for Manual Entry

## Breakfast Items
- Oatmeal: 150 cal, 5g protein, 27g carbs, 3g fat
- Greek Yogurt: 120 cal, 17g protein, 9g carbs, 0g fat
- Banana: 105 cal, 1g protein, 27g carbs, 0g fat
- Orange Juice: 110 cal, 2g protein, 26g carbs, 0g fat

## Lunch Items  
- Chicken Breast: 165 cal, 31g protein, 0g carbs, 4g fat
- Brown Rice: 220 cal, 5g protein, 45g carbs, 2g fat
- Mixed Salad: 50 cal, 3g protein, 10g carbs, 0g fat
- Apple: 95 cal, 0g protein, 25g carbs, 0g fat

## Dinner Items
- Salmon Fillet: 280 cal, 25g protein, 0g carbs, 20g fat
- Sweet Potato: 180 cal, 4g protein, 41g carbs, 0g fat
- Broccoli: 55 cal, 4g protein, 11g carbs, 1g fat
- Olive Oil (1 tbsp): 120 cal, 0g protein, 0g carbs, 14g fat

## Snack Items
- Almonds (1 oz): 160 cal, 6g protein, 6g carbs, 14g fat
- String Cheese: 80 cal, 8g protein, 1g carbs, 6g fat
- Carrots: 25 cal, 1g protein, 6g carbs, 0g fat
- Protein Bar: 200 cal, 20g protein, 15g carbs, 8g fat
EOF

echo "   ✅ Test food data created: $TEST_DIR/test-foods.txt"

# Create search terms file
cat > "$TEST_DIR/search-terms.txt" << 'EOF'
# Search Terms for Testing Food Database

## Basic Foods
chicken
apple
banana
rice
bread
milk

## Complex Terms
chicken breast
protein shake
greek yogurt
brown rice
olive oil

## Edge Cases
"" (empty search)
a (single character)
supercalifragilisticexpialidocious (very long)
123!@# (invalid characters)
CHICKEN (uppercase)
ChIcKeN (mixed case)

## International Foods
quinoa
avocado
hummus
tofu
salmon

## Brand Names
coca cola
pepsi
cheerios
doritos
EOF

echo "   ✅ Search terms created: $TEST_DIR/search-terms.txt"

# Create network testing guide
cat > "$TEST_DIR/network-testing-guide.txt" << 'EOF'
# Network Testing Guide

## Test Network Conditions

### 1. WiFi Testing
- Connect to stable WiFi
- Test search and barcode features
- Note response times

### 2. Cellular Testing  
- Disable WiFi, use cellular only
- Test in different locations
- Monitor data usage

### 3. Slow Connection Simulation
In iPhone Settings:
- Developer → Network Link Conditioner
- Enable and select "3G" profile
- Test app behavior with slow network

### 4. Offline Testing
- Enable Airplane Mode
- Test offline features:
  • Manual food entry
  • Viewing cached search results
  • Food diary functionality
  • Settings and help screens

### 5. Network Recovery Testing
- Start in Airplane Mode
- Use app with offline features
- Disable Airplane Mode
- Verify smooth transition back online
EOF

echo "   ✅ Network testing guide: $TEST_DIR/network-testing-guide.txt"

echo ""
echo "📋 Step 4: Opening testing documentation"

# Copy checklists for easy access
cp "device-testing-checklist.md" "$TEST_DIR/"
echo "   ✅ Testing checklist copied to $TEST_DIR"

echo ""
echo "🎯 Step 5: Pre-flight check"

# Check critical components
echo "   Checking critical app components..."

# Check if Info.plist has required permissions
if grep -q "NSCameraUsageDescription" Info.plist 2>/dev/null; then
    echo "   ✅ Camera permission configured"
else
    echo "   ⚠️  Camera permission not found in Info.plist"
fi

if grep -q "NSPhotoLibraryUsageDescription" Info.plist 2>/dev/null; then
    echo "   ✅ Photo library permission configured"
else
    echo "   ⚠️  Photo library permission not found in Info.plist"
fi

# Check for app icon
if [ -d "AppIcon.appiconset" ] || find . -name "*.appiconset" -type d | grep -q .; then
    echo "   ✅ App icons found"
else
    echo "   ⚠️  App icons not configured"
fi

echo ""
echo "🚀 Ready for Device Testing!"
echo ""
echo "📝 Next Steps:"
echo ""
echo "1. **Connect your iPhone/iPad via USB**"
echo ""
echo "2. **Open Xcode and run on device:**"
echo "   open CalTrackProFixed.xcodeproj"
echo ""
echo "3. **Follow the testing checklist:**"
echo "   open $TEST_DIR/device-testing-checklist.md"
echo ""
echo "4. **Use test materials:**"
echo "   • Food data: $TEST_DIR/test-foods.txt"
echo "   • Search terms: $TEST_DIR/search-terms.txt"
echo "   • Network guide: $TEST_DIR/network-testing-guide.txt"
echo ""
echo "📱 Testing Tips:"
echo "• Test with real barcodes from food packaging"
echo "• Try different lighting conditions for scanner"
echo "• Test with low battery and limited storage"
echo "• Use various network conditions"
echo "• Test accessibility features (VoiceOver)"
echo ""
echo "🎯 Success Criteria:"
echo "• No crashes during normal usage"
echo "• All core features work as expected"
echo "• Good performance on target devices"
echo "• Proper error handling and user feedback"
echo ""
echo "📊 When testing is complete:"
echo "• Fill out the testing checklist"
echo "• Document any issues found"
echo "• Re-test after fixing critical bugs"
echo "• Prepare for App Store submission"
echo ""

# Check if we should open Xcode
read -p "Would you like to open Xcode now to start device testing? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Opening Xcode..."
    open CalTrackProFixed.xcodeproj
    echo "   Select your connected device as the destination and press ⌘R to run!"
fi

echo ""
echo "✅ Device testing setup complete!"
echo "   Good luck with your testing! 📱"
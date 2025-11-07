#!/bin/bash

echo "🎨 CalTrackPro App Icon Setup Script"
echo "===================================="

# Check if we're in the right directory
if [ ! -f "CalTrackProFixed.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Please run this script from the CalTrackPro project root directory"
    exit 1
fi

echo "✅ Step 1: Locating Xcode project"

# Find the actual Assets.xcassets folder in the project
ASSETS_FOLDER=""
if [ -d "CalTrackPro/Assets.xcassets" ]; then
    ASSETS_FOLDER="CalTrackPro/Assets.xcassets"
elif [ -d "CalTrackProFixed/Assets.xcassets" ]; then
    ASSETS_FOLDER="CalTrackProFixed/Assets.xcassets"
elif [ -d "Assets.xcassets" ]; then
    ASSETS_FOLDER="Assets.xcassets"
fi

if [ -z "$ASSETS_FOLDER" ]; then
    echo "⚠️  Assets.xcassets folder not found. Creating one..."
    mkdir -p "CalTrackPro/Assets.xcassets"
    ASSETS_FOLDER="CalTrackPro/Assets.xcassets"
fi

echo "📁 Found assets folder: $ASSETS_FOLDER"

echo "🔄 Step 2: Setting up App Icon set"

# Remove existing AppIcon.appiconset if it exists
if [ -d "$ASSETS_FOLDER/AppIcon.appiconset" ]; then
    echo "   Removing existing AppIcon set..."
    rm -rf "$ASSETS_FOLDER/AppIcon.appiconset"
fi

# Copy the new AppIcon.appiconset
echo "   Copying new AppIcon set..."
cp -r "AppIcon.appiconset" "$ASSETS_FOLDER/"

# Verify the copy worked
if [ ! -d "$ASSETS_FOLDER/AppIcon.appiconset" ]; then
    echo "❌ Error: Failed to copy AppIcon.appiconset"
    exit 1
fi

echo "✅ Step 3: Verifying icon files"

# Check for required icon files
REQUIRED_ICONS=("1024.png" "180.png" "120.png" "87.png" "80.png" "58.png" "40.png" "29.png" "20.png")
MISSING_ICONS=()

for icon in "${REQUIRED_ICONS[@]}"; do
    if [ ! -f "$ASSETS_FOLDER/AppIcon.appiconset/$icon" ]; then
        MISSING_ICONS+=("$icon")
    else
        echo "   ✓ $icon"
    fi
done

if [ ${#MISSING_ICONS[@]} -ne 0 ]; then
    echo "⚠️  Warning: Missing icon files:"
    for missing in "${MISSING_ICONS[@]}"; do
        echo "     ❌ $missing"
    done
else
    echo "   ✅ All required icon files present"
fi

echo "📱 Step 4: Creating Contents.json for Xcode"

# Create a simplified Contents.json for iOS only
cat > "$ASSETS_FOLDER/AppIcon.appiconset/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "40.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "60.png",
      "idiom" : "iphone",
      "scale" : "3x", 
      "size" : "20x20"
    },
    {
      "filename" : "58.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "87.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "filename" : "80.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "120.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "filename" : "120.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "filename" : "180.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "filename" : "1024.png",
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo "✅ Step 5: Icon setup complete!"

echo ""
echo "📋 Next Steps:"
echo "1. Open your project in Xcode:"
echo "   open CalTrackProFixed.xcodeproj"
echo ""
echo "2. In Xcode, navigate to your project settings:"
echo "   • Select your project in navigator"
echo "   • Select your app target"
echo "   • Go to 'General' tab" 
echo "   • Under 'App Icons and Launch Screen'"
echo "   • Verify 'AppIcon' is selected for 'App Icon Source'"
echo ""
echo "3. Build and run to test the icons:"
echo "   • Press ⌘+R to build and run"
echo "   • Check home screen for new app icon"
echo "   • Icons should appear in all standard sizes"
echo ""
echo "4. For App Store submission:"
echo "   • The 1024x1024 icon will be used for App Store listing"
echo "   • All other sizes are for device display"
echo ""
echo "🎉 Your app icons are ready for production!"
echo ""
echo "⚠️  Remember:"
echo "• Test on physical device before App Store submission"
echo "• Icons should be recognizable at small sizes"
echo "• Ensure 1024x1024 icon has no transparency or rounded corners"
EOF
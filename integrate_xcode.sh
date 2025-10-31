#!/bin/bash

# Script to integrate CalTrackPro code into Xcode project

XCODE_PROJECT="/Users/ronniecraig/Desktop/CalTrackPro"
SOURCE_DIR="/Users/ronniecraig/CalTrackPro"

echo "🚀 Starting Xcode integration..."

# Step 1: Backup existing files
echo "📦 Backing up existing files..."
if [ -f "$XCODE_PROJECT/CalTrackPro/ContentView.swift" ]; then
    mv "$XCODE_PROJECT/CalTrackPro/ContentView.swift" "$XCODE_PROJECT/CalTrackPro/ContentView.swift.backup"
fi
if [ -f "$XCODE_PROJECT/CalTrackPro/CalTrackProApp.swift" ]; then
    mv "$XCODE_PROJECT/CalTrackPro/CalTrackProApp.swift" "$XCODE_PROJECT/CalTrackPro/CalTrackProApp.swift.backup"
fi

# Step 2: Create folder structure
echo "📁 Creating folder structure..."
mkdir -p "$XCODE_PROJECT/CalTrackPro/App"
mkdir -p "$XCODE_PROJECT/CalTrackPro/Models"
mkdir -p "$XCODE_PROJECT/CalTrackPro/Views"
mkdir -p "$XCODE_PROJECT/CalTrackPro/Services"
mkdir -p "$XCODE_PROJECT/CalTrackPro/Utilities"
mkdir -p "$XCODE_PROJECT/CalTrackPro/Resources"

# Step 3: Copy Swift files
echo "📄 Copying Swift files..."

# Copy App files
cp -r "$SOURCE_DIR/CalTrackPro/App/"* "$XCODE_PROJECT/CalTrackPro/App/" 2>/dev/null || true

# Copy Models
cp -r "$SOURCE_DIR/CalTrackPro/Models/"* "$XCODE_PROJECT/CalTrackPro/Models/" 2>/dev/null || true

# Copy Views
cp -r "$SOURCE_DIR/CalTrackPro/Views/"* "$XCODE_PROJECT/CalTrackPro/Views/" 2>/dev/null || true

# Copy Utilities
cp -r "$SOURCE_DIR/CalTrackPro/Utilities/"* "$XCODE_PROJECT/CalTrackPro/Utilities/" 2>/dev/null || true

# Step 4: Copy Info.plist
echo "📋 Copying Info.plist..."
cp "$SOURCE_DIR/Info.plist" "$XCODE_PROJECT/CalTrackPro/Info.plist"

echo "✅ Integration complete!"
echo ""
echo "📱 Next steps in Xcode:"
echo "1. Right-click on CalTrackPro folder in Xcode"
echo "2. Select 'Add Files to CalTrackPro'"
echo "3. Navigate to the folders we created (App, Models, Views, etc.)"
echo "4. Select all folders and click 'Add'"
echo "5. Make sure 'Create groups' is selected and 'CalTrackPro' target is checked"
echo ""
echo "🔧 Then:"
echo "1. Delete the backup files (.backup extension)"
echo "2. Build the project (Cmd+B)"
echo "3. Fix any errors that appear"
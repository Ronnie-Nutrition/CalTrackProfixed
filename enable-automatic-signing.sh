#!/bin/bash

echo "🔐 CalTrackPro - Enable Automatic Code Signing"
echo "=============================================="

# Check if we're in the right directory
if [ ! -f "CalTrackProFixed.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Please run this script from the CalTrackPro project root directory"
    exit 1
fi

echo ""
echo "🔧 This script will configure your project for automatic code signing."
echo "   This is the easiest way to get started with App Store deployment."
echo ""

# Check if user wants to continue
read -p "Continue with automatic signing setup? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Setup cancelled by user"
    exit 0
fi

echo ""
echo "📝 Step 1: Backing up current project settings"

# Create backup of project file
cp CalTrackProFixed.xcodeproj/project.pbxproj CalTrackProFixed.xcodeproj/project.pbxproj.backup
echo "   ✅ Backup created: project.pbxproj.backup"

echo ""
echo "🔧 Step 2: Configuring automatic code signing"

# Enable automatic code signing in project file
sed -i '' 's/CODE_SIGN_STYLE = Manual/CODE_SIGN_STYLE = Automatic/g' CalTrackProFixed.xcodeproj/project.pbxproj
sed -i '' 's/"CODE_SIGN_STYLE" = Manual/"CODE_SIGN_STYLE" = Automatic/g' CalTrackProFixed.xcodeproj/project.pbxproj

# Remove manual provisioning profile specifications
sed -i '' '/PROVISIONING_PROFILE_SPECIFIER/d' CalTrackProFixed.xcodeproj/project.pbxproj
sed -i '' '/"PROVISIONING_PROFILE_SPECIFIER"/d' CalTrackProFixed.xcodeproj/project.pbxproj

# Ensure development team is set (you'll need to update this in Xcode)
echo "   ✅ Automatic signing enabled in project file"

echo ""
echo "🎯 Step 3: Next steps to complete setup"
echo ""
echo "   1. Open Xcode:"
echo "      open CalTrackProFixed.xcodeproj"
echo ""
echo "   2. Sign in to your Apple Developer account:"
echo "      • Xcode → Preferences → Accounts"
echo "      • Add your Apple ID: extremenutrition.craig@gmail.com"
echo "      • Select your development team"
echo ""
echo "   3. Configure project signing:"
echo "      • Select CalTrackProFixed project in navigator"
echo "      • Select CalTrackProFixed target"
echo "      • Go to 'Signing & Capabilities' tab"
echo "      • Verify 'Automatically manage signing' is checked ✅"
echo "      • Select your team from the dropdown"
echo ""
echo "   4. Test the configuration:"
echo "      • Connect an iPhone via USB"
echo "      • Select iPhone as destination in Xcode"
echo "      • Press ⌘R to build and run"
echo "      • App should install and launch on your device"
echo ""

echo "📱 Step 4: For App Store submission"
echo ""
echo "   When ready to submit to App Store:"
echo "   • Product → Archive (creates distribution build)"
echo "   • In Organizer → Distribute App → App Store Connect"
echo "   • Upload to App Store Connect for review"
echo ""

echo "✅ Automatic code signing setup complete!"
echo ""
echo "🔄 If you need to revert to manual signing:"
echo "   cp CalTrackProFixed.xcodeproj/project.pbxproj.backup CalTrackProFixed.xcodeproj/project.pbxproj"
echo ""
echo "🧪 Test your setup:"
echo "   ./verify-code-signing.sh"
echo ""
echo "📖 For detailed guidance, see:"
echo "   code-signing-action-plan.md"
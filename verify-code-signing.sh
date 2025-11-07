#!/bin/bash

echo "🔐 CalTrackPro Code Signing Verification"
echo "========================================"

# Check if we're in the right directory
if [ ! -f "CalTrackProFixed.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Please run this script from the CalTrackPro project root directory"
    exit 1
fi

echo ""
echo "📋 Step 1: Checking Apple Developer Account Setup"

# Check if signed into Xcode
XCODE_ACCOUNTS=$(defaults read com.apple.dt.Xcode IDEProvisioningDisposition 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "   ✅ Xcode appears to be configured with Apple ID"
else
    echo "   ⚠️  Xcode may not be signed in to Apple Developer account"
    echo "      Please go to Xcode → Preferences → Accounts"
fi

echo ""
echo "🔑 Step 2: Checking Code Signing Certificates"

# List available code signing identities
echo "   Available code signing certificates:"
CERTS=$(security find-identity -v -p codesigning 2>/dev/null)
if [ $? -eq 0 ] && [ -n "$CERTS" ]; then
    echo "$CERTS" | grep -E "(Apple Development|Apple Distribution|iOS Distribution|iPhone Developer|iPhone Distribution)" | head -5
    
    # Check for distribution certificate specifically
    DIST_CERT=$(echo "$CERTS" | grep -E "(Apple Distribution|iOS Distribution)")
    if [ -n "$DIST_CERT" ]; then
        echo "   ✅ Distribution certificate found (good for App Store)"
    else
        echo "   ⚠️  No distribution certificate found"
        echo "      You'll need this for App Store submission"
    fi
    
    # Check for development certificate
    DEV_CERT=$(echo "$CERTS" | grep -E "(Apple Development|iPhone Developer)")
    if [ -n "$DEV_CERT" ]; then
        echo "   ✅ Development certificate found (good for testing)"
    else
        echo "   ⚠️  No development certificate found"
        echo "      You'll need this for device testing"
    fi
else
    echo "   ❌ No code signing certificates found"
    echo "      Please set up certificates in Apple Developer Portal"
fi

echo ""
echo "📱 Step 3: Checking Provisioning Profiles"

# Check for provisioning profiles
PROFILES_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
if [ -d "$PROFILES_DIR" ]; then
    PROFILE_COUNT=$(find "$PROFILES_DIR" -name "*.mobileprovision" | wc -l)
    echo "   Found $PROFILE_COUNT provisioning profile(s)"
    
    if [ $PROFILE_COUNT -gt 0 ]; then
        echo "   ✅ Provisioning profiles are installed"
        
        # Look for CalTrackPro-specific profiles
        find "$PROFILES_DIR" -name "*.mobileprovision" -exec bash -c '
            PROFILE_INFO=$(security cms -D -i "$1" 2>/dev/null)
            if echo "$PROFILE_INFO" | grep -q "easyaiflows.com.CalTrackProFixed"; then
                PROFILE_NAME=$(echo "$PROFILE_INFO" | grep -A1 "Name" | tail -1 | sed "s/.*<string>\(.*\)<\/string>.*/\1/")
                echo "   📋 Found CalTrackPro profile: $PROFILE_NAME"
            fi
        ' _ {} \;
    fi
else
    echo "   ❌ No provisioning profiles directory found"
fi

echo ""
echo "🔧 Step 4: Checking Project Configuration"

# Check if project file exists and get bundle identifier
if [ -f "CalTrackProFixed.xcodeproj/project.pbxproj" ]; then
    echo "   ✅ Xcode project file found"
    
    # Extract bundle identifier
    BUNDLE_ID=$(grep -o 'PRODUCT_BUNDLE_IDENTIFIER = [^;]*' CalTrackProFixed.xcodeproj/project.pbxproj | head -1 | sed 's/PRODUCT_BUNDLE_IDENTIFIER = //' | tr -d ';' | tr -d '"')
    if [ -n "$BUNDLE_ID" ]; then
        echo "   📱 Bundle Identifier: $BUNDLE_ID"
        
        if [ "$BUNDLE_ID" = "easyaiflows.com.CalTrackProFixed" ]; then
            echo "   ✅ Bundle ID matches expected value"
        else
            echo "   ⚠️  Bundle ID doesn't match expected: easyaiflows.com.CalTrackProFixed"
        fi
    else
        echo "   ⚠️  Could not extract bundle identifier from project"
    fi
    
    # Check iOS deployment target
    DEPLOYMENT_TARGET=$(grep -o 'IPHONEOS_DEPLOYMENT_TARGET = [^;]*' CalTrackProFixed.xcodeproj/project.pbxproj | head -1 | sed 's/IPHONEOS_DEPLOYMENT_TARGET = //' | tr -d ';')
    if [ -n "$DEPLOYMENT_TARGET" ]; then
        echo "   📱 iOS Deployment Target: $DEPLOYMENT_TARGET"
        
        # Check if it's 17.0 or higher
        if [ "$(echo "$DEPLOYMENT_TARGET >= 17.0" | bc 2>/dev/null)" = "1" ]; then
            echo "   ✅ Deployment target is appropriate (17.0+)"
        else
            echo "   ⚠️  Deployment target should be 17.0 or higher for modern features"
        fi
    fi
else
    echo "   ❌ Xcode project file not found"
fi

echo ""
echo "🧪 Step 5: Testing Build Configuration"

# Try a quick build to test code signing
echo "   Testing build configuration..."
BUILD_OUTPUT=$(xcodebuild -project CalTrackProFixed.xcodeproj -scheme CalTrackProFixed -configuration Release -destination generic/platform=iOS clean build 2>&1)
BUILD_STATUS=$?

if [ $BUILD_STATUS -eq 0 ]; then
    echo "   ✅ Project builds successfully with Release configuration"
else
    echo "   ❌ Build failed. Common code signing issues:"
    echo "$BUILD_OUTPUT" | grep -i "signing\|provisioning\|certificate" | head -3
fi

echo ""
echo "📊 Step 6: Summary and Recommendations"

# Count successes and issues
SUCCESS_COUNT=0
ISSUE_COUNT=0

if echo "$CERTS" | grep -q -E "(Apple Distribution|iOS Distribution)"; then
    ((SUCCESS_COUNT++))
else
    ((ISSUE_COUNT++))
    echo "   🔧 TODO: Create iOS Distribution certificate in Apple Developer Portal"
fi

if [ $PROFILE_COUNT -gt 0 ]; then
    ((SUCCESS_COUNT++))
else
    ((ISSUE_COUNT++))
    echo "   🔧 TODO: Create and download provisioning profiles"
fi

if [ "$BUNDLE_ID" = "easyaiflows.com.CalTrackProFixed" ]; then
    ((SUCCESS_COUNT++))
else
    ((ISSUE_COUNT++))
    echo "   🔧 TODO: Verify bundle identifier in Xcode project settings"
fi

if [ $BUILD_STATUS -eq 0 ]; then
    ((SUCCESS_COUNT++))
else
    ((ISSUE_COUNT++))
    echo "   🔧 TODO: Fix build configuration and code signing issues"
fi

echo ""
echo "📈 Results: $SUCCESS_COUNT successes, $ISSUE_COUNT issues to address"

if [ $ISSUE_COUNT -eq 0 ]; then
    echo "🎉 Excellent! Code signing appears to be properly configured."
    echo "   You should be ready for:"
    echo "   • Device testing"
    echo "   • TestFlight distribution"  
    echo "   • App Store submission"
elif [ $ISSUE_COUNT -le 2 ]; then
    echo "🔧 Good progress! Just a few items to address."
    echo "   Review the TODOs above and complete the setup."
else
    echo "⚠️  Several items need attention for production readiness."
    echo "   Follow the code-signing-guide.md for detailed setup steps."
fi

echo ""
echo "📖 Next Steps:"
echo "1. Address any issues identified above"
echo "2. Follow the complete setup guide: code-signing-guide.md"  
echo "3. Test on a physical device"
echo "4. Create an archive for App Store submission"
echo ""
echo "🔗 Helpful Commands:"
echo "   Open Xcode: open CalTrackProFixed.xcodeproj"
echo "   Clean build: Product → Clean Build Folder"
echo "   Archive: Product → Archive"
#!/bin/bash

#####################################################################
# CalTrackPro Build Script for App Store
# 
# Usage:
#   ./build_for_appstore.sh [version] [build]
#
# Examples:
#   ./build_for_appstore.sh 1.0.0 1
#   ./build_for_appstore.sh        # Uses existing version numbers
#####################################################################

set -e  # Exit on error

# Configuration - UPDATE THESE
PROJECT_NAME="CalTrackPro"
SCHEME="CalTrackPro"
WORKSPACE="${PROJECT_NAME}.xcworkspace"
# If no workspace, use project:
# PROJECT="${PROJECT_NAME}.xcodeproj"

TEAM_ID="YOUR_TEAM_ID"  # Update with your Apple Developer Team ID
BUNDLE_ID="com.ronnienutrition.CalTrackPro"

# Build directories
BUILD_DIR="build"
ARCHIVE_PATH="${BUILD_DIR}/${PROJECT_NAME}.xcarchive"
EXPORT_PATH="${BUILD_DIR}/AppStore"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  CalTrackPro App Store Build Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}Error: xcodebuild not found. Please install Xcode.${NC}"
    exit 1
fi

# Update version numbers if provided
if [ ! -z "$1" ]; then
    echo -e "${YELLOW}Setting version to $1${NC}"
    # Update Info.plist version
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $1" "${PROJECT_NAME}/Info.plist" 2>/dev/null || true
fi

if [ ! -z "$2" ]; then
    echo -e "${YELLOW}Setting build number to $2${NC}"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $2" "${PROJECT_NAME}/Info.plist" 2>/dev/null || true
fi

# Clean build directory
echo -e "${YELLOW}Cleaning build directory...${NC}"
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# Step 1: Clean
echo -e "${YELLOW}Step 1/4: Cleaning project...${NC}"
if [ -f "${WORKSPACE}" ]; then
    xcodebuild clean \
        -workspace "${WORKSPACE}" \
        -scheme "${SCHEME}" \
        -configuration Release \
        | grep -E "(Clean|error:|warning:)" || true
else
    xcodebuild clean \
        -project "${PROJECT_NAME}.xcodeproj" \
        -scheme "${SCHEME}" \
        -configuration Release \
        | grep -E "(Clean|error:|warning:)" || true
fi

# Step 2: Archive
echo ""
echo -e "${YELLOW}Step 2/4: Creating archive...${NC}"
if [ -f "${WORKSPACE}" ]; then
    xcodebuild archive \
        -workspace "${WORKSPACE}" \
        -scheme "${SCHEME}" \
        -configuration Release \
        -archivePath "${ARCHIVE_PATH}" \
        -destination "generic/platform=iOS" \
        -allowProvisioningUpdates \
        CODE_SIGN_STYLE=Automatic \
        DEVELOPMENT_TEAM="${TEAM_ID}" \
        | grep -E "(Archive|Signing|error:|warning:)" || true
else
    xcodebuild archive \
        -project "${PROJECT_NAME}.xcodeproj" \
        -scheme "${SCHEME}" \
        -configuration Release \
        -archivePath "${ARCHIVE_PATH}" \
        -destination "generic/platform=iOS" \
        -allowProvisioningUpdates \
        CODE_SIGN_STYLE=Automatic \
        DEVELOPMENT_TEAM="${TEAM_ID}" \
        | grep -E "(Archive|Signing|error:|warning:)" || true
fi

# Check if archive was created
if [ ! -d "${ARCHIVE_PATH}" ]; then
    echo -e "${RED}Error: Archive failed to create${NC}"
    exit 1
fi

echo -e "${GREEN}Archive created successfully!${NC}"

# Step 3: Export for App Store
echo ""
echo -e "${YELLOW}Step 3/4: Exporting for App Store...${NC}"
xcodebuild -exportArchive \
    -archivePath "${ARCHIVE_PATH}" \
    -exportOptionsPlist "Config/ExportOptions.plist" \
    -exportPath "${EXPORT_PATH}" \
    -allowProvisioningUpdates \
    | grep -E "(Export|Signing|error:|warning:)" || true

# Check if IPA was created
IPA_PATH=$(find "${EXPORT_PATH}" -name "*.ipa" 2>/dev/null | head -1)
if [ -z "${IPA_PATH}" ]; then
    echo -e "${RED}Error: IPA file not created${NC}"
    exit 1
fi

echo -e "${GREEN}IPA created: ${IPA_PATH}${NC}"

# Step 4: Validate (optional but recommended)
echo ""
echo -e "${YELLOW}Step 4/4: Validating build...${NC}"
xcrun altool --validate-app \
    -f "${IPA_PATH}" \
    -t ios \
    --apiKey YOUR_API_KEY \
    --apiIssuer YOUR_ISSUER_ID \
    2>/dev/null || echo -e "${YELLOW}Skipping validation (API key not configured)${NC}"

# Summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Build Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Archive: ${ARCHIVE_PATH}"
echo -e "IPA: ${IPA_PATH}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Open Xcode → Window → Organizer"
echo "2. Select the archive and click 'Distribute App'"
echo "3. Choose 'App Store Connect' → 'Upload'"
echo ""
echo "Or upload via command line:"
echo "xcrun altool --upload-app -f ${IPA_PATH} -t ios --apiKey YOUR_KEY --apiIssuer YOUR_ISSUER"
echo ""

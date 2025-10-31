#!/bin/bash
# Deployment Script for CalTrackPro
# Usage: ./scripts/deploy.sh [staging|production]

set -e

PROJECT_NAME="CalTrackProFixed"
SCHEME="CalTrackProFixed"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

echo_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to validate environment
validate_environment() {
    echo_info "Validating deployment environment..."
    
    # Check if we're on a clean git state
    if [ -n "$(git status --porcelain)" ]; then
        echo_error "Git working directory is not clean. Please commit or stash changes."
        exit 1
    fi
    
    # Check if we're on main branch for production
    current_branch=$(git branch --show-current)
    if [ "$1" = "production" ] && [ "$current_branch" != "main" ]; then
        echo_error "Production deployments must be from main branch. Current: $current_branch"
        exit 1
    fi
    
    echo_success "Environment validation passed!"
}

# Function to run pre-deployment tests
run_pre_deployment_tests() {
    echo_info "Running pre-deployment tests..."
    
    # Run full test suite
    ./scripts/quick-build.sh all
    
    echo_success "All pre-deployment tests passed!"
}

# Function to build for archive
build_for_archive() {
    local config=$1
    echo_info "Building archive for $config..."
    
    xcodebuild archive \
        -project "$PROJECT_NAME.xcodeproj" \
        -scheme "$SCHEME" \
        -configuration "$config" \
        -archivePath "build/$PROJECT_NAME.xcarchive" \
        CODE_SIGNING_ALLOWED=YES
        
    echo_success "Archive build completed!"
}

# Function to export IPA
export_ipa() {
    local method=$1
    echo_info "Exporting IPA with method: $method..."
    
    # Create export options plist
    cat > "build/ExportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>$method</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
EOF

    xcodebuild -exportArchive \
        -archivePath "build/$PROJECT_NAME.xcarchive" \
        -exportPath "build/" \
        -exportOptionsPlist "build/ExportOptions.plist"
        
    echo_success "IPA export completed!"
}

# Function to deploy to App Store Connect
deploy_to_app_store() {
    echo_info "Uploading to App Store Connect..."
    
    # Note: This requires App Store Connect API key setup
    # xcrun altool --upload-app -f "build/$PROJECT_NAME.ipa" -u "your@email.com" -p "@keychain:AC_PASSWORD"
    
    echo_warning "Manual upload to App Store Connect required"
    echo_info "IPA location: build/$PROJECT_NAME.ipa"
}

# Function to create GitHub release
create_github_release() {
    local version=$1
    local environment=$2
    
    echo_info "Creating GitHub release for version $version..."
    
    # Create tag
    git tag -a "v$version" -m "Release version $version for $environment"
    git push origin "v$version"
    
    echo_success "GitHub release created: v$version"
}

# Function to update version
update_version() {
    local version=$1
    echo_info "Updating app version to $version..."
    
    # Update Info.plist version (simplified - adjust path as needed)
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $version" "Models/Utilities/CalTrackProFixed/Info.plist" 2>/dev/null || true
    
    echo_success "Version updated to $version"
}

# Main deployment function
deploy() {
    local environment=$1
    local version=$(date +"%Y.%m.%d.%H%M")
    
    echo_info "Starting deployment to $environment..."
    echo_info "Version: $version"
    
    # Create build directory
    mkdir -p build
    
    case "$environment" in
        "staging")
            validate_environment "$environment"
            run_pre_deployment_tests
            update_version "$version-staging"
            build_for_archive "Debug"
            export_ipa "development"
            echo_success "Staging deployment completed!"
            echo_info "Build available at: build/$PROJECT_NAME.ipa"
            ;;
        "production")
            validate_environment "$environment"
            run_pre_deployment_tests
            update_version "$version"
            build_for_archive "Release"
            export_ipa "app-store"
            deploy_to_app_store
            create_github_release "$version" "$environment"
            echo_success "Production deployment completed!"
            ;;
        *)
            echo_error "Invalid environment. Use: staging or production"
            exit 1
            ;;
    esac
}

# Script execution
if [ $# -eq 0 ]; then
    echo_error "Usage: $0 [staging|production]"
    exit 1
fi

deploy "$1"
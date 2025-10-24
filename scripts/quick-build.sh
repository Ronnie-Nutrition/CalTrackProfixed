#!/bin/bash
# Quick Build Script for CalTrackPro Development
# Usage: ./scripts/quick-build.sh [clean|test|lint]

set -e

PROJECT_NAME="CalTrackProFixed"
SCHEME="CalTrackProFixed"
DESTINATION="platform=iOS Simulator,name=iPhone 15,OS=latest"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

echo_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to build the project
build_project() {
    echo "🔨 Building $PROJECT_NAME..."
    xcodebuild clean build \
        -project "$PROJECT_NAME.xcodeproj" \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        CODE_SIGNING_ALLOWED=NO \
        -quiet
    echo_success "Build completed successfully!"
}

# Function to run tests
run_tests() {
    echo "🧪 Running tests..."
    xcodebuild test \
        -project "$PROJECT_NAME.xcodeproj" \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        CODE_SIGNING_ALLOWED=NO \
        -quiet
    echo_success "All tests passed!"
}

# Function to run linting
run_lint() {
    echo "🔍 Running code quality checks..."
    
    if command -v swiftlint &> /dev/null; then
        swiftlint --quiet
        echo_success "SwiftLint checks passed!"
    else
        echo_warning "SwiftLint not installed. Install with: brew install swiftlint"
    fi
    
    if command -v swiftformat &> /dev/null; then
        swiftformat --lint . --quiet
        echo_success "SwiftFormat checks passed!"
    else
        echo_warning "SwiftFormat not installed. Install with: brew install swiftformat"
    fi
}

# Function to clean derived data
clean_build() {
    echo "🧹 Cleaning derived data..."
    rm -rf ~/Library/Developer/Xcode/DerivedData
    echo_success "Cleaned derived data!"
}

# Main execution
case "$1" in
    "clean")
        clean_build
        build_project
        ;;
    "test")
        build_project
        run_tests
        ;;
    "lint")
        run_lint
        ;;
    "all")
        clean_build
        build_project
        run_tests
        run_lint
        echo_success "Complete workflow finished!"
        ;;
    *)
        echo "🚀 Quick build for CalTrackPro"
        build_project
        ;;
esac

echo_success "Script completed in $(date)"
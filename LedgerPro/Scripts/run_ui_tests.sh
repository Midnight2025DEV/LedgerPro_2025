#!/bin/bash

# Run LedgerPro UI Tests

echo "🧪 Running LedgerPro UI Tests..."

# Check if Xcode project exists
if [ ! -d "LedgerPro.xcodeproj" ]; then
    echo "❌ Error: LedgerPro.xcodeproj not found!"
    echo "Please create the Xcode project first. See Scripts/create_xcode_project.md"
    exit 1
fi

# Build and test
xcodebuild test \
    -project LedgerPro.xcodeproj \
    -scheme LedgerPro \
    -destination 'platform=macOS' \
    -only-testing:LedgerProUITests \
    | xcpretty

echo "✅ UI Tests completed!"

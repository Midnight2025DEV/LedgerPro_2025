#!/bin/bash

# This script helps add accessibility identifiers to SwiftUI views
# Run this to see where you need to add identifiers

echo "🔍 Searching for UI elements that need accessibility identifiers..."

# Search for Buttons without accessibilityIdentifier
echo -e "\n📌 Buttons without accessibility identifiers:"
grep -n "Button(" Sources/LedgerPro/Views/*.swift | grep -v "accessibilityIdentifier" | head -10

# Search for TextFields without accessibilityIdentifier  
echo -e "\n📌 TextFields without accessibility identifiers:"
grep -n "TextField(" Sources/LedgerPro/Views/*.swift | grep -v "accessibilityIdentifier" | head -10

# Search for Lists/Tables without accessibilityIdentifier
echo -e "\n📌 Lists without accessibility identifiers:"
grep -n "List\|Table" Sources/LedgerPro/Views/*.swift | grep -v "accessibilityIdentifier" | head -10

echo -e "\n💡 Add identifiers like this:"
echo 'Button("Upload") { }'
echo '    .accessibilityIdentifier("uploadButton")'

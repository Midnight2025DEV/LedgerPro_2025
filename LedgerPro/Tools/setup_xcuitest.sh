#!/bin/bash

# LedgerPro XCUITest Setup Script
# This script helps create the necessary structure for UI testing

set -e

echo "🚀 Setting up XCUITest for LedgerPro..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

echo -e "${YELLOW}📁 Project root: $PROJECT_ROOT${NC}"

# Step 1: Create UI Tests directory structure
echo -e "\n${GREEN}1. Creating UI test directory structure...${NC}"
mkdir -p "$PROJECT_ROOT/LedgerProUITests"
mkdir -p "$PROJECT_ROOT/LedgerProUITests/TestHelpers"
mkdir -p "$PROJECT_ROOT/LedgerProUITests/TestResources"

# Step 2: Create a basic test CSV file
echo -e "\n${GREEN}2. Creating test resources...${NC}"
cat > "$PROJECT_ROOT/LedgerProUITests/TestResources/test_transactions.csv" << 'EOF'
Date,Description,Amount,Category
2024-01-01,STARBUCKS COFFEE #12345,-5.50,Food & Dining
2024-01-02,SALARY DEPOSIT EMPLOYER,3000.00,Income
2024-01-03,UBER TRIP DOWNTOWN,-25.00,Transportation
2024-01-04,AMAZON.COM PURCHASE,-99.99,Shopping
2024-01-05,WHOLE FOODS MARKET,-156.32,Groceries
EOF

echo -e "${GREEN}✅ Test CSV created${NC}"

# Step 3: Create Info.plist for UI Tests
echo -e "\n${GREEN}3. Creating Info.plist for UI tests...${NC}"
cat > "$PROJECT_ROOT/LedgerProUITests/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
</dict>
</plist>
EOF

# Step 4: Create a helper script to add accessibility identifiers
echo -e "\n${GREEN}4. Creating accessibility identifier helper...${NC}"
cat > "$PROJECT_ROOT/Scripts/add_accessibility_ids.sh" << 'EOF'
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
EOF

chmod +x "$PROJECT_ROOT/Scripts/add_accessibility_ids.sh"

# Step 5: Create Xcode project generation script
echo -e "\n${GREEN}5. Creating Xcode project helper...${NC}"
cat > "$PROJECT_ROOT/Scripts/create_xcode_project.md" << 'EOF'
# Creating Xcode Project for LedgerPro UI Tests

Since LedgerPro uses Swift Package Manager, you need to create an Xcode project wrapper to enable UI testing.

## Steps:

1. **Open Xcode**

2. **Create New Project**
   - File → New → Project
   - Choose: macOS → App
   - Product Name: LedgerPro
   - Team: (Your team)
   - Organization Identifier: com.ledgerpro
   - Interface: SwiftUI
   - Language: Swift
   - Use Core Data: NO
   - Include Tests: YES

3. **Configure Project**
   - Delete auto-generated ContentView.swift and LedgerProApp.swift
   - File → Add Package Dependencies
   - Add local package: Choose your Package.swift file
   - Make sure the LedgerPro library is added to your app target

4. **Add UI Test Target**
   - File → New → Target
   - Choose: macOS → UI Testing Bundle
   - Product Name: LedgerProUITests
   - Team: (Your team)
   - Target to be Tested: LedgerPro

5. **Configure Build Settings**
   - Select LedgerPro target
   - Build Settings → Swift Compiler - Custom Flags
   - Add: -DUITESTING (for debug configuration)

6. **Copy UI Test Files**
   - Copy all .swift files from LedgerProUITests/ to your Xcode project
   - Make sure they're added to the LedgerProUITests target

7. **Run Tests**
   - Product → Test (⌘U)
   - Or select specific tests in Test Navigator
EOF

# Step 6: Create a sample SwiftUI view with accessibility identifiers
echo -e "\n${GREEN}6. Creating sample accessible view...${NC}"
cat > "$PROJECT_ROOT/Sources/LedgerPro/Views/Components/AccessibleButton.swift" << 'EOF'
import SwiftUI

/// Example of how to add accessibility identifiers to SwiftUI views
struct AccessibleButton: View {
    let title: String
    let action: () -> Void
    let accessibilityId: String
    
    var body: some View {
        Button(action: action) {
            Text(title)
        }
        .accessibilityIdentifier(accessibilityId)
        .accessibilityLabel(title)
        .accessibilityHint("Tap to \(title.lowercased())")
    }
}

// Usage example:
// AccessibleButton(
//     title: "Upload Statement",
//     action: { showUploadSheet = true },
//     accessibilityId: "uploadStatementButton"
// )
EOF

# Step 7: Create test runner script
echo -e "\n${GREEN}7. Creating UI test runner script...${NC}"
cat > "$PROJECT_ROOT/Scripts/run_ui_tests.sh" << 'EOF'
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
EOF

chmod +x "$PROJECT_ROOT/Scripts/run_ui_tests.sh"

# Step 8: Update Package.swift to support UI testing
echo -e "\n${GREEN}8. Creating Package.swift additions for testing...${NC}"
cat > "$PROJECT_ROOT/Scripts/package_swift_ui_test_additions.txt" << 'EOF'
# Add these to your Package.swift if you want to try SPM-based UI testing (experimental):

// In products array:
.executable(
    name: "LedgerProTestRunner",
    targets: ["LedgerProTestRunner"]
),

// In targets array:
.executableTarget(
    name: "LedgerProTestRunner",
    dependencies: ["LedgerPro"],
    path: "Sources/LedgerProTestRunner"
),

// Note: Full UI testing still requires Xcode project
EOF

# Summary
echo -e "\n${GREEN}✅ XCUITest setup complete!${NC}"
echo -e "\n📋 Next steps:"
echo -e "1. ${YELLOW}Create Xcode project${NC} - See Scripts/create_xcode_project.md"
echo -e "2. ${YELLOW}Add accessibility identifiers${NC} - Run ./Scripts/add_accessibility_ids.sh"
echo -e "3. ${YELLOW}Copy UI test files${NC} - From LedgerProUITests/ to Xcode project"
echo -e "4. ${YELLOW}Run tests${NC} - Use ./Scripts/run_ui_tests.sh"

echo -e "\n📁 Created structure:"
echo "   LedgerProUITests/"
echo "   ├── TestHelpers/"
echo "   ├── TestResources/"
echo "   │   └── test_transactions.csv"
echo "   └── Info.plist"

echo -e "\n🎯 Ready to implement UI tests!"

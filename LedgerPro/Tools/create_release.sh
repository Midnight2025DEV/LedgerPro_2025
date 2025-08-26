#!/bin/bash

#
# LedgerPro Release Builder
# Creates unsigned macOS app bundle for testing distribution
# 
# Usage: ./scripts/create_release.sh [version]
# Example: ./scripts/create_release.sh 1.0.0-beta.2
#

set -euo pipefail  # Exit on any error

# Configuration
APP_NAME="LedgerPro"
DEFAULT_VERSION="1.0.0-beta.1"
BUILD_CONFIG="release"
PROJECT_ROOT="$(dirname "$0")/.."
BUILD_DIR="$PROJECT_ROOT/.build"
RELEASE_DIR="$PROJECT_ROOT/releases"
TEMP_DIR="/tmp/ledgerpro_release_$$"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

cleanup() {
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
        log_info "Cleaned up temporary directory"
    fi
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

# Parse version argument
VERSION="${1:-$DEFAULT_VERSION}"

log_info "Building $APP_NAME release v$VERSION"
log_info "Project root: $PROJECT_ROOT"

# Validate we're in the right directory
if [[ ! -f "$PROJECT_ROOT/Package.swift" ]]; then
    log_error "Package.swift not found. Please run this script from the project root or scripts directory."
    exit 1
fi

# Create directories
mkdir -p "$RELEASE_DIR"
mkdir -p "$TEMP_DIR"

# Change to project directory
cd "$PROJECT_ROOT"

log_info "Cleaning previous builds..."
if [[ -d "$BUILD_DIR" ]]; then
    rm -rf "$BUILD_DIR"
fi

# Build the project
log_info "Building $APP_NAME for release..."
swift build -c $BUILD_CONFIG --arch arm64 --arch x86_64

if [[ $? -ne 0 ]]; then
    log_error "Build failed"
    exit 1
fi

log_success "Build completed successfully"

# Find the built executable
EXECUTABLE_PATH="$BUILD_DIR/$BUILD_CONFIG/$APP_NAME"

if [[ ! -f "$EXECUTABLE_PATH" ]]; then
    log_error "Built executable not found at $EXECUTABLE_PATH"
    exit 1
fi

log_info "Built executable found: $EXECUTABLE_PATH"

# Create app bundle structure
APP_BUNDLE="$TEMP_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

log_info "Creating app bundle structure..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
cp "$EXECUTABLE_PATH" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

# Create Info.plist
log_info "Creating Info.plist..."
cat > "$CONTENTS_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.ledgerpro.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$(date +%Y%m%d%H%M)</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.finance</string>
    <key>NSHumanReadableCopyright</key>
    <string>© 2024 LedgerPro. All rights reserved.</string>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
EOF

# Create a simple app icon (placeholder)
log_info "Creating placeholder app icon..."
# Note: For a real release, you'd want a proper .icns file
cat > "$RESOURCES_DIR/AppIcon.icns" << 'EOF'
# Placeholder - replace with actual .icns file
EOF

# Create PkgInfo
echo "APPL????" > "$CONTENTS_DIR/PkgInfo"

log_success "App bundle created: $APP_BUNDLE"

# Create release package directory
RELEASE_PACKAGE="$TEMP_DIR/LedgerPro-$VERSION"
mkdir -p "$RELEASE_PACKAGE"

# Copy app bundle
cp -R "$APP_BUNDLE" "$RELEASE_PACKAGE/"

# Create test data
log_info "Creating test data..."
TEST_DATA_DIR="$RELEASE_PACKAGE/TestData"
mkdir -p "$TEST_DATA_DIR"

# Sample transactions CSV
cat > "$TEST_DATA_DIR/sample_transactions.csv" << 'EOF'
Date,Description,Amount,Category
2024-01-15,STARBUCKS COFFEE #1234,"-5.75",Food & Dining
2024-01-15,UBER TRIP SAN FRANCISCO,"-18.50",Transportation
2024-01-14,PAYROLL DEPOSIT,"2500.00",Income
2024-01-14,WHOLE FOODS MARKET,"-156.43",Groceries
2024-01-13,NETFLIX SUBSCRIPTION,"-15.99",Entertainment
2024-01-13,CHEVRON GAS STATION,"-45.20",Transportation
2024-01-12,TARGET STORE #1842,"-67.89",Shopping
2024-01-12,VENMO PAYMENT TO JOHN,"-25.00",Transfers
2024-01-11,RESTAURANT XYZ,"-42.35",Food & Dining
2024-01-11,ATM WITHDRAWAL,"-100.00",Cash & ATM
2024-01-10,APPLE APP STORE,"-2.99",Entertainment
2024-01-10,PHARMACY CVS,"-23.45",Healthcare
2024-01-09,ELECTRIC BILL PAYMENT,"-125.60",Utilities
2024-01-09,AMAZON PURCHASE,"-89.99",Shopping
2024-01-08,COFFEE SHOP DOWNTOWN,"-4.50",Food & Dining
EOF

# Foreign currency sample data
cat > "$TEST_DATA_DIR/forex_transactions.csv" << 'EOF'
Date,Description,Amount,Currency,Original_Amount,Original_Currency,Exchange_Rate,Category
2024-01-15,LONDON RESTAURANT,"-45.50",USD,"-35.00",GBP,"1.30",Food & Dining
2024-01-14,PARIS HOTEL,"-180.75",USD,"-165.00",EUR,"1.095",Travel
2024-01-13,TOKYO SHOPPING,"-67.89",USD,"-10000",JPY,"0.00679",Shopping
2024-01-12,TORONTO COFFEE SHOP,"-5.25",USD,"-7.00",CAD,"0.75",Food & Dining
2024-01-11,MEXICO TAXI RIDE,"-8.50",USD,"-150.00",MXN,"0.0567",Transportation
2024-01-10,SYDNEY AIRPORT,"-25.99",USD,"-39.50",AUD,"0.658",Travel
2024-01-09,ZURICH ATM WITHDRAWAL,"-105.50",USD,"-95.00",CHF,"1.111",Cash & ATM
2024-01-08,SINGAPORE RESTAURANT,"-32.45",USD,"-44.00",SGD,"0.737",Food & Dining
EOF

# Large dataset generator script
cat > "$TEST_DATA_DIR/generate_large_dataset.py" << 'EOF'
#!/usr/bin/env python3
"""
Generate large test dataset for LedgerPro performance testing
Usage: python3 generate_large_dataset.py [number_of_transactions]
"""

import random
import sys
from datetime import datetime, timedelta
import csv

# Sample data for realistic transactions
merchants = [
    "STARBUCKS", "WHOLE FOODS", "TARGET", "AMAZON", "UBER", "NETFLIX", "SPOTIFY",
    "CHEVRON", "SHELL", "MCDONALDS", "SUBWAY", "CHIPOTLE", "CVS PHARMACY",
    "WALGREENS", "HOME DEPOT", "COSTCO", "WALMART", "SAFEWAY", "KROGER",
    "APPLE STORE", "BEST BUY", "DUNKIN DONUTS", "PANERA BREAD", "AT&T",
    "VERIZON", "COMCAST", "PG&E", "BANK OF AMERICA", "WELLS FARGO"
]

categories = [
    "Food & Dining", "Groceries", "Transportation", "Shopping", "Entertainment",
    "Utilities", "Healthcare", "Gas", "Coffee Shops", "Subscriptions",
    "Income", "Transfers", "Cash & ATM", "Travel", "Business"
]

def generate_transactions(count):
    transactions = []
    start_date = datetime(2023, 1, 1)
    
    for i in range(count):
        # Generate random date within last year
        days_offset = random.randint(0, 365)
        trans_date = start_date + timedelta(days=days_offset)
        
        # Generate realistic transaction
        merchant = random.choice(merchants)
        store_id = random.randint(1000, 9999)
        description = f"{merchant} #{store_id}"
        
        # Generate amount based on merchant type
        if merchant in ["PAYROLL", "SALARY"]:
            amount = round(random.uniform(2000, 5000), 2)
        elif merchant in ["RENT", "MORTGAGE"]:
            amount = round(random.uniform(-1500, -3000), 2)
        elif merchant in ["STARBUCKS", "DUNKIN"]:
            amount = round(random.uniform(-3, -8), 2)
        elif merchant in ["UBER", "LYFT"]:
            amount = round(random.uniform(-8, -45), 2)
        elif merchant in ["GROCERIES", "WHOLE FOODS", "SAFEWAY"]:
            amount = round(random.uniform(-50, -200), 2)
        else:
            amount = round(random.uniform(-5, -150), 2)
        
        category = random.choice(categories)
        
        transactions.append({
            'Date': trans_date.strftime('%Y-%m-%d'),
            'Description': description,
            'Amount': str(amount),
            'Category': category
        })
    
    return transactions

def main():
    count = int(sys.argv[1]) if len(sys.argv) > 1 else 1000
    print(f"Generating {count} transactions...")
    
    transactions = generate_transactions(count)
    
    filename = f"large_dataset_{count}_transactions.csv"
    with open(filename, 'w', newline='') as csvfile:
        fieldnames = ['Date', 'Description', 'Amount', 'Category']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        
        writer.writeheader()
        for transaction in transactions:
            writer.writerow(transaction)
    
    print(f"Generated {filename} with {count} transactions")

if __name__ == "__main__":
    main()
EOF

chmod +x "$TEST_DATA_DIR/generate_large_dataset.py"

# Create installer script
log_info "Creating installer script..."
cat > "$RELEASE_PACKAGE/Install_LedgerPro.command" << 'EOF'
#!/bin/bash

#
# LedgerPro Installer for macOS
# Handles Gatekeeper warnings and app installation
#

APP_NAME="LedgerPro"
INSTALL_DIR="/Applications"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 LedgerPro Installer${NC}"
echo "=================================="
echo

# Check if app bundle exists
if [[ ! -d "$APP_NAME.app" ]]; then
    echo -e "${RED}❌ $APP_NAME.app not found in current directory${NC}"
    echo "Please run this installer from the folder containing $APP_NAME.app"
    read -p "Press Enter to exit..."
    exit 1
fi

echo -e "${BLUE}📋 Installation Steps:${NC}"
echo "1. Copy $APP_NAME.app to Applications folder"
echo "2. Handle macOS Gatekeeper security"
echo "3. Launch the application"
echo

read -p "Continue with installation? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

# Check if Applications directory is writable
if [[ ! -w "$INSTALL_DIR" ]]; then
    echo -e "${YELLOW}⚠️  Need administrator privileges to install to Applications folder${NC}"
    echo "You may be prompted for your password..."
    sudo cp -R "$APP_NAME.app" "$INSTALL_DIR/"
else
    cp -R "$APP_NAME.app" "$INSTALL_DIR/"
fi

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ $APP_NAME copied to Applications folder${NC}"
else
    echo -e "${RED}❌ Failed to copy $APP_NAME to Applications${NC}"
    exit 1
fi

echo
echo -e "${YELLOW}🔒 Handling macOS Security (Gatekeeper)${NC}"
echo "Since this is an unsigned app, macOS will block it initially."
echo

# Remove quarantine attribute
echo "Removing quarantine attribute..."
xattr -dr com.apple.quarantine "$INSTALL_DIR/$APP_NAME.app" 2>/dev/null || true

echo -e "${BLUE}📖 First Launch Instructions:${NC}"
echo "1. Go to Applications folder"
echo "2. Right-click on $APP_NAME.app"
echo "3. Select 'Open' from the context menu"
echo "4. Click 'Open' in the security dialog"
echo
echo "Alternative method:"
echo "1. Open System Preferences > Security & Privacy"
echo "2. Click 'Open Anyway' if you see a blocked app message"
echo

read -p "Launch $APP_NAME now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Opening $APP_NAME..."
    open "$INSTALL_DIR/$APP_NAME.app"
    
    echo
    echo -e "${YELLOW}⚠️  If you see a security warning:${NC}"
    echo "1. Click 'Cancel' in the warning dialog"
    echo "2. Go to System Preferences > Security & Privacy"
    echo "3. Click 'Open Anyway' button"
    echo "4. Click 'Open' in the confirmation dialog"
fi

echo
echo -e "${GREEN}🎉 Installation complete!${NC}"
echo
echo "Test data files are available in the TestData folder:"
echo "- sample_transactions.csv (basic test data)"
echo "- forex_transactions.csv (foreign currency test data)"
echo "- generate_large_dataset.py (create large test datasets)"
echo
echo "Enjoy using $APP_NAME! 🚀"
echo
read -p "Press Enter to close installer..."
EOF

chmod +x "$RELEASE_PACKAGE/Install_LedgerPro.command"

# Create README
log_info "Creating README..."
cat > "$RELEASE_PACKAGE/README.md" << EOF
# LedgerPro v$VERSION - Testing Release

Welcome to LedgerPro, a powerful macOS financial transaction analyzer built with SwiftUI.

## 🚀 Quick Start

### Automatic Installation (Recommended)
1. Double-click \`Install_LedgerPro.command\`
2. Follow the on-screen instructions
3. The installer will handle macOS security settings

### Manual Installation
1. Copy \`LedgerPro.app\` to your Applications folder
2. Right-click on the app and select "Open"
3. Click "Open" in the security dialog

## 🔒 macOS Security Note

This is an **unsigned build** for testing purposes. macOS will show security warnings:

**If you see "LedgerPro cannot be opened because it is from an unidentified developer":**
1. Go to System Preferences > Security & Privacy
2. Click "Open Anyway" next to the blocked app message
3. Click "Open" in the confirmation dialog

**Alternative method:**
1. Right-click the app in Applications
2. Select "Open" from the context menu
3. Click "Open" in the security dialog

## 📊 Test Data

The \`TestData\` folder contains:

- **sample_transactions.csv** - 15 realistic transactions for basic testing
- **forex_transactions.csv** - Foreign currency transactions with exchange rates
- **generate_large_dataset.py** - Python script to create large test datasets

### Using Test Data
1. Launch LedgerPro
2. Use the file upload feature to import CSV files
3. Test various features with the provided data

### Generate Large Datasets
\`\`\`bash
cd TestData
python3 generate_large_dataset.py 5000
\`\`\`
This creates a CSV file with 5,000 transactions for performance testing.

## 🧪 What to Test

### Core Features
- [ ] File upload (CSV, PDF)
- [ ] Transaction categorization
- [ ] Account detection
- [ ] Summary calculations
- [ ] Filtering and search

### Performance Testing
- [ ] Import large datasets (1000+ transactions)
- [ ] Real-time filtering performance
- [ ] Memory usage with large datasets

### Foreign Currency
- [ ] Import forex_transactions.csv
- [ ] Verify exchange rate calculations
- [ ] Check multi-currency display

### User Interface
- [ ] Responsive design
- [ ] Dark/light mode support
- [ ] Accessibility features

## 🐛 Reporting Issues

Please report any issues with:
1. **Steps to reproduce** the problem
2. **Expected vs actual behavior**
3. **System information** (macOS version, hardware)
4. **Sample data** that causes the issue (if applicable)

## 📋 System Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon (M1/M2) or Intel processors
- 4GB RAM (8GB recommended for large datasets)
- 100MB free disk space

## 🔧 Technical Details

- **Version**: $VERSION
- **Build Date**: $(date)
- **Architecture**: Universal (ARM64 + x86_64)
- **Framework**: SwiftUI
- **Data Storage**: Core Data + UserDefaults

## 📞 Support

This is a testing release. For questions or feedback, contact the development team.

---

Thank you for testing LedgerPro! 🎉
EOF

# Create version info file
cat > "$RELEASE_PACKAGE/VERSION_INFO.txt" << EOF
LedgerPro Release Information
============================

Version: $VERSION
Build Date: $(date)
Build Configuration: $BUILD_CONFIG
Platform: macOS (Universal)
Swift Version: $(swift --version | head -n1)

Build Environment:
- Host: $(hostname)
- User: $(whoami)
- Working Directory: $PROJECT_ROOT
- Xcode: $(xcode-select --print-path 2>/dev/null || echo "Command Line Tools")

Release Contents:
- LedgerPro.app (Universal binary)
- Install_LedgerPro.command (Installer script)
- TestData/ (Sample data for testing)
- README.md (User instructions)

Git Information:
$(cd "$PROJECT_ROOT" && git log -1 --pretty=format:"Commit: %H%nAuthor: %an <%ae>%nDate: %ad%nMessage: %s" 2>/dev/null || echo "Git information not available")

Checksums:
$(find "$RELEASE_PACKAGE" -type f -exec shasum -a 256 {} \; | sort)
EOF

# Create final ZIP package
RELEASE_ZIP="$RELEASE_DIR/LedgerPro-$VERSION-macOS.zip"
log_info "Creating release ZIP: $RELEASE_ZIP"

cd "$TEMP_DIR"
zip -r "$RELEASE_ZIP" "LedgerPro-$VERSION" -x "*.DS_Store"

if [[ $? -eq 0 ]]; then
    log_success "Release package created: $RELEASE_ZIP"
    
    # Display package info
    echo
    echo -e "${BLUE}📦 Release Package Information:${NC}"
    echo "File: $RELEASE_ZIP"
    echo "Size: $(du -h "$RELEASE_ZIP" | cut -f1)"
    echo "SHA256: $(shasum -a 256 "$RELEASE_ZIP" | cut -d' ' -f1)"
    echo
    
    log_success "Release v$VERSION is ready for distribution!"
    
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Test the release package locally"
    echo "2. Upload to GitHub releases"
    echo "3. Share with testers"
    
else
    log_error "Failed to create release ZIP"
    exit 1
fi

# Open release directory
if command -v open >/dev/null 2>&1; then
    open "$RELEASE_DIR"
fi

log_success "Release creation completed successfully!"
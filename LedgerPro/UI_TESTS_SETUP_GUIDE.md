# LedgerPro UI Tests Setup Guide

## ✅ UI Tests Successfully Configured!

Your LedgerPro project now has a complete UI testing setup with **24 UI tests** across 5 test suites.

## 📁 Project Structure

```
LedgerPro/
├── Package.swift                    # ✅ Updated with UI test target
├── .swiftpm/xcode/                 # ✅ Xcode integration
│   └── xcshareddata/xcschemes/     # ✅ Test schemes created
├── LedgerProUITests/               # ✅ UI test files
│   ├── AccessibilityUITests.swift  # 6 accessibility tests
│   ├── CategoryUITests.swift       # 3 category tests
│   ├── FileUploadUITests.swift     # 5 file upload tests
│   ├── PerformanceUITests.swift    # 4 performance tests
│   ├── TransactionListUITests.swift # 5 transaction tests
│   ├── LedgerProUITestsBase.swift  # Base test class
│   ├── TestHelpers/TestDataHelper.swift
│   ├── TestResources/test_transactions.csv
│   └── Info.plist
└── run_ui_tests_xcode.sh           # ✅ Test runner script
```

## 🚀 How to Run UI Tests

### Method 1: Using the Script (Recommended)

```bash
# Run all UI tests
./run_ui_tests_xcode.sh

# List available tests
./run_ui_tests_xcode.sh --list

# Run with verbose output
./run_ui_tests_xcode.sh --verbose

# Get help
./run_ui_tests_xcode.sh --help
```

### Method 2: Using Swift Package Manager

```bash
# Run all UI tests
swift test --filter LedgerProUITests

# Run specific test suite
swift test --filter AccessibilityUITests

# Run specific test
swift test --filter testTransactionListDisplay
```

### Method 3: Using Xcode

1. **Open in Xcode:**
   ```bash
   open Package.swift
   ```

2. **Select the UI Test Scheme:**
   - In Xcode, click the scheme selector (next to the play button)
   - Choose "LedgerPro UI Tests" scheme

3. **Run Tests:**
   - Press `⌘+U` (Test)
   - Or: Product → Test

## 🧪 Test Suites Overview

### 1. **AccessibilityUITests** (6 tests)
- `testVoiceOverLabels` - VoiceOver compatibility
- `testKeyboardNavigation` - Tab navigation
- `testColorContrast` - Visual accessibility
- `testFocusIndicators` - Focus management
- `testTabKeyNavigation` - Tab shortcuts
- `testEscapeKeyDismissesSheets` - ESC key handling

### 2. **FileUploadUITests** (5 tests)
- `testUploadButtonOpensSheet` - Upload button functionality
- `testDragAndDropCSVFile` - Drag & drop support
- `testInvalidFileTypeError` - Error handling
- `testUploadProgress` - Progress tracking
- `testCancelUpload` - Upload cancellation

### 3. **TransactionListUITests** (5 tests)
- `testTransactionListDisplay` - List display
- `testSearchTransactions` - Search functionality
- `testFilterByUncategorized` - Filtering
- `testCategoryPicker` - Category selection
- `testScrollPerformance` - Scroll performance

### 4. **CategoryUITests** (3 tests)
- `testOpenCategoryTestView` - Category testing
- `testRulesManagement` - Rules interface
- `testLearningAnalytics` - Analytics view

### 5. **PerformanceUITests** (4 tests)
- `testTabSwitchingPerformance` - Navigation speed
- `testFileUploadSheetOpenPerformance` - Sheet performance
- `testCategoryPickerOpenPerformance` - Picker performance
- `testLargeTransactionListScrollPerformance` - Large data handling

## 🎯 Test Features

### ✅ **Accessibility Identifiers Added:**
- Upload button: `"uploadButton"`
- Choose File button: `"chooseFileButton"`
- Transaction list: `"transactionList"`
- Category search field: `"categorySearchField"`
- Category picker close button: `"categoryPickerCloseButton"`

### ✅ **Test Mode Support:**
- App handles `--uitesting` launch argument
- Animations disabled for consistent testing
- Test data loaded automatically
- Environment variables configured

### ✅ **Test Resources:**
- Sample CSV file: `test_transactions.csv`
- Test data helper utilities
- Base test class with common functionality

## 🔧 Configuration Files

### **Xcode Schemes Created:**
- `LedgerPro.xcscheme` - Main app scheme
- `LedgerPro UI Tests.xcscheme` - Dedicated UI test scheme

### **Environment Variables:**
- `DISABLE_ANIMATIONS=1` - Disables animations during tests
- Launch argument: `--uitesting` - Enables test mode

## 📋 Running Tests Step-by-Step

### **Command Line (Easiest):**

1. **Navigate to project directory:**
   ```bash
   cd /path/to/LedgerPro
   ```

2. **Run the test script:**
   ```bash
   ./run_ui_tests_xcode.sh
   ```

The script will:
- ✅ Build the app
- ✅ Start it in test mode
- ✅ Run all UI tests
- ✅ Clean up automatically

### **Xcode (Full IDE Experience):**

1. **Open project:**
   ```bash
   open Package.swift
   ```

2. **Wait for Xcode to load** the Swift Package

3. **Select UI test scheme:**
   - Click scheme dropdown (next to ▶️ button)
   - Choose "LedgerPro UI Tests"

4. **Run tests:**
   - Press `⌘+U`
   - Or Product → Test

## 🐛 Troubleshooting

### **Build Errors:**
```bash
# Clean and rebuild
swift package clean
swift build
```

### **App Won't Start:**
```bash
# Kill any running instances
pkill -f LedgerPro
```

### **Tests Fail to Find Elements:**
- Ensure app started with `--uitesting` flag
- Check accessibility identifiers are correct
- Verify test data loaded properly

### **Xcode Scheme Issues:**
- Close Xcode
- Delete `.swiftpm/xcode/package.xcworkspace/xcuserdata/`
- Reopen `Package.swift` in Xcode

## 🎉 Success Indicators

**When everything is working correctly, you should see:**

1. **Build Output:**
   ```
   Build complete! (X.XXs)
   ```

2. **App Launch:**
   ```
   🧪 Loaded 3 test transactions for UI testing
   ```

3. **Test Results:**
   ```
   ✅ All UI tests passed!
   ```

## 📊 Test Statistics

- **Total UI Tests:** 24
- **Test Suites:** 5
- **Accessibility Tests:** 6
- **Performance Tests:** 4
- **Functional Tests:** 14

## 🔄 Next Steps

1. **Run your first test:**
   ```bash
   ./run_ui_tests_xcode.sh --list
   ./run_ui_tests_xcode.sh
   ```

2. **Add more tests** as needed in the `LedgerProUITests/` directory

3. **Integrate with CI/CD** using the command-line approach

4. **Customize test data** in `TestResources/test_transactions.csv`

---

🎯 **Your UI testing setup is complete and ready to use!**
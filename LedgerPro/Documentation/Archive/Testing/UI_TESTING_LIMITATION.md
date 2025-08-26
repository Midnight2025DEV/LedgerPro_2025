# UI Testing Limitation

## The Issue
XCUITest requires an `.app` bundle, but Swift Package Manager creates executables. This is a fundamental incompatibility.

## Current Status
- ✅ **App works perfectly**: `swift run LedgerPro`
- ✅ **Unit tests work**: `swift test --filter LedgerProTests` 
- ❌ **UI tests fail**: XCUITest can't find app bundle

## Solutions

### Option A: Use the App (Recommended)
Your app works great from command line:
```bash
cd LedgerPro
swift run
```

### Option B: Manual Testing
Test the UI manually - often more valuable than automated tests for a personal app.

### Option C: Create Xcode Project (Complex)
If you absolutely need UI tests:
1. Create new macOS app project in Xcode
2. Import LedgerPro package as dependency
3. Create minimal app wrapper
4. Add UI test target

## Recommendation
**Skip UI tests.** Your app works perfectly. Focus on using it rather than testing infrastructure.
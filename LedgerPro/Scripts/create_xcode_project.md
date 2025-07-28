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

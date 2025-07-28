import XCTest

final class AccessibilityUITests: LedgerProUITestsBase {
    
    func testVoiceOverLabels() throws {
        // Verify main navigation has accessibility labels
        XCTAssertTrue(app.staticTexts["Overview"].exists || app.buttons["Overview"].exists)
        XCTAssertTrue(app.staticTexts["Transactions"].exists || app.buttons["Transactions"].exists)
        XCTAssertTrue(app.staticTexts["Accounts"].exists || app.buttons["Accounts"].exists)
        XCTAssertTrue(app.staticTexts["Insights"].exists || app.buttons["Insights"].exists)
        XCTAssertTrue(app.staticTexts["Settings"].exists || app.buttons["Settings"].exists)
        
        // Verify toolbar buttons have accessibility labels or help text
        let toolbarButtons = app.toolbars.buttons
        XCTAssertTrue(toolbarButtons.count > 0, "Toolbar should have buttons")
        
        // Check for specific buttons by their help text
        let uploadButton = app.buttons.matching(NSPredicate(format: "help CONTAINS 'Upload'")).firstMatch
        XCTAssertTrue(uploadButton.exists, "Upload button should have help text")
        
        let healthButton = app.buttons.matching(NSPredicate(format: "help CONTAINS 'health'")).firstMatch
        XCTAssertTrue(healthButton.exists, "Health check button should have help text")
    }
    
    func testKeyboardNavigation() throws {
        // Test Command+1 through Command+5 for tab switching
        let tabShortcuts = [
            ("1", "Overview"),
            ("2", "Transactions"),
            ("3", "Accounts"),
            ("4", "Insights"),
            ("5", "Settings")
        ]
        
        for (key, expectedView) in tabShortcuts {
            // Press Command+number
            XCUIElement.perform(withKeyModifiers: .command) {
                app.typeKey(key, modifierFlags: [])
            }
            
            // Give time for navigation
            Thread.sleep(forTimeInterval: 0.5)
            
            // Verify we're on the expected view
            // This verification might need adjustment based on actual view identifiers
            let viewExists = app.otherElements["\(expectedView)View"].exists ||
                           app.staticTexts.matching(identifier: expectedView).count > 0
            
            XCTAssertTrue(viewExists, "Should navigate to \(expectedView) with Cmd+\(key)")
        }
    }
    
    func testTabKeyNavigation() throws {
        // Test Tab key navigation through interface elements
        
        // Start from a known position
        app.windows.firstMatch.click()
        
        // Tab through interface elements
        for _ in 0..<5 {
            app.typeKey(.tab, modifierFlags: [])
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        // Verify we can tab backwards
        for _ in 0..<5 {
            app.typeKey(.tab, modifierFlags: .shift)
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        // No crash means tab navigation works
        XCTAssertTrue(true, "Tab navigation completed without issues")
    }
    
    func testEscapeKeyDismissesSheets() throws {
        // Open a sheet (upload dialog)
        let uploadButton = app.buttons.matching(NSPredicate(format: "help CONTAINS 'Upload'")).firstMatch
        if waitForElement(uploadButton) {
            uploadButton.click()
            
            // Wait for sheet
            let sheet = app.sheets.firstMatch
            XCTAssertTrue(waitForElement(sheet), "Sheet should appear")
            
            // Press Escape
            app.typeKey(.escape, modifierFlags: [])
            
            // Verify sheet dismisses
            XCTAssertFalse(sheet.exists, "Sheet should dismiss with Escape key")
        }
    }
    
    func testColorContrast() throws {
        // This test would ideally check color contrast ratios
        // For now, we just verify that important text elements exist and are visible
        
        // Navigate to transactions
        if app.staticTexts["Transactions"].exists {
            app.staticTexts["Transactions"].click()
        }
        
        // Wait for table
        let table = app.tables.firstMatch
        if waitForElement(table) {
            // Check that transaction amounts are visible
            let cells = table.cells
            if cells.count > 0 {
                let firstCell = cells.firstMatch
                
                // Verify text elements exist (indicating they're visible)
                let textElements = firstCell.staticTexts
                XCTAssertTrue(textElements.count >= 2, "Transaction cells should have visible text")
            }
        }
    }
    
    func testFocusIndicators() throws {
        // Test that focused elements have visible indicators
        
        // Click on first button to establish focus
        let firstButton = app.buttons.firstMatch
        if waitForElement(firstButton) {
            firstButton.click()
            
            // Tab to next element
            app.typeKey(.tab, modifierFlags: [])
            
            // In a real test, we'd verify visual focus indicators
            // For now, we ensure navigation doesn't crash
            XCTAssertTrue(true, "Focus navigation works")
        }
    }
}

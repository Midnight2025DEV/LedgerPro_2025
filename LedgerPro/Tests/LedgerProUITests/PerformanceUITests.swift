import XCTest

final class PerformanceUITests: LedgerProUITestsBase {
    
    func testLargeTransactionListScrollPerformance() throws {
        // Navigate to transactions
        navigateToTransactions()
        
        let transactionTable = app.tables.firstMatch
        XCTAssertTrue(waitForElement(transactionTable))
        
        // Measure scrolling performance
        measure(metrics: [XCTOSSignpostMetric.scrollingAndDecelerationMetric]) {
            // Scroll through large list
            transactionTable.swipeUp(velocity: .fast)
            Thread.sleep(forTimeInterval: 0.5)
            transactionTable.swipeDown(velocity: .fast)
            Thread.sleep(forTimeInterval: 0.5)
        }
    }
    
    func testCategoryPickerOpenPerformance() throws {
        navigateToTransactions()
        
        let transactionTable = app.tables.firstMatch
        XCTAssertTrue(waitForElement(transactionTable))
        
        // Ensure we have transactions
        let cells = transactionTable.cells
        guard cells.count > 0 else {
            XCTFail("No transactions to test")
            return
        }
        
        measure {
            // Click on first transaction's category
            let firstCell = cells.firstMatch
            firstCell.click()
            
            // Look for category button
            let categoryButton = firstCell.buttons.firstMatch
            if categoryButton.exists {
                categoryButton.click()
                
                // Wait for picker
                let picker = app.popovers.firstMatch
                _ = picker.waitForExistence(timeout: 2)
                
                // Dismiss picker by clicking outside
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).click()
                Thread.sleep(forTimeInterval: 0.2)
            }
        }
    }
    
    func testFileUploadSheetOpenPerformance() throws {
        measure {
            // Click upload button
            let uploadButton = findUploadButton()
            if let button = uploadButton {
                button.click()
                
                // Wait for sheet
                let sheet = app.sheets.firstMatch
                _ = sheet.waitForExistence(timeout: 2)
                
                // Dismiss sheet
                if app.sheets.buttons["Cancel"].exists {
                    app.sheets.buttons["Cancel"].click()
                }
                
                Thread.sleep(forTimeInterval: 0.2)
            }
        }
    }
    
    func testTabSwitchingPerformance() throws {
        let tabs = ["Overview", "Transactions", "Accounts", "Insights", "Settings"]
        
        measure {
            for tab in tabs {
                if app.staticTexts[tab].exists {
                    app.staticTexts[tab].click()
                } else if app.buttons[tab].exists {
                    app.buttons[tab].click()
                }
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToTransactions() {
        if app.staticTexts["Transactions"].exists {
            app.staticTexts["Transactions"].click()
        } else if app.buttons["Transactions"].exists {
            app.buttons["Transactions"].click()
        }
        
        // Wait for view to load
        _ = app.tables.firstMatch.waitForExistence(timeout: 5)
    }
    
    private func findUploadButton() -> XCUIElement? {
        if app.buttons["Upload Statement"].exists {
            return app.buttons["Upload Statement"]
        }
        
        // Try finding by plus icon
        let plusButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS '+'"))
        if plusButtons.count > 0 {
            return plusButtons.firstMatch
        }
        
        return nil
    }
}

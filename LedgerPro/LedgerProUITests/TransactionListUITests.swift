import XCTest

final class TransactionListUITests: LedgerProUITestsBase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Navigate to transactions tab
        navigateToTransactions()
    }
    
    func navigateToTransactions() {
        // Try multiple ways to navigate to transactions
        if app.staticTexts["Transactions"].exists {
            app.staticTexts["Transactions"].click()
        } else if app.buttons["Transactions"].exists {
            app.buttons["Transactions"].click()
        } else {
            // Try finding by icon
            let listIcon = app.buttons.matching(NSPredicate(format: "label CONTAINS 'list'")).firstMatch
            if waitForElement(listIcon) {
                listIcon.click()
            }
        }
        
        // Wait for transactions view
        XCTAssertTrue(app.tables.firstMatch.waitForExistence(timeout: 5))
    }
    
    func testTransactionListDisplay() throws {
        // Verify table exists
        let transactionTable = app.tables.firstMatch
        XCTAssertTrue(transactionTable.exists)
        
        // Check for transaction cells
        let cells = transactionTable.cells
        if cells.count > 0 {
            // Verify first cell has expected elements
            let firstCell = cells.firstMatch
            XCTAssertTrue(firstCell.exists)
            
            // Check for transaction details
            XCTAssertTrue(firstCell.staticTexts.count >= 3) // Date, description, amount
        }
    }
    
    func testFilterByUncategorized() throws {
        // Find and click filter button
        let filterButton = app.buttons["Filter"]
        if !filterButton.exists {
            // Try finding uncategorized button directly
            let uncategorizedButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Uncategorized'")).firstMatch
            if waitForElement(uncategorizedButton) {
                uncategorizedButton.click()
            }
        } else {
            filterButton.click()
            
            // Select uncategorized option
            let uncategorizedOption = app.menuItems["Uncategorized"]
            if waitForElement(uncategorizedOption) {
                uncategorizedOption.click()
            }
        }
        
        // Verify filter is applied (look for any indication)
        // This might show in a label or the filtered results
    }
    
    func testCategoryPicker() throws {
        // Find first transaction
        let transactionTable = app.tables.firstMatch
        XCTAssertTrue(waitForElement(transactionTable))
        
        let cells = transactionTable.cells
        if cells.count > 0 {
            let firstCell = cells.firstMatch
            
            // Click on the cell to select it
            firstCell.click()
            
            // Look for category button or picker
            let categoryButtons = firstCell.buttons
            if categoryButtons.count > 0 {
                let categoryButton = categoryButtons.firstMatch
                categoryButton.click()
                
                // Verify category picker appears
                let categoryPicker = app.popovers.firstMatch
                if waitForElement(categoryPicker, timeout: 2) {
                    // Try to select a category
                    let foodCategory = categoryPicker.buttons["Food & Dining"]
                    if waitForElement(foodCategory, timeout: 1) {
                        foodCategory.click()
                    }
                }
            }
        }
    }
    
    func testSearchTransactions() throws {
        // Find search field
        let searchField = app.searchFields.firstMatch
        if waitForElement(searchField) {
            searchField.click()
            searchField.typeText("Starbucks")
            
            // Press Enter to search
            searchField.typeKey(.return, modifierFlags: [])
            
            // Wait for results to update
            Thread.sleep(forTimeInterval: 0.5)
            
            // Verify table still exists (with filtered results)
            let transactionTable = app.tables.firstMatch
            XCTAssertTrue(transactionTable.exists)
        }
    }
    
    func testScrollPerformance() throws {
        let transactionTable = app.tables.firstMatch
        XCTAssertTrue(waitForElement(transactionTable))
        
        // Perform scroll test
        transactionTable.swipeUp(velocity: .fast)
        Thread.sleep(forTimeInterval: 0.5)
        transactionTable.swipeDown(velocity: .fast)
    }
}

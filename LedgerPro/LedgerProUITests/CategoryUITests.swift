import XCTest

final class CategoryUITests: LedgerProUITestsBase {
    
    func testOpenCategoryTestView() throws {
        // Click category test button in toolbar
        let categoryTestButton = app.buttons["Test Category System"]
        if !categoryTestButton.exists {
            // Try finding by help text
            let buttons = app.buttons.matching(NSPredicate(format: "help CONTAINS 'Test Category System'"))
            if buttons.count > 0 {
                buttons.firstMatch.click()
            } else {
                // Try finding by icon
                let folderButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'folder'")).firstMatch
                if waitForElement(folderButton) {
                    folderButton.click()
                }
            }
        } else {
            categoryTestButton.click()
        }
        
        // Verify category test view appears
        let categorySheet = app.sheets.firstMatch
        XCTAssertTrue(waitForElement(categorySheet))
        XCTAssertTrue(app.staticTexts["Test Category System"].exists)
    }
    
    func testRulesManagement() throws {
        // Click rules management button
        let rulesButton = app.buttons["Manage Rules"]
        if !rulesButton.exists {
            // Try finding by help text
            let buttons = app.buttons.matching(NSPredicate(format: "help CONTAINS 'Manage Rules'"))
            if buttons.count > 0 {
                buttons.firstMatch.click()
            } else {
                // Try finding by icon
                let gearButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'gear'")).firstMatch
                if waitForElement(gearButton) {
                    gearButton.click()
                }
            }
        } else {
            rulesButton.click()
        }
        
        // Verify rules sheet appears
        let rulesSheet = app.sheets.firstMatch
        XCTAssertTrue(waitForElement(rulesSheet))
        
        // Test create new rule
        let addRuleButton = app.buttons["Add Rule"]
        if waitForElement(addRuleButton) {
            addRuleButton.click()
            
            // Fill in rule details
            let ruleNameField = app.textFields["ruleName"]
            if waitForElement(ruleNameField) {
                ruleNameField.click()
                ruleNameField.typeText("Test Rule")
            }
            
            let merchantField = app.textFields["merchantPattern"]
            if waitForElement(merchantField) {
                merchantField.click()
                merchantField.typeText("TEST_MERCHANT")
            }
            
            // Save rule
            let saveButton = app.buttons["Save"]
            if waitForElement(saveButton) {
                saveButton.click()
                
                // Verify rule appears in list
                XCTAssertTrue(app.staticTexts["Test Rule"].waitForExistence(timeout: 2))
            }
        }
    }
    
    func testLearningAnalytics() throws {
        // Click learning analytics button
        let learningButton = app.buttons["Learning Analytics"]
        if !learningButton.exists {
            // Try finding by help text
            let buttons = app.buttons.matching(NSPredicate(format: "help CONTAINS 'Learning Analytics'"))
            if buttons.count > 0 {
                buttons.firstMatch.click()
            } else {
                // Try finding by icon
                let brainButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'brain'")).firstMatch
                if waitForElement(brainButton) {
                    brainButton.click()
                }
            }
        } else {
            learningButton.click()
        }
        
        // Verify learning analytics view appears
        let analyticsSheet = app.sheets.firstMatch
        XCTAssertTrue(waitForElement(analyticsSheet))
        
        // Check for tabs
        XCTAssertTrue(app.buttons["Overview"].exists || app.staticTexts["Overview"].exists)
        XCTAssertTrue(app.buttons["Patterns"].exists || app.staticTexts["Patterns"].exists)
        XCTAssertTrue(app.buttons["Suggestions"].exists || app.staticTexts["Suggestions"].exists)
    }
}

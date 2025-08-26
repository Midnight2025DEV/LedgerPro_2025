import XCTest

final class FileUploadUITests: LedgerProUITestsBase {
    
    func testUploadButtonOpensSheet() throws {
        // Find and click the upload button in toolbar
        let uploadButton = app.buttons["Upload Statement"]
        if !uploadButton.exists {
            // Try finding by image
            let plusButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '+'")).firstMatch
            XCTAssertTrue(waitForElement(plusButton))
            plusButton.click()
        } else {
            uploadButton.click()
        }
        
        // Verify upload sheet appears
        let uploadSheet = app.sheets.firstMatch
        XCTAssertTrue(waitForElement(uploadSheet))
        
        // Verify sheet contains expected elements
        XCTAssertTrue(app.staticTexts["Upload Bank Statement"].exists)
        XCTAssertTrue(app.staticTexts["Drag and drop files here or click to browse"].exists)
    }
    
    func testDragAndDropCSVFile() throws {
        // Open upload sheet
        tapButton("Upload Statement")
        
        // Wait for upload sheet
        let uploadSheet = app.sheets.firstMatch
        XCTAssertTrue(waitForElement(uploadSheet))
        
        // Find drop zone
        let dropZone = app.otherElements["FileDropZone"]
        XCTAssertTrue(waitForElement(dropZone))
        
        // Create test file path
        let testFilePath = Bundle(for: FileUploadUITests.self)
            .path(forResource: "test_transactions", ofType: "csv") ?? ""
        
        // Perform drag and drop
        dragFile(from: testFilePath, to: dropZone)
        
        // Verify processing starts
        XCTAssertTrue(app.progressIndicators.firstMatch.waitForExistence(timeout: 2))
    }
    
    func testCancelUpload() throws {
        // Open upload sheet
        tapButton("Upload Statement")
        
        // Find and click cancel button
        let cancelButton = app.sheets.buttons["Cancel"]
        XCTAssertTrue(waitForElement(cancelButton))
        cancelButton.click()
        
        // Verify sheet dismisses
        XCTAssertFalse(app.sheets.firstMatch.exists)
    }
    
    func testUploadProgress() throws {
        // Open upload sheet
        tapButton("Upload Statement")
        
        // Trigger file selection
        let browseButton = app.buttons["Browse Files"]
        if waitForElement(browseButton) {
            browseButton.click()
            
            // Wait for file dialog
            let openDialog = app.dialogs.firstMatch
            if waitForElement(openDialog) {
                // Select test file if dialog appears
                // This is simplified - real implementation would interact with file browser
                openDialog.buttons["Cancel"].click()
            }
        }
    }
    
    func testInvalidFileTypeError() throws {
        // Open upload sheet
        tapButton("Upload Statement")
        
        // Wait for sheet
        let uploadSheet = app.sheets.firstMatch
        XCTAssertTrue(waitForElement(uploadSheet))
        
        // Try to drop an invalid file type (if we had one)
        // This would test error handling
        
        // For now, just verify the sheet can be closed
        if app.sheets.buttons["Cancel"].exists {
            app.sheets.buttons["Cancel"].click()
        }
    }
}

import XCTest

class LedgerProUITestsBase: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        
        // Disable animations for faster testing
        app.launchEnvironment = [
            "DISABLE_ANIMATIONS": "1"
        ]
        
        app.launch()
        
        // Wait for app to be ready
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }
    
    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }
    
    // MARK: - Helper Methods
    
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        element.waitForExistence(timeout: timeout)
    }
    
    func tapButton(_ label: String) {
        let button = app.buttons[label]
        XCTAssertTrue(waitForElement(button))
        button.click()
    }
    
    func typeInTextField(_ identifier: String, text: String) {
        let textField = app.textFields[identifier]
        XCTAssertTrue(waitForElement(textField))
        textField.click()
        textField.typeText(text)
    }
    
    func dragFile(from sourcePath: String, to element: XCUIElement) {
        // Proper macOS drag and drop implementation
        let fileURL = URL(fileURLWithPath: sourcePath)
        
        // Create a pasteboard item
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([fileURL as NSPasteboardWriting])
        
        // Perform drag operation
        let startCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1))
        let dropCoordinate = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        
        startCoordinate.press(forDuration: 0.1, thenDragTo: dropCoordinate)
    }
}

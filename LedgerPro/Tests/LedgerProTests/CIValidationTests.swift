import XCTest

final class CIValidationTests: XCTestCase {
    func testCIEnvironment() {
        XCTAssertTrue(true, "CI environment is working")
    }
    
    func testSwiftVersion() {
        #if swift(>=5.9)
        XCTAssertTrue(true, "Swift version is 5.9 or higher")
        #else
        XCTFail("Swift version is too old")
        #endif
    }
}
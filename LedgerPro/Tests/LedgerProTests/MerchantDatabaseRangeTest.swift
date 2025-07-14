import XCTest
@testable import LedgerPro


final class MerchantDatabaseRangeTest: XCTestCase {
    var merchantDatabase: MerchantDatabase!
    
    override func setUp() async throws {
        try await super.setUp()
        merchantDatabase = MerchantDatabase.shared
    }
    
    override func tearDown() async throws {
        merchantDatabase = nil
        try await super.tearDown()
    }
    
    func testFindMerchantWithPositiveTransaction() {
        // Test the specific case that was causing range errors
        let result = merchantDatabase.findMerchant(for: "PAYCHECK")
        
        // Should not crash and should return some result (match or no match)
        XCTAssertTrue(true, "Test completed without crashing")
    }
    
    func testFindMerchantWithEmptyDescription() {
        // Test edge case of empty description
        let result = merchantDatabase.findMerchant(for: "")
        
        // Should not crash
        XCTAssertTrue(true, "Empty description test completed")
    }
    
    func testFindMerchantWithSpecialCharacters() {
        // Test with special characters that might cause regex issues
        let descriptions = [
            "UBER EATS * DELIVERY",
            "STARBUCKS #12345",
            "AMAZON.COM/BILL WA",
            "NETFLIX.COM",
            "WAL-MART SUPERCENTER"
        ]
        
        for description in descriptions {
            let result = merchantDatabase.findMerchant(for: description)
            // Should not crash regardless of result
        }
        
        XCTAssertTrue(true, "Special characters test completed")
    }
}
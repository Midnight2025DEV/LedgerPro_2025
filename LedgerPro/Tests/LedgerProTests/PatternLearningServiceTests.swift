import XCTest
@testable import LedgerPro


@MainActor
final class PatternLearningServiceTests: XCTestCase {
    var sut: PatternLearningService!
    var mockTransaction: Transaction!
    
    override func setUp() async throws {
        try await super.setUp()
        sut = PatternLearningService.shared
        await sut.clearAllData()
        
        mockTransaction = Transaction(
            date: "2024-01-01",
            description: "UBER RIDE TO AIRPORT",
            amount: 45.50,
            category: "Transportation"
        )
    }
    
    override func tearDown() async throws {
        await sut.clearAllData()
        sut = nil
        mockTransaction = nil
        try await super.tearDown()
    }
    
    // MARK: - Basic Service Tests
    
    func testServiceInitialization_hasEmptyData() async {
        // Given - Clean state from setUp
        
        // Then
        XCTAssertTrue(sut.corrections.isEmpty)
        XCTAssertTrue(sut.patterns.isEmpty)
        XCTAssertTrue(sut.suggestedRules.isEmpty)
    }
    
    func testRecordCorrection_addsToCorrections() async {
        // Given
        let oldCategory = "Food"
        let newCategory = "Transportation"
        
        // When
        await sut.recordCorrection(
            transaction: mockTransaction,
            originalCategory: oldCategory,
            newCategory: newCategory
        )
        
        // Then
        XCTAssertFalse(sut.corrections.isEmpty)
        XCTAssertEqual(sut.corrections.count, 1)
    }
    
    func testRecordMultipleCorrections_increasesCount() async {
        // Given
        let corrections = 3
        
        // When
        for i in 0..<corrections {
            await sut.recordCorrection(
                transaction: mockTransaction,
                originalCategory: "Food",
                newCategory: "Transportation"
            )
        }
        
        // Then
        XCTAssertEqual(sut.corrections.count, corrections)
    }
    
    func testClearAllData_removesAllData() async {
        // Given - Add some corrections first
        await sut.recordCorrection(
            transaction: mockTransaction,
            originalCategory: "Food",
            newCategory: "Transportation"
        )
        XCTAssertFalse(sut.corrections.isEmpty)
        
        // When
        await sut.clearAllData()
        
        // Then
        XCTAssertTrue(sut.corrections.isEmpty)
        XCTAssertTrue(sut.patterns.isEmpty)
        XCTAssertTrue(sut.suggestedRules.isEmpty)
    }
    
    // MARK: - Error Handling Tests
    
    func testRecordCorrection_withEmptyDescription_handlesGracefully() async {
        // Given
        let transaction = Transaction(
            date: "2024-01-01",
            description: "",
            amount: 100.0,
            category: "Test"
        )
        
        // When/Then - Should not crash
        await sut.recordCorrection(
            transaction: transaction,
            originalCategory: "Food",
            newCategory: "Transportation"
        )
        
        // Should still add the correction even with empty description
        XCTAssertEqual(sut.corrections.count, 1)
    }
    
    func testRecordCorrection_withSameCategories_handlesGracefully() async {
        // Given
        let sameCategory = "Transportation"
        
        // When
        await sut.recordCorrection(
            transaction: mockTransaction,
            originalCategory: sameCategory,
            newCategory: sameCategory
        )
        
        // Then - Should add correction even if categories are the same
        XCTAssertEqual(sut.corrections.count, 1)
    }
    
    // MARK: - Integration Tests
    
    func testPatternLearningWorkflow_endToEnd() async {
        // Given - Multiple similar transactions
        let transactions = [
            Transaction(date: "2024-01-01", description: "UBER TRIP", amount: -25.0, category: "Food"),
            Transaction(date: "2024-01-02", description: "UBER RIDE", amount: -30.0, category: "Food"),
            Transaction(date: "2024-01-03", description: "UBER EATS", amount: -15.0, category: "Food")
        ]
        
        // When - User corrects them all to Transportation
        for transaction in transactions {
            await sut.recordCorrection(
                transaction: transaction,
                originalCategory: "Food",
                newCategory: "Transportation"
            )
        }
        
        // Then - Should have recorded all corrections
        XCTAssertEqual(sut.corrections.count, 3)
        
        // Should have patterns (though we can't easily test the internal structure)
        // The main test is that it doesn't crash and records corrections
    }
    
    // MARK: - Performance Tests
    
    func testPerformance_largeNumberOfCorrections() async {
        // Test with 100 corrections (smaller than the full test to avoid timeout)
        let correctionCount = 100
        
        let startTime = Date()
        
        for i in 0..<correctionCount {
            let transaction = Transaction(
                date: "2024-01-01",
                description: "MERCHANT \(i) PURCHASE",
                amount: Double(i),
                category: "Test Category"
            )
            
            await sut.recordCorrection(
                transaction: transaction,
                originalCategory: "Food",
                newCategory: "Transportation"
            )
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        XCTAssertLessThan(duration, 5.0, "Recording 100 corrections should take less than 5 seconds")
        XCTAssertEqual(sut.corrections.count, correctionCount)
    }
}
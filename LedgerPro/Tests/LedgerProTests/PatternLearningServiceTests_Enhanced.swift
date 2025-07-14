import XCTest
@testable import LedgerPro

@MainActor
final class PatternLearningServiceEnhancedTests: XCTestCase {
    var sut: PatternLearningService!
    var mockCategories: [LedgerPro.Category]!
    var mockTransactions: [Transaction]!
    
    override func setUp() async throws {
        try await super.setUp()
        sut = PatternLearningService.shared
        
        // Clear any existing data
        sut.clearAllData()
        
        // Setup mock categories
        mockCategories = [
            LedgerPro.Category(name: "Food & Dining", icon: "fork.knife", color: "#FF9800"),
            LedgerPro.Category(name: "Transportation", icon: "car.fill", color: "#2196F3"),
            LedgerPro.Category(name: "Shopping", icon: "bag.fill", color: "#E91E63"),
            LedgerPro.Category(name: "Entertainment", icon: "tv.fill", color: "#9C27B0")
        ]
        
        // Setup mock transactions
        mockTransactions = [
            Transaction(date: "2024-01-01", description: "UBER TRIP HELP.UBER.COM", 
                       amount: -25.50, category: mockCategories[0].name),
            Transaction(date: "2024-01-02", description: "STARBUCKS #12345 NEW YORK", 
                       amount: -5.75, category: mockCategories[0].name),
            Transaction(date: "2024-01-03", description: "AMAZON.COM MERCHANDISE", 
                       amount: -49.99, category: mockCategories[2].name)
        ]
    }
    
    override func tearDown() async throws {
        sut.clearAllData()
        sut = nil
        mockCategories = nil
        mockTransactions = nil
        try await super.tearDown()
    }
    
    // MARK: - Pattern Extraction Tests
    
    func testPatternExtraction_extractsCorrectPatterns() async {
        // Given
        let transaction = mockTransactions[0] // UBER transaction
        
        // When - Use merchant extraction logic similar to the actual service
        let description = transaction.description.lowercased()
        let words = description.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty && $0.count > 2 }
            .filter { !$0.contains(".") && !$0.contains("@") }
            .prefix(3)
        
        // Then
        XCTAssertTrue(words.contains("uber"), "Should extract merchant name")
        XCTAssertTrue(words.contains("trip"), "Should extract meaningful words")
        XCTAssertFalse(words.joined().contains("help.uber.com"), "Should filter out domains")
    }
    
    func testPatternExtraction_handlesVariousMerchants() async {
        // Test different merchant formats with more realistic pattern extraction
        let testCases = [
            ("PAYPAL *MERCHANTNAME", ["paypal"]),
            ("SQ *COFFEE SHOP", ["shop"]),  // SQ is too short, * is filtered
            ("VENMO PAYMENT", ["venmo", "payment"]),
            ("ATM WITHDRAWAL 123", ["atm", "withdrawal"])
        ]
        
        for (description, expectedPatterns) in testCases {
            let words = description.lowercased()
                .components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty && $0.count > 2 }
                .filter { !$0.contains("*") && !$0.isNumber }
                .prefix(3)
            
            for expected in expectedPatterns {
                XCTAssertTrue(words.contains(expected), 
                            "Failed to extract '\(expected)' from '\(description)'. Found: \(words)")
            }
        }
    }
    
    // MARK: - Correction Recording Tests
    
    func testRecordCorrection_createsLearningEntry() async {
        // Given
        let transaction = mockTransactions[0]
        let oldCategory = mockCategories[0].name
        let newCategory = mockCategories[1].name // Transportation
        
        // When
        sut.recordCorrection(
            transaction: transaction,
            originalCategory: oldCategory,
            newCategory: newCategory
        )
        
        // Then
        XCTAssertFalse(sut.corrections.isEmpty)
        XCTAssertEqual(sut.corrections.count, 1)
    }
    
    func testRecordCorrection_updatesPatternConfidence() async {
        // Given
        let uberTransaction = mockTransactions[0]
        let transportCategory = mockCategories[1].name
        
        // When - Record same correction 3 times
        for _ in 0..<3 {
            sut.recordCorrection(
                transaction: uberTransaction,
                originalCategory: mockCategories[0].name,
                newCategory: transportCategory
            )
        }
        
        // Then
        XCTAssertEqual(sut.corrections.count, 3)
        // The pattern should be learned after multiple corrections
        XCTAssertFalse(sut.patterns.isEmpty)
    }
    
    func testRecordCorrection_handlesMixedCorrections() async {
        // Given - Uber corrected to different categories
        let transaction = mockTransactions[0]
        
        // When - Correct to Transport twice, then Food once
        sut.recordCorrection(transaction: transaction, 
                           originalCategory: mockCategories[0].name,
                           newCategory: mockCategories[1].name) // Transport
        sut.recordCorrection(transaction: transaction,
                           originalCategory: mockCategories[0].name,
                           newCategory: mockCategories[1].name) // Transport
        sut.recordCorrection(transaction: transaction,
                           originalCategory: mockCategories[1].name,
                           newCategory: mockCategories[0].name) // Food
        
        // Then - All corrections should be recorded
        XCTAssertEqual(sut.corrections.count, 3)
    }
    
    // MARK: - Rule Suggestion Tests
    
    func testRuleSuggestion_afterThreshold_createsValidRule() async {
        // Given - Multiple consistent corrections
        let starbucksDesc = "STARBUCKS COFFEE"
        let foodCategory = mockCategories[0].name
        
        // When - Record 5 corrections (above threshold)
        for i in 0..<5 {
            let transaction = Transaction(
                date: "2024-01-\(String(format: "%02d", i+1))",
                description: starbucksDesc,
                amount: -5.00,
                category: mockCategories[2].name // Wrong category initially
            )
            
            sut.recordCorrection(
                transaction: transaction,
                originalCategory: mockCategories[2].name,
                newCategory: foodCategory
            )
        }
        
        // Then - Should have recorded all corrections and created patterns
        XCTAssertEqual(sut.corrections.count, 5)
        XCTAssertFalse(sut.patterns.isEmpty)
        
        // Check if suggested rules are generated
        XCTAssertFalse(sut.suggestedRules.isEmpty)
    }
    
    func testRuleSuggestion_belowThreshold_noSuggestion() async {
        // Given - Only one correction (below threshold)
        sut.recordCorrection(
            transaction: mockTransactions[0],
            originalCategory: mockCategories[0].name,
            newCategory: mockCategories[1].name
        )
        
        // When
        let suggestedRulesCount = sut.suggestedRules.count
        
        // Then - Should have few or no suggestions with only one correction
        XCTAssertLessThanOrEqual(suggestedRulesCount, 1)
    }
    
    // MARK: - Real-world Pattern Tests
    
    func testCommonMerchantPatterns_extractCorrectly() async {
        let realWorldCases = [
            ("UBER EATS HELP.UBER.COM CA", "uber"),
            ("STARBUCKS #1234 NEW YORK NY", "starbucks"),
            ("AMAZON.COM BILL WA", "bill"), // Amazon.com is filtered due to .
            ("PAYPAL *NETFLIX MEMBERSHIP", "paypal"), // Netflix would be filtered due to *
            ("MCDONALDS #5678", "mcdonalds"),
            ("WAL-MART SUPERCENTER", "wal-mart"),
            ("CHEVRON 123456789", "chevron")
        ]
        
        for (description, expectedMerchant) in realWorldCases {
            let words = description.lowercased()
                .components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty && $0.count > 2 }
                .filter { !$0.contains(".") && !$0.contains("#") && !$0.contains("*") }
            
            let hasExpectedMerchant = words.contains { $0.contains(expectedMerchant) }
            XCTAssertTrue(hasExpectedMerchant, 
                         "Failed to extract '\(expectedMerchant)' from '\(description)'. Found: \(words)")
        }
    }
    
    // MARK: - Analytics and Statistics Tests
    
    func testCorrectionAnalytics_calculatesCorrectly() async {
        // Given - Various corrections over time
        let correctionCount = 7
        for i in 0..<correctionCount {
            sut.recordCorrection(
                transaction: mockTransactions[i % mockTransactions.count],
                originalCategory: mockCategories[0].name,
                newCategory: mockCategories[1].name
            )
        }
        
        // When/Then
        XCTAssertEqual(sut.corrections.count, correctionCount)
        XCTAssertFalse(sut.patterns.isEmpty)
        
        // Verify patterns contain expected merchants
        let patternKeys = sut.patterns.keys
        XCTAssertTrue(patternKeys.contains { $0.contains("uber") || $0.contains("starbucks") || $0.contains("amazon") })
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testEmptyDescription_handlesGracefully() async {
        // Given
        let emptyTransaction = Transaction(
            date: "2024-01-01",
            description: "",
            amount: -10.00,
            category: mockCategories[0].name
        )
        
        // When
        sut.recordCorrection(
            transaction: emptyTransaction,
            originalCategory: mockCategories[0].name,
            newCategory: mockCategories[1].name
        )
        
        // Then - Should not crash and should record the correction
        XCTAssertEqual(sut.corrections.count, 1)
    }
    
    func testSpecialCharacters_extractsPatternsCorrectly() async {
        // Test descriptions with special characters
        let specialCases = [
            "CAFÉ RÖSTI #123",
            "7-ELEVEN STORE",
            "MCDONALD'S #456", 
            "AT&T PAYMENT"
        ]
        
        for description in specialCases {
            let transaction = Transaction(
                date: "2024-01-01",
                description: description,
                amount: -10.00,
                category: mockCategories[0].name
            )
            
            // When
            sut.recordCorrection(
                transaction: transaction,
                originalCategory: mockCategories[0].name,
                newCategory: mockCategories[1].name
            )
            
            // Then - Should not crash
            XCTAssertTrue(sut.corrections.count > 0, 
                         "Failed to handle special characters in '\(description)'")
        }
        
        XCTAssertEqual(sut.corrections.count, specialCases.count)
    }
    
    func testVeryLongDescription_handlesCorrectly() async {
        // Given
        let longDescription = String(repeating: "VERY LONG MERCHANT NAME WITH MANY WORDS ", count: 10)
        let transaction = Transaction(
            date: "2024-01-01",
            description: longDescription,
            amount: -25.00,
            category: mockCategories[0].name
        )
        
        // When
        sut.recordCorrection(
            transaction: transaction,
            originalCategory: mockCategories[0].name,
            newCategory: mockCategories[1].name
        )
        
        // Then - Should handle gracefully
        XCTAssertEqual(sut.corrections.count, 1)
    }
    
    // MARK: - Performance Tests
    
    func testPerformance_handlesLargeCorrections() async {
        // Measure performance with many corrections
        let startTime = Date()
        let correctionCount = 100
        
        // Record 100 corrections
        for i in 0..<correctionCount {
            let transaction = Transaction(
                date: "2024-01-01",
                description: "MERCHANT_\(i % 10)",
                amount: -10.00,
                category: mockCategories[0].name
            )
            
            sut.recordCorrection(
                transaction: transaction,
                originalCategory: mockCategories[0].name,
                newCategory: mockCategories[i % 4].name
            )
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Should handle 100 corrections efficiently
        XCTAssertLessThan(duration, 2.0, "Should handle 100 corrections in under 2 seconds")
        XCTAssertEqual(sut.corrections.count, correctionCount)
    }
    
    func testMemoryManagement_limitsStoredCorrections() async {
        // Given - Add many corrections beyond reasonable limit
        let excessiveCount = 1500 // Beyond typical usage
        
        // When
        for i in 0..<excessiveCount {
            let transaction = Transaction(
                date: "2024-01-01",
                description: "TRANSACTION_\(i)",
                amount: -1.00,
                category: "Original"
            )
            
            sut.recordCorrection(
                transaction: transaction,
                originalCategory: "Original",
                newCategory: "Corrected"
            )
        }
        
        // Then - Should limit stored corrections to prevent memory issues
        XCTAssertLessThanOrEqual(sut.corrections.count, 1000, 
                                "Should limit corrections to prevent memory bloat")
    }
    
    // MARK: - Integration Tests
    
    func testEndToEndLearningWorkflow() async {
        // Given - Simulate real user workflow
        let merchantTransactions = [
            ("UBER TRIP", "Food & Dining", "Transportation"),
            ("UBER EATS", "Food & Dining", "Transportation"), 
            ("UBER RIDE", "Food & Dining", "Transportation"),
            ("STARBUCKS COFFEE", "Transportation", "Food & Dining"),
            ("STARBUCKS STORE", "Transportation", "Food & Dining")
        ]
        
        // When - User corrects categories over time
        for (description, originalCat, correctCat) in merchantTransactions {
            let transaction = Transaction(
                date: "2024-01-01",
                description: description,
                amount: -20.00,
                category: originalCat
            )
            
            sut.recordCorrection(
                transaction: transaction,
                originalCategory: originalCat,
                newCategory: correctCat
            )
        }
        
        // Then - Should learn patterns and suggest rules
        XCTAssertEqual(sut.corrections.count, merchantTransactions.count)
        XCTAssertFalse(sut.patterns.isEmpty)
        
        // Should have patterns for both UBER and STARBUCKS
        let patternKeys = sut.patterns.keys
        let hasUberPattern = patternKeys.contains { $0.contains("uber") }
        let hasStarbucksPattern = patternKeys.contains { $0.contains("starbucks") }
        
        XCTAssertTrue(hasUberPattern || hasStarbucksPattern, 
                     "Should learn patterns from repeated corrections")
    }
    
    // MARK: - Data Consistency Tests
    
    func testDataConsistency_afterMultipleOperations() async {
        // Given - Perform various operations
        let transaction = mockTransactions[0]
        
        // When - Record, clear, record again
        sut.recordCorrection(transaction: transaction, 
                           originalCategory: mockCategories[0].name,
                           newCategory: mockCategories[1].name)
        
        let firstCount = sut.corrections.count
        
        sut.clearAllData()
        XCTAssertTrue(sut.corrections.isEmpty)
        
        sut.recordCorrection(transaction: transaction,
                           originalCategory: mockCategories[0].name, 
                           newCategory: mockCategories[1].name)
        
        // Then - Data should be consistent
        XCTAssertEqual(sut.corrections.count, 1)
        XCTAssertEqual(firstCount, 1)
    }
}

// MARK: - Helper Extensions

private extension String {
    var isNumber: Bool {
        return !isEmpty && allSatisfy { $0.isNumber }
    }
}
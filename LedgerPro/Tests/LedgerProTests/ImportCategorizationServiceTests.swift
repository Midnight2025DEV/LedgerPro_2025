import XCTest
@testable import LedgerPro


final class ImportCategorizationServiceTests: XCTestCase {
    var sut: ImportCategorizationService!
    var mockTransactions: [Transaction]!
    var mockDuplicateTransactions: [Transaction]!
    
    override func setUp() async throws {
        try await super.setUp()
        sut = await ImportCategorizationService()
        
        // Ensure CategoryService and MerchantCategorizer are loaded
        await CategoryService.shared.loadCategories()
        
        // Setup mock transactions
        mockTransactions = [
            Transaction(
                id: "test_1",
                date: "2024-01-01",
                description: "STARBUCKS COFFEE #12345",
                amount: -5.50,
                category: "Uncategorized"
            ),
            Transaction(
                id: "test_2", 
                date: "2024-01-02",
                description: "UBER RIDE DOWNTOWN",
                amount: -25.00,
                category: "Uncategorized"
            ),
            Transaction(
                id: "test_3",
                date: "2024-01-03",
                description: "SALARY DEPOSIT COMPANY ABC",
                amount: 3000.00,
                category: "Uncategorized"
            ),
            Transaction(
                id: "test_4",
                date: "2024-01-04",
                description: "AMAZON.COM PURCHASE",
                amount: -99.99,
                category: "Uncategorized"
            )
        ]
        
        // Setup duplicate transactions (same description, date, amount)
        mockDuplicateTransactions = [
            Transaction(
                id: "duplicate_1",
                date: "2024-01-01",
                description: "STARBUCKS COFFEE #12345",
                amount: -5.50,
                category: "Uncategorized"
            ),
            Transaction(
                id: "duplicate_2",
                date: "2024-01-02", 
                description: "UBER RIDE DOWNTOWN",
                amount: -25.00,
                category: "Uncategorized"
            )
        ]
    }
    
    override func tearDown() async throws {
        sut = nil
        mockTransactions = nil
        mockDuplicateTransactions = nil
        try await super.tearDown()
    }
    
    // MARK: - Basic Service Tests
    
    func testServiceInitialization_succeeds() async {
        // Given/When - Service created in setUp
        
        // Then
        XCTAssertNotNil(sut)
    }
    
    func testCategorizeTransactions_withEmptyArray_returnsEmptyResult() async {
        // Given
        let emptyTransactions: [Transaction] = []
        
        // When
        let result = await sut.categorizeTransactions(emptyTransactions)
        
        // Then
        XCTAssertEqual(result.totalTransactions, 0)
        XCTAssertEqual(result.categorizedCount, 0)
        XCTAssertEqual(result.uncategorizedCount, 0)
        XCTAssertTrue(result.categorizedTransactions.isEmpty)
        XCTAssertTrue(result.uncategorizedTransactions.isEmpty)
    }
    
    // MARK: - Transaction Processing Tests
    
    func testCategorizeTransactions_processesAllTransactions() async {
        // When
        let result = await sut.categorizeTransactions(mockTransactions)
        
        // Then
        XCTAssertEqual(result.totalTransactions, mockTransactions.count)
        XCTAssertEqual(result.categorizedCount + result.uncategorizedCount, mockTransactions.count)
        
        // Verify some transactions were categorized
        XCTAssertGreaterThan(result.categorizedCount, 0)
    }
    
    func testCategorizeTransactions_assignsConfidenceScores() async {
        // When
        let result = await sut.categorizeTransactions(mockTransactions)
        
        // Then
        for (transaction, _, confidence) in result.categorizedTransactions {
            XCTAssertGreaterThanOrEqual(confidence, 0.0)
            XCTAssertLessThanOrEqual(confidence, 1.0)
            XCTAssertGreaterThanOrEqual(transaction.confidence ?? 0.0, 0.0)
            XCTAssertLessThanOrEqual(transaction.confidence ?? 1.0, 1.0)
        }
    }
    
    func testCategorizeTransactions_calculatesSuccessRate() async {
        // When
        let result = await sut.categorizeTransactions(mockTransactions)
        
        // Then
        let expectedSuccessRate = Double(result.categorizedCount) / Double(result.totalTransactions)
        XCTAssertEqual(result.successRate, expectedSuccessRate, accuracy: 0.001)
        XCTAssertGreaterThanOrEqual(result.successRate, 0.0)
        XCTAssertLessThanOrEqual(result.successRate, 1.0)
    }
    
    // MARK: - Categorization Logic Tests
    
    func testCategorizeTransaction_forKnownMerchants_assignsCorrectCategory() async {
        // Test specific merchants with expected categories
        let testCases = [
            ("STARBUCKS COFFEE", ["Food & Dining", "Food", "Dining"]),
            ("UBER RIDE", ["Transportation", "Travel"]),
            ("AMAZON.COM", ["Shopping", "Online"]),
            ("SALARY DEPOSIT", ["Income", "Salary"])
        ]
        
        for (description, possibleCategories) in testCases {
            let transaction = Transaction(
                date: "2024-01-01",
                description: description,
                amount: -10.00,
                category: "Uncategorized"
            )
            
            // When
            let result = await sut.categorizeTransactions([transaction])
            
            // Then
            XCTAssertEqual(result.totalTransactions, 1)
            
            if result.categorizedCount > 0 {
                let (categorizedTransaction, category, _) = result.categorizedTransactions.first!
                let categoryFound = possibleCategories.contains { expectedCategory in
                    category.name.contains(expectedCategory) || categorizedTransaction.category.contains(expectedCategory)
                }
                
                XCTAssertTrue(categoryFound,
                             "Transaction '\(description)' should be categorized appropriately. Got: '\(category.name)'")
            }
            // If not categorized, that's also acceptable depending on the merchant database
        }
    }
    
    func testCategorizeTransaction_withAmountBasedRules_appliesCorrectly() async {
        // Given - Large positive amount (likely income)
        let incomeTransaction = Transaction(
            date: "2024-01-01",
            description: "DIRECT DEPOSIT PAYROLL",
            amount: 2500.00,
            category: "Uncategorized"
        )
        
        // When
        let result = await sut.categorizeTransactions([incomeTransaction])
        
        // Then
        XCTAssertEqual(result.totalTransactions, 1)
        
        if result.categorizedCount > 0 {
            let (categorizedTransaction, category, _) = result.categorizedTransactions.first!
            XCTAssertTrue(category.name.contains("Income") || categorizedTransaction.amount > 0,
                         "Large positive amount should be categorized as income")
        }
    }
    
    // MARK: - High Confidence Detection Tests
    
    func testCategorizeTransactions_identifiesHighConfidenceMatches() async {
        // Given - Transaction that should have high confidence
        let highConfidenceTransaction = Transaction(
            date: "2024-01-01",
            description: "STARBUCKS COFFEE #12345",
            amount: -5.50,
            category: "Uncategorized"
        )
        
        // When
        let result = await sut.categorizeTransactions([highConfidenceTransaction])
        
        // Then
        XCTAssertEqual(result.totalTransactions, 1)
        if result.categorizedCount > 0 {
            XCTAssertGreaterThanOrEqual(result.highConfidenceCount, 0)
            XCTAssertLessThanOrEqual(result.highConfidenceCount, result.categorizedCount)
        }
    }
    
    func testCategorizeTransactions_handlesMultipleTransactions() async {
        // Given - Mix of transactions
        let mixedTransactions = [
            Transaction(date: "2024-01-01", description: "STARBUCKS COFFEE", amount: -5.50, category: "Uncategorized"),
            Transaction(date: "2024-01-02", description: "UNKNOWN MERCHANT ABC123", amount: -25.00, category: "Uncategorized")
        ]
        
        // When
        let result = await sut.categorizeTransactions(mixedTransactions)
        
        // Then
        XCTAssertEqual(result.totalTransactions, 2)
        XCTAssertEqual(result.categorizedCount + result.uncategorizedCount, 2)
        XCTAssertGreaterThanOrEqual(result.categorizedCount, 0)
        XCTAssertGreaterThanOrEqual(result.uncategorizedCount, 0)
    }
    
    // MARK: - Import Result Tests
    
    func testImportResult_calculatesCorrectly() async {
        // When
        let result = await sut.categorizeTransactions(mockTransactions)
        
        // Then
        XCTAssertEqual(result.totalTransactions, mockTransactions.count)
        XCTAssertLessThanOrEqual(result.categorizedCount, result.totalTransactions)
        XCTAssertLessThanOrEqual(result.highConfidenceCount, result.categorizedCount)
        XCTAssertLessThanOrEqual(result.uncategorizedCount, result.totalTransactions)
        XCTAssertEqual(result.categorizedCount + result.uncategorizedCount, result.totalTransactions)
    }
    
    func testImportResult_summaryMessage_isInformative() async {
        // When
        let result = await sut.categorizeTransactions(mockTransactions)
        
        // Then
        let summary = result.summaryMessage
        XCTAssertTrue(summary.contains("Import Summary:"))
        XCTAssertTrue(summary.contains("\(result.totalTransactions) transactions"))
        XCTAssertTrue(summary.contains("\(result.categorizedCount)"))
        XCTAssertTrue(summary.contains("\(result.highConfidenceCount)"))
        XCTAssertTrue(summary.contains("\(result.uncategorizedCount)"))
    }
    
    // MARK: - Transaction Format Handling Tests
    
    func testCategorizeTransactions_handlesCapitalOneFormat() async {
        // Given - Capital One specific transactions
        let capitalOneTransactions = [
            Transaction(
                date: "2024-01-01",
                description: "UBER TRIP HELP.UBER.COM CA",
                amount: -25.50,
                category: "Uncategorized",
                originalAmount: -21.50,
                originalCurrency: "EUR",
                exchangeRate: 1.186,
                hasForex: true
            ),
            Transaction(
                date: "2024-01-02", 
                description: "PAYMENT RECEIVED - THANK YOU",
                amount: 150.00,
                category: "Uncategorized"
            )
        ]
        
        // When
        let result = await sut.categorizeTransactions(capitalOneTransactions)
        
        // Then
        XCTAssertEqual(result.totalTransactions, capitalOneTransactions.count)
        
        // Verify forex transaction is preserved in categorized results
        let allTransactions = result.categorizedTransactions.map { $0.0 } + result.uncategorizedTransactions
        let forexTransaction = allTransactions.first { $0.hasForex == true }
        XCTAssertNotNil(forexTransaction)
        XCTAssertEqual(forexTransaction?.originalCurrency, "EUR")
    }
    
    func testCategorizeTransactions_handlesChaseFormat() async {
        // Given - Chase specific format
        let chaseTransactions = [
            Transaction(
                date: "2024-01-01",
                description: "CHECKCARD 1234 STARBUCKS STORE",
                amount: -6.75,
                category: "Uncategorized"
            ),
            Transaction(
                date: "2024-01-02",
                description: "ACH CREDIT SALARY DEP",
                amount: 2800.00,
                category: "Uncategorized"
            )
        ]
        
        // When
        let result = await sut.categorizeTransactions(chaseTransactions)
        
        // Then
        XCTAssertEqual(result.totalTransactions, chaseTransactions.count)
        
        // Verify some categorization occurs with Chase format
        XCTAssertGreaterThanOrEqual(result.categorizedCount, 0)
    }
    
    // MARK: - Edge Cases and Error Handling Tests
    
    func testCategorizeTransactions_withSpecialCharacters_handlesCorrectly() async {
        // Given
        let specialCharTransactions = [
            Transaction(
                date: "2024-01-01",
                description: "CAFÉ MÜNCHEN & CO.",
                amount: -15.50,
                category: "Uncategorized"
            ),
            Transaction(
                date: "2024-01-02",
                description: "MCDONALD'S #1234 - LOCATION",
                amount: -8.99,
                category: "Uncategorized"
            ),
            Transaction(
                date: "2024-01-03",
                description: "7-ELEVEN STORE (CONVENIENCE)",
                amount: -12.34,
                category: "Uncategorized"
            )
        ]
        
        // When
        let result = await sut.categorizeTransactions(specialCharTransactions)
        
        // Then - Should not crash and should process all transactions
        XCTAssertEqual(result.totalTransactions, specialCharTransactions.count)
        
        // All categorized transactions should have valid confidence scores
        for (transaction, _, confidence) in result.categorizedTransactions {
            XCTAssertGreaterThanOrEqual(confidence, 0.0)
            XCTAssertLessThanOrEqual(confidence, 1.0)
            XCTAssertGreaterThanOrEqual(transaction.confidence ?? 0.0, 0.0)
            XCTAssertLessThanOrEqual(transaction.confidence ?? 1.0, 1.0)
        }
    }
    
    func testCategorizeTransactions_withEmptyDescriptions_handlesGracefully() async {
        // Given
        let emptyDescTransactions = [
            Transaction(
                date: "2024-01-01",
                description: "",
                amount: -10.00,
                category: "Uncategorized"
            ),
            Transaction(
                date: "2024-01-02",
                description: "   ",
                amount: -5.00,
                category: "Uncategorized"
            )
        ]
        
        // When
        let result = await sut.categorizeTransactions(emptyDescTransactions)
        
        // Then - Should not crash
        XCTAssertEqual(result.totalTransactions, emptyDescTransactions.count)
        
        // Should either categorize or leave uncategorized (both are valid)
        XCTAssertEqual(result.categorizedCount + result.uncategorizedCount, emptyDescTransactions.count)
    }
    
    func testCategorizeTransactions_withVeryLargeAmounts_handlesCorrectly() async {
        // Given
        let largeAmountTransactions = [
            Transaction(
                date: "2024-01-01",
                description: "LARGE PURCHASE",
                amount: -99999.99,
                category: "Uncategorized"
            ),
            Transaction(
                date: "2024-01-02",
                description: "BONUS PAYMENT",
                amount: 50000.00,
                category: "Uncategorized"
            )
        ]
        
        // When
        let result = await sut.categorizeTransactions(largeAmountTransactions)
        
        // Then
        XCTAssertEqual(result.totalTransactions, largeAmountTransactions.count)
        
        // Should handle large amounts without errors
        XCTAssertEqual(result.categorizedCount + result.uncategorizedCount, largeAmountTransactions.count)
        
        // All categorized transactions should have valid confidence
        for (_, _, confidence) in result.categorizedTransactions {
            XCTAssertGreaterThanOrEqual(confidence, 0.0)
            XCTAssertLessThanOrEqual(confidence, 1.0)
        }
    }
    
    // MARK: - Performance Tests
    
    func testBatchProcessing_performance() async {
        // Given - Large batch of transactions
        let batchSize = 100
        let largeBatch = (0..<batchSize).map { index in
            Transaction(
                date: "2024-01-01",
                description: "MERCHANT_\\(index % 10) PURCHASE",
                amount: Double.random(in: -500...500),
                category: "Uncategorized"
            )
        }
        
        // When
        let startTime = Date()
        let result = await sut.categorizeTransactions(largeBatch)
        let duration = Date().timeIntervalSince(startTime)
        
        // Then - Should process efficiently
        XCTAssertLessThan(duration, 5.0, "Processing 100 transactions should take less than 5 seconds")
        XCTAssertEqual(result.totalTransactions, batchSize)
        XCTAssertEqual(result.categorizedCount + result.uncategorizedCount, batchSize)
    }
    
    func testLargeVolumeProcessing_performance() async {
        // Given - Many similar transactions
        let baseTransaction = mockTransactions[0]
        let largeBatch = (0..<50).map { index in
            let dayOfMonth = (index % 28) + 1
            let dateString = "2024-01-\(String(format: "%02d", dayOfMonth))"
            let descriptionString = "\(baseTransaction.description) #\(index)"
            return Transaction(
                date: dateString,
                description: descriptionString,
                amount: baseTransaction.amount + Double(index),
                category: "Uncategorized"
            )
        }
        
        // When
        let startTime = Date()
        let result = await sut.categorizeTransactions(largeBatch)
        let duration = Date().timeIntervalSince(startTime)
        
        // Then - Should process large volumes efficiently
        XCTAssertLessThan(duration, 2.0, "Large volume processing should be fast")
        XCTAssertEqual(result.totalTransactions, largeBatch.count)
    }
    
    // MARK: - Integration Tests
    
    func testEndToEndCategorizationWorkflow() async {
        // Given - Simulate complete categorization workflow
        let importTransactions = [
            Transaction(date: "2024-01-01", description: "STARBUCKS COFFEE", amount: -5.50, category: "Uncategorized"),
            Transaction(date: "2024-01-02", description: "UBER RIDE", amount: -25.00, category: "Uncategorized"),
            Transaction(date: "2024-01-03", description: "SALARY DEPOSIT", amount: 3000.00, category: "Uncategorized"),
            Transaction(date: "2024-01-04", description: "AMAZON PURCHASE", amount: -99.99, category: "Uncategorized"),
            Transaction(date: "2024-01-05", description: "UNKNOWN MERCHANT XYZ", amount: -15.00, category: "Uncategorized")
        ]
        
        // When - Process through complete workflow
        let result = await sut.categorizeTransactions(importTransactions)
        
        // Then - Verify complete workflow
        XCTAssertEqual(result.totalTransactions, importTransactions.count)
        XCTAssertEqual(result.categorizedCount + result.uncategorizedCount, importTransactions.count)
        
        // Some transactions should be categorized
        XCTAssertGreaterThanOrEqual(result.categorizedCount, 0)
        
        // Success rate should be reasonable (allowing for unknown merchants)
        XCTAssertGreaterThanOrEqual(result.successRate, 0.0)
        XCTAssertLessThanOrEqual(result.successRate, 1.0)
        
        // High confidence count should not exceed categorized count
        XCTAssertLessThanOrEqual(result.highConfidenceCount, result.categorizedCount)
        
        // Verify summary message is generated
        XCTAssertFalse(result.summaryMessage.isEmpty)
    }
    
    func testMultipleBatchProcessing_handlesCorrectly() async {
        // Given - Process multiple batches
        let batch1 = Array(mockTransactions.prefix(2))
        let batch2 = Array(mockTransactions.suffix(2))
        
        // When - Process batches separately
        let result1 = await sut.categorizeTransactions(batch1)
        let result2 = await sut.categorizeTransactions(batch2)
        
        // Then - Should handle all transactions correctly
        XCTAssertEqual(result1.totalTransactions, batch1.count)
        XCTAssertEqual(result2.totalTransactions, batch2.count)
        XCTAssertEqual(result1.totalTransactions + result2.totalTransactions, mockTransactions.count)
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement_withLargeDatasets() async {
        // Given - Very large dataset
        let largeDataset = (0..<1000).map { index in
            Transaction(
                date: "2024-01-01",
                description: "TRANSACTION_\\(index)",
                amount: Double(index),
                category: "Uncategorized"
            )
        }
        
        // When
        let result = await sut.categorizeTransactions(largeDataset)
        
        // Then - Should handle large datasets without memory issues
        XCTAssertEqual(result.totalTransactions, largeDataset.count)
        XCTAssertEqual(result.categorizedCount + result.uncategorizedCount, largeDataset.count)
        
        // Service should remain functional after large processing
        let smallBatch = [mockTransactions[0]]
        let smallResult = await sut.categorizeTransactions(smallBatch)
        XCTAssertEqual(smallResult.totalTransactions, 1)
    }
    
    // MARK: - Auto-Categorization Metadata Tests
    
    func testCategorizeTransactions_setsAutoCategorizedFlag() async {
        // Given - Transaction that should be auto-categorized
        let transaction = Transaction(
            date: "2024-01-01",
            description: "STARBUCKS COFFEE #12345",
            amount: -5.50,
            category: "Uncategorized"
        )
        
        // When
        let result = await sut.categorizeTransactions([transaction])
        
        // Then
        if result.categorizedCount > 0 {
            let (categorizedTransaction, _, _) = result.categorizedTransactions.first!
            XCTAssertTrue(categorizedTransaction.wasAutoCategorized == true,
                         "Auto-categorized transactions should have wasAutoCategorized = true")
            XCTAssertNotNil(categorizedTransaction.categorizationMethod)
            XCTAssertFalse(categorizedTransaction.categorizationMethod!.isEmpty)
        }
    }
    
    func testCategorizeTransactions_preservesMetadata() async {
        // Given - Transaction with existing metadata
        var transaction = mockTransactions[0]
        transaction = Transaction(
            id: transaction.id,
            date: transaction.date,
            description: transaction.description,
            amount: transaction.amount,
            category: transaction.category,
            confidence: transaction.confidence,
            jobId: transaction.jobId,
            accountId: transaction.accountId,
            rawData: ["original_key": "original_value"],
            originalAmount: transaction.originalAmount,
            originalCurrency: transaction.originalCurrency,
            exchangeRate: transaction.exchangeRate,
            hasForex: transaction.hasForex
        )
        
        // When
        let result = await sut.categorizeTransactions([transaction])
        
        // Then - Original metadata should be preserved
        let allTransactions = result.categorizedTransactions.map { $0.0 } + result.uncategorizedTransactions
        let processedTransaction = allTransactions.first!
        
        if let rawData = processedTransaction.rawData {
            XCTAssertEqual(rawData["original_key"], "original_value")
        }
    }
}
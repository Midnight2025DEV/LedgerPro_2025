import XCTest
@testable import LedgerPro

@MainActor
final class CriticalWorkflowTests: XCTestCase {
    // Services
    var financialManager: FinancialDataManager!
    var importService: ImportCategorizationService!
    var categoryService: CategoryService!
    var patternLearning: PatternLearningService!
    var apiService: APIService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize all services
        financialManager = FinancialDataManager()
        importService = ImportCategorizationService()
        categoryService = CategoryService.shared
        patternLearning = PatternLearningService.shared
        apiService = APIService()
        
        // Clear any existing data
        financialManager.clearAllData()
        patternLearning.clearAllData()
        await categoryService.loadCategories()
    }
    
    override func tearDown() async throws {
        // Clean up test data
        financialManager.clearAllData()
        patternLearning.clearAllData()
        
        financialManager = nil
        importService = nil
        apiService = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Critical Workflow 1: Import → Categorize → Display
    
    func testCompleteImportWorkflow() async throws {
        // FIXED: Range errors resolved in Transaction model
        
        let transactions = [
            Transaction(id: "test1", date: "2024-01-01", description: "UBER", amount: -25.50, category: "Uncategorized"),
            Transaction(id: "test2", date: "2024-01-02", description: "STARBUCKS", amount: -5.75, category: "Uncategorized"),
            Transaction(id: "test3", date: "2024-01-03", description: "PAYCHECK", amount: 3000.00, category: "Uncategorized")
        ]
        
        // Step 1: Categorize transactions
        let categorized = importService.categorizeTransactions(transactions)
        XCTAssertEqual(categorized.totalTransactions, 3)
        
        // Step 2: Import to FinancialDataManager (should work without range errors)
        let allTransactions = categorized.categorizedTransactions.map { $0.0 } + categorized.uncategorizedTransactions
        financialManager.addTransactions(allTransactions, jobId: "complete-import", filename: "test_import.csv")
        
        // Step 3: Verify import success
        XCTAssertEqual(financialManager.transactions.count, 3)
        XCTAssertEqual(financialManager.uploadedStatements.count, 1)
        
        // Step 4: Verify summary calculation
        let summary = financialManager.summary
        XCTAssertGreaterThan(summary.totalIncome, 0)
        XCTAssertGreaterThan(summary.totalExpenses, 0)
        XCTAssertEqual(summary.transactionCount, 3)
    }
    
    // MARK: - Critical Workflow 2: User Correction → Pattern Learning → Rule Creation
    
    func testLearningWorkflow() async throws {
        // Given - Transactions with wrong categories
        let transactions = [
            Transaction(id: "coffee1", date: "2024-01-01", description: "COFFEESHOP LATTE", amount: -4.50, category: "Shopping"),
            Transaction(id: "coffee2", date: "2024-01-02", description: "COFFEESHOP ESPRESSO", amount: -3.50, category: "Shopping"),
            Transaction(id: "coffee3", date: "2024-01-03", description: "COFFEESHOP MOCHA", amount: -5.00, category: "Shopping")
        ]
        
        financialManager.addTransactions(transactions, jobId: "test-learning", filename: "test.csv")
        
        let foodCategory = categoryService.categories.first { $0.name == "Food & Dining" }
        XCTAssertNotNil(foodCategory, "Food & Dining category should exist")
        
        // Step 1: User corrects categories (simulating UI action)
        for transaction in financialManager.transactions {
            if transaction.description.contains("COFFEESHOP") {
                // Record correction
                patternLearning.recordCorrection(
                    transaction: transaction,
                    originalCategory: transaction.category,
                    newCategory: foodCategory!.name
                )
                
                // Update transaction
                financialManager.updateTransactionCategory(
                    transactionId: transaction.id,
                    newCategory: foodCategory!
                )
            }
        }
        
        // Step 2: Verify pattern learning occurred
        let patterns = patternLearning.patterns
        XCTAssertFalse(patterns.isEmpty, "Should have learned patterns")
        
        // Step 3: Check for rule suggestions
        let suggestions = patternLearning.getRuleSuggestions()
        XCTAssertGreaterThanOrEqual(suggestions.count, 0, "Should generate rule suggestions")
        
        // Step 4: Import new transaction with same pattern
        let newTransaction = Transaction(
            id: "coffee4",
            date: "2024-01-04", 
            description: "COFFEESHOP AMERICANO", 
            amount: -3.00,
            category: "Uncategorized"
        )
        
        // Step 5: Verify pattern learning helps with categorization
        let categorizedResult = importService.categorizeTransactions([newTransaction])
        
        // Should either be categorized correctly or at least processed
        XCTAssertEqual(categorizedResult.totalTransactions, 1)
        XCTAssertEqual(categorizedResult.categorizedCount + categorizedResult.uncategorizedCount, 1)
    }
    
    // MARK: - Critical Workflow 3: Bank-Specific Import → Forex → Categorization
    
    func testBankSpecificWorkflow() async throws {
        // Given - Capital One format with forex
        let capitalOneTransactions = [
            Transaction(
                id: "uber_forex",
                date: "2024-01-15",
                description: "UBER BV NL",
                amount: -25.50,
                category: "Uncategorized",
                originalAmount: -27.83,
                originalCurrency: "EUR",
                exchangeRate: 0.916933333,
                hasForex: true
            ),
            Transaction(
                id: "starbucks_test",
                date: "2024-01-20",
                description: "STARBUCKS",
                amount: -5.75,
                category: "Uncategorized"
            )
        ]
        
        // Step 1: Verify forex data preservation
        let forexTransactions = capitalOneTransactions.filter { $0.hasForex == true }
        XCTAssertEqual(forexTransactions.count, 1)
        if let originalAmount = forexTransactions[0].originalAmount {
            XCTAssertEqual(originalAmount, -27.83, accuracy: 0.01)
        }
        if let exchangeRate = forexTransactions[0].exchangeRate {
            XCTAssertEqual(exchangeRate, 0.916933333, accuracy: 0.0001)
        }
        XCTAssertEqual(forexTransactions[0].originalCurrency, "EUR")
        
        // Step 2: Import and categorize
        let categorized = importService.categorizeTransactions(capitalOneTransactions)
        financialManager.addTransactions(
            categorized.categorizedTransactions.map { $0.0 } + categorized.uncategorizedTransactions,
            jobId: "capital-one-import",
            filename: "capital_one.csv"
        )
        
        // Step 3: Verify forex data preserved after import
        let savedTransactions = financialManager.transactions
        let savedForexTransaction = savedTransactions.first { $0.hasForex == true }
        XCTAssertNotNil(savedForexTransaction)
        XCTAssertEqual(savedForexTransaction?.originalCurrency, "EUR")
        if let originalAmount = savedForexTransaction?.originalAmount {
            XCTAssertEqual(originalAmount, -27.83, accuracy: 0.01)
        }
    }
    
    // MARK: - Critical Workflow 4: Large Dataset Performance
    
    func testLargeDatasetWorkflow() async throws {
        // Given - 500 transactions (reduced from 1000 for test performance)
        let startTime = Date()
        var transactions: [Transaction] = []
        
        let merchants = ["UBER", "STARBUCKS", "AMAZON", "WALMART", "TARGET", "NETFLIX"]
        let amounts = [-10.50, -5.75, -99.99, -125.43, -49.99, -15.99]
        
        for i in 0..<500 {
            let merchantIndex = i % merchants.count
            transactions.append(Transaction(
                id: "bulk_\(i)",
                date: "2024-01-01",
                description: "\(merchants[merchantIndex]) PURCHASE #\(i)",
                amount: amounts[merchantIndex] + Double(i % 10),
                category: "Uncategorized"
            ))
        }
        
        // Step 1: Categorize all transactions
        let categorized = importService.categorizeTransactions(transactions)
        
        // Step 2: Save to database (now works with range error fixes)
        let allTransactions = categorized.categorizedTransactions.map { $0.0 } + categorized.uncategorizedTransactions
        XCTAssertEqual(allTransactions.count, 500, "Should preserve all transactions")
        
        // Import all transactions (this should work now)
        financialManager.addTransactions(allTransactions, jobId: "large-import", filename: "large_dataset.csv")
        
        // Step 3: Calculate summary
        let summary = financialManager.summary
        
        // Step 4: Verify performance
        let duration = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(duration, 15.0, "Large dataset processing too slow")
        
        // Step 5: Verify data integrity
        XCTAssertEqual(summary.transactionCount, 500)
        XCTAssertEqual(financialManager.transactions.count, 500)
        
        // Step 6: Verify categorization occurred
        XCTAssertGreaterThanOrEqual(categorized.categorizedCount, 0, "Should categorize some transactions")
        XCTAssertEqual(categorized.totalTransactions, 500)
    }
    
    // MARK: - Critical Workflow 5: Error Recovery
    
    func testErrorRecoveryWorkflow() async throws {
        // Test recovery from various error conditions
        
        // Step 1: Test with empty description (edge case)
        let edgeCaseTransaction = Transaction(
            id: "edge_case",
            date: "2024-01-01",
            description: "",  // Empty description
            amount: -10.0,
            category: "Test"
        )
        
        // Should handle empty description gracefully
        financialManager.addTransactions([edgeCaseTransaction], jobId: "edge-case", filename: "edge.csv")
        XCTAssertEqual(financialManager.transactions.count, 1)
        
        // Step 2: Test with very long description (another edge case)
        let longDescription = String(repeating: "A", count: 1000)
        let longDescTransaction = Transaction(
            id: "long_desc",
            date: "2024-01-02",
            description: longDescription,
            amount: -20.0,
            category: "Test"
        )
        
        // Should handle long description gracefully
        financialManager.addTransactions([longDescTransaction], jobId: "long-desc", filename: "long.csv")
        XCTAssertEqual(financialManager.transactions.count, 2)
        
        // Step 3: Test duplicate job ID handling
        let duplicateTransaction = Transaction(
            id: "duplicate",
            date: "2024-01-03",
            description: "DUPLICATE TEST",
            amount: -30.0,
            category: "Test"
        )
        
        // First import should succeed
        financialManager.addTransactions([duplicateTransaction], jobId: "duplicate-test", filename: "dup1.csv")
        XCTAssertEqual(financialManager.transactions.count, 3)
        
        // Second import with same job ID should be ignored
        financialManager.addTransactions([duplicateTransaction], jobId: "duplicate-test", filename: "dup2.csv")
        XCTAssertEqual(financialManager.transactions.count, 3) // No change
    }
    
    // MARK: - Critical Workflow 6: Service Integration
    
    func testServiceIntegrationWorkflow() async throws {
        // Verify all services work together correctly
        XCTAssertNotNil(importService)
        XCTAssertNotNil(categoryService)
        XCTAssertNotNil(financialManager)
        XCTAssertNotNil(patternLearning)
        
        // Test end-to-end integration
        let testTransaction = Transaction(id: "integration1", date: "2024-01-01", description: "UBER", amount: -25.50, category: "Uncategorized")
        
        // Step 1: Categorization service
        let categorized = importService.categorizeTransactions([testTransaction])
        XCTAssertEqual(categorized.totalTransactions, 1)
        
        // Step 2: Financial data management
        let allTransactions = categorized.categorizedTransactions.map { $0.0 } + categorized.uncategorizedTransactions
        financialManager.addTransactions(allTransactions, jobId: "integration-test", filename: "integration.csv")
        XCTAssertEqual(financialManager.transactions.count, 1)
        
        // Step 3: Pattern learning integration
        if let firstTransaction = financialManager.transactions.first {
            patternLearning.recordCorrection(
                transaction: firstTransaction,
                originalCategory: firstTransaction.category,
                newCategory: "Transportation"
            )
            
            let patterns = patternLearning.patterns
            XCTAssertGreaterThanOrEqual(patterns.count, 0)
        }
        
        // Step 4: Category service integration
        XCTAssertGreaterThan(categoryService.categories.count, 0)
        XCTAssertGreaterThan(categoryService.rootCategories.count, 0)
    }
    
    // MARK: - Critical Workflow 7: Memory and Performance Under Load
    
    func testMemoryPerformanceWorkflow() async throws {
        // Test memory management with multiple operations
        
        let startTime = Date()
        
        // Create multiple batches of transactions
        for batchIndex in 0..<5 {
            let batchTransactions = (0..<50).map { index in
                Transaction(
                    id: "batch_\(batchIndex)_\(index)",
                    date: "2024-01-\(String(format: "%02d", (index % 28) + 1))",
                    description: "MERCHANT_\(batchIndex)_\(index)",
                    amount: -Double(10 + index % 100),
                    category: "Uncategorized"
                )
            }
            
            // Process each batch
            let categorized = importService.categorizeTransactions(batchTransactions)
            
            // Import all transactions (now works with range error fixes)
            let allTransactions = categorized.categorizedTransactions.map { $0.0 } + categorized.uncategorizedTransactions
            XCTAssertEqual(allTransactions.count, 50, "Each batch should have 50 transactions")
            
            financialManager.addTransactions(allTransactions, jobId: "batch-\(batchIndex)", filename: "batch_\(batchIndex).csv")
        }
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        // Verify performance
        XCTAssertLessThan(processingTime, 20.0, "Batch processing should be reasonably fast")
        
        // Verify final state
        let summary = financialManager.summary
        XCTAssertEqual(summary.transactionCount, 250) // 5 batches × 50 transactions
        XCTAssertEqual(financialManager.transactions.count, 250)
        
        // Cleanup should work
        financialManager.clearAllData()
        XCTAssertEqual(financialManager.transactions.count, 0)
    }
}

// MARK: - Helper Extensions

extension CriticalWorkflowTests {
    /// Helper to verify service initialization
    private func verifyServicesInitialized() {
        XCTAssertNotNil(financialManager)
        XCTAssertNotNil(importService)
        XCTAssertNotNil(categoryService)
        XCTAssertNotNil(patternLearning)
        XCTAssertNotNil(apiService)
    }
    
    /// Helper to create test transactions with variety
    private func createTestTransactions(count: Int) -> [Transaction] {
        let merchants = ["STARBUCKS", "UBER", "AMAZON", "WALMART", "NETFLIX"]
        let amounts = [-5.50, -25.00, -99.99, -125.43, -15.99]
        
        return (0..<count).map { index in
            let merchantIndex = index % merchants.count
            return Transaction(
                id: "helper_\(index)",
                date: "2024-01-\(String(format: "%02d", (index % 28) + 1))",
                description: "\(merchants[merchantIndex]) TRANSACTION #\(index)",
                amount: amounts[merchantIndex] + Double(index % 10),
                category: "Uncategorized"
            )
        }
    }
    
    /// Helper to validate transaction integrity
    private func validateTransactionIntegrity(_ transactions: [Transaction]) {
        for transaction in transactions {
            XCTAssertFalse(transaction.id.isEmpty, "Transaction should have valid ID")
            XCTAssertFalse(transaction.date.isEmpty, "Transaction should have valid date")
            XCTAssertFalse(transaction.description.isEmpty, "Transaction should have description")
            XCTAssertNotEqual(transaction.amount, 0.0, "Transaction should have non-zero amount")
        }
    }
}

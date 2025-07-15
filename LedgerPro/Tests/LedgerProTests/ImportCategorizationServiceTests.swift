import XCTest
@testable import LedgerPro

final class ImportCategorizationServiceTests: XCTestCase {
    var categorizationService: ImportCategorizationService!
    var categoryService: CategoryService!
    
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        categoryService = CategoryService.shared
        await categoryService.loadCategories()
        try await Task.sleep(for: .milliseconds(100))
        
        categorizationService = ImportCategorizationService()
    }
    
    @MainActor
    func testCategorizeMixedTransactions() async {
        // Given - Mix of categorizable and uncategorizable transactions
        let transactions = [
            Transaction(
                date: "2025-01-15",
                description: "UBER TRIP 123456",
                amount: -25.50,
                category: "Other"
            ),
            Transaction(
                date: "2025-01-15",
                description: "PAYROLL DEPOSIT COMPANY",
                amount: 3500.00,
                category: "Other"
            ),
            Transaction(
                date: "2025-01-15",
                description: "AMAZON.COM PURCHASE",
                amount: -89.99,
                category: "Other"
            ),
            Transaction(
                date: "2025-01-15",
                description: "UNKNOWN MERCHANT XYZ",
                amount: -15.00,
                category: "Other"
            )
        ]
        
        // When
        let result = await categorizationService.categorizeTransactions(transactions)
        
        // Then
        XCTAssertEqual(result.totalTransactions, 4)
        XCTAssertGreaterThanOrEqual(result.categorizedCount, 2, "Should categorize at least Uber and Payroll")
        XCTAssertLessThanOrEqual(result.uncategorizedCount, 2, "Should have at most 2 uncategorized")
        XCTAssertGreaterThan(result.successRate, 0.5, "Should categorize majority of transactions")
        
        // Verify categorized transactions have updated categories
        for (transaction, category, confidence) in result.categorizedTransactions {
            XCTAssertNotEqual(transaction.category, "Other", "Categorized transaction should not be 'Other'")
            XCTAssertEqual(transaction.category, category.name, "Transaction category should match suggested category")
            XCTAssertGreaterThanOrEqual(confidence, 0.7, "Should only auto-categorize with high confidence")
            XCTAssertNotNil(transaction.confidence, "Categorized transaction should have confidence score")
        }
    }
    
    @MainActor
    func testHighConfidenceTransactions() async {
        // Given - Transactions that should have very high confidence
        let highConfidenceTransactions = [
            Transaction(
                date: "2025-01-15",
                description: "PAYROLL DEPOSIT",
                amount: 2500.00,
                category: "Other"
            ),
            Transaction(
                date: "2025-01-15",
                description: "CAPITAL ONE MOBILE PAYMENT",
                amount: 350.00,
                category: "Other"
            )
        ]
        
        // When
        let result = await categorizationService.categorizeTransactions(highConfidenceTransactions)
        
        // Then
        XCTAssertEqual(result.totalTransactions, 2)
        XCTAssertEqual(result.categorizedCount, 2, "All high-confidence transactions should be categorized")
        XCTAssertGreaterThan(result.highConfidenceCount, 0, "Should have high confidence transactions")
        XCTAssertEqual(result.uncategorizedCount, 0, "No transactions should be uncategorized")
        XCTAssertEqual(result.successRate, 1.0, "Should achieve 100% success rate")
        
        // Verify high confidence scores
        for (_, _, confidence) in result.categorizedTransactions {
            XCTAssertGreaterThanOrEqual(confidence, 0.9, "High confidence transactions should have confidence >= 90%")
        }
    }
    
    @MainActor
    func testLowConfidenceTransactionsNotCategorized() async {
        // Given - Transactions that should have low confidence
        let lowConfidenceTransactions = [
            Transaction(
                date: "2025-01-15",
                description: "RANDOM STORE ABC123",
                amount: -45.00,
                category: "Other"
            ),
            Transaction(
                date: "2025-01-15",
                description: "UNKNOWN MERCHANT XYZ",
                amount: -25.00,
                category: "Other"
            )
        ]
        
        // When
        let result = await categorizationService.categorizeTransactions(lowConfidenceTransactions)
        
        // Then
        XCTAssertEqual(result.totalTransactions, 2)
        XCTAssertLessThanOrEqual(result.categorizedCount, 1, "Low confidence transactions should not be auto-categorized")
        XCTAssertGreaterThanOrEqual(result.uncategorizedCount, 1, "Should have uncategorized transactions")
        XCTAssertEqual(result.highConfidenceCount, 0, "Should have no high confidence matches")
        
        // Verify uncategorized transactions maintain original category
        for transaction in result.uncategorizedTransactions {
            XCTAssertEqual(transaction.category, "Other", "Uncategorized transactions should keep original category")
        }
    }
    
    @MainActor
    func testImportResultSummaryMessage() async {
        // Given
        let transactions = [
            Transaction(date: "2025-01-15", description: "UBER EATS", amount: -15.50, category: "Other"),
            Transaction(date: "2025-01-15", description: "PAYROLL", amount: 2500.00, category: "Other"),
            Transaction(date: "2025-01-15", description: "AMAZON", amount: -99.99, category: "Other"),
            Transaction(date: "2025-01-15", description: "UNKNOWN", amount: -25.00, category: "Other")
        ]
        
        // When
        let result = await categorizationService.categorizeTransactions(transactions)
        
        // Then
        let summaryMessage = result.summaryMessage
        XCTAssertTrue(summaryMessage.contains("Total: 4 transactions"), "Should show total count")
        XCTAssertTrue(summaryMessage.contains("Auto-categorized:"), "Should show categorized count")
        XCTAssertTrue(summaryMessage.contains("High confidence:"), "Should show high confidence count")
        XCTAssertTrue(summaryMessage.contains("Need review:"), "Should show uncategorized count")
        
        // Verify success rate calculation
        let expectedRate = Int(result.successRate * 100)
        XCTAssertTrue(summaryMessage.contains("\(expectedRate)%"), "Should show correct success rate percentage")
    }
    
    @MainActor
    func testEmptyTransactionList() async {
        // Given
        let emptyTransactions: [Transaction] = []
        
        // When
        let result = await categorizationService.categorizeTransactions(emptyTransactions)
        
        // Then
        XCTAssertEqual(result.totalTransactions, 0)
        XCTAssertEqual(result.categorizedCount, 0)
        XCTAssertEqual(result.uncategorizedCount, 0)
        XCTAssertEqual(result.highConfidenceCount, 0)
        XCTAssertEqual(result.successRate, 0)
        XCTAssertTrue(result.categorizedTransactions.isEmpty)
        XCTAssertTrue(result.uncategorizedTransactions.isEmpty)
    }
    
    @MainActor
    func testRealWorldTransactionMix() async {
        // Given - Real-world transaction mix
        let realWorldTransactions = [
            // High confidence - should be categorized
            Transaction(date: "2025-01-15", description: "CHEVRON GAS STATION", amount: -45.00, category: "Other"),
            Transaction(date: "2025-01-15", description: "WALMART SUPERCENTER", amount: -124.35, category: "Other"),
            Transaction(date: "2025-01-15", description: "DIRECT DEPOSIT PAYROLL", amount: 2800.00, category: "Other"),
            
            // Medium confidence - might be categorized
            Transaction(date: "2025-01-15", description: "STARBUCKS COFFEE", amount: -6.50, category: "Other"),
            Transaction(date: "2025-01-15", description: "TARGET STORE", amount: -75.00, category: "Other"),
            
            // Low confidence - likely uncategorized
            Transaction(date: "2025-01-15", description: "LOCAL BUSINESS #123", amount: -50.00, category: "Other"),
            Transaction(date: "2025-01-15", description: "ATM WITHDRAWAL", amount: -60.00, category: "Other")
        ]
        
        // When
        let result = await categorizationService.categorizeTransactions(realWorldTransactions)
        
        // Then
        XCTAssertEqual(result.totalTransactions, 7)
        XCTAssertGreaterThanOrEqual(result.categorizedCount, 3, "Should categorize at least the high-confidence ones")
        XCTAssertGreaterThan(result.successRate, 0.4, "Should achieve reasonable success rate")
        
        // Verify specific high-confidence categorizations
        let categorizedDescriptions = result.categorizedTransactions.map { $0.0.description }
        XCTAssertTrue(categorizedDescriptions.contains { $0.contains("CHEVRON") }, "Chevron should be categorized")
        XCTAssertTrue(categorizedDescriptions.contains { $0.contains("PAYROLL") }, "Payroll should be categorized")
        XCTAssertTrue(categorizedDescriptions.contains { $0.contains("WALMART") }, "Walmart should be categorized")
        
        print("📊 Real-world test results:")
        print("   Categorized: \(result.categorizedCount)/\(result.totalTransactions) (\(Int(result.successRate * 100))%)")
        print("   High confidence: \(result.highConfidenceCount)")
        print("   Need review: \(result.uncategorizedCount)")
    }
}
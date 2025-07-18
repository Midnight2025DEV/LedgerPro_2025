import XCTest
@testable import LedgerPro

@MainActor
final class RangeErrorDebugTest: XCTestCase {
    var financialManager: FinancialDataManager!
    var importService: ImportCategorizationService!
    
    override func setUp() async throws {
        try await super.setUp()
        financialManager = FinancialDataManager()
        importService = ImportCategorizationService()
        financialManager.clearAllData()
        
        // Wait for async updates to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }
    
    override func tearDown() async throws {
        financialManager = nil
        importService = nil
        try await super.tearDown()
    }
    
    func testMinimalAddTransactions() async throws {
        // Test the most basic case that should work
        let transaction = Transaction(
            id: "test",
            date: "2024-01-01",
            description: "TEST",
            amount: -10.0,
            category: "Test"
        )
        
        // This should not crash
        financialManager.addTransactions([transaction], jobId: "debug", filename: "debug.csv")
        
        // Wait for async updates to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        XCTAssertEqual(financialManager.transactions.count, 1)
    }
    
    func testEmptyTransactionsArray() async {
        // Test adding empty array
        financialManager.addTransactions([], jobId: "empty", filename: "empty.csv")
        
        // Wait for async updates to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        XCTAssertEqual(financialManager.transactions.count, 0)
    }
    
    func testTransactionWithEmptyDescription() async {
        // Test transaction with empty description (might cause prefix issues)
        let transaction = Transaction(
            id: "empty_desc",
            date: "2024-01-01",
            description: "",
            amount: -10.0,
            category: "Test"
        )
        
        financialManager.addTransactions([transaction], jobId: "empty_desc", filename: "test.csv")
        
        // Wait for async updates to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        XCTAssertEqual(financialManager.transactions.count, 1)
    }
    
    func testClearAllData() async {
        // Add some data first
        let transaction = Transaction(
            id: "test",
            date: "2024-01-01", 
            description: "TEST",
            amount: -10.0,
            category: "Test"
        )
        
        financialManager.addTransactions([transaction], jobId: "test", filename: "test.csv")
        
        // Wait for async updates to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        XCTAssertEqual(financialManager.transactions.count, 1)
        
        // Now clear it
        financialManager.clearAllData()
        
        // Wait for async updates to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        XCTAssertEqual(financialManager.transactions.count, 0)
    }
    
    func testLoadDemoData() async {
        // Test loading demo data
        financialManager.loadDemoData()
        
        // Wait for async updates to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        XCTAssertGreaterThan(financialManager.transactions.count, 0)
    }
    
    // Test gradually increasing size to find the threshold
    func testTwoTransactions() async {
        let transactions = [
            Transaction(id: "test1", date: "2024-01-01", description: "UBER", amount: -25.50, category: "Uncategorized"),
            Transaction(id: "test2", date: "2024-01-02", description: "STARBUCKS", amount: -5.75, category: "Uncategorized")
        ]
        
        let categorized = importService.categorizeTransactions(transactions)
        let allTransactions = categorized.categorizedTransactions.map { $0.0 } + categorized.uncategorizedTransactions
        
        financialManager.addTransactions(allTransactions, jobId: "two-test", filename: "test.csv")
        
        // Wait for async updates to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        XCTAssertEqual(financialManager.transactions.count, 2)
    }
    
    func testThreeTransactions() async {
        let transactions = [
            Transaction(id: "test1", date: "2024-01-01", description: "UBER", amount: -25.50, category: "Uncategorized"),
            Transaction(id: "test2", date: "2024-01-02", description: "STARBUCKS", amount: -5.75, category: "Uncategorized"),
            Transaction(id: "test3", date: "2024-01-03", description: "AMAZON", amount: -99.99, category: "Uncategorized")
        ]
        
        let categorized = importService.categorizeTransactions(transactions)
        let allTransactions = categorized.categorizedTransactions.map { $0.0 } + categorized.uncategorizedTransactions
        
        financialManager.addTransactions(allTransactions, jobId: "three-test", filename: "test.csv")
        
        // Wait for async updates to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        XCTAssertEqual(financialManager.transactions.count, 3)
    }
    
    func testFourTransactionsAllNegative() async {
        // Test 4 transactions all negative amounts
        let transactions = [
            Transaction(id: "test1", date: "2024-01-01", description: "UBER", amount: -25.50, category: "Uncategorized"),
            Transaction(id: "test2", date: "2024-01-02", description: "STARBUCKS", amount: -5.75, category: "Uncategorized"),
            Transaction(id: "test3", date: "2024-01-03", description: "AMAZON", amount: -99.99, category: "Uncategorized"),
            Transaction(id: "test4", date: "2024-01-04", description: "WALMART", amount: -125.43, category: "Uncategorized")
        ]
        
        let categorized = importService.categorizeTransactions(transactions)
        let allTransactions = categorized.categorizedTransactions.map { $0.0 } + categorized.uncategorizedTransactions
        
        financialManager.addTransactions(allTransactions, jobId: "four-negative-test", filename: "test.csv")
        
        // Wait for async updates to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        XCTAssertEqual(financialManager.transactions.count, 4)
    }
    
    func testThreeTransactionsWithPositive() async {
        // Test 3 transactions with one positive
        let transactions = [
            Transaction(id: "test1", date: "2024-01-01", description: "UBER", amount: -25.50, category: "Uncategorized"),
            Transaction(id: "test2", date: "2024-01-02", description: "STARBUCKS", amount: -5.75, category: "Uncategorized"),
            Transaction(id: "test3", date: "2024-01-03", description: "PAYCHECK", amount: 3000.00, category: "Uncategorized")
        ]
        
        let categorized = importService.categorizeTransactions(transactions)
        let allTransactions = categorized.categorizedTransactions.map { $0.0 } + categorized.uncategorizedTransactions
        
        financialManager.addTransactions(allTransactions, jobId: "three-positive-test", filename: "test.csv")
        
        // Wait for async updates to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        XCTAssertEqual(financialManager.transactions.count, 3)
    }
    
    // Test specifically what might be different about categorized transactions
    func testCategorizedTransactionStructure() async {
        let transaction = Transaction(id: "test", date: "2024-01-01", description: "STARBUCKS", amount: -5.50, category: "Uncategorized")
        
        let categorized = importService.categorizeTransactions([transaction])
        
        // Examine the structure
        print("Categorized count: \(categorized.categorizedCount)")
        print("Uncategorized count: \(categorized.uncategorizedCount)")
        print("Total: \(categorized.totalTransactions)")
        
        if !categorized.categorizedTransactions.isEmpty {
            let (transactionFromCategorized, _, confidence) = categorized.categorizedTransactions[0]
            print("Categorized transaction description: '\(transactionFromCategorized.description)'")
            print("Categorized transaction ID: '\(transactionFromCategorized.id)'")
        }
        
        if !categorized.uncategorizedTransactions.isEmpty {
            let uncategorizedTransaction = categorized.uncategorizedTransactions[0]
            print("Uncategorized transaction description: '\(uncategorizedTransaction.description)'")
            print("Uncategorized transaction ID: '\(uncategorizedTransaction.id)'")
        }
        
        // Now try adding them
        let allTransactions = categorized.categorizedTransactions.map { $0.0 } + categorized.uncategorizedTransactions
        financialManager.addTransactions(allTransactions, jobId: "structure-test", filename: "test.csv")
        
        // Wait for async updates to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        XCTAssertEqual(financialManager.transactions.count, 1)
    }
}
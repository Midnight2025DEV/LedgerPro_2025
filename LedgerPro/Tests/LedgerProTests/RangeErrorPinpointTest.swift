import XCTest
@testable import LedgerPro

@MainActor
final class RangeErrorPinpointTest: XCTestCase {
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
    
    func testPinpointExactCrash() async {
        // The minimal case that causes the crash
        let transactions = [
            Transaction(id: "test1", date: "2024-01-01", description: "UBER", amount: -25.50, category: "Uncategorized"),
            Transaction(id: "test2", date: "2024-01-02", description: "STARBUCKS", amount: -5.75, category: "Uncategorized"),
            Transaction(id: "test3", date: "2024-01-03", description: "PAYCHECK", amount: 3000.00, category: "Uncategorized")
        ]
        
        print("🔍 Step 1: Testing ImportService.categorizeTransactions...")
        let categorized = importService.categorizeTransactions(transactions)
        print("✅ Categorization completed successfully")
        print("   - Categorized: \(categorized.categorizedCount)")
        print("   - Uncategorized: \(categorized.uncategorizedCount)")
        
        print("🔍 Step 2: Testing transaction extraction...")
        let allTransactions = categorized.categorizedTransactions.map { $0.0 } + categorized.uncategorizedTransactions
        print("✅ Transaction extraction completed")
        print("   - Total transactions: \(allTransactions.count)")
        
        // Check each transaction individually
        for (index, transaction) in allTransactions.enumerated() {
            print("   - Transaction \(index): \(transaction.description), amount: \(transaction.amount)")
        }
        
        print("🔍 Step 3: Testing FinancialDataManager.addTransactions...")
        // This is where the crash should occur
        financialManager.addTransactions(allTransactions, jobId: "pinpoint-test", filename: "test.csv")
        
        // Wait for async updates to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        print("✅ addTransactions completed successfully")
        
        XCTAssertEqual(financialManager.transactions.count, 3)
    }
    
    // Test adding the positive transaction directly without categorization
    func testDirectPositiveTransaction() async {
        let positiveTransaction = Transaction(id: "pos", date: "2024-01-01", description: "PAYCHECK", amount: 3000.00, category: "Uncategorized")
        
        print("🔍 Testing direct positive transaction...")
        financialManager.addTransactions([positiveTransaction], jobId: "direct-positive", filename: "test.csv")
        
        // Wait for async updates to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        print("✅ Direct positive transaction added successfully")
        
        XCTAssertEqual(financialManager.transactions.count, 1)
    }
    
    // Test with a categorized positive transaction
    func testCategorizedPositiveTransaction() async {
        let positiveTransaction = Transaction(id: "pos", date: "2024-01-01", description: "PAYCHECK", amount: 3000.00, category: "Uncategorized")
        
        print("🔍 Step 1: Categorizing positive transaction...")
        let categorized = importService.categorizeTransactions([positiveTransaction])
        print("✅ Categorization of positive transaction completed")
        
        print("🔍 Step 2: Extracting categorized positive transaction...")
        let allTransactions = categorized.categorizedTransactions.map { $0.0 } + categorized.uncategorizedTransactions
        print("✅ Extraction completed")
        
        if let transaction = allTransactions.first {
            print("   - Description: '\(transaction.description)'")
            print("   - Amount: \(transaction.amount)")
            print("   - Category: '\(transaction.category)'")
            print("   - ID: '\(transaction.id)'")
        }
        
        print("🔍 Step 3: Adding categorized positive transaction...")
        financialManager.addTransactions(allTransactions, jobId: "categorized-positive", filename: "test.csv")
        
        // Wait for async updates to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        print("✅ Categorized positive transaction added successfully")
        
        XCTAssertEqual(financialManager.transactions.count, 1)
    }
}
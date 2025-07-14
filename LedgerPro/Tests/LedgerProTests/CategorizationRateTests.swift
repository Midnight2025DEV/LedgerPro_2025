import XCTest
@testable import LedgerPro

final class CategorizationRateTests: XCTestCase {
    var categorizationService: ImportCategorizationService!
    var categoryService: CategoryService!
    
    
    override func setUp() async throws {
        try await super.setUp()
        categoryService = CategoryService.shared
        await categoryService.loadCategories()
        try await Task.sleep(for: .milliseconds(100))
        
        categorizationService = ImportCategorizationService()
    }
    
    
    func testEnhancedCategorizationRate() {
        // Given - Real world transaction examples that should be categorized with new rules
        let transactions = [
            // AI & Tech Services
            Transaction(date: "2025-01-15", description: "CLAUDE AI SUBSCRIPTION", amount: -20.00, category: "Other"),
            Transaction(date: "2025-01-15", description: "ANTHROPIC BILLING", amount: -50.00, category: "Other"),
            Transaction(date: "2025-01-15", description: "OPENAI CHATGPT PLUS", amount: -20.00, category: "Other"),
            Transaction(date: "2025-01-15", description: "GOOGLE CLOUD SERVICES", amount: -15.00, category: "Other"),
            Transaction(date: "2025-01-15", description: "COURSERA COURSE", amount: -49.00, category: "Other"),
            
            // Enhanced Food & Coffee
            Transaction(date: "2025-01-15", description: "RIFLE COFFEE COMPANY", amount: -25.00, category: "Other"),
            Transaction(date: "2025-01-15", description: "PANERA BREAD", amount: -12.50, category: "Other"),
            Transaction(date: "2025-01-15", description: "STARBUCKS STORE", amount: -8.50, category: "Other"),
            
            // Transportation & Parking
            Transaction(date: "2025-01-15", description: "PARKING METER", amount: -5.00, category: "Other"),
            Transaction(date: "2025-01-15", description: "76 GAS STATION", amount: -45.00, category: "Other"),
            Transaction(date: "2025-01-15", description: "PY TRANSPORT", amount: -12.00, category: "Other"),
            Transaction(date: "2025-01-15", description: "CHEVRON STATION", amount: -50.00, category: "Other"),
            
            // Mexican Stores
            Transaction(date: "2025-01-15", description: "OXXO CONVENIENCE", amount: -8.00, category: "Other"),
            Transaction(date: "2025-01-15", description: "CARNICERIA LOPEZ", amount: -25.00, category: "Other"),
            Transaction(date: "2025-01-15", description: "FRUTERIA GARCIA", amount: -15.00, category: "Other"),
            Transaction(date: "2025-01-15", description: "CARN MARKET", amount: -30.00, category: "Other"),
            
            // Hotels & Entertainment
            Transaction(date: "2025-01-15", description: "MOTEL 6", amount: -85.00, category: "Other"),
            Transaction(date: "2025-01-15", description: "HOTEL MARRIOTT", amount: -150.00, category: "Other"),
            Transaction(date: "2025-01-15", description: "CRUNCHYROLL", amount: -9.99, category: "Other"),
            Transaction(date: "2025-01-15", description: "NETFLIX SUBSCRIPTION", amount: -15.99, category: "Other"),
            Transaction(date: "2025-01-15", description: "YOUTUBE PREMIUM", amount: -11.99, category: "Other"),
            
            // Financial Services
            Transaction(date: "2025-01-15", description: "PAYPAL PAYMENT", amount: -35.00, category: "Other"),
            Transaction(date: "2025-01-15", description: "CAPITAL ONE MOBILE TRANSFER", amount: 500.00, category: "Other"),
            
            // Existing rules that should still work
            Transaction(date: "2025-01-15", description: "UBER TRIP 123456", amount: -25.50, category: "Other"),
            Transaction(date: "2025-01-15", description: "AMAZON.COM PURCHASE", amount: -89.99, category: "Other"),
            Transaction(date: "2025-01-15", description: "PAYROLL DEPOSIT", amount: 3500.00, category: "Other"),
            
            // Some that might not be categorized
            Transaction(date: "2025-01-15", description: "UNKNOWN MERCHANT XYZ", amount: -15.00, category: "Other"),
            Transaction(date: "2025-01-15", description: "RANDOM STORE ABC", amount: -22.00, category: "Other"),
            Transaction(date: "2025-01-15", description: "MYSTERY PURCHASE", amount: -18.00, category: "Other")
        ]
        
        // When
        let result = categorizationService.categorizeTransactions(transactions)
        
        // Then
        let successRate = result.successRate
        print("📊 Categorization Results:")
        print("   Total transactions: \(result.totalTransactions)")
        print("   Categorized: \(result.categorizedCount)")
        print("   Uncategorized: \(result.uncategorizedCount)")
        print("   Success rate: \(String(format: "%.1f", successRate * 100))%")
        print("   High confidence: \(result.highConfidenceCount)")
        
        // Print categorized transactions
        print("\n✅ Categorized transactions:")
        for (transaction, category, confidence) in result.categorizedTransactions {
            print("   \(transaction.description) → \(category.name) (confidence: \(String(format: "%.1f", confidence * 100))%)")
        }
        
        // Print uncategorized transactions
        if !result.uncategorizedTransactions.isEmpty {
            print("\n❌ Uncategorized transactions:")
            for transaction in result.uncategorizedTransactions {
                print("   \(transaction.description)")
            }
        }
        
        // Our goal is to achieve 80%+ categorization rate
        XCTAssertGreaterThanOrEqual(successRate, 0.8, "Should achieve at least 80% categorization rate with new rules")
        
        // Verify that the new rules are working for specific merchants
        let categorizedDescriptions = result.categorizedTransactions.map { $0.0.description }
        
        // Check some specific merchants that should be categorized with new rules
        XCTAssertTrue(categorizedDescriptions.contains { $0.contains("CLAUDE") }, "Claude AI should be categorized")
        XCTAssertTrue(categorizedDescriptions.contains { $0.contains("RIFLE COFFEE") }, "Rifle Coffee should be categorized")
        XCTAssertTrue(categorizedDescriptions.contains { $0.contains("PANERA") }, "Panera should be categorized")
        XCTAssertTrue(categorizedDescriptions.contains { $0.contains("OXXO") }, "OXXO should be categorized")
        XCTAssertTrue(categorizedDescriptions.contains { $0.contains("NETFLIX") }, "Netflix should be categorized")
        XCTAssertTrue(categorizedDescriptions.contains { $0.contains("PARKING") }, "Parking should be categorized")
    }
    
    
    func testSpecificNewRules() {
        // Test individual new rules to ensure they're working
        let testCases: [(description: String, expectedCategory: String)] = [
            ("CLAUDE AI SUBSCRIPTION", "Subscriptions"),
            ("ANTHROPIC BILLING", "Subscriptions"),
            ("OPENAI CHATGPT", "Subscriptions"),
            ("COURSERA COURSE", "Education"),
            ("RIFLE COFFEE COMPANY", "Food & Dining"),
            ("PANERA BREAD", "Food & Dining"),
            ("PARKING METER", "Transportation"),
            ("76 GAS STATION", "Transportation"),
            ("OXXO CONVENIENCE", "Shopping"),
            ("CARNICERIA LOPEZ", "Groceries"),
            ("FRUTERIA GARCIA", "Groceries"),
            ("MOTEL 6", "Lodging"),
            ("HOTEL MARRIOTT", "Lodging"),
            ("CRUNCHYROLL", "Entertainment"),
            ("NETFLIX SUBSCRIPTION", "Entertainment"),
            ("YOUTUBE PREMIUM", "Entertainment"),
            ("PAYPAL PAYMENT", "Business"),
            ("CAPITAL ONE MOBILE TRANSFER", "Transfers")
        ]
        
        var passedTests = 0
        var failedTests: [String] = []
        
        for testCase in testCases {
            let transaction = Transaction(
                date: "2025-01-15",
                description: testCase.description,
                amount: -25.00,
                category: "Other"
            )
            
            let result = categorizationService.categorizeTransactions([transaction])
            
            if result.categorizedCount > 0 {
                let categorizedTransaction = result.categorizedTransactions[0]
                if categorizedTransaction.1.name == testCase.expectedCategory {
                    passedTests += 1
                    print("✅ \(testCase.description) → \(categorizedTransaction.1.name)")
                } else {
                    failedTests.append("\(testCase.description) → expected \(testCase.expectedCategory), got \(categorizedTransaction.1.name)")
                    print("❌ \(testCase.description) → expected \(testCase.expectedCategory), got \(categorizedTransaction.1.name)")
                }
            } else {
                failedTests.append("\(testCase.description) → not categorized")
                print("❌ \(testCase.description) → not categorized")
            }
        }
        
        print("\n📊 Rule Testing Results:")
        print("   Passed: \(passedTests)/\(testCases.count)")
        print("   Success rate: \(String(format: "%.1f", (Double(passedTests) / Double(testCases.count)) * 100))%")
        
        if !failedTests.isEmpty {
            print("\n❌ Failed tests:")
            for failure in failedTests {
                print("   \(failure)")
            }
        }
        
        // Expect at least 80% of our specific rules to work
        let ruleSuccessRate = Double(passedTests) / Double(testCases.count)
        XCTAssertGreaterThanOrEqual(ruleSuccessRate, 0.8, "At least 80% of new rules should work correctly")
    }
}
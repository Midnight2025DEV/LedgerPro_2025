import XCTest
@testable import LedgerPro

final class EndToEndCategorizationTest: XCTestCase {
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
    func testComprehensiveEnhancedCategorization() {
        // These are the EXACT transactions from our CSV test, with backend categories
        let transactions = [
            Transaction(date: "2025-01-15", description: "CLAUDE AI SUBSCRIPTION", amount: -20.00, category: "Other"),
            Transaction(date: "2025-01-15", description: "ANTHROPIC BILLING", amount: -50.00, category: "Other"),
            Transaction(date: "2025-01-15", description: "OPENAI API CHARGES", amount: -75.00, category: "Other"),
            Transaction(date: "2025-01-15", description: "RIFLE COFFEE COMPANY", amount: -45.50, category: "Food & Dining"),
            Transaction(date: "2025-01-15", description: "PANERA BREAD #2351", amount: -12.75, category: "Other"),
            Transaction(date: "2025-01-15", description: "OXXO CONVENIENCE STORE", amount: -25.00, category: "Shopping"),
            Transaction(date: "2025-01-15", description: "CARNICERIA LA MICHOACANA", amount: -85.50, category: "Other"),
            Transaction(date: "2025-01-15", description: "NETFLIX SUBSCRIPTION", amount: -15.99, category: "Entertainment"),
            Transaction(date: "2025-01-15", description: "CRUNCHYROLL PREMIUM", amount: -9.99, category: "Insurance"),
            Transaction(date: "2025-01-15", description: "PAYPAL PAYMENT", amount: -35.00, category: "Payment"),
            Transaction(date: "2025-01-15", description: "CAPITAL ONE MOBILE TRANSFER", amount: 500.00, category: "Payment"),
            Transaction(date: "2025-01-15", description: "76 GAS STATION", amount: -65.00, category: "Transportation"),
            Transaction(date: "2025-01-15", description: "PARKING METER DOWNTOWN", amount: -8.50, category: "Transportation"),
            Transaction(date: "2025-01-15", description: "UBER TRIP 123456", amount: -25.50, category: "Transportation"),
            Transaction(date: "2025-01-15", description: "PY *TRANSPOR 8832", amount: -15.00, category: "Other"),
            Transaction(date: "2025-01-15", description: "AMAZON.COM PURCHASE", amount: -125.99, category: "Shopping"),
            Transaction(date: "2025-01-15", description: "GOOGLE *YOUTUBE TV", amount: -64.99, category: "Other"),
            Transaction(date: "2025-01-15", description: "BOOKING.COM HOTEL", amount: -350.00, category: "Travel")
        ]
        
        // Run through our enhanced categorization
        let result = categorizationService.categorizeTransactions(transactions)
        
        print("🔥 COMPREHENSIVE CATEGORIZATION RESULTS:")
        print("📊 Total transactions: \(result.totalTransactions)")
        print("✅ Categorized: \(result.categorizedCount)")
        print("❌ Uncategorized: \(result.uncategorizedCount)")
        print("📈 Success rate: \(String(format: "%.1f", result.successRate * 100))%")
        print("🎯 High confidence: \(result.highConfidenceCount)")
        
        print("\n🔍 DETAILED CATEGORIZATION ANALYSIS:")
        print("Backend → Frontend Enhancement:")
        
        // Compare backend vs frontend categorization
        var improvedCount = 0
        for (transaction, category, confidence) in result.categorizedTransactions {
            let originalCategory = transaction.category
            let newCategory = category.name
            
            if originalCategory == "Other" && newCategory != "Other" {
                improvedCount += 1
                print("✨ IMPROVED: \(transaction.description)")
                print("   Backend: \(originalCategory) → Frontend: \(newCategory) (confidence: \(String(format: "%.1f", confidence * 100))%)")
            } else if originalCategory != newCategory {
                print("🔄 CHANGED: \(transaction.description)")
                print("   Backend: \(originalCategory) → Frontend: \(newCategory) (confidence: \(String(format: "%.1f", confidence * 100))%)")
            } else {
                print("✓ CONFIRMED: \(transaction.description) → \(newCategory) (confidence: \(String(format: "%.1f", confidence * 100))%)")
            }
        }
        
        print("\n📊 IMPROVEMENT SUMMARY:")
        print("• Transactions improved from 'Other': \(improvedCount)")
        print("• Overall success rate: \(String(format: "%.1f", result.successRate * 100))%")
        
        // Print uncategorized transactions
        if !result.uncategorizedTransactions.isEmpty {
            print("\n⚠️ UNCATEGORIZED TRANSACTIONS:")
            for transaction in result.uncategorizedTransactions {
                print("   - \(transaction.description) (originally: \(transaction.category))")
            }
        }
        
        // Test that our enhanced rules worked for specific merchants
        let categorizedDescriptions = result.categorizedTransactions.map { $0.0.description }
        let categoryNames = result.categorizedTransactions.map { $0.1.name }
        
        // Enhanced AI & Tech Services
        XCTAssertTrue(categorizedDescriptions.contains { $0.contains("CLAUDE AI") })
        XCTAssertTrue(categorizedDescriptions.contains { $0.contains("ANTHROPIC") })
        XCTAssertTrue(categorizedDescriptions.contains { $0.contains("OPENAI") })
        
        // Enhanced Food & Coffee
        XCTAssertTrue(categorizedDescriptions.contains { $0.contains("RIFLE COFFEE") })
        XCTAssertTrue(categorizedDescriptions.contains { $0.contains("PANERA") })
        
        // Mexican Stores
        XCTAssertTrue(categorizedDescriptions.contains { $0.contains("OXXO") })
        XCTAssertTrue(categorizedDescriptions.contains { $0.contains("CARNICERIA") })
        
        // Enhanced Entertainment
        XCTAssertTrue(categorizedDescriptions.contains { $0.contains("CRUNCHYROLL") })
        XCTAssertTrue(categorizedDescriptions.contains { $0.contains("YOUTUBE") })
        
        // Enhanced Transportation
        XCTAssertTrue(categorizedDescriptions.contains { $0.contains("76") })
        XCTAssertTrue(categorizedDescriptions.contains { $0.contains("PARKING") })
        XCTAssertTrue(categorizedDescriptions.contains { $0.contains("PY") })
        
        // Our goal is to achieve 80%+ categorization rate
        XCTAssertGreaterThanOrEqual(result.successRate, 0.8, "Should achieve at least 80% categorization rate")
        
        // Most transactions should be high confidence (>70% of categorized)
        let expectedHighConfidence = Int(Double(result.categorizedCount) * 0.7)
        XCTAssertGreaterThanOrEqual(result.highConfidenceCount, expectedHighConfidence, "Should have high confidence for at least 70% of categorized transactions")
    }
}
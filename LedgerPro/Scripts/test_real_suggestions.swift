#!/usr/bin/env swift

// Test Real Transaction Suggestions
// This script tests the Rule Suggestions system with realistic transaction data

import Foundation

// Mock Transaction and Category structures for testing
struct TestTransaction {
    let id: String = UUID().uuidString
    let date: String
    let description: String
    let amount: Double
    let category: String
    let confidence: Double?
    
    var needsCategorization: Bool {
        return category == "Other" || 
               confidence == nil || 
               (confidence ?? 0.0) < 0.5
    }
}

struct TestCategoryService {
    static let foodDiningId = UUID(uuidString: "00000000-0000-0000-0000-000000000023")!
    static let transportationId = UUID(uuidString: "00000000-0000-0000-0000-000000000022")!
    static let shoppingId = UUID(uuidString: "00000000-0000-0000-0000-000000000031")!
}

// Create realistic test transaction data
let realTransactionData = [
    // Starbucks transactions (should generate suggestion)
    TestTransaction(date: "2024-12-01", description: "STARBUCKS STORE #12345 SEATTLE WA", amount: -5.47, category: "Other", confidence: nil),
    TestTransaction(date: "2024-12-03", description: "STARBUCKS STORE #67890 BELLEVUE WA", amount: -4.75, category: "Other", confidence: nil),
    TestTransaction(date: "2024-12-07", description: "STARBUCKS STORE #11111 REDMOND WA", amount: -6.25, category: "Other", confidence: nil),
    TestTransaction(date: "2024-12-10", description: "STARBUCKS STORE #22222 KIRKLAND WA", amount: -5.85, category: "Other", confidence: nil),
    
    // Amazon transactions (should generate suggestion)
    TestTransaction(date: "2024-12-02", description: "AMAZON.COM AMZN.COM/BILL WA", amount: -45.67, category: "Other", confidence: nil),
    TestTransaction(date: "2024-12-05", description: "AMAZON MKTP US AMZN.COM/BILL", amount: -89.12, category: "Other", confidence: nil),
    TestTransaction(date: "2024-12-08", description: "AMAZON.COM MARKETPLACE WA", amount: -25.34, category: "Other", confidence: nil),
    
    // Uber transactions (should generate suggestion) 
    TestTransaction(date: "2024-12-04", description: "UBER TRIP 123ABC HELP.UBER.COM", amount: -23.45, category: "Other", confidence: nil),
    TestTransaction(date: "2024-12-09", description: "UBER EATS 456DEF HELP.UBER.COM", amount: -18.90, category: "Other", confidence: nil),
    TestTransaction(date: "2024-12-12", description: "UBER 789GHI SAN FRANCISCO CA", amount: -31.25, category: "Other", confidence: nil),
    
    // Shell gas station (should generate suggestion)
    TestTransaction(date: "2024-12-06", description: "SHELL OIL 12345678 HOUSTON TX", amount: -45.67, category: "Other", confidence: nil),
    TestTransaction(date: "2024-12-11", description: "SHELL OIL 87654321 DALLAS TX", amount: -52.34, category: "Other", confidence: nil),
    TestTransaction(date: "2024-12-14", description: "SHELL OIL 11223344 AUSTIN TX", amount: -38.90, category: "Other", confidence: nil),
    
    // Low confidence transactions (should be included)
    TestTransaction(date: "2024-12-13", description: "NETFLIX.COM LOS GATOS CA", amount: -15.99, category: "Entertainment", confidence: 0.3),
    TestTransaction(date: "2024-12-15", description: "NETFLIX.COM LOS GATOS CA", amount: -15.99, category: "Entertainment", confidence: 0.2),
    TestTransaction(date: "2024-12-16", description: "NETFLIX.COM LOS GATOS CA", amount: -15.99, category: "Entertainment", confidence: 0.4),
    
    // Single transactions (should NOT generate suggestions)
    TestTransaction(date: "2024-12-17", description: "LOCAL COFFEE SHOP MAIN ST", amount: -4.50, category: "Other", confidence: nil),
    TestTransaction(date: "2024-12-18", description: "UNKNOWN MERCHANT XYZ123", amount: -25.00, category: "Other", confidence: nil),
    
    // Already categorized transactions (should be ignored)
    TestTransaction(date: "2024-12-19", description: "WALMART SUPERCENTER #1234", amount: -78.34, category: "Groceries", confidence: 0.8),
    TestTransaction(date: "2024-12-20", description: "TARGET STORE #5678", amount: -34.56, category: "Shopping", confidence: 0.9),
]

// Test merchant pattern extraction
func testMerchantExtraction() {
    print("🧪 Testing Merchant Pattern Extraction")
    print("=" * 50)
    
    let testCases = [
        "STARBUCKS STORE #12345 SEATTLE WA",
        "AMAZON.COM AMZN.COM/BILL WA",
        "UBER TRIP 123ABC HELP.UBER.COM",
        "SHELL OIL 12345678 HOUSTON TX",
        "NETFLIX.COM LOS GATOS CA",
        "TARGET 00012345 ANYTOWN US"
    ]
    
    for description in testCases {
        let pattern = extractMerchantPattern(from: description)
        print("✅ '\(description)' → '\(pattern)'")
    }
    print()
}

// Simple merchant pattern extraction (mimics the real implementation)
func extractMerchantPattern(from description: String) -> String {
    var cleaned = description.uppercased()
    
    // Remove common patterns
    let patternsToRemove = [
        #"\s+#\d+"#,           // Store numbers like "#1234"
        #"\s+\d{4,}"#,         // Long numbers
        #"\s+[A-Z]{2}$"#,      // State codes at end
        #"\.COM.*$"#           // .com and everything after
    ]
    
    for pattern in patternsToRemove {
        cleaned = cleaned.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
    }
    
    // Extract main merchant name (first 1-3 words)
    let words = cleaned.components(separatedBy: .whitespacesAndNewlines)
        .filter { !$0.isEmpty }
        .prefix(3)
    
    let merchantName = words.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Must be at least 3 characters and not too generic
    let genericTerms = ["PAYMENT", "TRANSFER", "DEPOSIT", "WITHDRAWAL", "FEE", "CHARGE"]
    
    if merchantName.count >= 3 && !genericTerms.contains(merchantName) {
        return merchantName
    }
    
    return ""
}

// Test suggestion generation logic
func testSuggestionGeneration() {
    print("🎯 Testing Suggestion Generation Logic")
    print("=" * 50)
    
    // Filter uncategorized transactions
    let uncategorizedTransactions = realTransactionData.filter { $0.needsCategorization }
    print("Total transactions: \(realTransactionData.count)")
    print("Uncategorized transactions: \(uncategorizedTransactions.count)")
    print()
    
    // Group by merchant pattern
    var merchantGroups: [String: [TestTransaction]] = [:]
    
    for transaction in uncategorizedTransactions {
        let merchantPattern = extractMerchantPattern(from: transaction.description)
        if !merchantPattern.isEmpty {
            merchantGroups[merchantPattern, default: []].append(transaction)
        }
    }
    
    print("Merchant groups found:")
    for (pattern, transactions) in merchantGroups.sorted(by: { $0.key < $1.key }) {
        print("  📍 \(pattern): \(transactions.count) transactions")
        for transaction in transactions.prefix(2) {
            print("    - \(transaction.description) (\(String(format: "%.2f", abs(transaction.amount))))")
        }
        if transactions.count > 2 {
            print("    - ... and \(transactions.count - 2) more")
        }
    }
    print()
    
    // Filter by minimum frequency (3+ transactions)
    let frequentMerchants = merchantGroups.filter { $0.value.count >= 3 }
    
    print("Merchants with 3+ transactions (will generate suggestions):")
    for (pattern, transactions) in frequentMerchants.sorted(by: { $0.key < $1.key }) {
        let averageAmount = transactions.map { $0.amount }.reduce(0, +) / Double(transactions.count)
        print("  ⭐ \(pattern): \(transactions.count) transactions, avg: $\(String(format: "%.2f", abs(averageAmount)))")
    }
    print()
    
    print("Expected suggestions count: \(frequentMerchants.count)")
}

// Test dismissed suggestions functionality
func testDismissedSuggestions() {
    print("🚫 Testing Dismissed Suggestions Logic")
    print("=" * 50)
    
    // Simulate dismissed suggestions
    let dismissedPatterns = ["STARBUCKS STORE", "NETFLIX"]
    print("Dismissed patterns: \(dismissedPatterns)")
    
    // Filter suggestions
    let allSuggestions = ["STARBUCKS STORE", "AMAZON", "UBER", "SHELL OIL", "NETFLIX"]
    let filteredSuggestions = allSuggestions.filter { !dismissedPatterns.contains($0) }
    
    print("All potential suggestions: \(allSuggestions)")
    print("After filtering dismissed: \(filteredSuggestions)")
    print()
}

// String multiplication helper
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

// Run all tests
print("🚀 Testing Rule Suggestions with Real Transaction Data")
print("=" * 70)
print()

testMerchantExtraction()
testSuggestionGeneration()
testDismissedSuggestions()

print("=" * 70)
print("✅ All tests completed!")
print()
print("Expected behavior in the app:")
print("1. Generate suggestions for STARBUCKS, AMAZON, UBER, SHELL OIL, NETFLIX")
print("2. Show confidence scores based on transaction consistency")
print("3. Suggest appropriate categories (Food, Shopping, Transportation, etc.)")
print("4. Persist dismissed suggestions across app launches")
print("5. Filter out dismissed patterns from future suggestions")
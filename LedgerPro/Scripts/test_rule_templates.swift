#!/usr/bin/env swift

// Test Rule Templates Script
// This script tests the commonRuleTemplates against real transaction descriptions

import Foundation

// Mock Transaction struct for testing
struct TestTransaction {
    let description: String
    let amount: Double
    
    var formattedDate: Date { Date() }
}

// Test data with real transaction descriptions
let testTransactions = [
    // Coffee shops
    TestTransaction(description: "STARBUCKS STORE #12345 SEATTLE WA", amount: -5.47),
    TestTransaction(description: "DUNKIN #123456 BOSTON MA", amount: -3.29),
    
    // Fast food
    TestTransaction(description: "MCDONALD'S F32123 CHICAGO IL", amount: -8.99),
    TestTransaction(description: "CHIPOTLE 2567 NEW YORK NY", amount: -12.45),
    TestTransaction(description: "SUBWAY 45678 LOS ANGELES CA", amount: -7.50),
    
    // Ride sharing
    TestTransaction(description: "UBER TRIP 123ABC SAN FRANCISCO", amount: -23.45),
    TestTransaction(description: "LYFT RIDE 789XYZ AUSTIN TX", amount: -18.90),
    
    // Online shopping
    TestTransaction(description: "AMAZON.COM AMZN.COM/BILL WA", amount: -45.67),
    TestTransaction(description: "AMAZON MKTP US AMZN.COM/BILL", amount: -89.12),
    TestTransaction(description: "TARGET.COM * MINNEAPOLIS MN", amount: -34.56),
    TestTransaction(description: "WAL-MART SUPERCENTER #1234", amount: -78.34),
    TestTransaction(description: "WALMART.COM 8009WALMART AR", amount: -25.67),
    
    // Grocery stores
    TestTransaction(description: "WHOLE FOODS MARKET WFM AUSTIN", amount: -56.78),
    TestTransaction(description: "KROGER #0123 FUEL CENTER", amount: -89.23),
    
    // Gas stations
    TestTransaction(description: "SHELL OIL 12345678 HOUSTON TX", amount: -45.67),
    TestTransaction(description: "EXXON MOBIL 87654321 DALLAS TX", amount: -52.34),
    TestTransaction(description: "BP#123456789 ATLANTA GA", amount: -38.90),
    TestTransaction(description: "CHEVRON 00123456 DENVER CO", amount: -49.12),
    
    // Streaming services
    TestTransaction(description: "NETFLIX.COM LOS GATOS CA", amount: -15.99),
    TestTransaction(description: "SPOTIFY USA NEW YORK NY", amount: -9.99),
    TestTransaction(description: "APPLE.COM/BILL ITUNES.COM", amount: -4.99),
    
    // Utilities
    TestTransaction(description: "PG&E ELECTRIC SAN FRANCISCO", amount: -127.45),
    TestTransaction(description: "CON ED CONSOLIDATED EDISON NY", amount: -89.67),
    TestTransaction(description: "COMCAST XFINITY PHILADELPHIA", amount: -79.99),
    TestTransaction(description: "VERIZON WIRELESS PAYMENT", amount: -85.00),
    TestTransaction(description: "AT&T MOBILITY ATLANTA GA", amount: -75.50),
    
    // Banking/payments
    TestTransaction(description: "CAPITAL ONE MOBILE PAYMENT", amount: 250.00),
    TestTransaction(description: "ONLINE PAYMENT THANK YOU", amount: 500.00),
    TestTransaction(description: "AUTOPAY PAYMENT RECEIVED", amount: 300.00),
    
    // Edge cases that shouldn't match
    TestTransaction(description: "LOCAL COFFEE SHOP MAIN ST", amount: -4.50),
    TestTransaction(description: "UNKNOWN MERCHANT XYZ123", amount: -25.00),
    TestTransaction(description: "CASH WITHDRAWAL ATM", amount: -40.00)
]

// Mock CategoryRule matching functions
extension TestTransaction {
    func matches(merchantContains: String?) -> Bool {
        guard let merchant = merchantContains else { return false }
        return description.localizedCaseInsensitiveContains(merchant)
    }
    
    func matches(regexPattern: String?) -> Bool {
        guard let pattern = regexPattern else { return false }
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let range = NSRange(location: 0, length: description.utf16.count)
            return regex.firstMatch(in: description, options: [], range: range) != nil
        } catch {
            return false
        }
    }
}

// Test function
func testRuleTemplates() {
    print("🧪 Testing Rule Templates with Real Transaction Descriptions\n")
    print("=" * 70)
    
    let templates: [(String, String?, String?)] = [
        // Coffee shops
        ("Starbucks", "STARBUCKS", nil),
        ("Dunkin Donuts", "DUNKIN", nil),
        
        // Fast food
        ("McDonald's", "MCDONALD", nil),
        ("Chipotle", "CHIPOTLE", nil),
        ("Subway", "SUBWAY", nil),
        
        // Ride sharing
        ("Uber", "UBER", nil),
        ("Lyft", "LYFT", nil),
        
        // Online shopping
        ("Amazon", nil, "AMAZON|AMZN"),
        ("Target", "TARGET", nil),
        ("Walmart", nil, "WAL-MART|WALMART"),
        
        // Grocery stores
        ("Whole Foods", "WHOLE FOODS", nil),
        ("Kroger", "KROGER", nil),
        
        // Gas stations
        ("Shell Gas", "SHELL", nil),
        ("Exxon Mobile", nil, "EXXON|MOBIL"),
        ("BP Gas", "BP", nil),
        
        // Streaming services
        ("Netflix", "NETFLIX", nil),
        ("Spotify", "SPOTIFY", nil),
        ("Apple Subscriptions", nil, "APPLE\\.COM|ITUNES"),
        
        // Utilities
        ("Electric Company", nil, "ELECTRIC|PG&E|CON ED|EDISON"),
        ("Internet/Cable", nil, "COMCAST|VERIZON|AT&T|SPECTRUM|XFINITY"),
        
        // Banking/finance
        ("Credit Card Payments", nil, "PAYMENT|AUTOPAY|ONLINE PMT")
    ]
    
    var totalMatches = 0
    var testedTemplates = 0
    
    for (templateName, merchantContains, regexPattern) in templates {
        print("\n📋 Testing Template: \(templateName)")
        print("-" * 50)
        
        var matches = 0
        
        for transaction in testTransactions {
            var matched = false
            
            if let merchant = merchantContains {
                matched = transaction.matches(merchantContains: merchant)
            } else if let regex = regexPattern {
                matched = transaction.matches(regexPattern: regex)
            }
            
            if matched {
                matches += 1
                print("✅ \(transaction.description) ($\(String(format: "%.2f", abs(transaction.amount))))")
            }
        }
        
        if matches == 0 {
            print("❌ No matches found")
        }
        
        print("📊 Total matches: \(matches)")
        totalMatches += matches
        testedTemplates += 1
    }
    
    print("\n" + "=" * 70)
    print("🎯 SUMMARY")
    print("=" * 70)
    print("Templates tested: \(testedTemplates)")
    print("Total transactions: \(testTransactions.count)")
    print("Total matches: \(totalMatches)")
    print("Match rate: \(String(format: "%.1f", Double(totalMatches) / Double(testTransactions.count) * 100))%")
    
    // Test edge cases
    print("\n🔍 EDGE CASE ANALYSIS")
    print("-" * 50)
    
    let unmatchedTransactions = testTransactions.filter { transaction in
        !templates.contains { (_, merchantContains, regexPattern) in
            if let merchant = merchantContains {
                return transaction.matches(merchantContains: merchant)
            } else if let regex = regexPattern {
                return transaction.matches(regexPattern: regex)
            }
            return false
        }
    }
    
    print("Unmatched transactions (\(unmatchedTransactions.count)):")
    for transaction in unmatchedTransactions {
        print("⚪ \(transaction.description)")
    }
    
    if unmatchedTransactions.count > 0 {
        print("\n💡 These transactions would fall back to the default categorization system.")
    }
}

// String multiplication helper
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

// Run the test
testRuleTemplates()
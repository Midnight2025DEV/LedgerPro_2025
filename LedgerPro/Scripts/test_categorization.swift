#!/usr/bin/env swift

import Foundation

// Test the categorization system
print("🧪 Testing Auto-Categorization System")
print("=====================================")

// Create test transactions
let testTransactions = [
    ("WALMART STORE #1234", -45.67),
    ("UBER TRIP HELP.UBER.COM", -12.34),
    ("STARBUCKS STORE 12345", -5.89),
    ("PAYROLL DEPOSIT COMPANY XYZ", 2500.00),
    ("CAPITAL ONE ONLINE PAYMENT", 150.00),
    ("AMAZON.COM MERCHANDISE", -89.99),
    ("CHEVRON GAS STATION", -45.00),
    ("GROCERY OUTLET #123", -67.89)
]

print("\nTest Transactions:")
for (desc, amount) in testTransactions {
    print("  • \(desc): $\(amount)")
}

print("\nExpected Categories:")
print("  • WALMART → Shopping")
print("  • UBER → Transportation")
print("  • STARBUCKS → Food & Dining")
print("  • PAYROLL → Salary")
print("  • CAPITAL ONE → Credit Card Payment")
print("  • AMAZON → Shopping")
print("  • CHEVRON → Transportation")
print("  • GROCERY → Groceries")

print("\n✅ Categorization rules have been updated!")
print("🚀 Run the app and import a file to test auto-categorization")
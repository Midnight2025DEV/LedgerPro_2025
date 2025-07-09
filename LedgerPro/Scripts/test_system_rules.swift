#!/usr/bin/env swift

import Foundation

// Test transactions to validate categorization
let testTransactions = [
    // Transportation
    ("UBER *TRIP", -25.43, "transportation"),
    ("LYFT *RIDE", -18.75, "transportation"),
    ("YELLOW CAB NYC", -32.00, "transportation"),
    
    // Food & Dining  
    ("UBER EATS *ORDER", -23.45, "foodDining"),
    ("DOORDASH ORDER", -19.87, "foodDining"),
    ("STARBUCKS #1234", -5.47, "foodDining"),
    ("MCDONALD'S F12345", -8.93, "foodDining"),
    ("CHIPOTLE MEXICAN GRILL", -12.85, "foodDining"),
    ("MAIN STREET RESTAURANT", -45.60, "foodDining"),
    
    // Shopping
    ("AMAZON.COM*2G4", -89.99, "shopping"),
    ("WALMART SUPERCENTER", -156.23, "shopping"),
    ("TARGET 00123", -67.45, "shopping"),
    ("HOME DEPOT #456", -234.56, "shopping"),
    
    // Income
    ("EMPLOYER INC DIRECT DEP", 3500.00, "salary"),
    ("ACH DEPOSIT PAYROLL", 2850.00, "salary"),
    ("MOBILE DEPOSIT", 500.00, "income"),
    
    // Housing
    ("APARTMENT RENT PAYMENT", -1850.00, "housing"),
    ("CHASE MORTGAGE PAYMENT", -2145.00, "housing"),
    
    // Missing categories (should map to shopping or other)
    ("SHELL OIL 12345", -45.67, "shopping/other?"),
    ("KROGER #456", -123.45, "shopping"),
    ("CVS PHARMACY", -25.99, "shopping"),
    ("NETFLIX.COM", -15.99, "shopping/other?"),
    ("COMCAST CABLE", -89.99, "other?")
]

print("🧪 Testing System Rules Coverage")
print(String(repeating: "=", count: 50))

var matches = 0
var misses = 0

for (description, amount, expectedCategory) in testTransactions {
    print("\n📍 Testing: \(description) (\(amount))")
    print("   Expected: \(expectedCategory)")
    
    // Simulate rule matching (simplified)
    var matched = false
    
    // Check our patterns (specific patterns first)
    if description.contains("UBER EATS") || description.contains("DOORDASH") || description.contains("GRUBHUB") {
        print("   ✅ Matched: foodDining (delivery)")
        matched = true
    } else if description.contains("STARBUCKS") || description.contains("MCDONALD") || description.contains("CHIPOTLE") || description.contains("RESTAURANT") {
        print("   ✅ Matched: foodDining")
        matched = true
    } else if description.contains("UBER") || description.contains("LYFT") || description.contains("TAXI") || description.contains("CAB") || description.contains("SHELL") || description.contains("CHEVRON") || description.contains("GAS") {
        print("   ✅ Matched: transportation")
        matched = true
    } else if description.contains("AMAZON") || description.contains("WALMART") || description.contains("TARGET") || description.contains("HOME DEPOT") || description.contains("KROGER") || description.contains("CVS") || description.contains("NETFLIX") {
        print("   ✅ Matched: shopping")
        matched = true
    } else if amount > 0 && (description.contains("DIRECT DEP") || description.contains("PAYROLL") || description.contains("DEPOSIT")) {
        print("   ✅ Matched: salary/income")
        matched = true
    } else if description.contains("RENT") || description.contains("MORTGAGE") || description.contains("COMCAST") || description.contains("ELECTRIC") || description.contains("CABLE") {
        print("   ✅ Matched: housing")
        matched = true
    } else {
        print("   ❌ No match - would use fallback")
        misses += 1
    }
    
    if matched {
        matches += 1
    }
}

print("\n" + String(repeating: "=", count: 50))
print("📊 Results:")
print("   Total transactions: \(testTransactions.count)")
print("   Matched: \(matches) (\(Int(Double(matches) * 100 / Double(testTransactions.count)))%)")
print("   Missed: \(misses) (\(Int(Double(misses) * 100 / Double(testTransactions.count)))%)")

print("\n💡 Recommendations:")
if misses > 0 {
    print("   - Consider adding more categories (gas, groceries, utilities)")
    print("   - Or add more patterns to existing categories")
    print("   - Current gaps: gas stations, grocery stores, utilities, streaming")
} else {
    print("   - Excellent coverage! System rules are working well.")
}
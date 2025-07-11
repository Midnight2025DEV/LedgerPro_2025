// Test script to verify forex data flow
print("🔍 Checking Transaction model for forex support...")

// Check if Transaction has forex fields
let transactionPath = "Sources/LedgerPro/Models/Transaction.swift"
if let content = try? String(contentsOfFile: transactionPath) {
    let hasOriginalCurrency = content.contains("originalCurrency")
    let hasOriginalAmount = content.contains("originalAmount")
    let hasExchangeRate = content.contains("exchangeRate")
    
    print("✅ Transaction.swift forex fields:")
    print("  - originalCurrency: \(hasOriginalCurrency)")
    print("  - originalAmount: \(hasOriginalAmount)")
    print("  - exchangeRate: \(hasExchangeRate)")
} else {
    print("❌ Could not read Transaction.swift")
}

// Check TransactionProcessor
let processorPath = "Sources/LedgerPro/Services/TransactionProcessor.swift"
if let content = try? String(contentsOfFile: processorPath) {
    let handlesForex = content.contains("originalCurrency") || content.contains("has_forex")
    print("\n✅ TransactionProcessor forex handling: \(handlesForex)")
    
    // Find the line where we process MCP results
    let lines = content.split(separator: "\n")
    for (i, line) in lines.enumerated() {
        if line.contains("amount") && line.contains("=") {
            print("  Line \(i+1): \(line.trimmingCharacters(in: .whitespaces))")
        }
    }
} else {
    print("❌ Could not read TransactionProcessor.swift")
}

print("\n🎯 Next: Need to update TransactionProcessor to handle forex fields from MCP")
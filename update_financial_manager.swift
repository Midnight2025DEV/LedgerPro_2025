// In FinancialDataManager.swift, replace the updateTransactionCategory method (around line 454) with:

func updateTransactionCategory(transactionId: String, newCategory: String) {
    guard let index = transactions.firstIndex(where: { $0.id == transactionId }) else {
        print("❌ Transaction not found: \(transactionId)")
        return
    }
    
    let oldCategory = transactions[index].category
    let originalTransaction = transactions[index]
    
    // Create new transaction with updated category
    let updatedTransaction = Transaction(
        id: originalTransaction.id,
        date: originalTransaction.date,
        description: originalTransaction.description,
        amount: originalTransaction.amount,
        category: newCategory,
        confidence: originalTransaction.confidence,
        jobId: originalTransaction.jobId,
        accountId: originalTransaction.accountId,
        rawData: originalTransaction.rawData,
        originalAmount: originalTransaction.originalAmount,
        originalCurrency: originalTransaction.originalCurrency,
        exchangeRate: originalTransaction.exchangeRate,
        hasForex: originalTransaction.hasForex
    )
    
    // Update the transaction in the array
    transactions[index] = updatedTransaction
    
    // NEW: Learn from this categorization
    Task {
        await learnFromCategorization(
            transaction: updatedTransaction,
            oldCategory: oldCategory,
            newCategory: newCategory
        )
    }
    
    // Update summary and save
    updateSummary()
    saveData()
    
    print("✅ Updated transaction category: \(oldCategory) → \(newCategory)")
}

// NEW: Add this method after updateTransactionCategory
@MainActor
private func learnFromCategorization(transaction: Transaction, oldCategory: String, newCategory: String) async {
    // Get the merchant name from the transaction
    let merchantName = extractMerchantName(from: transaction.description)
    
    // Get CategoryService and RuleStorageService instances
    let categoryService = CategoryService.shared
    let ruleStorage = RuleStorageService.shared
    
    // Check if there was an existing rule that suggested the old category
    let (suggestedCategory, confidence) = categoryService.suggestCategory(for: transaction)
    
    if let suggestedCategory = suggestedCategory {
        // There was a suggestion
        if suggestedCategory.name == newCategory {
            // User confirmed the suggestion - increase confidence
            if var matchingRule = findMatchingRule(for: transaction) {
                matchingRule.recordMatch()
                ruleStorage.updateRule(matchingRule)
                print("✅ Rule confidence increased for: \(merchantName)")
            }
        } else if suggestedCategory.name == oldCategory {
            // User corrected the suggestion
            if var matchingRule = findMatchingRule(for: transaction) {
                matchingRule.recordCorrection()
                ruleStorage.updateRule(matchingRule)
                print("📝 Rule confidence decreased for: \(merchantName)")
            }
        }
    }
    
    // Create a new rule if none exists for this merchant and it's a meaningful pattern
    if \!hasRuleForMerchant(merchantName) && shouldCreateRule(for: merchantName, transaction: transaction) {
        await createMerchantRule(
            merchantName: merchantName,
            category: newCategory,
            transaction: transaction
        )
    }
}

// NEW: Helper to extract clean merchant name
private func extractMerchantName(from description: String) -> String {
    // Use similar logic to Transaction's displayMerchantName
    if description.contains("UBER") {
        return "UBER"
    } else if description.contains("WAL-MART") || description.contains("WALMART") {
        return "WALMART"
    } else if description.contains("CHEVRON") {
        return "CHEVRON"
    } else if description.contains("NETFLIX") {
        return "NETFLIX"
    } else if description.contains("AMAZON") {
        return "AMAZON"
    } else if description.contains("STARBUCKS") {
        return "STARBUCKS"
    }
    
    // For other merchants, take first 1-3 meaningful words
    let words = description.components(separatedBy: .whitespaces)
        .filter { \!$0.isEmpty && $0.count > 2 }
        .prefix(2)
    
    return words.joined(separator: " ").uppercased()
}

// NEW: Find a rule that matches this transaction
private func findMatchingRule(for transaction: Transaction) -> CategoryRule? {
    let allRules = RuleStorageService.shared.allRules
    
    return allRules.first { rule in
        rule.matches(transaction: transaction)
    }
}

// NEW: Check if we already have a rule for this merchant
private func hasRuleForMerchant(_ merchantName: String) -> Bool {
    let allRules = RuleStorageService.shared.allRules
    
    return allRules.contains { rule in
        if let exact = rule.merchantExact {
            return exact.localizedCaseInsensitiveCompare(merchantName) == .orderedSame
        }
        if let contains = rule.merchantContains {
            return merchantName.localizedCaseInsensitiveContains(contains)
        }
        return false
    }
}

// NEW: Determine if we should create a rule for this merchant
private func shouldCreateRule(for merchantName: String, transaction: Transaction) -> Bool {
    // Don't create rules for very generic or short merchant names
    if merchantName.count < 3 || merchantName.contains("UNKNOWN") {
        return false
    }
    
    // Don't create rules for one-time transactions (transfers, payments, etc.)
    let description = transaction.description.lowercased()
    let skipPatterns = ["payment", "transfer", "xfer", "pymt", "deposit", "withdrawal", "atm"]
    
    for pattern in skipPatterns {
        if description.contains(pattern) {
            return false
        }
    }
    
    return true
}

// NEW: Create a merchant-specific rule from user categorization
private func createMerchantRule(merchantName: String, category: String, transaction: Transaction) async {
    // Find the category object
    guard let categoryObj = CategoryService.shared.category(by: UUID()) ?? CategoryService.shared.categories.first(where: { $0.name == category }) else {
        print("❌ Category not found: \(category)")
        return
    }
    
    // Create a merchant-based rule
    var newRule = CategoryRule(
        categoryId: categoryObj.id,
        ruleName: "Auto: \(merchantName)"
    )
    
    // Set rule properties
    newRule.merchantContains = merchantName
    newRule.amountSign = transaction.amount < 0 ? .negative : .positive
    newRule.priority = 75 // User-generated rules get medium priority
    newRule.confidence = 0.75 // Start with reasonable confidence
    newRule.isActive = true
    
    // Save the rule
    RuleStorageService.shared.saveRule(newRule)
    print("🎯 Created new merchant rule: \(merchantName) → \(category)")
}
EOF < /dev/null
import Foundation

@MainActor
class ImportCategorizationService {
    private let categoryService = CategoryService.shared
    private let confidenceThreshold = 0.5 // Lowered for better categorization
    
    func categorizeTransactions(_ transactions: [Transaction]) async -> ImportResult {
        AppLogger.shared.info("🔄 ImportCategorizationService: Starting categorization of \(transactions.count) transactions")
        
        // Ensure categories are loaded
        if categoryService.categories.isEmpty {
            AppLogger.shared.warning("⚠️ No categories loaded! Force loading categories...")
            await categoryService.forceReinitializeCategories()
            
            // Wait a moment for categories to fully load
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        AppLogger.shared.info("📊 Categories available: \(categoryService.categories.count)")
        
        var categorized: [(Transaction, Category, Double)] = []
        var uncategorized: [Transaction] = []
        var highConfidenceCount = 0
        
        for (index, transaction) in transactions.enumerated() {
            // Log first few transactions for debugging
            if index < 3 {
                AppLogger.shared.info("🔍 Processing transaction \(index + 1): '\(transaction.description)'")
            }
            
            let (category, confidence) = categoryService.suggestCategory(for: transaction)
            
            if index < 3 {
                AppLogger.shared.info("📤 Suggestion: \(category?.name ?? "nil") (confidence: \(String(format: "%.2f", confidence)))")
            }
            
            if let category = category, confidence >= confidenceThreshold {
                // Create updated transaction with suggested category
                let updatedTransaction = Transaction(
                    id: transaction.id,
                    date: transaction.date,
                    description: transaction.description,
                    amount: transaction.amount,
                    category: category.name,
                    confidence: confidence,
                    jobId: transaction.jobId,
                    accountId: transaction.accountId,
                    rawData: transaction.rawData,
                    originalAmount: transaction.originalAmount,
                    originalCurrency: transaction.originalCurrency,
                    exchangeRate: transaction.exchangeRate,
                    wasAutoCategorized: true,
                    categorizationMethod: "rule_based"
                )
                
                categorized.append((updatedTransaction, category, confidence))
                
                if confidence >= 0.9 {
                    highConfidenceCount += 1
                }
            } else {
                uncategorized.append(transaction)
            }
        }
        
        let result = ImportResult(
            totalTransactions: transactions.count,
            categorizedCount: categorized.count,
            highConfidenceCount: highConfidenceCount,
            uncategorizedCount: uncategorized.count,
            categorizedTransactions: categorized,
            uncategorizedTransactions: uncategorized
        )
        
        AppLogger.shared.info("✅ Categorization complete: \(result.categorizedCount)/\(result.totalTransactions) categorized (\(Int(result.successRate * 100))%)")
        
        return result
    }
}
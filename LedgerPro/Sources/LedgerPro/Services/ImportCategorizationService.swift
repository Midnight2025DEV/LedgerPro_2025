import Foundation

@MainActor
class ImportCategorizationService {
    private let categoryService = CategoryService.shared
    private let confidenceThreshold = 0.7 // Only auto-apply if confidence > 70%
    
    func categorizeTransactions(_ transactions: [Transaction]) -> ImportResult {
        var categorized: [(Transaction, Category, Double)] = []
        var uncategorized: [Transaction] = []
        var highConfidenceCount = 0
        
        for transaction in transactions {
            let (category, confidence) = categoryService.suggestCategory(for: transaction)
            
            if let category = category, confidence >= confidenceThreshold {
                // Create updated transaction with suggested category
                var updatedTransaction = transaction
                updatedTransaction = Transaction(
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
                    hasForex: transaction.hasForex,
                    wasAutoCategorized: true,
                    categorizationMethod: "merchant_rule"
                )
                
                categorized.append((updatedTransaction, category, confidence))
                
                if confidence >= 0.9 {
                    highConfidenceCount += 1
                }
            } else {
                uncategorized.append(transaction)
            }
        }
        
        return ImportResult(
            totalTransactions: transactions.count,
            categorizedCount: categorized.count,
            highConfidenceCount: highConfidenceCount,
            uncategorizedCount: uncategorized.count,
            categorizedTransactions: categorized,
            uncategorizedTransactions: uncategorized
        )
    }
}
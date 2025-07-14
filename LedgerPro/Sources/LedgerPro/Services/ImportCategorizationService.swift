import Foundation

@MainActor
class ImportCategorizationService {
    private let categoryService = CategoryService.shared
    private let merchantCategorizer = MerchantCategorizer.shared
    private let confidenceThreshold = 0.7 // Only auto-apply if confidence > 70%
    
    func categorizeTransactions(_ transactions: [Transaction]) -> ImportResult {
        var categorized: [(Transaction, Category, Double)] = []
        var uncategorized: [Transaction] = []
        var highConfidenceCount = 0
        
        for transaction in transactions {
            // Try enhanced merchant categorization first
            let categorizationResult = merchantCategorizer.categorize(transaction: transaction)
            
            // Determine the method string based on the source
            let method: String
            switch categorizationResult.source {
            case .merchantDatabase:
                method = "merchant_database"
            case .fallbackRules:
                method = "fallback_rules"
            case .userRule:
                method = "user_rule"
            case .unknown:
                method = "unknown"
            }
            
            if categorizationResult.confidence >= confidenceThreshold {
                // Create updated transaction with enhanced categorization
                var updatedTransaction = transaction
                updatedTransaction = Transaction(
                    id: transaction.id,
                    date: transaction.date,
                    description: transaction.description,
                    amount: transaction.amount,
                    category: categorizationResult.category.name,
                    confidence: categorizationResult.confidence,
                    jobId: transaction.jobId,
                    accountId: transaction.accountId,
                    rawData: addMerchantMetadata(to: transaction.rawData, result: categorizationResult),
                    originalAmount: transaction.originalAmount,
                    originalCurrency: transaction.originalCurrency,
                    exchangeRate: transaction.exchangeRate,
                    hasForex: transaction.hasForex,
                    wasAutoCategorized: true,
                    categorizationMethod: method
                )
                
                categorized.append((updatedTransaction, categorizationResult.category, categorizationResult.confidence))
                
                if categorizationResult.confidence >= 0.9 {
                    highConfidenceCount += 1
                }
            } else {
                // Fallback to legacy categorization for low-confidence merchant matches
                let (legacyCategory, legacyConfidence) = categoryService.suggestCategory(for: transaction)
                
                if let category = legacyCategory, legacyConfidence >= confidenceThreshold {
                    var updatedTransaction = transaction
                    updatedTransaction = Transaction(
                        id: transaction.id,
                        date: transaction.date,
                        description: transaction.description,
                        amount: transaction.amount,
                        category: category.name,
                        confidence: legacyConfidence,
                        jobId: transaction.jobId,
                        accountId: transaction.accountId,
                        rawData: transaction.rawData,
                        originalAmount: transaction.originalAmount,
                        originalCurrency: transaction.originalCurrency,
                        exchangeRate: transaction.exchangeRate,
                        hasForex: transaction.hasForex,
                        wasAutoCategorized: true,
                        categorizationMethod: "legacy_rules"
                    )
                    
                    categorized.append((updatedTransaction, category, legacyConfidence))
                    
                    if legacyConfidence >= 0.9 {
                        highConfidenceCount += 1
                    }
                } else {
                    uncategorized.append(transaction)
                }
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
    
    /// Add merchant metadata to transaction's raw data
    private func addMerchantMetadata(to rawData: [String: String]?, result: MerchantCategorizer.CategorizationResult) -> [String: String] {
        var metadata = rawData ?? [:]
        
        // Add categorization info
        metadata["categorization_source"] = result.source.description
        metadata["categorization_confidence"] = String(result.confidence)
        metadata["categorization_reasoning"] = result.reasoning
        
        // Add merchant info if available
        if let merchantMatch = result.merchantMatch {
            metadata["merchant_id"] = merchantMatch.merchant.id
            metadata["merchant_name"] = merchantMatch.merchant.canonicalName
            metadata["merchant_type"] = merchantMatch.merchant.merchantType.rawValue
            metadata["match_type"] = merchantMatch.matchType.rawValue
            metadata["matched_pattern"] = merchantMatch.matchedPattern
            
            if merchantMatch.merchant.isSubscription {
                metadata["is_subscription"] = "true"
            }
            
            if let website = merchantMatch.merchant.metadata.website {
                metadata["merchant_website"] = website
            }
            
            if let color = merchantMatch.merchant.metadata.color {
                metadata["brand_color"] = color
            }
        }
        
        return metadata
    }
}

// MARK: - Extensions

private extension MerchantCategorizer.CategorizationResult.Source {
    var description: String {
        switch self {
        case .merchantDatabase: return "merchant_database"
        case .fallbackRules: return "fallback_rules"
        case .userRule: return "user_rule"
        case .unknown: return "unknown"
        }
    }
}
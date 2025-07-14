import Foundation

/// Enhanced merchant categorizer that uses the merchant database
@MainActor
class MerchantCategorizer: ObservableObject {
    static let shared = MerchantCategorizer()
    
    @Published private(set) var stats = CategorizationStats()
    
    private let merchantDatabase = MerchantDatabase.shared
    private let fallbackCategorizer = BasicTransactionCategorizer()
    
    struct CategorizationStats {
        var totalProcessed: Int = 0
        var databaseMatches: Int = 0
        var fallbackMatches: Int = 0
        var uncategorized: Int = 0
        
        var databaseMatchRate: Double {
            guard totalProcessed > 0 else { return 0 }
            return Double(databaseMatches) / Double(totalProcessed)
        }
        
        var overallSuccessRate: Double {
            guard totalProcessed > 0 else { return 0 }
            return Double(databaseMatches + fallbackMatches) / Double(totalProcessed)
        }
    }
    
    struct CategorizationResult {
        let category: Category
        let confidence: Double
        let source: Source
        let merchantMatch: MerchantMatch?
        let reasoning: String
        
        enum Source {
            case merchantDatabase
            case fallbackRules
            case userRule
            case unknown
        }
    }
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Enhanced categorization using merchant database + fallback rules
    func categorize(transaction: Transaction) -> CategorizationResult {
        stats.totalProcessed += 1
        
        // 1. Try merchant database first
        if let merchantMatch = merchantDatabase.findMerchant(for: transaction.description) {
            stats.databaseMatches += 1
            
            return CategorizationResult(
                category: merchantMatch.merchant.category,
                confidence: merchantMatch.confidence,
                source: .merchantDatabase,
                merchantMatch: merchantMatch,
                reasoning: "Matched '\(merchantMatch.merchant.canonicalName)' via \(merchantMatch.matchType.rawValue.lowercased())"
            )
        }
        
        // 2. Fall back to rule-based categorization
        if let ruleResult = fallbackCategorizer.categorize(description: transaction.description, amount: transaction.amount) {
            stats.fallbackMatches += 1
            
            return CategorizationResult(
                category: ruleResult.category,
                confidence: ruleResult.confidence,
                source: .fallbackRules,
                merchantMatch: nil,
                reasoning: "Matched pattern: \(ruleResult.matchedPattern ?? "keyword")"
            )
        }
        
        // 3. Default to Other with low confidence
        stats.uncategorized += 1
        
        // Use safe category retrieval with fallback
        let fallbackCategory = Category.systemCategory(id: Category.systemCategoryIds.other) ?? 
                              Category(name: "Other", icon: "questionmark.circle", color: "#8E8E93")
        
        return CategorizationResult(
            category: fallbackCategory,
            confidence: 0.1,
            source: .unknown,
            merchantMatch: nil,
            reasoning: "No matching patterns found"
        )
    }
    
    /// Batch categorize multiple transactions
    func categorize(transactions: [Transaction]) -> [Transaction] {
        return transactions.map { transaction in
            let result = categorize(transaction: transaction)
            
            // Prepare rawData with merchant info if available
            var enhancedRawData = transaction.rawData ?? [:]
            if let merchantMatch = result.merchantMatch {
                enhancedRawData["merchant_id"] = merchantMatch.merchant.id
                enhancedRawData["merchant_name"] = merchantMatch.merchant.canonicalName
                enhancedRawData["match_type"] = merchantMatch.matchType.rawValue
                enhancedRawData["categorization_source"] = result.source.description
            }
            
            // Create updated transaction with new category
            let updatedTransaction = Transaction(
                id: transaction.id,
                date: transaction.date,
                description: transaction.description,
                amount: transaction.amount,
                category: result.category.name,
                confidence: result.confidence,
                jobId: transaction.jobId,
                accountId: transaction.accountId,
                rawData: enhancedRawData,
                originalAmount: transaction.originalAmount,
                originalCurrency: transaction.originalCurrency,
                exchangeRate: transaction.exchangeRate,
                hasForex: transaction.hasForex,
                wasAutoCategorized: transaction.wasAutoCategorized,
                categorizationMethod: transaction.categorizationMethod
            )
            
            return updatedTransaction
        }
    }
    
    /// Get merchant suggestions for a description
    func getMerchantSuggestions(for description: String, limit: Int = 5) -> [MerchantMatch] {
        // This could be expanded to return multiple matches with different confidence levels
        if let match = merchantDatabase.findMerchant(for: description) {
            return [match]
        }
        return []
    }
    
    /// Get all merchants for a category
    func getMerchants(for category: Category) -> [Merchant] {
        return merchantDatabase.merchants(for: category)
    }
    
    /// Add a custom merchant to the database
    func addCustomMerchant(
        name: String,
        category: Category,
        aliases: [String] = [],
        patterns: [String] = [],
        isSubscription: Bool = false
    ) {
        let merchant = Merchant(
            id: "custom_\(UUID().uuidString)",
            canonicalName: name,
            category: category,
            subcategory: "Custom",
            aliases: aliases,
            patterns: patterns,
            isSubscription: isSubscription,
            merchantType: .retail, // Default type
            commonAmounts: nil,
            metadata: MerchantMetadata(
                website: nil,
                logo: nil,
                color: nil,
                countryOrigin: nil,
                tags: ["custom", "user-defined"]
            )
        )
        
        merchantDatabase.addCustomMerchant(merchant)
        AppLogger.shared.info("Added custom merchant: \(name) -> \(category.name)")
    }
    
    /// Reset statistics
    func resetStats() {
        stats = CategorizationStats()
    }
    
    /// Get detailed categorization report
    func getCategorizationReport() -> String {
        return """
        📊 Merchant Categorization Report
        ================================
        
        Total Processed: \(stats.totalProcessed)
        Database Matches: \(stats.databaseMatches) (\(String(format: "%.1f", stats.databaseMatchRate * 100))%)
        Fallback Matches: \(stats.fallbackMatches) (\(String(format: "%.1f", Double(stats.fallbackMatches) / Double(max(stats.totalProcessed, 1)) * 100))%)
        Uncategorized: \(stats.uncategorized) (\(String(format: "%.1f", Double(stats.uncategorized) / Double(max(stats.totalProcessed, 1)) * 100))%)
        
        Overall Success Rate: \(String(format: "%.1f", stats.overallSuccessRate * 100))%
        """
    }
}

// MARK: - Supporting Types

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

/// Fallback categorizer for when merchant database doesn't have a match
private class BasicTransactionCategorizer {
    
    struct RuleResult {
        let category: Category
        let confidence: Double
        let matchedPattern: String?
    }
    
    // Helper function to safely get category with fallback
    private func safeCategory(id: UUID, fallbackName: String, fallbackIcon: String, fallbackColor: String) -> Category {
        return Category.systemCategory(id: id) ?? 
               Category(name: fallbackName, icon: fallbackIcon, color: fallbackColor)
    }
    
    private lazy var categoryRules: [String: (category: Category, patterns: [String], confidence: Double)] = [
        "food": (safeCategory(id: Category.systemCategoryIds.foodDining, fallbackName: "Food & Dining", fallbackIcon: "fork.knife", fallbackColor: "#34C759"), ["restaurant", "cafe", "coffee", "pizza", "burger", "deli", "bakery", "bar", "grill"], 0.8),
        "gas": (safeCategory(id: Category.systemCategoryIds.transportation, fallbackName: "Transportation", fallbackIcon: "car.fill", fallbackColor: "#007AFF"), ["shell", "exxon", "bp", "chevron", "mobil", "gas", "fuel", "station"], 0.9),
        "grocery": (safeCategory(id: Category.systemCategoryIds.groceries, fallbackName: "Groceries", fallbackIcon: "cart.fill", fallbackColor: "#FFCC00"), ["market", "grocery", "food", "supermarket", "whole foods", "trader joe"], 0.85),
        "shopping": (safeCategory(id: Category.systemCategoryIds.shopping, fallbackName: "Shopping", fallbackIcon: "bag.fill", fallbackColor: "#AF52DE"), ["store", "shop", "retail", "mall", "outlet", "dept"], 0.7),
        "utilities": (safeCategory(id: Category.systemCategoryIds.utilities, fallbackName: "Utilities", fallbackIcon: "bolt.fill", fallbackColor: "#FF3B30"), ["electric", "water", "gas", "utility", "power", "energy"], 0.9),
        "entertainment": (safeCategory(id: Category.systemCategoryIds.entertainment, fallbackName: "Entertainment", fallbackIcon: "tv.fill", fallbackColor: "#FF2D92"), ["movie", "theater", "cinema", "game", "entertainment", "music"], 0.8),
        "healthcare": (safeCategory(id: Category.systemCategoryIds.healthcare, fallbackName: "Healthcare", fallbackIcon: "cross.fill", fallbackColor: "#00C7BE"), ["hospital", "clinic", "medical", "doctor", "pharmacy", "health"], 0.85),
        "transport": (safeCategory(id: Category.systemCategoryIds.transportation, fallbackName: "Transportation", fallbackIcon: "car.fill", fallbackColor: "#007AFF"), ["taxi", "uber", "lyft", "bus", "train", "metro", "parking"], 0.8),
        "financial": (safeCategory(id: Category.systemCategoryIds.other, fallbackName: "Other", fallbackIcon: "questionmark.circle", fallbackColor: "#8E8E93"), ["bank", "atm", "fee", "interest", "loan", "credit", "transfer"], 0.9)
    ]
    
    func categorize(description: String, amount: Double) -> RuleResult? {
        let lowercaseDesc = description.lowercased()
        
        var bestMatch: RuleResult?
        var bestScore = 0.0
        
        for (_, rule) in categoryRules {
            for pattern in rule.patterns {
                if lowercaseDesc.contains(pattern) {
                    let score = rule.confidence * (Double(pattern.count) / Double(description.count))
                    if score > bestScore {
                        bestScore = score
                        bestMatch = RuleResult(
                            category: rule.category,
                            confidence: rule.confidence,
                            matchedPattern: pattern
                        )
                    }
                }
            }
        }
        
        return bestMatch
    }
}
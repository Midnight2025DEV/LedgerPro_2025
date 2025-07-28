import Foundation

/// A suggested rule based on transaction analysis
struct RuleSuggestion: Identifiable, Hashable {
    let id: UUID = UUID()
    let merchantPattern: String
    let transactionCount: Int
    let suggestedCategory: UUID
    let averageAmount: Decimal
    let exampleTransactions: [Transaction]
    
    /// Confidence score for this suggestion (0.0 to 1.0)
    var confidence: Double {
        let countScore = min(Double(transactionCount) / 10.0, 1.0) // More transactions = higher confidence
        let consistencyScore = exampleTransactions.isEmpty ? 0.0 : 
            (1.0 - (standardDeviation / Double(truncating: averageAmount as NSNumber)))
        return (countScore * 0.7 + max(0.0, min(1.0, consistencyScore)) * 0.3)
    }
    
    /// Standard deviation of transaction amounts for consistency measurement
    private var standardDeviation: Double {
        guard exampleTransactions.count > 1 else { return 0.0 }
        
        let amounts = exampleTransactions.map { abs($0.amount) }
        let mean = amounts.reduce(0, +) / Double(amounts.count)
        let variance = amounts.map { pow($0 - mean, 2) }.reduce(0, +) / Double(amounts.count)
        return sqrt(variance)
    }
    
    /// Creates a CategoryRule from this suggestion
    func toCategoryRule() -> CategoryRule {
        var rule = CategoryRule(
            categoryId: suggestedCategory,
            ruleName: merchantPattern
        )
        rule.priority = max(70, min(90, Int(confidence * 100)))
        rule.merchantContains = merchantPattern
        rule.amountSign = averageAmount < 0 ? .negative : .positive
        rule.isActive = true
        
        return rule
    }
}

/// Engine for analyzing transactions and generating rule suggestions
@MainActor
class RuleSuggestionEngine: ObservableObject {
    private let categoryService: CategoryService
    private let minimumTransactionCount: Int
    
    init(categoryService: CategoryService, minimumTransactionCount: Int = 3) {
        self.categoryService = categoryService
        self.minimumTransactionCount = minimumTransactionCount
    }
    
    /// Analyzes transactions and generates rule suggestions
    func generateSuggestions(from transactions: [Transaction]) -> [RuleSuggestion] {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            AppLogger.shared.info("Generated suggestions for \(transactions.count) transactions in \(String(format: "%.3f", timeElapsed))s", category: "Rules")
        }
        
        // Process in batches for large datasets to improve memory usage
        let batchSize = 500
        if transactions.count > batchSize {
            AppLogger.shared.info("Processing \(transactions.count) transactions in batches of \(batchSize)", category: "Rules")
            return generateSuggestionsInBatches(transactions: transactions, batchSize: batchSize)
        }
        
        // Standard processing for smaller datasets
        return generateSuggestionsForBatch(transactions)
    }
    
    /// Processes large transaction sets in batches for better memory management
    private func generateSuggestionsInBatches(transactions: [Transaction], batchSize: Int) -> [RuleSuggestion] {
        let batches = transactions.chunked(into: batchSize)
        var merchantGroups: [String: [Transaction]] = [:]
        
        // Process each batch and merge results
        for batch in batches {
            let batchUncategorized = filterUncategorizedTransactions(batch)
            let batchGroups = groupTransactionsByMerchant(batchUncategorized)
            
            // Merge batch results into main merchant groups
            for (pattern, batchTransactions) in batchGroups {
                merchantGroups[pattern, default: []].append(contentsOf: batchTransactions)
            }
        }
        
        let filteredGroups = filterGroupsByFrequency(merchantGroups)
        return filteredGroups.compactMap { (merchantPattern, transactions) in
            createSuggestion(for: merchantPattern, transactions: transactions)
        }.sorted { $0.confidence > $1.confidence }
    }
    
    /// Generates suggestions for a single batch of transactions
    private func generateSuggestionsForBatch(_ transactions: [Transaction]) -> [RuleSuggestion] {
        let uncategorizedTransactions = filterUncategorizedTransactions(transactions)
        let merchantGroups = groupTransactionsByMerchant(uncategorizedTransactions)
        let filteredGroups = filterGroupsByFrequency(merchantGroups)
        
        return filteredGroups.compactMap { (merchantPattern, transactions) in
            createSuggestion(for: merchantPattern, transactions: transactions)
        }.sorted { $0.confidence > $1.confidence }
    }
    
    // MARK: - Private Methods
    
    /// Filters transactions that need categorization
    private func filterUncategorizedTransactions(_ transactions: [Transaction]) -> [Transaction] {
        return transactions.filter { transaction in
            // Include transactions with "Other" category or low confidence
            transaction.category == "Other" || 
            transaction.confidence == nil || 
            (transaction.confidence ?? 0.0) < 0.5
        }
    }
    
    /// Groups transactions by extracted merchant patterns
    private func groupTransactionsByMerchant(_ transactions: [Transaction]) -> [String: [Transaction]] {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            if timeElapsed > 0.1 { // Log if grouping takes more than 100ms
                AppLogger.shared.debug("Merchant grouping took \(String(format: "%.3f", timeElapsed))s for \(transactions.count) transactions", category: "Rules")
            }
        }
        
        // Pre-allocate dictionary capacity for better performance
        var groups: [String: [Transaction]] = [:]
        groups.reserveCapacity(transactions.count / 3) // Estimate: ~3 transactions per merchant on average
        
        for transaction in transactions {
            let merchantPattern = extractMerchantPattern(from: transaction.description)
            if !merchantPattern.isEmpty {
                groups[merchantPattern, default: []].append(transaction)
            }
        }
        
        return groups
    }
    
    // Safe regex pattern compilation with fallback to no-op regex
    private static func safeRegex(pattern: String) -> NSRegularExpression {
        do {
            return try NSRegularExpression(pattern: pattern)
        } catch {
            AppLogger.shared.error("Failed to compile regex pattern '\(pattern)': \(error)")
            // Return a simple regex that matches nothing as fallback
            return (try? NSRegularExpression(pattern: "(?!.*)")) ?? NSRegularExpression()
        }
    }
    
    // Pre-compiled regex patterns for better performance
    private static let storeNumberPattern = safeRegex(pattern: #"\s+#\d{4,}"#)
    private static let longNumberPattern = safeRegex(pattern: #"\s+\d{8,}"#)
    private static let stateCodePattern = safeRegex(pattern: #"\s+[A-Z]{2}$"#)
    private static let companySuffixPattern = safeRegex(pattern: #"\s+(INC|LLC|CORP)\.?"#)
    private static let asteriskPattern = safeRegex(pattern: #"\s+\*.*$"#)
    private static let datePattern = safeRegex(pattern: #"\s+\d{2}/\d{2}"#)
    private static let dotComPattern = safeRegex(pattern: #"\.COM.*$"#)
    
    /// Extracts a clean merchant pattern from transaction description
    func extractMerchantPattern(from description: String) -> String {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            if timeElapsed > 0.01 { // Log if extraction takes more than 10ms
                AppLogger.shared.debug("Merchant extraction took \(String(format: "%.3f", timeElapsed))s for: \(description.prefix(50))", category: "Rules")
            }
        }
        
        // Remove common suffixes and prefixes
        var cleaned = description.uppercased()
        
        // Use pre-compiled regex patterns for better performance
        let compiledPatterns = [
            Self.storeNumberPattern,    // Store numbers like " #1234" (4+ digits after #)
            Self.longNumberPattern,     // Very long numbers (8+ digits) like account numbers
            Self.stateCodePattern,      // State codes at end
            Self.companySuffixPattern,  // Company suffixes
            Self.asteriskPattern,       // Everything after asterisk
            Self.datePattern,           // Dates
            Self.dotComPattern          // .com and everything after
        ]
        
        for pattern in compiledPatterns {
            guard !cleaned.isEmpty else { continue }
            let range = NSRange(location: 0, length: cleaned.utf16.count)
            cleaned = pattern.stringByReplacingMatches(in: cleaned, range: range, withTemplate: "")
        }
        
        // Extract main merchant name (first 1-2 words for better grouping)
        let words = cleaned.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .prefix(2)
        
        let merchantName = words.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Normalize common merchant variations for better grouping
        let normalizedMerchant = normalizeMerchantName(merchantName)
        
        // Must be at least 3 characters (or 2 for known short brands) and not too generic
        let genericTerms = ["PAYMENT", "TRANSFER", "DEPOSIT", "WITHDRAWAL", "FEE", "CHARGE"]
        let knownShortBrands = ["BP", "QT", "AM", "PM"]
        let brandsWithNumbers = ["7-ELEVEN", "24 HOUR FITNESS"]
        
        let minimumLength = (knownShortBrands.contains(normalizedMerchant) || brandsWithNumbers.contains(normalizedMerchant)) ? 2 : 3
        
        if normalizedMerchant.count >= minimumLength && !genericTerms.contains(normalizedMerchant) {
            return normalizedMerchant
        }
        
        return ""
    }
    
    // Sorted alphabetically for easy maintenance
    /// Map of normalized names to their possible prefixes
    private static let merchantPrefixMap: [String: [String]] = [
        "7-ELEVEN": ["7-ELEVEN", "7-11", "SEVEN ELEVEN"],
        "24 HOUR FITNESS": ["24 HOUR FITNESS", "24 HOUR"],
        "AMAZON": ["AMAZON", "AMZN"],
        "AMERICAN": ["AMERICAN AIRLINES", "AA", "AAL"],
        "APPLE": ["APPLE", "APL"],
        "BEST BUY": ["BEST BUY", "BESTBUY"],
        "BP": ["BP"],
        "CHEVRON": ["CHEVRON"],
        "CHIPOTLE": ["CHIPOTLE"],
        "COSTCO": ["COSTCO"],
        "CVS": ["CVS"],
        "DELTA": ["DELTA AIR", "DELTA", "DAL"],
        "DOORDASH": ["DOORDASH", "DD", "DOOR DASH"],
        "DROPBOX": ["DROPBOX", "DBX"],
        "DUNKIN": ["DUNKIN", "DUNKIN'", "DUNKIN DONUTS"],
        "EXXON": ["EXXON", "ESSO"],
        "GITHUB": ["GITHUB", "GITHUB.COM"],
        "GOOGLE": ["GOOGLE", "GOOGL"],
        "GRUBHUB": ["GRUBHUB", "SEAMLESS"],
        "HILTON": ["HILTON", "HAMPTON INN", "DOUBLETREE", "EMBASSY SUITES"],
        "HOME DEPOT": ["HOME DEPOT", "HOMEDEPOT"],
        "HYATT": ["HYATT", "ANDAZ", "GRAND HYATT"],
        "KROGER": ["KROGER"],
        "LOWES": ["LOWES", "LOWE'S"],
        "MARRIOTT": ["MARRIOTT", "COURTYARD", "RESIDENCE INN", "RITZ CARLTON"],
        "MCDONALDS": ["MCDONALDS", "MCDONALD'S", "MCD"],
        "MICROSOFT": ["MICROSOFT", "MSFT"],
        "NETFLIX": ["NETFLIX"],
        "PANERA": ["PANERA"],
        "POSTMATES": ["POSTMATES", "POSTMATE"],
        "PUBLIX": ["PUBLIX", "PUBLIX SUPER"],
        "RITE AID": ["RITE AID", "RITEAID"],
        "SAFEWAY": ["SAFEWAY"],
        "SHELL": ["SHELL"],
        "SOUTHWEST": ["SOUTHWEST AIR", "SOUTHWEST", "SWA"],
        "SPOTIFY": ["SPOTIFY"],
        "STARBUCKS": ["STARBUCKS", "SBUX"],
        "SUBWAY": ["SUBWAY"],
        "TARGET": ["TARGET"],
        "TESLA": ["TESLA", "TSL"],
        "UBER": ["UBER"],
        "UNITED": ["UNITED AIRLINES", "UNITED", "UAL"],
        "WALGREENS": ["WALGREENS", "WAG"],
        "WALMART": ["WALMART", "WAL-MART"],
        "ZOOM": ["ZOOM.US", "ZOOM"]
    ]
    
    // Common merchants ordered by frequency for O(1) lookup optimization
    private static let commonMerchantPrefixes = [
        "AMAZON", "STARBUCKS", "WALMART", "TARGET", "MCDONALDS", "UBER", "APPLE", 
        "GOOGLE", "NETFLIX", "CVS", "WALGREENS", "HOME DEPOT", "COSTCO"
    ]
    
    /// Normalizes merchant names to group similar merchants together
    private func normalizeMerchantName(_ merchantName: String) -> String {
        let merchant = merchantName.uppercased()
        
        // Fast path: Check most common merchants first for better performance
        for commonMerchant in Self.commonMerchantPrefixes {
            if let prefixes = Self.merchantPrefixMap[commonMerchant] {
                if prefixes.contains(where: { merchant.hasPrefix($0) }) {
                    return commonMerchant
                }
            }
        }
        
        // Slower path: Check remaining merchants
        for (normalized, prefixes) in Self.merchantPrefixMap {
            if !Self.commonMerchantPrefixes.contains(normalized) {
                if prefixes.contains(where: { merchant.hasPrefix($0) }) {
                    return normalized
                }
            }
        }
        
        // Return original if no normalization needed
        return merchant
    }
    
    /// Filters merchant groups by minimum transaction count
    private func filterGroupsByFrequency(_ groups: [String: [Transaction]]) -> [String: [Transaction]] {
        return groups.filter { $0.value.count >= minimumTransactionCount }
    }
    
    /// Creates a rule suggestion for a merchant pattern
    private func createSuggestion(for merchantPattern: String, transactions: [Transaction]) -> RuleSuggestion? {
        guard !transactions.isEmpty else { return nil }
        
        let amounts = transactions.map { Decimal($0.amount) }
        let averageAmount = amounts.reduce(0, +) / Decimal(amounts.count)
        let suggestedCategory = suggestCategory(for: transactions, merchantPattern: merchantPattern)
        
        return RuleSuggestion(
            merchantPattern: merchantPattern,
            transactionCount: transactions.count,
            suggestedCategory: suggestedCategory,
            averageAmount: averageAmount,
            exampleTransactions: Array(transactions.prefix(5)) // Limit examples
        )
    }
    
    /// Suggests the most appropriate category for transactions
    private func suggestCategory(for transactions: [Transaction], merchantPattern: String) -> UUID {
        let merchantLower = merchantPattern.lowercased()
        
        // Business logic for category suggestions based on merchant patterns and amounts
        if merchantLower.contains("starbucks") || merchantLower.contains("dunkin") || 
           merchantLower.contains("coffee") || merchantLower.contains("cafe") {
            return Category.systemCategoryIds.foodDining
        }
        
        if merchantLower.contains("uber") || merchantLower.contains("lyft") || 
           merchantLower.contains("taxi") || merchantLower.contains("shell") ||
           merchantLower.contains("chevron") || merchantLower.contains("exxon") ||
           merchantLower.contains("bp") || merchantLower.contains("gas") {
            return Category.systemCategoryIds.transportation
        }
        
        if merchantLower.contains("amazon") || merchantLower.contains("target") || 
           merchantLower.contains("walmart") || merchantLower.contains("ebay") ||
           merchantLower.contains("shop") || merchantLower.contains("store") {
            return Category.systemCategoryIds.shopping
        }
        
        if merchantLower.contains("netflix") || merchantLower.contains("spotify") || 
           merchantLower.contains("apple") || merchantLower.contains("subscription") {
            return UUID(uuidString: "00000000-0000-0000-0000-000000000047")! // Subscriptions
        }
        
        if merchantLower.contains("whole foods") || merchantLower.contains("kroger") || 
           merchantLower.contains("safeway") || merchantLower.contains("grocery") ||
           merchantLower.contains("market") {
            return UUID(uuidString: "00000000-0000-0000-0000-000000000046")! // Groceries
        }
        
        if merchantLower.contains("electric") || merchantLower.contains("gas company") || 
           merchantLower.contains("water") || merchantLower.contains("utility") ||
           merchantLower.contains("comcast") || merchantLower.contains("verizon") ||
           merchantLower.contains("at&t") {
            return UUID(uuidString: "00000000-0000-0000-0000-000000000024")! // Utilities
        }
        
        // Analyze transaction amounts and patterns
        let averageAmount = transactions.map { $0.amount }.reduce(0, +) / Double(transactions.count)
        
        if averageAmount > 0 {
            // Positive amounts - likely income or transfers
            if averageAmount > 500 {
                return Category.systemCategoryIds.salary
            } else {
                return Category.systemCategoryIds.income
            }
        } else {
            // Negative amounts - categorize by amount ranges
            let absAmount = abs(averageAmount)
            
            if absAmount > 200 {
                return Category.systemCategoryIds.housing // Large expenses likely housing
            } else if absAmount > 50 {
                return Category.systemCategoryIds.shopping // Medium expenses likely shopping
            } else {
                return Category.systemCategoryIds.foodDining // Small expenses likely food
            }
        }
    }
}

// MARK: - Transaction Analysis Extensions

extension Transaction {
    /// Returns true if this transaction likely needs categorization
    var needsCategorization: Bool {
        return category == "Other" || 
               confidence == nil || 
               (confidence ?? 0.0) < 0.5
    }
}


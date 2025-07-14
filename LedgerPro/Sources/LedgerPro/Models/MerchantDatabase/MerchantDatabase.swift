import Foundation

// MARK: - Merchant Database Models

/// Represents a merchant with all its variations and metadata
struct Merchant: Codable, Identifiable {
    let id: String
    let canonicalName: String
    let category: Category
    let subcategory: String?
    let aliases: [String]
    let patterns: [String]  // Regex patterns for complex matching
    let isSubscription: Bool
    let merchantType: MerchantType
    let commonAmounts: [Decimal]?  // Common amounts for validation
    let metadata: MerchantMetadata
    
    enum MerchantType: String, Codable {
        case retail
        case restaurant
        case subscription
        case transportation
        case grocery
        case entertainment
        case utility
        case financial
        case healthcare
        case travel
    }
}

struct MerchantMetadata: Codable {
    let website: String?
    let logo: String?  // URL or asset name
    let color: String?  // Brand color
    let countryOrigin: String?
    let tags: [String]
}

/// Merchant matching result with confidence
struct MerchantMatch {
    let merchant: Merchant
    let confidence: Double  // 0.0 to 1.0
    let matchType: MatchType
    let matchedPattern: String
    
    enum MatchType: String {
        case exact = "Exact Match"
        case alias = "Known Alias"
        case pattern = "Pattern Match"
        case fuzzy = "Fuzzy Match"
        case partial = "Partial Match"
    }
}

/// Main merchant database class
class MerchantDatabase {
    static let shared = MerchantDatabase()
    
    private var merchants: [String: Merchant] = [:]
    private var aliasIndex: [String: String] = [:]  // alias -> merchantId
    private var categoryIndex: [String: Set<String>] = [:]  // category -> Set<merchantId>
    
    private init() {
        loadMerchants()
        buildIndices()
    }
    
    // MARK: - Public Methods
    
    /// Find best merchant match for a transaction description
    func findMerchant(for description: String) -> MerchantMatch? {
        // TEMPORARY: Disable all operations for empty strings to debug
        guard !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        
        let normalizedDesc = normalize(description)
        
        // 1. Try exact match first
        if let exactMatch = tryExactMatch(normalizedDesc) {
            return exactMatch
        }
        
        // 2. Try alias match
        if let aliasMatch = tryAliasMatch(normalizedDesc) {
            return aliasMatch
        }
        
        // 3. Try pattern match
        if let patternMatch = tryPatternMatch(description) {
            return patternMatch
        }
        
        // 4. Try fuzzy match
        if let fuzzyMatch = tryFuzzyMatch(normalizedDesc) {
            return fuzzyMatch
        }
        
        return nil
    }
    
    /// Get all merchants for a category
    func merchants(for category: Category) -> [Merchant] {
        guard let merchantIds = categoryIndex[category.name] else { return [] }
        return merchantIds.compactMap { merchants[$0] }
    }
    
    /// Add custom merchant (for user-defined merchants)
    func addCustomMerchant(_ merchant: Merchant) {
        merchants[merchant.id] = merchant
        rebuildIndices()
    }
    
    // MARK: - Private Methods
    
    private func normalize(_ text: String) -> String {
        // First trim and check for empty/whitespace
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        
        var normalized = trimmed.uppercased()
        
        // Early exit if still empty after processing
        guard !normalized.isEmpty else { return "" }
        
        // Use only simple string replacements to avoid any range errors
        let simpleReplacements = [
            " INC", " LLC", " CORP", " CO", " LTD", " LP",
            " STORE", " SHOP", " LOCATION", " LOC",
            " NORTH", " SOUTH", " EAST", " WEST", " N ", " S ", " E ", " W ",
            " ST", " AVE", " DR", " RD", " BLVD", " LN", " CT", " WAY", " PL"
        ]
        
        // Remove common business suffixes and location indicators
        for suffix in simpleReplacements {
            if !normalized.isEmpty {
                normalized = normalized.replacingOccurrences(of: suffix, with: "")
            }
        }
        
        // Remove punctuation manually only if string is not empty
        if !normalized.isEmpty {
            let punctuation = "!@#$%^&*()[]{}|;':\",./<>?~`-_=+"
            for char in punctuation {
                normalized = normalized.replacingOccurrences(of: String(char), with: "")
            }
        }
        
        // Clean up multiple spaces only if string is not empty
        if !normalized.isEmpty {
            while normalized.contains("  ") {
                normalized = normalized.replacingOccurrences(of: "  ", with: " ")
            }
        }
        
        return normalized.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func tryExactMatch(_ normalized: String) -> MerchantMatch? {
        for merchant in merchants.values {
            if normalize(merchant.canonicalName) == normalized {
                return MerchantMatch(
                    merchant: merchant,
                    confidence: 1.0,
                    matchType: .exact,
                    matchedPattern: merchant.canonicalName
                )
            }
        }
        return nil
    }
    
    private func tryAliasMatch(_ normalized: String) -> MerchantMatch? {
        for (alias, merchantId) in aliasIndex {
            if normalized.contains(normalize(alias)) {
                if let merchant = merchants[merchantId] {
                    let confidence = Double(alias.count) / Double(normalized.count)
                    return MerchantMatch(
                        merchant: merchant,
                        confidence: min(0.95, confidence + 0.3),
                        matchType: .alias,
                        matchedPattern: alias
                    )
                }
            }
        }
        return nil
    }
    
    private func tryPatternMatch(_ description: String) -> MerchantMatch? {
        for merchant in merchants.values {
            for pattern in merchant.patterns {
                // Skip empty descriptions and patterns to avoid range errors
                guard !description.isEmpty, !pattern.isEmpty else { continue }
                
                // Use simple contains check instead of regex for safety
                if description.uppercased().contains(pattern.uppercased()) {
                    return MerchantMatch(
                        merchant: merchant,
                        confidence: 0.8,  // Slightly lower confidence for simple matching
                        matchType: .pattern,
                        matchedPattern: pattern
                    )
                }
            }
        }
        return nil
    }
    
    private func tryFuzzyMatch(_ normalized: String) -> MerchantMatch? {
        var bestMatch: (merchant: Merchant, score: Double, pattern: String)?
        
        for merchant in merchants.values {
            // Check canonical name
            let canonicalScore = fuzzyScore(normalized, normalize(merchant.canonicalName))
            if canonicalScore > 0.7 {
                if bestMatch?.score ?? 0 < canonicalScore {
                    bestMatch = (merchant, canonicalScore, merchant.canonicalName)
                }
            }
            
            // Check aliases
            for alias in merchant.aliases {
                let aliasScore = fuzzyScore(normalized, normalize(alias))
                if aliasScore > 0.7 {
                    if bestMatch?.score ?? 0 < aliasScore {
                        bestMatch = (merchant, aliasScore, alias)
                    }
                }
            }
        }
        
        if let match = bestMatch {
            return MerchantMatch(
                merchant: match.merchant,
                confidence: match.score,
                matchType: .fuzzy,
                matchedPattern: match.pattern
            )
        }
        
        return nil
    }
    
    private func fuzzyScore(_ str1: String, _ str2: String) -> Double {
        // Enhanced fuzzy matching with multiple scoring methods
        
        // 1. Exact substring match gets highest score
        if !str1.isEmpty && !str2.isEmpty && (str1.contains(str2) || str2.contains(str1)) {
            let longer = max(str1.count, str2.count)
            let shorter = min(str1.count, str2.count)
            guard longer > 0 else { return 0.0 }
            return Double(shorter) / Double(longer) * 0.95 // High but not perfect score
        }
        
        // 2. Word-based matching for multi-word merchants
        let words1 = str1.components(separatedBy: " ").filter { !$0.isEmpty }
        let words2 = str2.components(separatedBy: " ").filter { !$0.isEmpty }
        
        if words1.count > 1 || words2.count > 1 {
            let wordScore = calculateWordMatchScore(words1: words1, words2: words2)
            if wordScore > 0.6 {
                return wordScore
            }
        }
        
        // 3. Character-based similarity for single words or fallback
        let charScore = calculateCharacterSimilarity(str1, str2)
        
        // 4. Levenshtein distance as final fallback
        let distance = levenshteinDistance(str1, str2)
        let maxLength = max(str1.count, str2.count)
        let levenshteinScore = 1.0 - (Double(distance) / Double(maxLength))
        
        // Return the best score
        return max(charScore, levenshteinScore)
    }
    
    private func calculateWordMatchScore(words1: [String], words2: [String]) -> Double {
        guard !words1.isEmpty && !words2.isEmpty else { return 0.0 }
        
        var matchedWords = 0
        let totalWords = max(words1.count, words2.count)
        
        // Ensure we don't divide by zero
        guard totalWords > 0 else { return 0.0 }
        
        for word1 in words1 {
            guard !word1.isEmpty else { continue }
            
            for word2 in words2 {
                guard !word2.isEmpty else { continue }
                
                // Exact word match
                if word1 == word2 {
                    matchedWords += 1
                    break
                }
                // Partial word match for longer words
                else if word1.count >= 4 && word2.count >= 4 {
                    if word1.hasPrefix(word2) || word2.hasPrefix(word1) ||
                       word1.hasSuffix(word2) || word2.hasSuffix(word1) {
                        matchedWords += 1
                        break
                    }
                }
            }
        }
        
        return Double(matchedWords) / Double(totalWords)
    }
    
    private func calculateCharacterSimilarity(_ str1: String, _ str2: String) -> Double {
        let set1 = Set(str1.lowercased())
        let set2 = Set(str2.lowercased())
        
        let intersection = set1.intersection(set2)
        let union = set1.union(set2)
        
        guard !union.isEmpty else { return 0.0 }
        
        // Jaccard similarity
        return Double(intersection.count) / Double(union.count)
    }
    
    private func levenshteinDistance(_ str1: String, _ str2: String) -> Int {
        let s1 = Array(str1)
        let s2 = Array(str2)
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: s2.count + 1), count: s1.count + 1)
        
        for i in 0...s1.count {
            matrix[i][0] = i
        }
        for j in 0...s2.count {
            matrix[0][j] = j
        }
        
        for i in 1...s1.count {
            for j in 1...s2.count {
                let cost = s1[i-1] == s2[j-1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i-1][j] + 1,      // deletion
                    matrix[i][j-1] + 1,      // insertion
                    matrix[i-1][j-1] + cost  // substitution
                )
            }
        }
        
        return matrix[s1.count][s2.count]
    }
    
    private func loadMerchants() {
        // Load from embedded database
        merchants = MerchantDatabaseData.allMerchants
    }
    
    private func buildIndices() {
        rebuildIndices()
    }
    
    private func rebuildIndices() {
        // Clear indices
        aliasIndex.removeAll()
        categoryIndex.removeAll()
        
        // Rebuild
        for (id, merchant) in merchants {
            // Build alias index
            for alias in merchant.aliases {
                aliasIndex[alias.uppercased()] = id
            }
            
            // Build category index
            let categoryKey = merchant.category.name
            if categoryIndex[categoryKey] == nil {
                categoryIndex[categoryKey] = Set<String>()
            }
            categoryIndex[categoryKey]?.insert(id)
        }
    }
}
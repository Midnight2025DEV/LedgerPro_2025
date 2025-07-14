import Foundation

/// Tracks user corrections to learn patterns for better categorization
struct UserCorrection: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let transactionDescription: String
    let originalCategory: String
    let correctedCategory: String
    let amount: Double
    let merchantName: String?
    let confidence: Double? // Original AI confidence
    
    init(timestamp: Date, transactionDescription: String, originalCategory: String, correctedCategory: String, amount: Double, merchantName: String?, confidence: Double?) {
        self.id = UUID()
        self.timestamp = timestamp
        self.transactionDescription = transactionDescription
        self.originalCategory = originalCategory
        self.correctedCategory = correctedCategory
        self.amount = amount
        self.merchantName = merchantName
        self.confidence = confidence
    }
    
    /// Extract key patterns from the description for learning
    var learningPatterns: [String] {
        let description = transactionDescription.lowercased()
        var patterns: [String] = []
        
        // Extract merchant name if available
        if let merchant = merchantName?.lowercased() {
            patterns.append(merchant)
        }
        
        // Extract common payment processors
        let processors = ["paypal", "square", "stripe", "venmo", "zelle", "cashapp", "apple pay"]
        for processor in processors {
            if description.contains(processor.lowercased()) {
                patterns.append(processor.lowercased())
            }
        }
        
        // Extract meaningful words (length > 3, no special characters)
        let words = description.components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
            .filter { $0.count > 3 && !$0.contains("*") && $0.allSatisfy { $0.isLetter } }
            .prefix(3) // Take first 3 meaningful words
        patterns.append(contentsOf: words)
        
        return Array(Set(patterns)) // Remove duplicates
    }
    
    /// Classification of the correction type
    var correctionType: CorrectionType {
        if originalCategory == "Uncategorized" {
            return .initialCategorization
        } else if confidence != nil && confidence! < 0.5 {
            return .lowConfidenceCorrection
        } else {
            return .categoryChange
        }
    }
    
    enum CorrectionType: String, Codable {
        case initialCategorization = "initial"
        case lowConfidenceCorrection = "low_confidence"
        case categoryChange = "category_change"
    }
}

/// Aggregates correction patterns to create learning rules
struct CorrectionPattern: Codable, Identifiable {
    let id: UUID
    let pattern: String
    let categoryName: String
    var confidence: Double
    var occurrenceCount: Int
    var successfulMatches: Int
    let firstSeen: Date
    var lastUpdated: Date
    
    init(pattern: String, categoryName: String, confidence: Double, occurrenceCount: Int, successfulMatches: Int, firstSeen: Date, lastUpdated: Date) {
        self.id = UUID()
        self.pattern = pattern
        self.categoryName = categoryName
        self.confidence = confidence
        self.occurrenceCount = occurrenceCount
        self.successfulMatches = successfulMatches
        self.firstSeen = firstSeen
        self.lastUpdated = lastUpdated
    }
    
    /// Minimum occurrences before suggesting a rule
    static let minimumOccurrences = 2
    
    /// Minimum confidence to suggest a rule
    static let minimumConfidence = 0.65
    
    /// Maximum age in days before considering pattern stale
    static let maxAgeDays = 90
    
    var shouldSuggestRule: Bool {
        let isFrequentEnough = occurrenceCount >= Self.minimumOccurrences
        let isConfidentEnough = confidence >= Self.minimumConfidence
        let isRecent = Date().timeIntervalSince(lastUpdated) < TimeInterval(Self.maxAgeDays * 24 * 3600)
        
        return isFrequentEnough && isConfidentEnough && isRecent
    }
    
    /// Calculate accuracy of this pattern
    var accuracy: Double {
        guard occurrenceCount > 0 else { return 0.0 }
        return Double(successfulMatches) / Double(occurrenceCount)
    }
    
    mutating func recordMatch(successful: Bool) {
        if successful {
            successfulMatches += 1
            confidence = min(1.0, confidence + 0.1)
        } else {
            confidence = max(0.1, confidence - 0.15)
        }
        lastUpdated = Date()
    }
}

extension Array where Element: Hashable {
    /// Remove duplicates while preserving order
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

/// Statistics for correction learning analytics
struct CorrectionStats: Codable {
    let totalCorrections: Int
    let correctionsPerDay: [String: Int] // Date string -> count
    let mostCorrectedCategories: [String: Int] // Category -> count
    let averageCorrectionsPerDay: Double
    let patternSuccessRate: Double
    let learningTrends: LearningTrends
}

struct LearningTrends: Codable {
    let improvingPatterns: Int
    let decliningPatterns: Int
    let newPatternsThisWeek: Int
    let rulesCreatedThisWeek: Int
}
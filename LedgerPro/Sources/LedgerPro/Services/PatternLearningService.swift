import Foundation
import OSLog

/// Service that learns from user corrections to improve categorization accuracy
@MainActor
final class PatternLearningService: ObservableObject {
    static let shared = PatternLearningService()
    
    private let logger = AppLogger.shared
    
    @Published private(set) var corrections: [UserCorrection] = []
    @Published private(set) var patterns: [String: CorrectionPattern] = [:]
    @Published private(set) var suggestedRules: [CategoryRule] = []
    
    private let correctionsKey = "UserCorrections_v2"
    private let patternsKey = "LearnedPatterns_v2"
    private let maxCorrectionsToKeep = 1000 // Prevent unbounded growth
    
    private init() {
        loadCorrections()
        loadPatterns()
        generateRuleSuggestions()
    }
    
    // MARK: - Testing Support
    
    /// Clear all data - for testing only
    func clearAllData() {
        corrections.removeAll()
        patterns.removeAll()
        suggestedRules.removeAll()
    }
    
    // MARK: - Public Interface
    
    /// Record a user correction for learning
    func recordCorrection(
        transaction: Transaction,
        originalCategory: String,
        newCategory: String,
        confidence: Double? = nil
    ) {
        let correction = UserCorrection(
            timestamp: Date(),
            transactionDescription: transaction.description,
            originalCategory: originalCategory,
            correctedCategory: newCategory,
            amount: transaction.amount,
            merchantName: extractMerchantName(from: transaction.description),
            confidence: confidence
        )
        
        // Add correction
        corrections.append(correction)
        
        // Trim old corrections if needed
        if corrections.count > maxCorrectionsToKeep {
            corrections.removeFirst(corrections.count - maxCorrectionsToKeep)
        }
        
        saveCorrections()
        
        // Update learning patterns
        updatePatterns(from: correction)
        
        logger.info("Recorded correction: '\(transaction.description)' \(originalCategory) → \(newCategory)")
    }
    
    /// Get suggestions for new rules based on learned patterns
    func getRuleSuggestions() -> [CategoryRule] {
        return suggestedRules
    }
    
    /// Create a rule from a pattern suggestion
    func createRuleFromPattern(_ pattern: CorrectionPattern) {
        guard let category = CategoryService.shared.categories.first(where: { $0.name == pattern.categoryName }) else {
            logger.error("Category not found: \(pattern.categoryName)")
            return
        }
        
        let rule = CategoryRule(
            categoryId: category.id,
            ruleName: "Learned: \(pattern.pattern)",
            priority: 80 // Medium-high priority for learned rules
        ).applying {
            $0.merchantContains = pattern.pattern
            $0.confidence = pattern.confidence
            $0.isActive = true
        }
        
        // Add to rule storage
        RuleStorageService.shared.saveRule(rule)
        
        // Remove from suggestions
        suggestedRules.removeAll { $0.merchantContains == pattern.pattern }
        patterns.removeValue(forKey: pattern.pattern)
        
        savePatterns()
        logger.info("Created rule from pattern: \(pattern.pattern) → \(pattern.categoryName)")
    }
    
    /// Dismiss a rule suggestion
    func dismissRuleSuggestion(_ pattern: CorrectionPattern) {
        suggestedRules.removeAll { $0.merchantContains == pattern.pattern }
        patterns.removeValue(forKey: pattern.pattern)
        savePatterns()
        logger.info("Dismissed suggestion: \(pattern.pattern)")
    }
    
    /// Get correction statistics for analytics
    func getCorrectionStats() -> CorrectionStats {
        let calendar = Calendar.current
        
        // Group corrections by day
        let dailyCounts = Dictionary(grouping: corrections) { correction in
            calendar.startOfDay(for: correction.timestamp)
        }.mapValues { $0.count }
        
        // Convert to string keys for JSON serialization
        let dailyCountsString = dailyCounts.reduce(into: [String: Int]()) { result, pair in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            result[formatter.string(from: pair.key)] = pair.value
        }
        
        // Category correction counts
        let categoryCounts = corrections.reduce(into: [String: Int]()) { counts, correction in
            counts[correction.correctedCategory, default: 0] += 1
        }
        
        // Pattern analytics
        let improvingCount = patterns.values.filter { $0.confidence > 0.7 }.count
        let decliningCount = patterns.values.filter { $0.confidence < 0.4 }.count
        
        let oneWeekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        let newPatternsThisWeek = patterns.values.filter { $0.firstSeen >= oneWeekAgo }.count
        
        // Calculate overall pattern success rate
        let totalMatches = patterns.values.reduce(0) { $0 + $1.occurrenceCount }
        let successfulMatches = patterns.values.reduce(0) { $0 + $1.successfulMatches }
        let overallSuccessRate = totalMatches > 0 ? Double(successfulMatches) / Double(totalMatches) : 0.0
        
        return CorrectionStats(
            totalCorrections: corrections.count,
            correctionsPerDay: dailyCountsString,
            mostCorrectedCategories: categoryCounts,
            averageCorrectionsPerDay: Double(corrections.count) / Double(max(1, dailyCounts.count)),
            patternSuccessRate: overallSuccessRate,
            learningTrends: LearningTrends(
                improvingPatterns: improvingCount,
                decliningPatterns: decliningCount,
                newPatternsThisWeek: newPatternsThisWeek,
                rulesCreatedThisWeek: 0 // Would need to track this separately
            )
        )
    }
    
    // MARK: - Private Methods
    
    private func updatePatterns(from correction: UserCorrection) {
        for pattern in correction.learningPatterns {
            if var existing = patterns[pattern] {
                // Update existing pattern
                existing.occurrenceCount += 1
                
                // Adjust confidence based on consistency
                if existing.categoryName == correction.correctedCategory {
                    // Same category - increase confidence
                    existing.successfulMatches += 1
                    existing.confidence = min(1.0, existing.confidence + 0.05)
                } else {
                    // Different category - this pattern might not be reliable
                    existing.confidence = max(0.1, existing.confidence - 0.1)
                }
                
                existing.lastUpdated = Date()
                patterns[pattern] = existing
            } else {
                // Create new pattern
                patterns[pattern] = CorrectionPattern(
                    pattern: pattern,
                    categoryName: correction.correctedCategory,
                    confidence: 0.7, // Start with moderate confidence
                    occurrenceCount: 1,
                    successfulMatches: 1,
                    firstSeen: Date(),
                    lastUpdated: Date()
                )
            }
        }
        
        savePatterns()
        generateRuleSuggestions()
    }
    
    private func generateRuleSuggestions() {
        suggestedRules = patterns.values
            .filter { $0.shouldSuggestRule }
            .compactMap { pattern in
                guard let category = CategoryService.shared.categories.first(where: { $0.name == pattern.categoryName }) else {
                    return nil
                }
                
                return CategoryRule(
                    categoryId: category.id,
                    ruleName: "Suggested: \(pattern.pattern)",
                    priority: 75
                ).applying {
                    $0.merchantContains = pattern.pattern
                    $0.confidence = pattern.confidence
                    $0.isActive = false // Suggested rules are inactive until accepted
                }
            }
            .sorted { $0.confidence > $1.confidence }
    }
    
    private func extractMerchantName(from description: String) -> String? {
        // Remove common transaction prefixes
        let prefixes = ["POS ", "PURCHASE ", "DEBIT ", "CREDIT ", "ATM ", "PAYMENT ", "ONLINE "]
        var cleaned = description.uppercased()
        
        for prefix in prefixes {
            if cleaned.hasPrefix(prefix) && cleaned.count >= prefix.count {
                cleaned = String(cleaned.dropFirst(prefix.count))
            }
        }
        
        // Take first meaningful component (>2 characters)
        let components = cleaned.components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
        return components.first { $0.count > 2 && !$0.allSatisfy { $0.isNumber } }
    }
    
    // MARK: - Persistence
    
    private func loadCorrections() {
        guard let data = UserDefaults.standard.data(forKey: correctionsKey),
              let decoded = try? JSONDecoder().decode([UserCorrection].self, from: data) else {
            logger.debug("No corrections found or failed to decode")
            return
        }
        corrections = decoded
        logger.info("Loaded \(self.corrections.count) corrections")
    }
    
    private func saveCorrections() {
        do {
            let encoded = try JSONEncoder().encode(corrections)
            UserDefaults.standard.set(encoded, forKey: correctionsKey)
            logger.debug("Saved \(self.corrections.count) corrections")
        } catch {
            logger.error("Failed to save corrections: \(error)")
        }
    }
    
    private func loadPatterns() {
        guard let data = UserDefaults.standard.data(forKey: patternsKey),
              let decoded = try? JSONDecoder().decode([String: CorrectionPattern].self, from: data) else {
            logger.debug("No patterns found or failed to decode")
            return
        }
        patterns = decoded
        logger.info("Loaded \(self.patterns.count) learning patterns")
    }
    
    private func savePatterns() {
        do {
            let encoded = try JSONEncoder().encode(patterns)
            UserDefaults.standard.set(encoded, forKey: patternsKey)
            logger.debug("Saved \(self.patterns.count) patterns")
        } catch {
            logger.error("Failed to save patterns: \(error)")
        }
    }
}

// MARK: - Helper Extensions

private extension CategoryRule {
    func applying(_ configuration: (inout CategoryRule) -> Void) -> CategoryRule {
        var copy = self
        configuration(&copy)
        return copy
    }
}
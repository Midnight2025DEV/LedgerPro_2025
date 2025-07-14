import XCTest
@testable import LedgerPro


final class PatternLearningTests: XCTestCase {
    var learningService: PatternLearningService!
    
    override func setUp() async throws {
        try await super.setUp()
        learningService = PatternLearningService.shared
        
        // Clear any existing data
        learningService.clearAllData()
    }
    
    func testPatternExtraction() {
        let correction = UserCorrection(
            timestamp: Date(),
            transactionDescription: "UBER TRIP HELP.UBER.COM",
            originalCategory: "Uncategorized",
            correctedCategory: "Transportation",
            amount: 25.50,
            merchantName: "UBER",
            confidence: nil
        )
        
        let patterns = correction.learningPatterns
        XCTAssertTrue(patterns.contains("uber"))
        XCTAssertTrue(patterns.contains("trip"))
        XCTAssertTrue(patterns.contains("help"))
    }
    
    func testCorrectionTypeClassification() {
        // Initial categorization
        let initialCorrection = UserCorrection(
            timestamp: Date(),
            transactionDescription: "STARBUCKS COFFEE",
            originalCategory: "Uncategorized",
            correctedCategory: "Food & Dining",
            amount: 5.50,
            merchantName: "STARBUCKS",
            confidence: nil
        )
        XCTAssertEqual(initialCorrection.correctionType, .initialCategorization)
        
        // Low confidence correction
        let lowConfidenceCorrection = UserCorrection(
            timestamp: Date(),
            transactionDescription: "UNKNOWN MERCHANT",
            originalCategory: "Shopping",
            correctedCategory: "Entertainment",
            amount: 15.00,
            merchantName: "UNKNOWN",
            confidence: 0.3
        )
        XCTAssertEqual(lowConfidenceCorrection.correctionType, .lowConfidenceCorrection)
        
        // Category change
        let categoryChange = UserCorrection(
            timestamp: Date(),
            transactionDescription: "AMAZON PURCHASE",
            originalCategory: "Shopping",
            correctedCategory: "Groceries",
            amount: 45.00,
            merchantName: "AMAZON",
            confidence: 0.9
        )
        XCTAssertEqual(categoryChange.correctionType, .categoryChange)
    }
    
    func testPatternLearning() async {
        let transaction = Transaction(
            date: "2024-01-01",
            description: "UBER TRIP DOWNTOWN",
            amount: -25.50,
            category: "Uncategorized"
        )
        
        // Record first correction
        await learningService.recordCorrection(
            transaction: transaction,
            originalCategory: "Uncategorized",
            newCategory: "Transportation"
        )
        
        // Check if pattern was created
        XCTAssertNotNil(learningService.patterns["uber"])
        XCTAssertEqual(learningService.patterns["uber"]?.categoryName, "Transportation")
        XCTAssertEqual(learningService.patterns["uber"]?.occurrenceCount, 1)
        XCTAssertEqual(learningService.patterns["uber"]?.successfulMatches, 1)
    }
    
    func testPatternConfidenceAdjustment() async {
        let transaction1 = Transaction(
            date: "2024-01-01",
            description: "STARBUCKS COFFEE",
            amount: -5.50,
            category: "Uncategorized"
        )
        
        let transaction2 = Transaction(
            date: "2024-01-02",
            description: "STARBUCKS DOWNTOWN",
            amount: -4.75,
            category: "Uncategorized"
        )
        
        // First correction - creates pattern
        await learningService.recordCorrection(
            transaction: transaction1,
            originalCategory: "Uncategorized",
            newCategory: "Food & Dining"
        )
        
        let initialConfidence = learningService.patterns["starbucks"]?.confidence ?? 0
        
        // Second correction - same category should increase confidence
        await learningService.recordCorrection(
            transaction: transaction2,
            originalCategory: "Uncategorized",
            newCategory: "Food & Dining"
        )
        
        let updatedConfidence = learningService.patterns["starbucks"]?.confidence ?? 0
        XCTAssertGreaterThan(updatedConfidence, initialConfidence)
    }
    
    func testPatternConfidenceDecline() async {
        let transaction1 = Transaction(
            date: "2024-01-01",
            description: "AMAZON PURCHASE",
            amount: -25.00,
            category: "Uncategorized"
        )
        
        let transaction2 = Transaction(
            date: "2024-01-02",
            description: "AMAZON FRESH",
            amount: -15.00,
            category: "Uncategorized"
        )
        
        // First correction
        await learningService.recordCorrection(
            transaction: transaction1,
            originalCategory: "Uncategorized",
            newCategory: "Shopping"
        )
        
        let initialConfidence = learningService.patterns["amazon"]?.confidence ?? 0
        
        // Second correction - different category should decrease confidence
        await learningService.recordCorrection(
            transaction: transaction2,
            originalCategory: "Uncategorized",
            newCategory: "Groceries"
        )
        
        let updatedConfidence = learningService.patterns["amazon"]?.confidence ?? 0
        XCTAssertLessThan(updatedConfidence, initialConfidence)
    }
    
    func testRuleSuggestionGeneration() async {
        let transaction = Transaction(
            date: "2024-01-01",
            description: "NETFLIX SUBSCRIPTION",
            amount: -15.99,
            category: "Uncategorized"
        )
        
        // Record enough corrections to trigger rule suggestion
        for _ in 0..<CorrectionPattern.minimumOccurrences {
            await learningService.recordCorrection(
                transaction: transaction,
                originalCategory: "Uncategorized",
                newCategory: "Entertainment"
            )
        }
        
        // Check if rule suggestion was generated
        let suggestions = learningService.getRuleSuggestions()
        XCTAssertFalse(suggestions.isEmpty)
        
        if let netflixRule = suggestions.first(where: { $0.merchantContains == "netflix" }) {
            XCTAssertEqual(netflixRule.ruleName, "Suggested: netflix")
            XCTAssertFalse(netflixRule.isActive) // Suggestions start inactive
        }
    }
    
    func testCorrectionStatsGeneration() async {
        // Generate some test corrections
        let corrections = [
            ("STARBUCKS", "Food & Dining"),
            ("UBER", "Transportation"),
            ("NETFLIX", "Entertainment"),
            ("STARBUCKS", "Food & Dining"),
            ("AMAZON", "Shopping")
        ]
        
        for (merchant, category) in corrections {
            let transaction = Transaction(
                date: "2024-01-01",
                description: "\(merchant) PURCHASE",
                amount: -10.00,
                category: "Uncategorized"
            )
            
            await learningService.recordCorrection(
                transaction: transaction,
                originalCategory: "Uncategorized",
                newCategory: category
            )
        }
        
        let stats = learningService.getCorrectionStats()
        XCTAssertEqual(stats.totalCorrections, 5)
        XCTAssertGreaterThan(stats.averageCorrectionsPerDay, 0)
        XCTAssertTrue(stats.mostCorrectedCategories["Food & Dining"] == 2)
    }
    
    func testPatternAgeFiltering() {
        var oldPattern = CorrectionPattern(
            pattern: "old_merchant",
            categoryName: "Shopping",
            confidence: 0.8,
            occurrenceCount: 3,
            successfulMatches: 3,
            firstSeen: Calendar.current.date(byAdding: .day, value: -100, to: Date()) ?? Date(),
            lastUpdated: Calendar.current.date(byAdding: .day, value: -100, to: Date()) ?? Date()
        )
        
        // Old pattern should not suggest rule
        XCTAssertFalse(oldPattern.shouldSuggestRule)
        
        var recentPattern = CorrectionPattern(
            pattern: "recent_merchant",
            categoryName: "Shopping",
            confidence: 0.8,
            occurrenceCount: 3,
            successfulMatches: 3,
            firstSeen: Date(),
            lastUpdated: Date()
        )
        
        // Recent pattern should suggest rule
        XCTAssertTrue(recentPattern.shouldSuggestRule)
    }
    
    func testAccuracyCalculation() {
        var pattern = CorrectionPattern(
            pattern: "test_merchant",
            categoryName: "Shopping",
            confidence: 0.7,
            occurrenceCount: 10,
            successfulMatches: 8,
            firstSeen: Date(),
            lastUpdated: Date()
        )
        
        XCTAssertEqual(pattern.accuracy, 0.8, accuracy: 0.001)
        
        // Test edge case with zero occurrences
        pattern.occurrenceCount = 0
        XCTAssertEqual(pattern.accuracy, 0.0)
    }
}
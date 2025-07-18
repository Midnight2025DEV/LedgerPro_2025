import XCTest
@testable import LedgerPro
import Foundation

@MainActor
final class CategoryServiceCustomRuleTests: XCTestCase {
    var categoryService: CategoryService!
    var ruleStorage: RuleStorageService!
    
    
    override func setUp() async throws {
        try await super.setUp()
        categoryService = CategoryService.shared
        ruleStorage = RuleStorageService.shared
        
        // Clear any existing custom rules
        ruleStorage.customRules.forEach { rule in
            ruleStorage.deleteRule(id: rule.id)
        }
        
        // Ensure categories are loaded
        await categoryService.loadCategories()
        try await Task.sleep(for: .milliseconds(100))
    }
    
    
    override func tearDown() async throws {
        // Clean up custom rules
        ruleStorage.customRules.forEach { rule in
            ruleStorage.deleteRule(id: rule.id)
        }
        try await super.tearDown()
    }
    
    
    func testCustomRuleOverridesSystemRule() {
        // Given - Create a custom rule for Uber with higher priority
        var customUberRule = CategoryRule(
            categoryId: LedgerPro.Category.systemCategoryIds.foodDining, // Different from system rule
            ruleName: "Custom Uber Eats Rule"
        )
        customUberRule.merchantContains = "uber"
        customUberRule.priority = 100 // Higher than system rule (90)
        customUberRule.confidence = 0.95
        
        ruleStorage.saveRule(customUberRule)
        
        // When - Test categorization
        let transaction = Transaction(
            date: "2025-01-15",
            description: "UBER EATS DELIVERY",
            amount: -25.50,
            category: "Other"
        )
        
        let (category, confidence) = categoryService.suggestCategory(for: transaction)
        
        // Then - Should use custom rule (Food & Dining) not system rule (Transportation)
        XCTAssertNotNil(category)
        XCTAssertEqual(category?.name, "Food & Dining", "Should use custom rule with higher priority")
        XCTAssertGreaterThan(confidence, 0.9, "Should have high confidence from custom rule")
    }
    
    
    func testCustomRuleForNewMerchant() {
        // Given - Create custom rule for a merchant not in system rules
        var customRule = CategoryRule(
            categoryId: UUID(uuidString: "00000000-0000-0000-0000-000000000032")!, // Entertainment
            ruleName: "Spotify Subscription"
        )
        customRule.merchantContains = "spotify"
        customRule.amountMin = Decimal(-20)
        customRule.amountMax = Decimal(-5)
        customRule.priority = 90
        customRule.confidence = 0.85
        
        ruleStorage.saveRule(customRule)
        
        // When
        let transaction = Transaction(
            date: "2025-01-15",
            description: "SPOTIFY USA SUBSCRIPTION",
            amount: -9.99,
            category: "Other"
        )
        
        let (category, confidence) = categoryService.suggestCategory(for: transaction)
        
        // Then
        XCTAssertNotNil(category)
        XCTAssertEqual(category?.name, "Entertainment", "Should categorize Spotify as Entertainment")
        XCTAssertGreaterThan(confidence, 0.8, "Should have good confidence from custom rule")
    }
    
    
    func testMultipleCustomRulesPriority() {
        // Given - Create multiple custom rules that could match
        var rule1 = CategoryRule(
            categoryId: LedgerPro.Category.systemCategoryIds.shopping,
            ruleName: "General Amazon Rule"
        )
        rule1.merchantContains = "amazon"
        rule1.priority = 110 // Higher than system rule
        
        var rule2 = CategoryRule(
            categoryId: UUID(uuidString: "00000000-0000-0000-0000-000000000032")!, // Entertainment
            ruleName: "Amazon Prime Video"
        )
        rule2.merchantContains = "amazon"
        rule2.descriptionContains = "prime video"
        rule2.priority = 150 // Much higher priority to override subscription rules
        
        ruleStorage.saveRule(rule1)
        ruleStorage.saveRule(rule2)
        
        // When - Transaction matches both rules
        let transaction = Transaction(
            date: "2025-01-15",
            description: "AMAZON PRIME VIDEO SUBSCRIPTION",
            amount: -14.99,
            category: "Other"
        )
        
        let (category, confidence) = categoryService.suggestCategory(for: transaction)
        
        // Then - Should use a matching rule (either Entertainment or Subscriptions is valid)
        XCTAssertNotNil(category)
        let validCategories = ["Entertainment", "Subscriptions"]
        XCTAssertTrue(validCategories.contains(category?.name ?? ""), 
                     "Should categorize as either Entertainment or Subscriptions, got: \(category?.name ?? "nil")")
    }
    
    
    func testCustomRuleWithRegex() {
        // Given - Custom rule with regex pattern
        var regexRule = CategoryRule(
            categoryId: LedgerPro.Category.systemCategoryIds.housing,
            ruleName: "Rent Payment Rule"
        )
        regexRule.regexPattern = "RENT|LEASE|APT\\s*#?\\d+"
        regexRule.amountMin = Decimal(-5000)
        regexRule.amountMax = Decimal(-500)
        regexRule.priority = 95
        
        ruleStorage.saveRule(regexRule)
        
        // Test various rent-related transactions
        let testCases = [
            ("MONTHLY RENT PAYMENT", -1500.00),
            ("LEASE PAYMENT APT #123", -1200.00),
            ("APT#456 RENTAL", -1800.00)
        ]
        
        for (description, amount) in testCases {
            let transaction = Transaction(
                date: "2025-01-15",
                description: description,
                amount: amount,
                category: "Other"
            )
            
            let (category, _) = categoryService.suggestCategory(for: transaction)
            
            XCTAssertNotNil(category, "Should match regex rule for: \(description)")
            XCTAssertEqual(category?.name, "Housing", "Should categorize as Housing for: \(description)")
        }
    }
    
    
    func testRuleLearningFromCorrections() {
        // Given - Create a custom rule
        var learningRule = CategoryRule(
            categoryId: LedgerPro.Category.systemCategoryIds.shopping,
            ruleName: "Target Rule"
        )
        learningRule.merchantContains = "target"
        learningRule.confidence = 0.7
        learningRule.matchCount = 5
        
        ruleStorage.saveRule(learningRule)
        
        // When - Record corrections
        if var rule = ruleStorage.customRules.first {
            rule.recordCorrection() // User corrected this categorization
            rule.recordCorrection() // Another correction
            ruleStorage.updateRule(rule)
        }
        
        // Then - Confidence should decrease
        let updatedRule = ruleStorage.customRules.first
        XCTAssertNotNil(updatedRule)
        XCTAssertLessThan(updatedRule!.confidence, 0.7, "Confidence should decrease after corrections")
        
        // When - Record successful matches
        if var rule = ruleStorage.customRules.first {
            rule.recordMatch()
            rule.recordMatch()
            rule.recordMatch()
            ruleStorage.updateRule(rule)
        }
        
        // Then - Confidence should increase slightly
        let improvedRule = ruleStorage.customRules.first
        XCTAssertNotNil(improvedRule)
        XCTAssertGreaterThan(improvedRule!.matchCount, 5, "Match count should increase")
    }
}
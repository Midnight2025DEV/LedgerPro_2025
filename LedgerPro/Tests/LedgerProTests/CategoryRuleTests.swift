import XCTest
@testable import LedgerPro

final class CategoryRuleTests: XCTestCase {
    
    func testRuleMatchingWithMerchantContains() {
        // Given
        let rule = CategoryRule(
            categoryId: Category.systemCategoryIds.transportation,
            ruleName: "Uber Rule"
        ).with {
            $0.merchantContains = "uber"
            $0.amountSign = .negative
        }
        
        let matchingTransaction = Transaction(
            date: "2025-01-15",
            description: "UBER EATS DELIVERY",
            amount: -25.50,
            category: "Other"
        )
        
        let nonMatchingTransaction = Transaction(
            date: "2025-01-15",
            description: "WALMART PURCHASE",
            amount: -50.00,
            category: "Other"
        )
        
        // When & Then
        XCTAssertTrue(rule.matches(transaction: matchingTransaction), "Should match Uber transaction")
        XCTAssertFalse(rule.matches(transaction: nonMatchingTransaction), "Should not match Walmart transaction")
    }
    
    func testRuleMatchingWithAmountRange() {
        // Given
        let rule = CategoryRule(
            categoryId: Category.systemCategoryIds.shopping,
            ruleName: "Large Purchase Rule"
        ).with {
            $0.amountMin = Decimal(-1000)
            $0.amountMax = Decimal(-100)
            $0.amountSign = .negative
        }
        
        let matchingTransaction = Transaction(
            date: "2025-01-15",
            description: "EXPENSIVE PURCHASE",
            amount: -500.00,
            category: "Other"
        )
        
        let tooSmallTransaction = Transaction(
            date: "2025-01-15",
            description: "SMALL PURCHASE",
            amount: -50.00,
            category: "Other"
        )
        
        let tooLargeTransaction = Transaction(
            date: "2025-01-15",
            description: "HUGE PURCHASE",
            amount: -2000.00,
            category: "Other"
        )
        
        // When & Then
        XCTAssertTrue(rule.matches(transaction: matchingTransaction), "Should match transaction in range")
        XCTAssertFalse(rule.matches(transaction: tooSmallTransaction), "Should not match transaction too small")
        XCTAssertFalse(rule.matches(transaction: tooLargeTransaction), "Should not match transaction too large")
    }
    
    func testRuleMatchingWithAmountSign() {
        // Given
        let incomeRule = CategoryRule(
            categoryId: Category.systemCategoryIds.salary,
            ruleName: "Income Rule"
        ).with {
            $0.amountSign = .positive
        }
        
        let expenseRule = CategoryRule(
            categoryId: Category.systemCategoryIds.shopping,
            ruleName: "Expense Rule"
        ).with {
            $0.amountSign = .negative
        }
        
        let incomeTransaction = Transaction(
            date: "2025-01-15",
            description: "PAYROLL DEPOSIT",
            amount: 2500.00,
            category: "Other"
        )
        
        let expenseTransaction = Transaction(
            date: "2025-01-15",
            description: "SHOPPING",
            amount: -100.00,
            category: "Other"
        )
        
        // When & Then
        XCTAssertTrue(incomeRule.matches(transaction: incomeTransaction), "Income rule should match positive amount")
        XCTAssertFalse(incomeRule.matches(transaction: expenseTransaction), "Income rule should not match negative amount")
        XCTAssertTrue(expenseRule.matches(transaction: expenseTransaction), "Expense rule should match negative amount")
        XCTAssertFalse(expenseRule.matches(transaction: incomeTransaction), "Expense rule should not match positive amount")
    }
    
    func testRuleConfidenceCalculation() {
        // Given
        let specificRule = CategoryRule(
            categoryId: Category.systemCategoryIds.transportation,
            ruleName: "Specific Uber Rule"
        ).with {
            $0.merchantExact = "uber"
            $0.amountMin = Decimal(-50)
            $0.amountMax = Decimal(-10)
            $0.confidence = 0.8
        }
        
        let transaction = Transaction(
            date: "2025-01-15",
            description: "UBER",
            amount: -25.00,
            category: "Other"
        )
        
        // When
        let confidence = specificRule.matchConfidence(for: transaction)
        
        // Then
        XCTAssertGreaterThan(confidence, 0.8, "Should boost confidence for specific conditions")
        XCTAssertLessThanOrEqual(confidence, 1.0, "Confidence should not exceed 1.0")
    }
    
    func testRuleValidation() {
        // Given
        let validRule = CategoryRule(
            categoryId: Category.systemCategoryIds.shopping,
            ruleName: "Valid Rule"
        ).with {
            $0.merchantContains = "amazon"
            $0.amountSign = .negative
        }
        
        let invalidRule = CategoryRule(
            categoryId: Category.systemCategoryIds.shopping,
            ruleName: "" // Empty name
        )
        
        let invalidAmountRule = CategoryRule(
            categoryId: Category.systemCategoryIds.shopping,
            ruleName: "Invalid Amount Rule"
        ).with {
            $0.amountMin = Decimal(100)
            $0.amountMax = Decimal(50) // Max < Min
        }
        
        // When & Then
        XCTAssertTrue(validRule.isValid, "Valid rule should pass validation")
        XCTAssertFalse(invalidRule.isValid, "Rule with empty name should fail validation")
        XCTAssertFalse(invalidAmountRule.isValid, "Rule with invalid amount range should fail validation")
    }
    
    func testRuleDescriptionGeneration() {
        // Given
        let rule = CategoryRule(
            categoryId: Category.systemCategoryIds.transportation,
            ruleName: "Complex Rule"
        ).with {
            $0.merchantContains = "uber"
            $0.amountMin = Decimal(-50)
            $0.amountMax = Decimal(-10)
            $0.amountSign = .negative
        }
        
        // When
        let description = rule.ruleDescription
        
        // Then
        XCTAssertTrue(description.contains("uber"), "Description should mention merchant")
        XCTAssertTrue(description.contains("10") && description.contains("50"), "Description should mention amount range")
        XCTAssertTrue(description.contains("negative"), "Description should mention amount sign")
    }
    
    func testSystemRulesExist() {
        // Given & When
        let systemRules = CategoryRule.systemRules
        
        // Then
        XCTAssertFalse(systemRules.isEmpty, "Should have system rules defined")
        
        // Check for key rules
        let hasUberRule = systemRules.contains { $0.ruleName.lowercased().contains("uber") }
        let hasPayrollRule = systemRules.contains { $0.ruleName.lowercased().contains("salary") }
        let hasGasRule = systemRules.contains { $0.ruleName.lowercased().contains("gas") }
        
        XCTAssertTrue(hasUberRule, "Should have Uber/Lyft rule")
        XCTAssertTrue(hasPayrollRule, "Should have salary/payroll rule")
        XCTAssertTrue(hasGasRule, "Should have gas station rule")
    }
    
    func testRulePriorityOrdering() {
        // Given
        let systemRules = CategoryRule.systemRules
        
        // When
        let sortedRules = systemRules.sorted { rule1, rule2 in
            if rule1.priority != rule2.priority {
                return rule1.priority > rule2.priority
            }
            return rule1.confidence > rule2.confidence
        }
        
        // Then
        XCTAssertGreaterThanOrEqual(sortedRules.first?.priority ?? 0, 90, 
                                   "Highest priority rule should be >= 90")
        
        // Verify sorting is correct
        for i in 1..<sortedRules.count {
            let prev = sortedRules[i-1]
            let current = sortedRules[i]
            
            if prev.priority == current.priority {
                XCTAssertGreaterThanOrEqual(prev.confidence, current.confidence,
                                           "When priorities are equal, confidence should be descending")
            } else {
                XCTAssertGreaterThan(prev.priority, current.priority,
                                    "Priorities should be in descending order")
            }
        }
    }
    
    func testRuleMatchRecording() {
        // Given
        var rule = CategoryRule(
            categoryId: Category.systemCategoryIds.shopping,
            ruleName: "Amazon Rule"
        ).with {
            $0.merchantContains = "amazon"
            $0.confidence = 0.7
        }
        
        let initialConfidence = rule.confidence
        let initialMatchCount = rule.matchCount
        
        // When
        rule.recordMatch()
        
        // Then
        XCTAssertEqual(rule.matchCount, initialMatchCount + 1, "Match count should increment")
        XCTAssertGreaterThan(rule.confidence, initialConfidence, "Confidence should increase slightly")
        XCTAssertNotNil(rule.lastMatched, "Last matched date should be set")
    }
    
    func testRuleCorrectionRecording() {
        // Given
        var rule = CategoryRule(
            categoryId: Category.systemCategoryIds.shopping,
            ruleName: "Amazon Rule"
        ).with {
            $0.merchantContains = "amazon"
            $0.confidence = 0.7
        }
        
        let initialConfidence = rule.confidence
        
        // When
        rule.recordCorrection()
        
        // Then
        XCTAssertLessThan(rule.confidence, initialConfidence, "Confidence should decrease after correction")
        XCTAssertGreaterThanOrEqual(rule.confidence, 0.1, "Confidence should not go below minimum threshold")
    }
}

// Helper extension for tests
private extension CategoryRule {
    func with(_ block: (inout CategoryRule) -> Void) -> CategoryRule {
        var copy = self
        block(&copy)
        return copy
    }
}
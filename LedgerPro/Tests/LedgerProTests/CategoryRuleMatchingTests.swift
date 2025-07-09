import XCTest
@testable import LedgerPro

final class CategoryRuleMatchingTests: XCTestCase {
    
    // MARK: - Pattern Matching Logic Tests
    
    func testExactMerchantMatching() {
        // Test exact merchant name matching
        var rule = CategoryRule(
            categoryId: UUID(),
            ruleName: "Exact Starbucks Rule"
        )
        rule.merchantExact = "STARBUCKS"
        rule.priority = 100
        rule.confidence = 0.95
        
        let starbucksTransaction = Transaction(
            date: "2024-01-15",
            description: "STARBUCKS COFFEE #1234",
            amount: -8.50,
            category: "Other"
        )
        
        let nonStarbucksTransaction = Transaction(
            date: "2024-01-15",
            description: "STARBURGERS RESTAURANT",
            amount: -15.00,
            category: "Other"
        )
        
        XCTAssertTrue(rule.matches(transaction: starbucksTransaction))
        XCTAssertFalse(rule.matches(transaction: nonStarbucksTransaction))
    }
    
    func testContainsMerchantMatching() {
        // Test contains merchant pattern matching
        var rule = CategoryRule(
            categoryId: UUID(),
            ruleName: "Contains Uber Rule"
        )
        rule.merchantContains = "UBER"
        rule.priority = 90
        rule.confidence = 0.90
        
        let uberTransaction = Transaction(
            date: "2024-01-15",
            description: "UBER EATS DELIVERY",
            amount: -25.50,
            category: "Other"
        )
        
        let uberRideTransaction = Transaction(
            date: "2024-01-15",
            description: "UBER TRIP HELP.UBER.COM",
            amount: -18.75,
            category: "Other"
        )
        
        let nonUberTransaction = Transaction(
            date: "2024-01-15",
            description: "SUPERMARKET PURCHASE",
            amount: -45.00,
            category: "Other"
        )
        
        XCTAssertTrue(rule.matches(transaction: uberTransaction))
        XCTAssertTrue(rule.matches(transaction: uberRideTransaction))
        XCTAssertFalse(rule.matches(transaction: nonUberTransaction))
    }
    
    func testDescriptionContainsMatching() {
        // Test description contains pattern matching
        var rule = CategoryRule(
            categoryId: UUID(),
            ruleName: "Payment Description Rule"
        )
        rule.descriptionContains = "PAYMENT"
        rule.priority = 80
        rule.confidence = 0.85
        
        let paymentTransaction = Transaction(
            date: "2024-01-15",
            description: "CAPITAL ONE MOBILE PAYMENT",
            amount: 250.00,
            category: "Other"
        )
        
        let nonPaymentTransaction = Transaction(
            date: "2024-01-15",
            description: "GROCERY STORE PURCHASE",
            amount: -67.50,
            category: "Other"
        )
        
        XCTAssertTrue(rule.matches(transaction: paymentTransaction))
        XCTAssertFalse(rule.matches(transaction: nonPaymentTransaction))
    }
    
    func testRegexPatternMatching() {
        // Test regex pattern matching
        var rule = CategoryRule(
            categoryId: UUID(),
            ruleName: "Gas Station Regex Rule"
        )
        rule.regexPattern = "SHELL|CHEVRON|EXXON(?!.*MOBILE)|BP|CITGO"
        rule.priority = 85
        rule.confidence = 0.88
        
        let chevronTransaction = Transaction(
            date: "2024-01-15",
            description: "CHEVRON GAS STATION #1234",
            amount: -45.00,
            category: "Other"
        )
        
        let shellTransaction = Transaction(
            date: "2024-01-15",
            description: "SHELL OIL STATION",
            amount: -52.30,
            category: "Other"
        )
        
        let exxonMobileTransaction = Transaction(
            date: "2024-01-15",
            description: "EXXON MOBILE STATION",
            amount: -38.75,
            category: "Other"
        )
        
        let nonGasTransaction = Transaction(
            date: "2024-01-15",
            description: "WALMART SUPERCENTER",
            amount: -89.99,
            category: "Other"
        )
        
        XCTAssertTrue(rule.matches(transaction: chevronTransaction))
        XCTAssertTrue(rule.matches(transaction: shellTransaction))
        XCTAssertFalse(rule.matches(transaction: exxonMobileTransaction)) // Should not match due to negative lookahead
        XCTAssertFalse(rule.matches(transaction: nonGasTransaction))
    }
    
    func testAmountRangeMatching() {
        // Test amount range matching
        var rule = CategoryRule(
            categoryId: UUID(),
            ruleName: "Coffee Amount Range Rule"
        )
        rule.merchantContains = "STARBUCKS"
        rule.amountMin = Decimal(-20)
        rule.amountMax = Decimal(-2)
        rule.priority = 75
        rule.confidence = 0.80
        
        let smallCoffeeTransaction = Transaction(
            date: "2024-01-15",
            description: "STARBUCKS COFFEE",
            amount: -5.50,
            category: "Other"
        )
        
        let largeCoffeeTransaction = Transaction(
            date: "2024-01-15",
            description: "STARBUCKS COFFEE",
            amount: -15.75,
            category: "Other"
        )
        
        let expensiveStarbucksTransaction = Transaction(
            date: "2024-01-15",
            description: "STARBUCKS COFFEE",
            amount: -35.00,
            category: "Other"
        )
        
        let cheapStarbucksTransaction = Transaction(
            date: "2024-01-15",
            description: "STARBUCKS COFFEE",
            amount: -1.00,
            category: "Other"
        )
        
        XCTAssertTrue(rule.matches(transaction: smallCoffeeTransaction))
        XCTAssertTrue(rule.matches(transaction: largeCoffeeTransaction))
        XCTAssertFalse(rule.matches(transaction: expensiveStarbucksTransaction))
        XCTAssertFalse(rule.matches(transaction: cheapStarbucksTransaction))
    }
    
    func testAmountSignMatching() {
        // Test amount sign matching
        var expenseRule = CategoryRule(
            categoryId: UUID(),
            ruleName: "Expense Only Rule"
        )
        expenseRule.merchantContains = "WALMART"
        expenseRule.amountSign = .negative
        expenseRule.priority = 70
        expenseRule.confidence = 0.85
        
        var incomeRule = CategoryRule(
            categoryId: UUID(),
            ruleName: "Income Only Rule"
        )
        incomeRule.descriptionContains = "SALARY"
        incomeRule.amountSign = .positive
        incomeRule.priority = 95
        incomeRule.confidence = 0.98
        
        let walmartExpense = Transaction(
            date: "2024-01-15",
            description: "WALMART SUPERCENTER",
            amount: -89.99,
            category: "Other"
        )
        
        let walmartRefund = Transaction(
            date: "2024-01-15",
            description: "WALMART REFUND",
            amount: 45.00,
            category: "Other"
        )
        
        let salaryDeposit = Transaction(
            date: "2024-01-15",
            description: "COMPANY SALARY DEPOSIT",
            amount: 3500.00,
            category: "Other"
        )
        
        let salaryDeduction = Transaction(
            date: "2024-01-15",
            description: "SALARY DEDUCTION",
            amount: -200.00,
            category: "Other"
        )
        
        XCTAssertTrue(expenseRule.matches(transaction: walmartExpense))
        XCTAssertFalse(expenseRule.matches(transaction: walmartRefund))
        XCTAssertTrue(incomeRule.matches(transaction: salaryDeposit))
        XCTAssertFalse(incomeRule.matches(transaction: salaryDeduction))
    }
    
    // MARK: - Priority Ordering Tests
    
    func testRulePriorityOrdering() {
        // Create rules with different priorities
        var highPriorityRule = CategoryRule(
            categoryId: UUID(),
            ruleName: "High Priority Rule"
        )
        highPriorityRule.merchantContains = "UBER"
        highPriorityRule.priority = 100
        highPriorityRule.confidence = 0.95
        
        var mediumPriorityRule = CategoryRule(
            categoryId: UUID(),
            ruleName: "Medium Priority Rule"
        )
        mediumPriorityRule.merchantContains = "UBER"
        mediumPriorityRule.priority = 80
        mediumPriorityRule.confidence = 0.90
        
        var lowPriorityRule = CategoryRule(
            categoryId: UUID(),
            ruleName: "Low Priority Rule"
        )
        lowPriorityRule.merchantContains = "UBER"
        lowPriorityRule.priority = 60
        lowPriorityRule.confidence = 0.85
        
        let rules = [mediumPriorityRule, lowPriorityRule, highPriorityRule]
        let sortedRules = rules.sorted { $0.priority > $1.priority }
        
        XCTAssertEqual(sortedRules[0].priority, 100)
        XCTAssertEqual(sortedRules[1].priority, 80)
        XCTAssertEqual(sortedRules[2].priority, 60)
        XCTAssertEqual(sortedRules[0].ruleName, "High Priority Rule")
    }
    
    func testSystemRulePriorityOverrides() {
        // Test that system rules have appropriate priorities
        let systemRules = CategoryRule.systemRules
        
        // Capital One payment rule should have high priority
        let capitalOneRule = systemRules.first { $0.ruleName.contains("Capital One") }
        XCTAssertNotNil(capitalOneRule)
        XCTAssertGreaterThanOrEqual(capitalOneRule?.priority ?? 0, 100)
        
        // Gas station rules should have medium-high priority
        let gasStationRule = systemRules.first { $0.ruleName.contains("Gas Station") }
        XCTAssertNotNil(gasStationRule)
        XCTAssertGreaterThanOrEqual(gasStationRule?.priority ?? 0, 85)
        
        // General shopping rules should have lower priority
        let shoppingRule = systemRules.first { $0.ruleName.contains("Shopping") }
        if let shoppingRule = shoppingRule {
            XCTAssertLessThan(shoppingRule.priority, 90)
        }
    }
    
    func testCustomRulePriorityOverSystemRules() {
        // Test that custom rules can override system rules with higher priority
        let systemRules = CategoryRule.systemRules
        let uberSystemRule = systemRules.first { $0.merchantContains == "UBER" }
        
        var customUberRule = CategoryRule(
            categoryId: UUID(),
            ruleName: "Custom Uber Rule"
        )
        customUberRule.merchantContains = "UBER"
        customUberRule.priority = 110  // Higher than system rule
        customUberRule.confidence = 0.95
        
        let allRules = [customUberRule] + systemRules
        let sortedRules = allRules.sorted { $0.priority > $1.priority }
        
        XCTAssertEqual(sortedRules.first?.ruleName, "Custom Uber Rule")
        XCTAssertEqual(sortedRules.first?.priority, 110)
    }
    
    // MARK: - Partial Matching Tests
    
    func testPartialMerchantNameMatching() {
        // Test partial merchant name matching
        var rule = CategoryRule(
            categoryId: UUID(),
            ruleName: "Partial McDonald's Rule"
        )
        rule.merchantContains = "MCDONALD"
        rule.priority = 75
        rule.confidence = 0.88
        
        let variations = [
            "MCDONALD'S #1234",
            "MCDONALD'S RESTAURANT",
            "MCDONALDS DRIVE THRU",
            "MCDONALD ST LOUIS",
            "MCDONALD'S USA"
        ]
        
        for variation in variations {
            let transaction = Transaction(
                date: "2024-01-15",
                description: variation,
                amount: -12.50,
                category: "Other"
            )
            
            XCTAssertTrue(rule.matches(transaction: transaction), "Failed to match: \(variation)")
        }
    }
    
    func testPartialDescriptionMatching() {
        // Test partial description matching with various formats
        var rule = CategoryRule(
            categoryId: UUID(),
            ruleName: "Partial Payment Rule"
        )
        rule.descriptionContains = "PAYMENT"
        rule.priority = 80
        rule.confidence = 0.85
        
        let variations = [
            "AUTOPAYMENT PROCESSED",
            "MOBILE PAYMENT SUCCESS",
            "PAYMENT RECEIVED",
            "ELECTRONIC PAYMENT",
            "PAYMENT AUTHORIZATION"
        ]
        
        for variation in variations {
            let transaction = Transaction(
                date: "2024-01-15",
                description: variation,
                amount: 100.00,
                category: "Other"
            )
            
            XCTAssertTrue(rule.matches(transaction: transaction), "Failed to match: \(variation)")
        }
    }
    
    func testCaseInsensitiveMatching() {
        // Test case insensitive matching
        var rule = CategoryRule(
            categoryId: UUID(),
            ruleName: "Case Insensitive Rule"
        )
        rule.merchantContains = "starbucks"
        rule.priority = 75
        rule.confidence = 0.80
        
        let caseVariations = [
            "STARBUCKS COFFEE",
            "starbucks coffee",
            "Starbucks Coffee",
            "StArBuCkS CoFfEe"
        ]
        
        for variation in caseVariations {
            let transaction = Transaction(
                date: "2024-01-15",
                description: variation,
                amount: -8.50,
                category: "Other"
            )
            
            XCTAssertTrue(rule.matches(transaction: transaction), "Failed to match: \(variation)")
        }
    }
    
    func testMultipleConditionMatching() {
        // Test rules with multiple conditions
        var rule = CategoryRule(
            categoryId: UUID(),
            ruleName: "Multiple Condition Rule"
        )
        rule.merchantContains = "WALMART"
        rule.amountMin = Decimal(-200)
        rule.amountMax = Decimal(-50)
        rule.amountSign = .negative
        rule.priority = 85
        rule.confidence = 0.90
        
        let matchingTransaction = Transaction(
            date: "2024-01-15",
            description: "WALMART SUPERCENTER #1234",
            amount: -125.50,
            category: "Other"
        )
        
        let nonMatchingAmount = Transaction(
            date: "2024-01-15",
            description: "WALMART SUPERCENTER #1234",
            amount: -25.00,  // Too small
            category: "Other"
        )
        
        let nonMatchingSign = Transaction(
            date: "2024-01-15",
            description: "WALMART REFUND",
            amount: 75.00,  // Positive amount
            category: "Other"
        )
        
        let nonMatchingMerchant = Transaction(
            date: "2024-01-15",
            description: "TARGET STORE",
            amount: -100.00,
            category: "Other"
        )
        
        XCTAssertTrue(rule.matches(transaction: matchingTransaction))
        XCTAssertFalse(rule.matches(transaction: nonMatchingAmount))
        XCTAssertFalse(rule.matches(transaction: nonMatchingSign))
        XCTAssertFalse(rule.matches(transaction: nonMatchingMerchant))
    }
    
    // MARK: - Confidence Scoring Tests
    
    func testMatchConfidenceScoring() {
        // Test that match confidence is calculated correctly
        var rule = CategoryRule(
            categoryId: UUID(),
            ruleName: "Confidence Test Rule"
        )
        rule.merchantExact = "STARBUCKS"
        rule.priority = 90
        rule.confidence = 0.95
        
        let perfectMatchTransaction = Transaction(
            date: "2024-01-15",
            description: "STARBUCKS",
            amount: -8.50,
            category: "Other"
        )
        
        let partialMatchTransaction = Transaction(
            date: "2024-01-15",
            description: "STARBUCKS COFFEE #1234",
            amount: -8.50,
            category: "Other"
        )
        
        let perfectConfidence = rule.matchConfidence(for: perfectMatchTransaction)
        let partialConfidence = rule.matchConfidence(for: partialMatchTransaction)
        
        XCTAssertGreaterThan(perfectConfidence, 0.9)
        XCTAssertGreaterThan(partialConfidence, 0.8)
    }
    
    // MARK: - Performance Tests
    
    func testRuleMatchingPerformance() {
        // Test performance of rule matching
        let rules = CategoryRule.systemRules
        let transactions = (0..<100).map { index in
            Transaction(
                date: "2024-01-15",
                description: "PERFORMANCE TEST \(index)",
                amount: -Double(index),
                category: "Other"
            )
        }
        
        measure {
            for transaction in transactions {
                for rule in rules {
                    let _ = rule.matches(transaction: transaction)
                }
            }
        }
    }
    
    func testLargeRuleSetPerformance() {
        // Test performance with large rule set
        let rules = (0..<1000).map { index in
            var rule = CategoryRule(
                categoryId: UUID(),
                ruleName: "Performance Rule \(index)"
            )
            rule.merchantContains = "MERCHANT\(index)"
            rule.priority = index % 100
            rule.confidence = 0.8
            return rule
        }
        
        let transaction = Transaction(
            date: "2024-01-15",
            description: "MERCHANT500 STORE",
            amount: -50.00,
            category: "Other"
        )
        
        measure {
            for rule in rules {
                let _ = rule.matches(transaction: transaction)
            }
        }
    }
}
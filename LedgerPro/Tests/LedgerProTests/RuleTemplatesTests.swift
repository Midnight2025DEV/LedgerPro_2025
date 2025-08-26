import XCTest
@testable import LedgerPro

final class RuleTemplatesTests: XCTestCase {
    
    func test_ruleTemplates_exist() {
        let templates = CategoryRule.commonRuleTemplates
        
        XCTAssertFalse(templates.isEmpty)
        XCTAssertEqual(templates.count, 27)
    }
    
    func test_ruleTemplates_haveValidCategories() {
        let templates = CategoryRule.commonRuleTemplates
        let validCategoryIds = Set(Category.systemCategories.map { $0.id })
        
        for template in templates {
            XCTAssertTrue(validCategoryIds.contains(template.categoryId), 
                         "Template '\(template.ruleName)' has invalid category ID")
        }
    }
    
    func test_ruleTemplates_haveUniqueNames() {
        let templates = CategoryRule.commonRuleTemplates
        let names = templates.map { $0.ruleName }
        let uniqueNames = Set(names)
        
        XCTAssertEqual(names.count, uniqueNames.count)
    }
    
    func test_ruleTemplates_haveMerchantPatterns() {
        let templates = CategoryRule.commonRuleTemplates
        
        for template in templates {
            let hasPattern = template.merchantContains != nil || 
                           template.merchantExact != nil || 
                           template.regexPattern != nil ||
                           template.descriptionContains != nil
            XCTAssertTrue(hasPattern, 
                         "Template '\(template.ruleName)' has no merchant patterns")
        }
    }
    
    func test_ruleTemplates_matchExpectedTransactions() {
        let testCases: [(description: String, shouldMatch: [String])] = [
            ("STARBUCKS #1234 SEATTLE WA", ["Starbucks"]),
            ("AMAZON.COM MARKETPLACE", ["Amazon"]),
            ("UBER TRIP HELP.UBER.COM", ["Uber Rides"]),
            ("TARGET 00012345 ANYTOWN US", ["Target"]),
            ("SPOTIFY USA", ["Spotify"])
        ]
        
        let templates = CategoryRule.commonRuleTemplates
        
        for testCase in testCases {
            let transaction = Transaction(
                date: "2025-01-01",
                description: testCase.description,
                amount: -10.00,
                category: "Other"
            )
            
            let matchingTemplates = templates.filter { template in
                template.matches(transaction: transaction)
            }
            
            let matchingNames = matchingTemplates.map { $0.ruleName }
            
            for expectedMatch in testCase.shouldMatch {
                XCTAssertTrue(matchingNames.contains(expectedMatch),
                            "'\(testCase.description)' should match '\(expectedMatch)' template")
            }
        }
    }
    
    func test_ruleTemplates_havePriorities() {
        let templates = CategoryRule.commonRuleTemplates
        
        for template in templates {
            XCTAssertGreaterThanOrEqual(template.priority, 0)
            XCTAssertLessThanOrEqual(template.priority, 100)
        }
    }
    
    func test_ruleTemplates_creditCardPaymentIsPositive() {
        let templates = CategoryRule.commonRuleTemplates
        let creditCardTemplate = templates.first { $0.ruleName == "Credit Card Payments" }
        
        XCTAssertNotNil(creditCardTemplate)
        XCTAssertEqual(creditCardTemplate?.amountSign, .positive)
    }
    
    func test_ruleTemplates_expensesAreNegative() {
        let templates = CategoryRule.commonRuleTemplates
        let incomeTemplates = ["Credit Card Payments", "Salary Deposits", "General Income", "Capital One Payments"]
        let expenseTemplates = templates.filter { !incomeTemplates.contains($0.ruleName) }
        
        for template in expenseTemplates {
            XCTAssertEqual(template.amountSign, .negative,
                         "Template '\(template.ruleName)' should be for negative amounts")
        }
    }
}
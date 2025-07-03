import Testing
import Foundation
@testable import LedgerPro

struct RuleTemplatesTests {
    
    @Test("Rule templates exist and are valid")
    func test_ruleTemplates_exist() async throws {
        // Given
        let templates = CategoryRule.commonRuleTemplates
        
        // Then
        #expect(templates.count > 15, "Should have at least 15+ templates")
        
        // Verify all templates are valid
        for template in templates {
            #expect(template.isValid, "Template '\(template.ruleName)' should be valid")
            #expect(!template.ruleName.isEmpty, "Template should have a name")
            #expect(template.priority > 0, "Template should have positive priority")
        }
    }
    
    @Test("Rule templates match real transaction descriptions")
    func test_ruleTemplates_matchRealTransactions() async throws {
        // Given
        let templates = CategoryRule.commonRuleTemplates
        let testTransactions = [
            Transaction(date: "2024-01-15", description: "STARBUCKS STORE #12345", amount: -5.47, category: "Other"),
            Transaction(date: "2024-01-15", description: "AMAZON.COM AMZN.COM/BILL", amount: -45.67, category: "Other"),
            Transaction(date: "2024-01-15", description: "UBER TRIP 123ABC", amount: -23.45, category: "Other"),
            Transaction(date: "2024-01-15", description: "NETFLIX.COM LOS GATOS", amount: -15.99, category: "Other"),
            Transaction(date: "2024-01-15", description: "WALMART SUPERCENTER", amount: -78.34, category: "Other"),
            Transaction(date: "2024-01-15", description: "SHELL OIL 12345678", amount: -45.67, category: "Other"),
            Transaction(date: "2024-01-15", description: "CAPITAL ONE MOBILE PAYMENT", amount: 250.00, category: "Other")
        ]
        
        var totalMatches = 0
        
        for transaction in testTransactions {
            for template in templates {
                if template.matches(transaction: transaction) {
                    totalMatches += 1
                    break // Only count first match per transaction
                }
            }
        }
        
        // Then - Should match most transactions
        #expect(totalMatches >= 6, "Should match at least 6 out of 7 test transactions")
    }
    
    @Test("Starbucks template matches Starbucks transactions")
    func test_starbucksTemplate_matchesStarbucksTransactions() async throws {
        // Given
        let starbucksTemplate = CategoryRule.commonRuleTemplates.first { $0.ruleName == "Starbucks" }
        #expect(starbucksTemplate != nil, "Starbucks template should exist")
        
        let starbucksTransaction = Transaction(
            date: "2024-01-15",
            description: "STARBUCKS STORE #12345 SEATTLE WA",
            amount: -5.47,
            category: "Other"
        )
        
        let nonStarbucksTransaction = Transaction(
            date: "2024-01-15",
            description: "LOCAL COFFEE SHOP MAIN ST",
            amount: -4.50,
            category: "Other"
        )
        
        // Then
        #expect(starbucksTemplate!.matches(transaction: starbucksTransaction), "Should match Starbucks transaction")
        #expect(!starbucksTemplate!.matches(transaction: nonStarbucksTransaction), "Should not match non-Starbucks transaction")
    }
    
    @Test("Amazon template matches Amazon transactions with regex")
    func test_amazonTemplate_matchesWithRegex() async throws {
        // Given
        let amazonTemplate = CategoryRule.commonRuleTemplates.first { $0.ruleName == "Amazon" }
        #expect(amazonTemplate != nil, "Amazon template should exist")
        #expect(amazonTemplate!.regexPattern != nil, "Amazon template should use regex")
        
        let amazonTransactions = [
            Transaction(date: "2024-01-15", description: "AMAZON.COM AMZN.COM/BILL", amount: -45.67, category: "Other"),
            Transaction(date: "2024-01-15", description: "AMAZON MKTP US AMZN.COM/BILL", amount: -89.12, category: "Other"),
            Transaction(date: "2024-01-15", description: "AMZN MKTP US ORDER", amount: -25.34, category: "Other")
        ]
        
        let nonAmazonTransaction = Transaction(
            date: "2024-01-15",
            description: "AMAZING DEALS STORE",
            amount: -34.56,
            category: "Other"
        )
        
        // Then
        for transaction in amazonTransactions {
            #expect(amazonTemplate!.matches(transaction: transaction), "Should match Amazon transaction: \(transaction.description)")
        }
        
        #expect(!amazonTemplate!.matches(transaction: nonAmazonTransaction), "Should not match non-Amazon transaction")
    }
    
    @Test("Credit card payment template matches payment transactions")
    func test_creditCardPaymentTemplate_matchesPayments() async throws {
        // Given
        let paymentTemplate = CategoryRule.commonRuleTemplates.first { $0.ruleName == "Credit Card Payments" }
        #expect(paymentTemplate != nil, "Credit card payment template should exist")
        
        let paymentTransactions = [
            Transaction(date: "2024-01-15", description: "CAPITAL ONE MOBILE PAYMENT", amount: 250.00, category: "Other"),
            Transaction(date: "2024-01-15", description: "ONLINE PAYMENT THANK YOU", amount: 500.00, category: "Other"),
            Transaction(date: "2024-01-15", description: "AUTOPAY PAYMENT RECEIVED", amount: 300.00, category: "Other")
        ]
        
        let nonPaymentTransaction = Transaction(
            date: "2024-01-15",
            description: "GROCERY STORE PURCHASE",
            amount: -45.67,
            category: "Other"
        )
        
        // Then
        for transaction in paymentTransactions {
            #expect(paymentTemplate!.matches(transaction: transaction), "Should match payment transaction: \(transaction.description)")
        }
        
        #expect(!paymentTemplate!.matches(transaction: nonPaymentTransaction), "Should not match non-payment transaction")
    }
    
    @Test("Templates have unique names")
    func test_templates_haveUniqueNames() async throws {
        // Given
        let templates = CategoryRule.commonRuleTemplates
        let templateNames = templates.map { $0.ruleName }
        
        // Then
        #expect(Set(templateNames).count == templateNames.count, "All template names should be unique")
    }
    
    @Test("Templates have appropriate categories")
    func test_templates_haveAppropriateCategories() async throws {
        // Given
        let templates = CategoryRule.commonRuleTemplates
        let validCategoryIds = Set([
            Category.systemCategoryIds.foodDining,
            Category.systemCategoryIds.transportation,
            Category.systemCategoryIds.shopping,
            Category.systemCategoryIds.creditCardPayment,
            UUID(uuidString: "00000000-0000-0000-0000-000000000046")!, // Groceries
            UUID(uuidString: "00000000-0000-0000-0000-000000000047")!, // Subscriptions
            UUID(uuidString: "00000000-0000-0000-0000-000000000024")!  // Utilities
        ])
        
        // Then
        for template in templates {
            #expect(validCategoryIds.contains(template.categoryId), "Template '\(template.ruleName)' should have a valid category ID")
        }
    }
    
    @Test("Templates are properly prioritized")
    func test_templates_properlyPrioritized() async throws {
        // Given
        let templates = CategoryRule.commonRuleTemplates
        
        // Then
        for template in templates {
            #expect(template.priority >= 70, "Template '\(template.ruleName)' should have priority >= 70")
            #expect(template.priority <= 95, "Template '\(template.ruleName)' should have priority <= 95")
        }
        
        // Credit card payments should have highest priority
        let creditCardTemplate = templates.first { $0.ruleName == "Credit Card Payments" }
        #expect(creditCardTemplate?.priority == 95, "Credit card payments should have highest priority")
    }
}
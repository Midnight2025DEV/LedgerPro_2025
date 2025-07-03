import XCTest
@testable import LedgerPro

@MainActor
final class RuleSuggestionEngineTests: XCTestCase {
    
    private var suggestionEngine: RuleSuggestionEngine!
    private var categoryService: CategoryService!
    
    override func setUp() {
        super.setUp()
        categoryService = CategoryService.shared
        suggestionEngine = RuleSuggestionEngine(categoryService: categoryService, minimumTransactionCount: 2)
    }
    
    override func tearDown() {
        suggestionEngine = nil
        categoryService = nil
        super.tearDown()
    }
    
    // MARK: - Merchant Pattern Extraction Tests
    
    func test_extractMerchantPattern_starbucks() {
        let description = "STARBUCKS STORE #12345 SEATTLE WA"
        let pattern = suggestionEngine.extractMerchantPattern(from: description)
        
        XCTAssertEqual(pattern, "STARBUCKS")
    }
    
    func test_extractMerchantPattern_amazon() {
        let description = "AMAZON.COM AMZN.COM/BILL WA"
        let pattern = suggestionEngine.extractMerchantPattern(from: description)
        
        XCTAssertEqual(pattern, "AMAZON")
    }
    
    func test_extractMerchantPattern_uber() {
        let description = "UBER TRIP 123ABC SAN FRANCISCO"
        let pattern = suggestionEngine.extractMerchantPattern(from: description)
        
        XCTAssertEqual(pattern, "UBER")
    }
    
    func test_extractMerchantPattern_removesNumbers() {
        let description = "TARGET 00012345 ANYTOWN US"
        let pattern = suggestionEngine.extractMerchantPattern(from: description)
        
        XCTAssertEqual(pattern, "TARGET")
    }
    
    func test_extractMerchantPattern_removesStateCode() {
        let description = "SHELL OIL 12345678 HOUSTON TX"
        let pattern = suggestionEngine.extractMerchantPattern(from: description)
        
        XCTAssertEqual(pattern, "SHELL")
    }
    
    func test_extractMerchantPattern_ignoresGenericTerms() {
        let description = "PAYMENT THANK YOU"
        let pattern = suggestionEngine.extractMerchantPattern(from: description)
        
        XCTAssertEqual(pattern, "PAYMENT THANK")
    }
    
    func test_extractMerchantPattern_shortNames() {
        let description = "BP#123456789 ATLANTA GA"
        let pattern = suggestionEngine.extractMerchantPattern(from: description)
        
        XCTAssertEqual(pattern, "BP")
    }
    
    func test_extractMerchantPattern_preservesNumbers() {
        let description = "7-ELEVEN STORE #1234 SEATTLE WA"
        let pattern = suggestionEngine.extractMerchantPattern(from: description)
        
        XCTAssertEqual(pattern, "7-ELEVEN")
    }
    
    func test_extractMerchantPattern_24HourFitness() {
        let description = "24 HOUR FITNESS CLUB 12345678 SAN FRANCISCO CA"
        let pattern = suggestionEngine.extractMerchantPattern(from: description)
        
        XCTAssertEqual(pattern, "24 HOUR FITNESS")
    }
    
    func test_extractMerchantPattern_studio54() {
        let description = "STUDIO 54 NIGHTCLUB NEW YORK NY"
        let pattern = suggestionEngine.extractMerchantPattern(from: description)
        
        XCTAssertEqual(pattern, "STUDIO 54")
    }
    
    func test_extractMerchantPattern_wholeFoods365() {
        let description = "365 BY WHOLE FOODS MARKET AUSTIN TX"
        let pattern = suggestionEngine.extractMerchantPattern(from: description)
        
        XCTAssertEqual(pattern, "365 BY")
    }
    
    func test_extractMerchantPattern_airline() {
        let description = "UNITED AIRLINES FLIGHT 1234 SFO"
        let pattern = suggestionEngine.extractMerchantPattern(from: description)
        
        XCTAssertEqual(pattern, "UNITED")
    }
    
    func test_extractMerchantPattern_hotel() {
        let description = "MARRIOTT HOTEL DOWNTOWN NYC"
        let pattern = suggestionEngine.extractMerchantPattern(from: description)
        
        XCTAssertEqual(pattern, "MARRIOTT")
    }
    
    func test_extractMerchantPattern_foodDelivery() {
        let description = "DOORDASH DELIVERY FEE SAN FRANCISCO CA"
        let pattern = suggestionEngine.extractMerchantPattern(from: description)
        
        XCTAssertEqual(pattern, "DOORDASH")
    }
    
    // MARK: - Suggestion Generation Tests
    
    func test_generateSuggestions_emptyTransactions() {
        let transactions: [Transaction] = []
        let suggestions = suggestionEngine.generateSuggestions(from: transactions)
        
        XCTAssertTrue(suggestions.isEmpty)
    }
    
    func test_generateSuggestions_noUncategorizedTransactions() {
        let transactions = [
            Transaction(date: "2024-01-01", description: "STARBUCKS #1234", amount: -5.50, category: "Food & Dining"),
            Transaction(date: "2024-01-02", description: "AMAZON.COM", amount: -25.99, category: "Shopping")
        ]
        let suggestions = suggestionEngine.generateSuggestions(from: transactions)
        
        XCTAssertTrue(suggestions.isEmpty)
    }
    
    func test_generateSuggestions_frequentMerchant() {
        let transactions = [
            Transaction(date: "2024-01-01", description: "STARBUCKS STORE #1234", amount: -5.50, category: "Other"),
            Transaction(date: "2024-01-02", description: "STARBUCKS STORE #5678", amount: -4.75, category: "Other"),
            Transaction(date: "2024-01-03", description: "STARBUCKS STORE #9012", amount: -6.25, category: "Other")
        ]
        let suggestions = suggestionEngine.generateSuggestions(from: transactions)
        
        XCTAssertEqual(suggestions.count, 1)
        
        let suggestion = suggestions.first!
        XCTAssertEqual(suggestion.merchantPattern, "STARBUCKS")
        XCTAssertEqual(suggestion.transactionCount, 3)
        XCTAssertEqual(suggestion.suggestedCategory, Category.systemCategoryIds.foodDining)
        XCTAssertGreaterThan(suggestion.confidence, 0.0)
    }
    
    func test_generateSuggestions_multipleFrequentMerchants() {
        let transactions = [
            // Starbucks transactions
            Transaction(date: "2024-01-01", description: "STARBUCKS STORE #1234", amount: -5.50, category: "Other"),
            Transaction(date: "2024-01-02", description: "STARBUCKS STORE #5678", amount: -4.75, category: "Other"),
            Transaction(date: "2024-01-03", description: "STARBUCKS STORE #9012", amount: -6.25, category: "Other"),
            
            // Amazon transactions
            Transaction(date: "2024-01-04", description: "AMAZON.COM MARKETPLACE", amount: -25.99, category: "Other"),
            Transaction(date: "2024-01-05", description: "AMAZON.COM AMZN.COM/BILL", amount: -45.67, category: "Other"),
            Transaction(date: "2024-01-06", description: "AMAZON MKTP US", amount: -12.34, category: "Other"),
            
            // Single transaction (should be ignored)
            Transaction(date: "2024-01-07", description: "SINGLE PURCHASE STORE", amount: -15.00, category: "Other")
        ]
        let suggestions = suggestionEngine.generateSuggestions(from: transactions)
        
        XCTAssertEqual(suggestions.count, 2)
        
        let merchantPatterns = suggestions.map { $0.merchantPattern }
        XCTAssertTrue(merchantPatterns.contains("STARBUCKS"))
        XCTAssertTrue(merchantPatterns.contains("AMAZON"))
    }
    
    func test_generateSuggestions_lowConfidenceTransactions() {
        let transactions = [
            Transaction(date: "2024-01-01", description: "STARBUCKS #1234", amount: -5.50, category: "Food", confidence: 0.3),
            Transaction(date: "2024-01-02", description: "STARBUCKS #5678", amount: -4.75, category: "Food", confidence: 0.4),
            Transaction(date: "2024-01-03", description: "STARBUCKS #9012", amount: -6.25, category: "Food", confidence: 0.2)
        ]
        let suggestions = suggestionEngine.generateSuggestions(from: transactions)
        
        XCTAssertEqual(suggestions.count, 1)
        XCTAssertEqual(suggestions.first?.merchantPattern, "STARBUCKS")
    }
    
    func test_generateSuggestions_belowMinimumThreshold() {
        let engine = RuleSuggestionEngine(categoryService: categoryService, minimumTransactionCount: 5)
        let transactions = [
            Transaction(date: "2024-01-01", description: "STARBUCKS #1234", amount: -5.50, category: "Other"),
            Transaction(date: "2024-01-02", description: "STARBUCKS #5678", amount: -4.75, category: "Other"),
            Transaction(date: "2024-01-03", description: "STARBUCKS #9012", amount: -6.25, category: "Other")
        ]
        let suggestions = engine.generateSuggestions(from: transactions)
        
        XCTAssertTrue(suggestions.isEmpty)
    }
    
    // MARK: - Category Suggestion Tests
    
    func test_categorySuggestion_starbucks() {
        let transactions = [
            Transaction(date: "2024-01-01", description: "STARBUCKS STORE #1234", amount: -5.50, category: "Other"),
            Transaction(date: "2024-01-02", description: "STARBUCKS STORE #5678", amount: -4.75, category: "Other")
        ]
        let suggestions = suggestionEngine.generateSuggestions(from: transactions)
        
        XCTAssertEqual(suggestions.first?.suggestedCategory, Category.systemCategoryIds.foodDining)
    }
    
    func test_categorySuggestion_uber() {
        let transactions = [
            Transaction(date: "2024-01-01", description: "UBER TRIP 123ABC", amount: -15.50, category: "Other"),
            Transaction(date: "2024-01-02", description: "UBER EATS DELIVERY", amount: -25.75, category: "Other")
        ]
        let suggestions = suggestionEngine.generateSuggestions(from: transactions)
        
        XCTAssertEqual(suggestions.first?.suggestedCategory, Category.systemCategoryIds.transportation)
    }
    
    func test_categorySuggestion_amazon() {
        let transactions = [
            Transaction(date: "2024-01-01", description: "AMAZON.COM MARKETPLACE", amount: -45.99, category: "Other"),
            Transaction(date: "2024-01-02", description: "AMAZON MKTP US", amount: -125.67, category: "Other")
        ]
        let suggestions = suggestionEngine.generateSuggestions(from: transactions)
        
        XCTAssertEqual(suggestions.first?.suggestedCategory, Category.systemCategoryIds.shopping)
    }
    
    func test_categorySuggestion_netflix() {
        let transactions = [
            Transaction(date: "2024-01-01", description: "NETFLIX.COM", amount: -15.99, category: "Other"),
            Transaction(date: "2024-01-02", description: "NETFLIX.COM", amount: -15.99, category: "Other")
        ]
        let suggestions = suggestionEngine.generateSuggestions(from: transactions)
        
        let subscriptionsId = UUID(uuidString: "00000000-0000-0000-0000-000000000047")!
        XCTAssertEqual(suggestions.first?.suggestedCategory, subscriptionsId)
    }
    
    func test_categorySuggestion_byAmount_highPositive() {
        let transactions = [
            Transaction(date: "2024-01-01", description: "PAYROLL DEPOSIT", amount: 3000.00, category: "Other"),
            Transaction(date: "2024-01-02", description: "PAYROLL DEPOSIT", amount: 3100.00, category: "Other")
        ]
        let suggestions = suggestionEngine.generateSuggestions(from: transactions)
        
        XCTAssertEqual(suggestions.first?.suggestedCategory, Category.systemCategoryIds.salary)
    }
    
    func test_categorySuggestion_byAmount_mediumNegative() {
        let transactions = [
            Transaction(date: "2024-01-01", description: "UNKNOWN MERCHANT ABC", amount: -75.00, category: "Other"),
            Transaction(date: "2024-01-02", description: "UNKNOWN MERCHANT ABC", amount: -85.00, category: "Other")
        ]
        let suggestions = suggestionEngine.generateSuggestions(from: transactions)
        
        XCTAssertEqual(suggestions.first?.suggestedCategory, Category.systemCategoryIds.shopping)
    }
    
    // MARK: - RuleSuggestion Model Tests
    
    func test_ruleSuggestion_toCategoryRule() {
        let suggestion = RuleSuggestion(
            merchantPattern: "STARBUCKS",
            transactionCount: 5,
            suggestedCategory: Category.systemCategoryIds.foodDining,
            averageAmount: Decimal(-5.50),
            exampleTransactions: []
        )
        
        let rule = suggestion.toCategoryRule()
        
        XCTAssertEqual(rule.ruleName, "STARBUCKS")
        XCTAssertEqual(rule.categoryId, Category.systemCategoryIds.foodDining)
        XCTAssertEqual(rule.merchantContains, "STARBUCKS")
        XCTAssertEqual(rule.amountSign, .negative)
        XCTAssertTrue(rule.isActive)
        XCTAssertGreaterThanOrEqual(rule.priority, 70)
        XCTAssertLessThanOrEqual(rule.priority, 90)
    }
    
    func test_ruleSuggestion_confidence_calculation() {
        let transactions = [
            Transaction(date: "2024-01-01", description: "TEST MERCHANT", amount: -10.00, category: "Other"),
            Transaction(date: "2024-01-02", description: "TEST MERCHANT", amount: -10.50, category: "Other"),
            Transaction(date: "2024-01-03", description: "TEST MERCHANT", amount: -9.50, category: "Other")
        ]
        
        let suggestion = RuleSuggestion(
            merchantPattern: "TEST MERCHANT",
            transactionCount: 3,
            suggestedCategory: Category.systemCategoryIds.other,
            averageAmount: Decimal(-10.00),
            exampleTransactions: transactions
        )
        
        XCTAssertGreaterThan(suggestion.confidence, 0.0)
        XCTAssertLessThanOrEqual(suggestion.confidence, 1.0)
    }
    
    // MARK: - Transaction Extension Tests
    
    func test_transaction_needsCategorization() {
        let otherTransaction = Transaction(date: "2024-01-01", description: "TEST", amount: -10.00, category: "Other")
        let lowConfidenceTransaction = Transaction(date: "2024-01-01", description: "TEST", amount: -10.00, category: "Food", confidence: 0.3)
        let categorizedTransaction = Transaction(date: "2024-01-01", description: "TEST", amount: -10.00, category: "Food", confidence: 0.8)
        
        XCTAssertTrue(otherTransaction.needsCategorization)
        XCTAssertTrue(lowConfidenceTransaction.needsCategorization)
        XCTAssertFalse(categorizedTransaction.needsCategorization)
    }
}
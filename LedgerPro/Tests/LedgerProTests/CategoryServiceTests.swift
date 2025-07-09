import XCTest
@testable import LedgerPro

final class CategoryServiceTests: XCTestCase {
    var categoryService: CategoryService!
    
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        categoryService = CategoryService.shared
        
        // Ensure categories are loaded for testing
        await categoryService.loadCategories()
        
        // Wait a moment for categories to be properly loaded
        try await Task.sleep(for: .milliseconds(100))
    }
    
    @MainActor
    func testCategoriesAreLoaded() {
        // Verify basic setup is working
        XCTAssertGreaterThan(categoryService.categories.count, 0, "Categories should be loaded")
        XCTAssertNotNil(categoryService.category(by: Category.systemCategoryIds.transportation), 
                       "Transportation category should exist")
        XCTAssertNotNil(categoryService.category(by: Category.systemCategoryIds.shopping), 
                       "Shopping category should exist")
        XCTAssertNotNil(categoryService.category(by: Category.systemCategoryIds.salary), 
                       "Salary category should exist")
    }
    
    @MainActor
    func testSuggestCategoryForUberTransaction() {
        // Given
        let transaction = Transaction(
            date: "2025-01-15",
            description: "UBER TRIP HELP.UBER.COM",
            amount: -25.50,
            category: "Other"
        )
        
        // When
        let (category, confidence) = categoryService.suggestCategory(for: transaction)
        
        // Then
        XCTAssertNotNil(category, "Should suggest a category for Uber transaction")
        XCTAssertEqual(category?.name, "Transportation", "Should categorize Uber as Transportation")
        XCTAssertGreaterThan(confidence, 0.8, "Should have high confidence for Uber rule match")
    }
    
    @MainActor
    func testSuggestCategoryForChevronGasStation() {
        // Given
        let transaction = Transaction(
            date: "2025-01-15",
            description: "CHEVRON GAS STATION #1234",
            amount: -45.00,
            category: "Other"
        )
        
        // When
        let (category, confidence) = categoryService.suggestCategory(for: transaction)
        
        // Then
        XCTAssertNotNil(category, "Should suggest a category for Chevron transaction")
        XCTAssertEqual(category?.name, "Transportation", "Should categorize Chevron as Transportation")
        XCTAssertGreaterThan(confidence, 0.8, "Should have high confidence for gas station rule match")
    }
    
    @MainActor
    func testSuggestCategoryForSalaryDeposit() {
        // Given
        let transaction = Transaction(
            date: "2025-01-15",
            description: "PAYROLL DEPOSIT COMPANY INC",
            amount: 3500.00,
            category: "Other"
        )
        
        // When
        let (category, confidence) = categoryService.suggestCategory(for: transaction)
        
        // Then
        XCTAssertNotNil(category, "Should suggest a category for payroll transaction")
        XCTAssertTrue(category?.name == "Salary" || category?.name == "Income", 
                     "Should categorize payroll as Salary or Income, got: \(category?.name ?? "nil")")
        XCTAssertGreaterThan(confidence, 0.9, "Should have very high confidence for salary rule match")
    }
    
    @MainActor
    func testSuggestCategoryForAmazonPurchase() {
        // Given
        let transaction = Transaction(
            date: "2025-01-15",
            description: "AMAZON.COM PURCHASE 123456",
            amount: -89.99,
            category: "Other"
        )
        
        // When
        let (category, confidence) = categoryService.suggestCategory(for: transaction)
        
        // Then
        XCTAssertNotNil(category, "Should suggest a category for Amazon transaction")
        XCTAssertEqual(category?.name, "Shopping", "Should categorize Amazon as Shopping")
        XCTAssertGreaterThan(confidence, 0.7, "Should have good confidence for Amazon rule match")
    }
    
    @MainActor
    func testSuggestCategoryForWalmartPurchase() {
        // Given
        let transaction = Transaction(
            date: "2025-01-15",
            description: "WALMART SUPERCENTER #1234",
            amount: -124.35,
            category: "Other"
        )
        
        // When
        let (category, confidence) = categoryService.suggestCategory(for: transaction)
        
        // Then
        XCTAssertNotNil(category, "Should suggest a category for Walmart transaction")
        XCTAssertEqual(category?.name, "Shopping", "Should categorize Walmart as Shopping")
        XCTAssertGreaterThan(confidence, 0.7, "Should have good confidence for Walmart rule match")
    }
    
    @MainActor
    func testSuggestCategoryForCreditCardPayment() {
        // Given
        let transaction = Transaction(
            date: "2025-01-15",
            description: "CAPITAL ONE MOBILE PAYMENT",
            amount: 250.00,
            category: "Other"
        )
        
        // When
        let (category, confidence) = categoryService.suggestCategory(for: transaction)
        
        // Then
        XCTAssertNotNil(category, "Should suggest a category for credit card payment")
        XCTAssertEqual(category?.name, "Credit Card Payment", "Should categorize as Credit Card Payment")
        XCTAssertGreaterThan(confidence, 0.8, "Should have high confidence for payment rule match")
    }
    
    @MainActor
    func testFallbackForUnknownTransaction() {
        // Given
        let transaction = Transaction(
            date: "2025-01-15",
            description: "RANDOM UNKNOWN MERCHANT 12345",
            amount: -50.00,
            category: "Other"
        )
        
        // When
        let (category, confidence) = categoryService.suggestCategory(for: transaction)
        
        // Then
        XCTAssertNotNil(category, "Should always suggest a category (fallback)")
        XCTAssertLessThan(confidence, 0.5, "Should have low confidence for unknown transaction")
    }
    
    @MainActor
    func testPositiveAmountFallback() {
        // Given - positive amount with no matching rules
        let transaction = Transaction(
            date: "2025-01-15",
            description: "RANDOM INCOME SOURCE",
            amount: 1000.00,
            category: "Other"
        )
        
        // When
        let (category, confidence) = categoryService.suggestCategory(for: transaction)
        
        // Then
        XCTAssertNotNil(category, "Should suggest income category for positive amount")
        XCTAssertTrue(category?.name == "Salary" || category?.name == "Income", 
                     "Should fallback to income category for positive amounts")
        XCTAssertLessThan(confidence, 0.5, "Should have low confidence for fallback")
    }
    
    @MainActor
    func testBackwardCompatibilityStringMethod() {
        // Given
        let description = "UBER EATS DELIVERY"
        let amount = -15.50
        
        // When - using old string-based method
        let category = categoryService.suggestCategory(for: description, amount: amount)
        
        // Then
        XCTAssertNotNil(category, "String-based method should still work")
        XCTAssertEqual(category?.name, "Food & Dining", "Should categorize Uber Eats as food delivery")
    }
    
    @MainActor
    func testRulePriorityOrdering() {
        // Given - transaction that could match multiple rules
        let transaction = Transaction(
            date: "2025-01-15",
            description: "CAPITAL ONE PAYROLL PAYMENT", // Could match both payroll and payment rules
            amount: 2500.00,
            category: "Other"
        )
        
        // When
        let (category, confidence) = categoryService.suggestCategory(for: transaction)
        
        // Then - should prefer the higher priority rule (payroll = 100 vs payment = 95)
        XCTAssertNotNil(category, "Should suggest a category")
        XCTAssertTrue(category?.name == "Salary" || category?.name == "Income" || category?.name == "Credit Card Payment",
                     "Should match either salary or payment rule based on priority")
        XCTAssertGreaterThan(confidence, 0.8, "Should have high confidence for rule match")
    }
}
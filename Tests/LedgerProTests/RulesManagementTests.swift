import XCTest
@testable import LedgerPro

// MARK: - RuleViewModel Tests
final class RuleViewModelTests: XCTestCase {
    var viewModel: RuleViewModel!
    
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        viewModel = RuleViewModel()
    }
    
    func test_init_loadsAllRules() {
        // Then
        XCTAssertFalse(viewModel.rules.isEmpty)
        XCTAssertTrue(viewModel.rules.contains { rule in
            CategoryRule.systemRules.contains { $0.id == rule.id }
        })
        XCTAssertTrue(viewModel.isLoading == false)
    }
    
    func test_filterRules_byActiveStatus() {
        // Given
        viewModel.filterActive = true
        
        // When
        let filtered = viewModel.filteredRules
        
        // Then
        XCTAssertTrue(filtered.allSatisfy { $0.isActive })
    }
    
    func test_createRule_fromTransaction() {
        // Given
        let transaction = Transaction(
            date: "2025-01-01",
            description: "STARBUCKS #1234",
            amount: -5.75,
            category: "Other"
        )
        
        // When
        let rule = viewModel.createRule(from: transaction)
        
        // Then
        XCTAssertEqual(rule.merchantContains, "STARBUCKS")
        XCTAssertEqual(rule.ruleName, "STARBUCKS #1234 Rule")
        XCTAssertTrue(rule.isActive)
    }
}

// MARK: - Rule Builder Tests
final class RuleBuilderTests: XCTestCase {
    @MainActor
    func test_ruleValidation_requiresName() {
        // Given
        let builder = RuleBuilder()
        
        // When
        builder.merchantContains = "Amazon"
        
        // Then
        XCTAssertFalse(builder.isValid)
        XCTAssertEqual(builder.validationErrors.first, "Rule name is required")
    }
    
    @MainActor
    func test_testRule_againstTransactions() {
        // Given
        let builder = RuleBuilder()
        builder.ruleName = "Amazon Shopping"
        builder.merchantContains = "AMAZON"
        builder.categoryId = UUID() // Required for building valid rule
        
        let testTransactions = [
            Transaction(date: "2025-01-01", description: "AMAZON MARKETPLACE", amount: -50, category: "Other"),
            Transaction(date: "2025-01-02", description: "WALMART", amount: -30, category: "Other"),
            Transaction(date: "2025-01-03", description: "AMAZON PRIME", amount: -15, category: "Other")
        ]
        
        // When
        let matches = builder.testRule(against: testTransactions)
        
        // Then
        XCTAssertEqual(matches.count, 2)
        XCTAssertTrue(matches.allSatisfy { $0.description.contains("AMAZON") })
    }
}
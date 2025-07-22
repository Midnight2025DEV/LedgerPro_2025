import XCTest
@testable import LedgerPro

@MainActor
final class RuleStorageServiceTests: XCTestCase {
    var storageService: RuleStorageService!
    var testFileName: String!
    
    
    override func setUp() async throws {
        try await super.setUp()
        // Create unique test filename for each test
        testFileName = "test_rules_\(UUID().uuidString).json"
        // Create isolated test instance with unique filename
        storageService = await RuleStorageService(testFileName: testFileName)
    }
    
    
    override func tearDown() async throws {
        // Clean up test file
        await storageService.cleanupTestFile()
        try await super.tearDown()
    }
    
    
    func testSaveAndLoadCustomRule() {
        // Given
        var customRule = CategoryRule(
            categoryId: Category.systemCategoryIds.shopping,
            ruleName: "Target Stores"
        )
        customRule.merchantContains = "TARGET"
        customRule.amountMin = -100
        customRule.amountMax = -10
        customRule.priority = 85
        
        // When
        storageService.saveRule(customRule)
        
        // Then
        XCTAssertEqual(storageService.customRules.count, 1)
        XCTAssertEqual(storageService.customRules.first?.ruleName, "Target Stores")
        XCTAssertEqual(storageService.customRules.first?.merchantContains, "TARGET")
        
        // Test persistence by creating new instance with same test file
        let newStorageService = RuleStorageService(testFileName: testFileName)
        XCTAssertEqual(newStorageService.customRules.count, 1)
        XCTAssertEqual(newStorageService.customRules.first?.ruleName, "Target Stores")
    }
    
    
    func testUpdateCustomRule() {
        // Given
        var customRule = CategoryRule(
            categoryId: Category.systemCategoryIds.shopping,
            ruleName: "Original Rule"
        )
        customRule.merchantContains = "TEST"
        storageService.saveRule(customRule)
        
        // When
        var updatedRule = customRule
        updatedRule.ruleName = "Updated Rule"
        updatedRule.merchantContains = "UPDATED"
        storageService.updateRule(updatedRule)
        
        // Then
        XCTAssertEqual(storageService.customRules.count, 1)
        XCTAssertEqual(storageService.customRules.first?.ruleName, "Updated Rule")
        XCTAssertEqual(storageService.customRules.first?.merchantContains, "UPDATED")
    }
    
    
    func testDeleteCustomRule() {
        // Given
        var rule1 = CategoryRule(
            categoryId: Category.systemCategoryIds.shopping,
            ruleName: "Rule 1"
        )
        rule1.merchantContains = "STORE1"
        
        var rule2 = CategoryRule(
            categoryId: Category.systemCategoryIds.transportation,
            ruleName: "Rule 2"
        )
        rule2.merchantContains = "TRANSIT"
        
        storageService.saveRule(rule1)
        storageService.saveRule(rule2)
        
        XCTAssertEqual(storageService.customRules.count, 2)
        
        // When
        storageService.deleteRule(id: rule1.id)
        
        // Then
        XCTAssertEqual(storageService.customRules.count, 1)
        XCTAssertEqual(storageService.customRules.first?.ruleName, "Rule 2")
    }
    
    
    func testAllRulesIncludesSystemAndCustom() {
        // Given
        var customRule = CategoryRule(
            categoryId: Category.systemCategoryIds.shopping,
            ruleName: "Custom Shopping Rule"
        )
        customRule.merchantContains = "CUSTOM"
        storageService.saveRule(customRule)
        
        // When
        let allRules = storageService.allRules
        
        // Then
        XCTAssertGreaterThan(allRules.count, CategoryRule.systemRules.count)
        XCTAssertTrue(allRules.contains { $0.ruleName == "Custom Shopping Rule" })
        XCTAssertTrue(allRules.contains { $0.ruleName.contains("Uber") })
    }
    
    
    func testPersistenceAcrossInstances() {
        // Given
        var rule1 = CategoryRule(
            categoryId: Category.systemCategoryIds.foodDining,
            ruleName: "Restaurant Rule"
        )
        rule1.merchantContains = "RESTAURANT"
        rule1.amountSign = .negative
        rule1.confidence = 0.9
        
        // When
        storageService.saveRule(rule1)
        
        // Create new instance with same test file and verify
        let freshStorageService = RuleStorageService(testFileName: testFileName)
        
        // Then
        XCTAssertEqual(freshStorageService.customRules.count, 1)
        let loadedRule = freshStorageService.customRules.first
        XCTAssertEqual(loadedRule?.ruleName, "Restaurant Rule")
        XCTAssertEqual(loadedRule?.merchantContains, "RESTAURANT")
        XCTAssertEqual(loadedRule?.amountSign, .negative)
        XCTAssertEqual(loadedRule?.confidence, 0.9)
    }
}
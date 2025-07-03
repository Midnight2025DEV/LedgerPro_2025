# LedgerPro Testing Framework Template

## 🧪 Testing Strategy for Every Feature

### Phase Planning Template

When starting any new feature, always create:
1. **Unit Tests** - Test individual components
2. **Integration Tests** - Test component interactions
3. **Debug Scripts** - Quick validation scripts
4. **Manual Test Checklists** - User flow validation

---

## 📋 Standard Test Creation Prompts for Claude Code

### 1. Unit Test Creation Prompt
```
Create unit tests for [FEATURE_NAME]:

cat > Tests/LedgerProTests/[Feature]Tests.swift << 'EOF'
import XCTest
@testable import LedgerPro

final class [Feature]Tests: XCTestCase {
    var sut: [FeatureClass]! // System Under Test
    
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        sut = [FeatureClass]()
        // Additional setup
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    func test_init_setsDefaultValues() {
        // Given/When - handled in setUp
        // Then
        XCTAssertNotNil(sut)
        // Add specific assertions
    }
    
    // MARK: - [Core Functionality] Tests
    func test_[methodName]_with[Condition]_returns[Expected]() {
        // Given
        let input = [TestData]
        
        // When
        let result = sut.[methodName](input)
        
        // Then
        XCTAssertEqual(result, expectedValue)
    }
    
    // MARK: - Edge Cases
    func test_[methodName]_withEmptyInput_handlesGracefully() {
        // Test edge cases
    }
    
    // MARK: - Error Handling
    func test_[methodName]_withInvalidData_throwsError() {
        // Test error scenarios
    }
}
EOF

swift test --filter [Feature]Tests
```

### 2. Integration Test Creation Prompt
```
Create integration tests for [FEATURE_NAME] interacting with [OTHER_COMPONENT]:

cat > Tests/LedgerProTests/[Feature]IntegrationTests.swift << 'EOF'
import XCTest
@testable import LedgerPro

final class [Feature]IntegrationTests: XCTestCase {
    var feature: [FeatureClass]!
    var dependency: [DependencyClass]!
    
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        dependency = [DependencyClass].shared
        await dependency.loadData() // If needed
        feature = [FeatureClass](dependency: dependency)
    }
    
    func test_integration_[scenario]_producesExpectedResult() {
        // Given
        let testData = createTestData()
        
        // When
        let result = feature.process(testData)
        
        // Then
        XCTAssertEqual(result.count, expectedCount)
        // Verify side effects on dependency
    }
}
EOF
```

### 3. Debug Script Creation Prompt
```
Create a debug script to validate [FEATURE_NAME]:

cat > Scripts/debug_[feature].swift << 'EOF'
#!/usr/bin/env swift

import Foundation

// Quick validation script for [FEATURE_NAME]
print("🧪 Testing [FEATURE_NAME]")
print("=" * 50)

// Test Case 1: Basic functionality
print("\n📍 Test 1: Basic [feature] operation")
let input1 = [test data]
let expected1 = [expected result]
let result1 = [operation]
print("Input: \(input1)")
print("Expected: \(expected1)")
print("Result: \(result1)")
print("✅ Pass" if result1 == expected1 else "❌ Fail")

// Test Case 2: Edge case
print("\n📍 Test 2: Edge case handling")
// Similar structure

// Performance Test
print("\n⏱️ Performance Test")
let startTime = Date()
// Run operation 1000 times
let iterations = 1000
for _ in 0..<iterations {
    _ = [operation]
}
let duration = Date().timeIntervalSince(startTime)
print("Completed \(iterations) operations in \(duration) seconds")
print("Average: \(duration/Double(iterations)*1000)ms per operation")

print("\n✅ Debug validation complete!")
EOF

chmod +x Scripts/debug_[feature].swift
./Scripts/debug_[feature].swift
```

### 4. Manual Test Checklist Creation Prompt
```
Create a manual testing checklist for [FEATURE_NAME]:

cat > Tests/ManualTests/[FEATURE_NAME]_CHECKLIST.md << 'EOF'
# [FEATURE_NAME] Manual Testing Checklist

## Pre-Test Setup
- [ ] Clean build (Cmd+Shift+K)
- [ ] Delete DerivedData if needed
- [ ] Ensure test data is available

## Functional Tests

### Basic Flow
- [ ] Launch app
- [ ] Navigate to [feature location]
- [ ] [Primary action] works correctly
- [ ] Visual feedback appears (loading, success, error states)
- [ ] Data persists after action

### Edge Cases
- [ ] Empty state displays correctly
- [ ] Maximum data limits handled
- [ ] Special characters in input
- [ ] Very long text truncates properly
- [ ] Rapid clicks don't cause issues

### Integration Points
- [ ] [Feature] updates when [related feature] changes
- [ ] Navigation works from [feature] to other views
- [ ] Data syncs correctly across views

### Error Scenarios
- [ ] Network timeout handling (if applicable)
- [ ] Invalid data shows appropriate error
- [ ] Recovery from error state works

### Performance
- [ ] No UI freezing during operations
- [ ] Smooth scrolling with large datasets
- [ ] Memory usage remains stable

### Accessibility
- [ ] VoiceOver reads all elements
- [ ] Keyboard navigation works
- [ ] Color contrast sufficient

## Post-Test Verification
- [ ] No console errors
- [ ] No memory leaks
- [ ] All automated tests still pass

## Test Data
- Small dataset: 10 items
- Medium dataset: 100 items  
- Large dataset: 1000+ items

## Notes
[Record any issues or observations]

---
Tested by: _____________
Date: _____________
Version: _____________
EOF
```

---

## 🏗️ Example: Testing CategoryRule Integration

### Phase 1 Testing Implementation
```bash
# 1. Create unit tests
PROMPT: Create unit tests for CategoryRule matching logic
RESULT: 10 tests covering rule conditions, confidence scoring, priority

# 2. Create integration tests  
PROMPT: Create integration tests for CategoryService using CategoryRule
RESULT: 11 tests validating rule engine integration

# 3. Create debug script
PROMPT: Create debug script to test rule matching performance
RESULT: Performance validation showing <1ms per rule match

# 4. Create manual checklist
PROMPT: Create manual test checklist for category suggestions UI
RESULT: Comprehensive UI validation checklist
```

---

## 📊 Test Coverage Standards

### Minimum Coverage Requirements
- **Unit Tests**: 80% code coverage
- **Critical Paths**: 100% coverage
- **Error Handling**: All error cases tested
- **Edge Cases**: Empty, nil, extreme values

### Test Naming Convention
```swift
func test_[methodName]_[condition]_[expectedResult]()

Examples:
- test_suggestCategory_withUberTransaction_returnsTransportation()
- test_saveRule_withInvalidData_throwsValidationError()
- test_importFile_withEmptyFile_showsEmptyStateMessage()
```

---

## 🔍 Debug Script Patterns

### Data Validation Script
```swift
// Validate data integrity
let allCategories = CategoryService.shared.categories
print("Total categories: \(allCategories.count)")
print("Missing colors: \(allCategories.filter { $0.color.isEmpty })")
print("Duplicate names: \(findDuplicates(in: allCategories))")
```

### Performance Profiling Script
```swift
// Measure operation performance
measureTime("Rule matching") {
    let results = transactions.map { categoryService.suggestCategory(for: $0) }
    print("Categorized \(results.count) transactions")
}
```

### State Inspection Script
```swift
// Inspect current state
print("🔍 Current State:")
print("- Rules loaded: \(RuleStorageService.shared.allRules.count)")
print("- Custom rules: \(RuleStorageService.shared.customRules.count)")
print("- Categories: \(CategoryService.shared.categories.count)")
```

---

## 🚀 Continuous Testing Workflow

### For Every New Feature
1. **Before Coding**
   ```
   PROMPT: Create test plan for [FEATURE_NAME] including:
   - Key test scenarios
   - Edge cases to cover
   - Performance benchmarks
   - Integration points
   ```

2. **During Development**
   ```
   PROMPT: Create unit test for [specific method]
   PROMPT: Create debug script to validate [specific behavior]
   ```

3. **After Implementation**
   ```
   PROMPT: Create integration tests for [FEATURE] with [SYSTEM]
   PROMPT: Create manual test checklist for QA validation
   ```

4. **Before Merge**
   ```
   swift test                    # Run all tests
   ./Scripts/debug_all.swift     # Run all debug scripts
   Review manual test checklists # Ensure UI/UX validated
   ```

---

## 📝 Test Documentation Template

### Test Summary Report
```markdown
# [FEATURE_NAME] Test Report

## Test Coverage
- Unit Tests: X/Y passing (Z% coverage)
- Integration Tests: X/Y passing
- Manual Tests: Completed ✓

## Performance Metrics
- Average operation time: Xms
- Memory usage: YMB
- Handles Z transactions/second

## Known Issues
- [Issue 1]: [Description] - [Workaround]

## Test Data Used
- [Dataset 1]: [Description]
- [Dataset 2]: [Description]

## Validation Date: [DATE]
## Validated By: [NAME]
```

---

## 🎯 Quick Reference: Common Test Prompts

### Create Basic Test Suite
```
Create a complete test suite for [FeatureName] with:
1. Unit tests for all public methods
2. Integration test with [RelatedService]
3. Debug script for quick validation
4. Manual test checklist
```

### Add Edge Case Tests
```
Add edge case tests for [FeatureName]:
- Empty input handling
- Nil/optional handling  
- Maximum size limits
- Special characters
- Concurrent access
```

### Create Performance Tests
```
Create performance tests for [FeatureName]:
- Measure average operation time
- Test with 1, 100, 1000, 10000 items
- Memory usage profiling
- Identify bottlenecks
```

### Debug Failing Tests
```
Create debug script to investigate why [TestName] is failing:
- Print intermediate values
- Validate test data
- Check state before/after
- Compare expected vs actual
```

---

*Use this template for every feature to ensure comprehensive testing and maintainable code!*
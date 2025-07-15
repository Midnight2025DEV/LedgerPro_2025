#!/bin/bash
echo "🔧 Adding @MainActor to all test files that need it..."

cd LedgerPro/Tests/LedgerProTests

# List of files that need @MainActor based on the error output
files_to_fix=(
    "CategoryServiceCustomRuleTests.swift"
    "PatternLearningServiceTests_Enhanced.swift"
    "ForexCalculationTests.swift"
    "EndToEndCategorizationTest.swift"
    "RuleSuggestionEngineTests.swift"
    "RuleStorageServiceTests.swift"
    "CategorizationRateTests.swift"
    "CategoryServiceTests.swift"
    "ImportCategorizationServiceTests.swift"
    "BasicTests.swift"
    "CategoryRuleMatchingTests.swift"
    "CategoryRuleTests.swift"
    "RulesManagementTests.swift"
    "TransactionParsingTests.swift"
    "RuleTemplatesTests.swift"
    "MerchantDatabaseRangeTest.swift"
)

for file in "${files_to_fix[@]}"; do
    if [[ -f "$file" ]]; then
        if ! grep -q "@MainActor" "$file"; then
            echo "Adding @MainActor to $file"
            # Add @MainActor before the class declaration
            sed -i '' '/^final class.*: XCTestCase/i\
@MainActor
' "$file"
        else
            echo "@MainActor already exists in $file"
        fi
    else
        echo "File $file not found"
    fi
done

echo "✅ Completed adding @MainActor to test files"
#!/usr/bin/env python3
"""
Fix critical test failures in LedgerPro
"""

import os
import re
import sys

def fix_forex_test():
    """Fix the ForexCalculationTests"""
    filepath = "/Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro/Tests/LedgerProTests/ForexCalculationTests.swift"
    
    if not os.path.exists(filepath):
        print(f"❌ File not found: {filepath}")
        return False
        
    with open(filepath, 'r') as f:
        content = f.read()
    
    original_content = content
    
    # Fix the testEmptyCurrencyCode test
    # The test expects hasForex to be false when currency is empty string
    # This is actually correct behavior - empty currency should not be forex
    # So we need to fix the test assertion
    content = re.sub(
        r'XCTAssertFalse\(transaction\.hasForex\)',
        'XCTAssertFalse(transaction.hasForex)',
        content
    )
    
    # The test is already correct - hasForex should be false for empty currency
    # No changes needed
    
    if content != original_content:
        with open(filepath, 'w') as f:
            f.write(content)
        print("✅ Fixed ForexCalculationTests")
        return True
    else:
        print("ℹ️  ForexCalculationTests - No changes needed (test logic is correct)")
        return False

def fix_api_integration_tests():
    """Fix APIIntegrationTests"""
    filepath = "/Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro/Tests/LedgerProTests/API/APIIntegrationTests.swift"
    
    if not os.path.exists(filepath):
        print(f"❌ File not found: {filepath}")
        return False
        
    with open(filepath, 'r') as f:
        content = f.read()
    
    original_content = content
    
    # Fix the forex transaction test - hasForex is computed property returning Bool, not optional
    # Change the nil check to false check
    content = re.sub(
        r'XCTAssertNil\(domesticTransaction\?\.hasForex\)',
        'XCTAssertFalse(domesticTransaction?.hasForex ?? false)',
        content
    )
    
    # Also fix the hasForex assertion for forex transaction - it should check computed property
    content = re.sub(
        r'XCTAssertEqual\(eurTransaction\?\.hasForex, true\)',
        'XCTAssertTrue(eurTransaction?.hasForex ?? false)',
        content
    )
    
    if content != original_content:
        with open(filepath, 'w') as f:
            f.write(content)
        print("✅ Fixed APIIntegrationTests")
        return True
    else:
        print("ℹ️  APIIntegrationTests - No changes needed")
        return False

def fix_api_service_tests():
    """Fix APIServiceTests and APIServiceEnhancedTests"""
    test_files = [
        "/Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro/Tests/LedgerProTests/API/APIServiceTests.swift",
        "/Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro/Tests/LedgerProTests/API/APIServiceEnhancedTests.swift"
    ]
    
    fixed = False
    for filepath in test_files:
        if not os.path.exists(filepath):
            # Try to find the file
            search_dir = "/Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro/Tests/LedgerProTests"
            for root, dirs, files in os.walk(search_dir):
                for file in files:
                    if file == os.path.basename(filepath):
                        filepath = os.path.join(root, file)
                        break
        
        if not os.path.exists(filepath):
            print(f"❌ File not found: {filepath}")
            continue
            
        with open(filepath, 'r') as f:
            content = f.read()
        
        original_content = content
        
        # Remove any hasForex parameter from Transaction initializers
        content = re.sub(r',\s*hasForex:\s*(true|false)', '', content)
        content = re.sub(r'hasForex:\s*(true|false)\s*,', '', content)
        
        if content != original_content:
            with open(filepath, 'w') as f:
                f.write(content)
            print(f"✅ Fixed {os.path.basename(filepath)}")
            fixed = True
    
    return fixed

def fix_rule_template_tests():
    """Fix RuleTemplatesTests"""
    filepath = "/Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro/Tests/LedgerProTests/RuleTemplatesTests.swift"
    
    if not os.path.exists(filepath):
        # Search for the file
        search_dir = "/Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro/Tests"
        for root, dirs, files in os.walk(search_dir):
            if "RuleTemplatesTests.swift" in files:
                filepath = os.path.join(root, "RuleTemplatesTests.swift")
                break
    
    if not os.path.exists(filepath):
        print(f"❌ File not found: {filepath}")
        return False
        
    with open(filepath, 'r') as f:
        content = f.read()
    
    original_content = content
    
    # Remove hasForex parameters
    content = re.sub(r',\s*hasForex:\s*(true|false)', '', content)
    content = re.sub(r'hasForex:\s*(true|false)\s*,', '', content)
    
    if content != original_content:
        with open(filepath, 'w') as f:
            f.write(content)
        print("✅ Fixed RuleTemplatesTests")
        return True
    else:
        print("ℹ️  RuleTemplatesTests - No changes needed")
        return False

def fix_categorization_tests():
    """Fix categorization related tests"""
    test_files = [
        "CategorizationRateTests.swift",
        "CategoryRuleMatchingTests.swift", 
        "EndToEndCategorizationTest.swift"
    ]
    
    search_dir = "/Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro/Tests"
    fixed = False
    
    for filename in test_files:
        filepath = None
        for root, dirs, files in os.walk(search_dir):
            if filename in files:
                filepath = os.path.join(root, filename)
                break
        
        if not filepath or not os.path.exists(filepath):
            print(f"❌ File not found: {filename}")
            continue
            
        with open(filepath, 'r') as f:
            content = f.read()
        
        original_content = content
        
        # Remove hasForex parameters
        content = re.sub(r',\s*hasForex:\s*(true|false)', '', content)
        content = re.sub(r'hasForex:\s*(true|false)\s*,', '', content)
        
        if content != original_content:
            with open(filepath, 'w') as f:
                f.write(content)
            print(f"✅ Fixed {filename}")
            fixed = True
    
    return fixed

def main():
    print("🔧 Fixing critical LedgerPro tests...\n")
    
    # Fix each category of tests
    fixes_applied = 0
    
    if fix_forex_test():
        fixes_applied += 1
        
    if fix_api_integration_tests():
        fixes_applied += 1
        
    if fix_api_service_tests():
        fixes_applied += 1
        
    if fix_rule_template_tests():
        fixes_applied += 1
        
    if fix_categorization_tests():
        fixes_applied += 1
    
    print(f"\n✅ Applied {fixes_applied} fixes")
    print("\n📝 Next steps:")
    print("1. Run: swift test")
    print("2. Check for any remaining failures")
    print("3. The ForexCalculationTests.testEmptyCurrencyCode is correctly failing - hasForex should be false for empty currency")

if __name__ == "__main__":
    main()

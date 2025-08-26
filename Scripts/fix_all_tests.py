#!/usr/bin/env python3
"""
Fix critical test failures in LedgerPro
This script addresses the main test failures by:
1. Removing hasForex parameters from Transaction initializers
2. Fixing assertion types for hasForex checks
3. Providing guidance on API tests that need backend
"""

import os
import re
import sys
from pathlib import Path

# Base test directory
TEST_DIR = Path("/Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro/Tests")

def find_swift_files(directory):
    """Find all Swift test files"""
    return list(Path(directory).rglob("*.swift"))

def fix_hasforex_parameters(content):
    """Remove hasForex parameters from Transaction initializers"""
    patterns = [
        # Pattern 1: hasForex at end with comma before
        (r',\s*hasForex:\s*(true|false)', ''),
        # Pattern 2: hasForex at beginning with comma after
        (r'hasForex:\s*(true|false)\s*,', ''),
        # Pattern 3: hasForex as only parameter
        (r'\(\s*hasForex:\s*(true|false)\s*\)', '()'),
        # Pattern 4: Line with just hasForex
        (r'^\s*hasForex:\s*(true|false)\s*\n', '', re.MULTILINE),
    ]
    
    modified = False
    for pattern, replacement, *flags in patterns:
        flag = flags[0] if flags else 0
        new_content = re.sub(pattern, replacement, content, flags=flag)
        if new_content != content:
            content = new_content
            modified = True
    
    return content, modified

def fix_hasforex_assertions(content, filename):
    """Fix hasForex assertion types based on file"""
    modified = False
    
    if "APIIntegrationTests.swift" in filename:
        # Fix nil assertion to false assertion
        new_content = content.replace(
            'XCTAssertNil(domesticTransaction?.hasForex)',
            'XCTAssertFalse(domesticTransaction?.hasForex ?? false)'
        )
        if new_content != content:
            content = new_content
            modified = True
    
    # Fix assertEquals for hasForex (it's not optional)
    pattern = r'XCTAssertEqual\(([^)]+)\.hasForex,\s*true\)'
    replacement = r'XCTAssertTrue(\1.hasForex)'
    new_content = re.sub(pattern, replacement, content)
    if new_content != content:
        content = new_content
        modified = True
    
    return content, modified

def process_file(filepath):
    """Process a single Swift file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"❌ Error reading {filepath}: {e}")
        return False
    
    original_content = content
    
    # Apply fixes
    content, mod1 = fix_hasforex_parameters(content)
    content, mod2 = fix_hasforex_assertions(content, str(filepath))
    
    if mod1 or mod2:
        try:
            # Create backup
            backup_path = f"{filepath}.backup"
            with open(backup_path, 'w', encoding='utf-8') as f:
                f.write(original_content)
            
            # Write fixed content
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            
            # Remove backup
            os.remove(backup_path)
            
            print(f"✅ Fixed {filepath.name}")
            return True
        except Exception as e:
            print(f"❌ Error writing {filepath}: {e}")
            # Restore from backup if it exists
            if os.path.exists(backup_path):
                os.rename(backup_path, filepath)
            return False
    
    return False

def main():
    print("🔧 Fixing critical LedgerPro test failures...\n")
    
    if not TEST_DIR.exists():
        print(f"❌ Test directory not found: {TEST_DIR}")
        return 1
    
    # Find all Swift test files
    swift_files = find_swift_files(TEST_DIR)
    print(f"📁 Found {len(swift_files)} Swift test files\n")
    
    # Process each file
    fixed_count = 0
    for filepath in swift_files:
        if process_file(filepath):
            fixed_count += 1
    
    print(f"\n✅ Fixed {fixed_count} files")
    
    # Print summary and guidance
    print("\n" + "="*60)
    print("📋 TEST FAILURE ANALYSIS")
    print("="*60)
    
    print("\n1️⃣ ForexCalculationTests.testEmptyCurrencyCode:")
    print("   ✅ Test logic is CORRECT - hasForex should be false for empty currency")
    print("   📝 This is the expected behavior based on Transaction.hasForex implementation")
    
    print("\n2️⃣ API-related tests (16 failures):")
    print("   ⚠️  These tests require the backend server to be running")
    print("   🚀 Start backend: cd backend && ./start_backend.sh")
    print("   📝 Tests will be skipped if backend is unavailable")
    
    print("\n3️⃣ Categorization tests:")
    print("   ✅ Should pass after removing hasForex parameters")
    
    print("\n4️⃣ RuleTemplatesTests:")
    print("   ✅ Fixed by removing hasForex from Transaction initializers")
    
    print("\n" + "="*60)
    print("🎯 NEXT STEPS")
    print("="*60)
    print("1. Start the backend server (if testing API functionality)")
    print("2. Run tests: swift test")
    print("3. For specific test: swift test --filter TestClassName.testMethodName")
    print("4. For parallel execution: swift test --parallel")
    
    print("\n💡 TIP: Most failures are API tests that need the backend.")
    print("   Focus on non-API tests first for core functionality validation.")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())

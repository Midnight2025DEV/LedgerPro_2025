#!/usr/bin/env python3

import os
import re
import sys

def fix_hasforex_in_file(filepath):
    """Remove hasForex parameter from Transaction initializers in a file."""
    with open(filepath, 'r') as f:
        content = f.read()
    
    original_content = content
    
    # Pattern 1: Remove lines that are just "hasForex: true" or "hasForex: false"
    # This handles cases where hasForex is on its own line
    content = re.sub(r'^\s*hasForex:\s*(true|false)\s*\n', '', content, flags=re.MULTILINE)
    
    # Pattern 2: Remove hasForex when it's the last parameter (with comma before it)
    # This handles: "exchangeRate: 0.058,\n            hasForex: true"
    content = re.sub(r',\s*\n\s*hasForex:\s*(true|false)', '', content)
    
    # Pattern 3: Remove hasForex when it's inline with comma after
    # This handles: "hasForex: true,"
    content = re.sub(r'hasForex:\s*(true|false)\s*,', '', content)
    
    # Pattern 4: Remove hasForex when it's inline as last parameter
    # This handles: "category: 'Other', hasForex: false)"
    content = re.sub(r',\s*hasForex:\s*(true|false)\s*\)', ')', content)
    
    if content != original_content:
        with open(filepath, 'w') as f:
            f.write(content)
        return True
    return False

def main():
    # Find all Swift test files
    test_dir = "/Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro/Tests"
    
    fixed_count = 0
    for root, dirs, files in os.walk(test_dir):
        for file in files:
            if file.endswith('.swift'):
                filepath = os.path.join(root, file)
                if fix_hasforex_in_file(filepath):
                    print(f"Fixed: {filepath}")
                    fixed_count += 1
    
    print(f"\nTotal files fixed: {fixed_count}")

if __name__ == "__main__":
    main()

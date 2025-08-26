#!/bin/bash

# Script to remove hasForex parameter from all test files

echo "Fixing hasForex parameter in test files..."

# Find all Swift test files
find LedgerPro/Tests -name "*.swift" -type f | while read -r file; do
    # Check if file contains hasForex parameter
    if grep -q "hasForex:" "$file"; then
        echo "Fixing: $file"
        
        # Create temporary file
        temp_file="${file}.tmp"
        
        # Remove lines with just "hasForex: true" or "hasForex: false"
        sed -E '/^[[:space:]]*hasForex:[[:space:]]*(true|false)[[:space:]]*$/d' "$file" > "$temp_file"
        
        # Remove hasForex parameter when it's on the same line with other parameters
        # This handles cases like "exchangeRate: 0.058,\n                hasForex: true"
        sed -i '' -E 's/,[[:space:]]*hasForex:[[:space:]]*(true|false)//g' "$temp_file"
        
        # Replace the original file
        mv "$temp_file" "$file"
    fi
done

echo "Completed fixing hasForex parameters in test files"

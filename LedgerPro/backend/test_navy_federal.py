#!/usr/bin/env python3
"""
Navy Federal CSV Format Tester
Tests the enhanced CSV processor with Navy Federal files
"""

import csv
import sys
from processors.python.csv_processor_enhanced import EnhancedCSVProcessor


def analyze_csv_structure(file_path):
    """Analyze the structure of a CSV file."""
    print(f"🔍 Analyzing CSV structure: {file_path}")
    print("=" * 80)

    with open(file_path, 'r', encoding='utf-8-sig') as f:
        lines = f.readlines()

    print(f"Total lines: {len(lines)}")
    print("\nFirst 20 lines:")
    print("-" * 80)
    for i, line in enumerate(lines[:20]):
        print(f"Line {i+1}: {line.strip()}")

    print("\n" + "=" * 80)

    # Try to detect sections
    processor = EnhancedCSVProcessor()
    content = ''.join(lines)
    sections = processor.detect_sections(content)

    print(f"\nDetected {len(sections)} sections:")
    for i, section in enumerate(sections):
        print(f"\nSection {i+1}:")
        print(f"  Header: {section['header']}")
        print(f"  Data rows: {len(section['data'])}")
        print(f"  Start line: {section['start_line']}")

        if section['data']:
            print(f"  First data row: {section['data'][0][:100]}...")


def test_navy_federal_processing(file_path):
    """Test processing with enhanced CSV processor."""
    print("\n🔄 Processing with EnhancedCSVProcessor...")
    print("=" * 80)

    processor = EnhancedCSVProcessor()
    result = processor.process_csv_file(file_path)

    print(f"\nProcessing Result:")
    print(f"  Status: {result['status']}")
    print(f"  Total transactions: {len(result['transactions'])}")

    if result['transactions']:
        print(f"\nFirst 5 transactions:")
        for i, txn in enumerate(result['transactions'][:5]):
            print(f"\n  Transaction {i+1}:")
            print(f"    Date: {txn['date']}")
            print(f"    Description: {txn['description']}")
            print(f"    Amount: ${txn['amount']:.2f}")
            print(f"    Category: {txn['category']}")
            if txn.get('has_forex'):
                print(f"    Forex: {txn['original_amount']} {txn['original_currency']} @ {txn['exchange_rate']}")
            if txn.get('raw_data'):
                print(f"    Raw data keys: {list(txn['raw_data'].keys())}")

    return result


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python test_navy_federal.py <navy_federal.csv>")
        sys.exit(1)

    file_path = sys.argv[1]

    # Analyze structure
    analyze_csv_structure(file_path)

    # Test processing
    result = test_navy_federal_processing(file_path)

    # Summary
    print("\n" + "=" * 80)
    print("📊 SUMMARY:")
    print(f"  Expected transactions: ~1013")
    print(f"  Actual transactions: {len(result['transactions'])}")
    print(f"  Success rate: {len(result['transactions'])/1013*100:.1f}%")

    if len(result['transactions']) < 100:
        print("\n❌ CRITICAL: Processing failed to extract expected transactions!")
        print("   The CSV format may need special handling.")

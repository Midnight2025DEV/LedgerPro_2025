#!/usr/bin/env python3
"""Verify that foreign currency detection is working correctly"""

import sys
from pathlib import Path

# Add PDF processor to path
sys.path.insert(0, str(Path(__file__).parent.parent / "mcp-servers" / "pdf-processor"))

import pdf_processor_server

def test_forex_detection():
    """Test forex detection on sample data"""
    
    # Sample Capital One forex transaction format
    sample_table = [
        ["May 16 May 17 UBER* EATSCIUDAD DE MEXCDM $34.60\n$672.51\nMXN\n19.436705202 Exchange Rate"],
        ["May 16 May 17 UBER* EATSCIUDAD DE MEXCDM $1.92\n$37.36\nMXN\n19.458333333 Exchange Rate"],
        ["May 16 May 17 FRUTERIA EL PARAISOTIJUANA BCN $10.81\n$210.02\nMXN\n19.428307123 Exchange Rate"]
    ]
    
    print("🧪 Testing forex detection on sample data...")
    
    for i, row in enumerate(sample_table, 1):
        print(f"\n📝 Sample {i}: {row[0][:50]}...")
        
        transactions = pdf_processor_server.parse_capital_one_transactions([row])
        
        if transactions:
            txn = transactions[0]
            print(f"  ✅ Parsed transaction:")
            print(f"     Description: {txn.get('description')}")
            print(f"     Amount: ${txn.get('amount')}")
            print(f"     Has forex: {txn.get('has_forex', False)}")
            
            if txn.get('has_forex'):
                print(f"     Original: {txn.get('original_amount')} {txn.get('original_currency')}")
                print(f"     Exchange rate: {txn.get('exchange_rate')}")
            else:
                print("     ❌ No forex data detected")
        else:
            print("  ❌ No transaction parsed")
    
    print(f"\n🎉 Forex detection test completed!")

if __name__ == "__main__":
    test_forex_detection()
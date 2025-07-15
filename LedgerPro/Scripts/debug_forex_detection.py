#!/usr/bin/env python3
"""Debug foreign currency detection in Capital One transactions"""

import sys
from pathlib import Path

# Add PDF processor to path
sys.path.insert(0, str(Path(__file__).parent.parent / "mcp-servers" / "pdf-processor"))

import pdf_processor_server
import asyncio

async def debug_forex():
    """Debug foreign currency transaction detection"""
    
    # Find Capital One PDF
    test_dir = Path.home() / "Documents" / "LedgerPro_Test_Statements"
    pdf_file = None
    for pdf in test_dir.glob("*Capital*One*.pdf"):
        pdf_file = pdf
        break
    
    if not pdf_file:
        print("❌ No Capital One PDF found")
        return
    
    print(f"🔍 Debugging forex detection in: {pdf_file.name}")
    
    # Process the PDF
    result = await pdf_processor_server.process_bank_pdf(str(pdf_file), processor="auto")
    
    if not result.get("success"):
        print(f"❌ Processing failed: {result.get('error')}")
        return
    
    transactions = result.get("transactions", [])
    print(f"📊 Total transactions found: {len(transactions)}")
    
    # Look for foreign currency indicators
    forex_indicators = []
    mexico_transactions = []
    uber_transactions = []
    
    for i, txn in enumerate(transactions):
        desc = txn.get("description", "").upper()
        
        # Check for Mexico/foreign indicators
        if any(indicator in desc for indicator in ["MEXICO", "MEX", "CDM", "TIJUANA", "MXN"]):
            mexico_transactions.append((i, txn))
            
        if "UBER" in desc:
            uber_transactions.append((i, txn))
    
    print(f"\n🇲🇽 Mexico-related transactions: {len(mexico_transactions)}")
    for i, (idx, txn) in enumerate(mexico_transactions[:5]):
        print(f"  {i+1}. {txn.get('date')} - {txn.get('description')} - ${txn.get('amount')}")
    
    print(f"\n🚗 Uber transactions: {len(uber_transactions)}")  
    for i, (idx, txn) in enumerate(uber_transactions[:5]):
        print(f"  {i+1}. {txn.get('date')} - {txn.get('description')} - ${txn.get('amount')}")
    
    # Check if any transactions have forex fields
    forex_transactions = []
    for txn in transactions:
        if any(key in txn for key in ["original_amount", "exchange_rate", "original_currency", "has_forex"]):
            forex_transactions.append(txn)
    
    print(f"\n💱 Transactions with forex fields: {len(forex_transactions)}")
    for i, txn in enumerate(forex_transactions[:3]):
        print(f"  {i+1}. {txn}")
    
    # Test foreign currency detection logic
    print(f"\n🧪 Testing forex detection on sample transaction...")
    
    # Sample transaction that should have forex
    sample_desc = "UBER* EATSCIUDAD DE MEXCDM $26.03"
    print(f"Sample: {sample_desc}")
    
    # This should detect Mexico and foreign currency
    has_mexico = any(word in sample_desc.upper() for word in ["MEXICO", "MEX", "CDM", "TIJUANA"])
    has_foreign_amount = "$" in sample_desc and any(curr in sample_desc for curr in ["MXN", "EUR", "GBP"])
    
    print(f"  - Has Mexico indicator: {has_mexico}")
    print(f"  - Has foreign amount: {has_foreign_amount}")

if __name__ == "__main__":
    asyncio.run(debug_forex())
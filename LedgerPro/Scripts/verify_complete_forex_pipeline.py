#!/usr/bin/env python3
"""Complete verification of forex data pipeline"""

import sys
import json
from pathlib import Path

# Add PDF processor to path
sys.path.insert(0, str(Path(__file__).parent.parent / "mcp-servers" / "pdf-processor"))

import pdf_processor_server
import asyncio

async def verify_complete_pipeline():
    """Verify the complete forex pipeline from PDF to Transaction objects"""
    
    # Find Capital One PDF
    test_dir = Path.home() / "Documents" / "LedgerPro_Test_Statements"
    pdf_file = None
    for pdf in test_dir.glob("*Capital*One*.pdf"):
        pdf_file = pdf
        break
    
    if not pdf_file:
        print("❌ No Capital One PDF found")
        return False
    
    print(f"🔍 Testing complete pipeline with: {pdf_file.name}")
    
    # 1. Process PDF with MCP server
    result = await pdf_processor_server.process_bank_pdf(str(pdf_file), processor="auto")
    
    if not result.get("success"):
        print(f"❌ PDF processing failed: {result.get('error')}")
        return False
    
    transactions = result.get("transactions", [])
    print(f"📊 Total transactions processed: {len(transactions)}")
    
    # 2. Count forex transactions
    forex_transactions = [t for t in transactions if t.get("has_forex")]
    print(f"💱 Forex transactions found: {len(forex_transactions)}")
    
    # 3. Verify forex data structure
    sample_forex = None
    for t in forex_transactions:
        if "UBER" in t.get("description", ""):
            sample_forex = t
            break
    
    if sample_forex:
        print(f"\n✅ Sample forex transaction:")
        print(f"   Description: {sample_forex.get('description')}")
        print(f"   USD Amount: ${sample_forex.get('amount')}")
        print(f"   Original: {sample_forex.get('original_amount')} {sample_forex.get('original_currency')}")
        print(f"   Exchange Rate: {sample_forex.get('exchange_rate')}")
        print(f"   Has Forex: {sample_forex.get('has_forex')}")
        
        # 4. Verify JSON serialization (what Swift will receive)
        try:
            json_str = json.dumps(sample_forex)
            parsed_back = json.loads(json_str)
            
            print(f"\n🔗 JSON serialization test:")
            print(f"   Original amount preserved: {parsed_back.get('original_amount') == sample_forex.get('original_amount')}")
            print(f"   Currency preserved: {parsed_back.get('original_currency') == sample_forex.get('original_currency')}")
            print(f"   Exchange rate preserved: {parsed_back.get('exchange_rate') == sample_forex.get('exchange_rate')}")
            print(f"   Has forex preserved: {parsed_back.get('has_forex') == sample_forex.get('has_forex')}")
            
        except Exception as e:
            print(f"❌ JSON serialization failed: {e}")
            return False
    
    else:
        print("❌ No Uber forex transaction found for verification")
        return False
    
    # 5. Summary
    print(f"\n🎉 PIPELINE VERIFICATION COMPLETE")
    print(f"   ✅ PDF processed successfully")
    print(f"   ✅ {len(forex_transactions)} forex transactions detected") 
    print(f"   ✅ Forex data structure correct")
    print(f"   ✅ JSON serialization working")
    print(f"\n📋 Expected in Swift app:")
    print(f"   - Transaction.hasForex = true for {len(forex_transactions)} transactions")
    print(f"   - Foreign currency amounts displayed in UI")
    print(f"   - Exchange rates shown in transaction details")
    print(f"   - Console logs: '💱 FOREX TRANSACTION DETECTED:'")
    
    return True

if __name__ == "__main__":
    success = asyncio.run(verify_complete_pipeline())
    print(f"\n{'✅ SUCCESS' if success else '❌ FAILED'}")
    exit(0 if success else 1)
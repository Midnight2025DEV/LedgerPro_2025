#!/usr/bin/env python3
"""Test the PDF processor server directly to debug processing issues"""

import asyncio
import json
import sys
import os
from pathlib import Path

# Add the mcp-servers directory to Python path
sys.path.insert(0, str(Path(__file__).parent.parent / "mcp-servers" / "pdf-processor"))

# Import the PDF processor
import pdf_processor_server

async def test_pdf_processing():
    """Test PDF processing with a Capital One statement"""
    
    # Look for test PDFs
    test_dir = Path.home() / "Documents" / "LedgerPro_Test_Statements"
    capital_one_pdf = None
    
    # Find Capital One PDF
    for pdf in test_dir.glob("*Capital*One*.pdf"):
        capital_one_pdf = pdf
        break
    
    if not capital_one_pdf:
        print("❌ No Capital One PDF found in test directory")
        return
    
    print(f"📄 Testing with: {capital_one_pdf.name}")
    print(f"📏 File size: {capital_one_pdf.stat().st_size / 1024 / 1024:.2f} MB")
    
    # Test bank detection
    print("\n🔍 Testing bank detection...")
    try:
        detection_result = await pdf_processor_server.detect_bank(str(capital_one_pdf))
        print(f"✅ Bank detected: {detection_result['bank']} (confidence: {detection_result['confidence']})")
    except Exception as e:
        print(f"❌ Bank detection failed: {e}")
        import traceback
        traceback.print_exc()
    
    # Test PDF processing
    print("\n📊 Testing PDF processing...")
    try:
        start_time = asyncio.get_event_loop().time()
        result = await pdf_processor_server.process_bank_pdf(str(capital_one_pdf), processor="auto")
        end_time = asyncio.get_event_loop().time()
        
        processing_time = end_time - start_time
        print(f"⏱️  Processing time: {processing_time:.2f} seconds")
        
        if result.get("success"):
            transactions = result.get("transactions", [])
            print(f"✅ Successfully processed {len(transactions)} transactions")
            
            # Show first 3 transactions as sample
            print("\n📝 Sample transactions:")
            for i, txn in enumerate(transactions[:3]):
                print(f"  {i+1}. {txn.get('date')} - {txn.get('description')} - ${txn.get('amount')}")
            
            # Show summary
            if "summary" in result:
                summary = result["summary"]
                print(f"\n📊 Summary:")
                print(f"  - Total transactions: {summary.get('transaction_count', 0)}")
                print(f"  - Total credits: ${summary.get('total_credits', 0):.2f}")
                print(f"  - Total debits: ${summary.get('total_debits', 0):.2f}")
                print(f"  - Net amount: ${summary.get('net_amount', 0):.2f}")
        else:
            print(f"❌ Processing failed: {result.get('error', 'Unknown error')}")
            
    except Exception as e:
        print(f"❌ PDF processing crashed: {e}")
        import traceback
        traceback.print_exc()
    
    # Test response size
    print("\n📦 Testing JSON response size...")
    try:
        # Simulate the full MCP response structure
        mcp_response = {
            "jsonrpc": "2.0",
            "id": "test-id",
            "result": {
                "isError": False,
                "content": [{
                    "type": "text",
                    "text": json.dumps(result)
                }]
            }
        }
        
        json_str = json.dumps(mcp_response)
        print(f"📏 Full MCP response size: {len(json_str) / 1024:.2f} KB ({len(json_str)} bytes)")
        
        # Check if it exceeds buffer limits
        if len(json_str) > 10_000_000:
            print("⚠️  WARNING: Response exceeds 10MB buffer limit!")
        elif len(json_str) > 5_000_000:
            print("⚠️  WARNING: Response is large (>5MB), may cause buffering issues")
        else:
            print("✅ Response size is within safe limits")
            
    except Exception as e:
        print(f"❌ Failed to calculate response size: {e}")

if __name__ == "__main__":
    print("🧪 PDF Processor Direct Test")
    print("=" * 50)
    asyncio.run(test_pdf_processing())
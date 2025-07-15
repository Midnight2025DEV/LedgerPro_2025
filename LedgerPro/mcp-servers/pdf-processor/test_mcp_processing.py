#!/usr/bin/env python3
"""
Test script to test the MCP PDF processor directly
"""
import sys
import os
import asyncio

# Add the current directory to Python path
sys.path.insert(0, os.path.dirname(__file__))

import pdf_processor_server

async def test_pdf_processing():
    """Test the PDF processing functionality"""
    pdf_path = "/var/folders/cd/w56n39qj36lfn_641_wy_m_h0000gn/T/70EB0199-E3C5-4664-8534-FFED62709FB7_Capital One_Credit Card_May 2025_Statement.pdf"
    
    print(f"🧪 Testing MCP PDF Processor")
    print(f"📄 PDF: {os.path.basename(pdf_path)}")
    print("=" * 60)
    
    try:
        # Test 1: Bank detection
        print("\n1. Testing bank detection...")
        result = await pdf_processor_server.detect_bank(pdf_path)
        print(f"   Detected bank: {result.get('bank', 'unknown')}")
        print(f"   Confidence: {result.get('confidence', 0.0)}")
        print(f"   Evidence: {result.get('evidence', [])}")
        
        # Test 2: PDF text extraction
        print("\n2. Testing text extraction...")
        text_result = await pdf_processor_server.extract_pdf_text(pdf_path)
        content = text_result.get('content', [])
        if content and content[0].get('text'):
            first_page_text = content[0]['text']
            print(f"   Pages extracted: {len(content)}")
            print(f"   First page text length: {len(first_page_text)} characters")
            print(f"   First 200 chars: {first_page_text[:200]}...")
        else:
            print("   ❌ No text extracted")
            print(f"   Result structure: {text_result.keys()}")
        
        # Test 3: Table extraction
        print("\n3. Testing table extraction...")
        table_result = await pdf_processor_server.extract_pdf_tables(pdf_path)
        tables = table_result.get('tables', [])
        print(f"   Found {len(tables)} tables across all pages")
        for i, table_info in enumerate(tables):
            if isinstance(table_info, dict) and 'data' in table_info:
                table_data = table_info['data']
                print(f"   Table {i+1} (Page {table_info.get('page', '?')}): {table_info.get('rows', 0)} rows, {table_info.get('columns', 0)} columns")
                if table_data and len(table_data) > 0:
                    sample_row = table_data[0][:3] if len(table_data[0]) > 3 else table_data[0]
                    print(f"     Sample: {sample_row}")
            else:
                print(f"   Table {i+1}: Invalid format - {type(table_info)}")
        
        # Test 4: Full bank statement processing
        print("\n4. Testing full bank statement processing...")
        process_result = await pdf_processor_server.process_bank_pdf(
            pdf_path, 
            bank="capital_one",
            processor="auto"
        )
        
        print(f"   Processing status: {'✅ Success' if process_result.get('success') else '❌ Failed'}")
        print(f"   Transactions found: {len(process_result.get('transactions', []))}")
        print(f"   Metadata: {process_result.get('metadata', {})}")
        
        if process_result.get('transactions'):
            print("\n   Sample transactions:")
            for i, txn in enumerate(process_result['transactions'][:3]):
                print(f"     {i+1}. {txn.get('date', 'N/A')} | {txn.get('description', 'N/A')} | ${txn.get('amount', 0.0)}")
        else:
            print("   ⚠️ No transactions extracted")
            if process_result.get('errors'):
                print(f"   Errors: {process_result['errors']}")
        
        return process_result
        
    except Exception as e:
        print(f"❌ Error during testing: {e}")
        import traceback
        traceback.print_exc()
        return None

if __name__ == "__main__":
    result = asyncio.run(test_pdf_processing())
    print("\n" + "=" * 60)
    if result and result.get('success'):
        print("🎉 PDF processing test completed successfully!")
    else:
        print("💥 PDF processing test failed!")
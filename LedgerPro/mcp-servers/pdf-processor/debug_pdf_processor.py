#!/usr/bin/env python3
"""
Debug the PDF processor to see why Capital One transactions aren't being extracted
"""
import sys
import os

# Add the current directory to Python path
sys.path.insert(0, os.path.dirname(__file__))

import pdf_processor_server

async def debug_pdf_processing():
    """Debug PDF processing step by step"""
    pdf_path = "/var/folders/cd/w56n39qj36lfn_641_wy_m_h0000gn/T/70EB0199-E3C5-4664-8534-FFED62709FB7_Capital One_Credit Card_May 2025_Statement.pdf"
    
    print(f"🔍 Debugging PDF Processing")
    print(f"📄 PDF: {os.path.basename(pdf_path)}")
    print("=" * 80)
    
    # Step 1: Extract tables
    table_result = await pdf_processor_server.extract_pdf_tables(pdf_path)
    tables = table_result.get('tables', [])
    
    print(f"\n1. Found {len(tables)} tables")
    
    # Step 2: Process each table
    for i, table_info in enumerate(tables):
        if isinstance(table_info, dict) and 'data' in table_info:
            table_data = table_info['data']
            print(f"\n📊 Table {i+1} (Page {table_info.get('page', '?')}):")
            print(f"   Rows: {len(table_data)}, Columns: {table_data[0] if table_data else 'N/A'}")
            
            # Test the Capital One parser on this table
            print(f"   Testing Capital One parser...")
            transactions = pdf_processor_server.parse_capital_one_transactions(table_data)
            print(f"   Found {len(transactions)} transactions in this table")
            
            if transactions:
                print(f"   Sample transactions:")
                for j, txn in enumerate(transactions[:3]):
                    print(f"     {j+1}. {txn['date']} | {txn['description']} | ${txn['amount']}")
            else:
                # Show table content for debugging
                print(f"   Table content (first 3 rows):")
                for row_idx, row in enumerate(table_data[:3]):
                    print(f"     Row {row_idx+1}: {row}")
    
    # Step 3: Test full processing
    print(f"\n3. Testing full processing...")
    result = await pdf_processor_server.process_bank_pdf(pdf_path, bank="capital_one", processor="auto")
    print(f"   Status: {'✅ Success' if result.get('success') else '❌ Failed'}")
    print(f"   Transactions: {len(result.get('transactions', []))}")
    print(f"   Metadata: {result.get('metadata', {})}")

if __name__ == "__main__":
    import asyncio
    asyncio.run(debug_pdf_processing())
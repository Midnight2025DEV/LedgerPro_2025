#!/usr/bin/env python3
"""
Debug Capital One table extraction to see the actual content
"""
import pdfplumber
import sys

def debug_capital_one_tables(pdf_path):
    """Debug what's actually in the Capital One tables"""
    
    print(f"🔍 Debugging Capital One tables in: {pdf_path}")
    print("=" * 80)
    
    with pdfplumber.open(pdf_path) as pdf:
        for page_num, page in enumerate(pdf.pages):
            tables = page.extract_tables()
            
            if tables:
                print(f"\n📄 PAGE {page_num + 1} - Found {len(tables)} tables:")
                for table_idx, table in enumerate(tables):
                    print(f"\n  📊 Table {table_idx + 1}:")
                    print(f"     Rows: {len(table)}, Columns: {len(table[0]) if table else 0}")
                    
                    # Show all rows for tables that might contain transactions
                    if table and len(table) > 2:  # Might have header + transactions
                        print(f"     Content:")
                        for row_idx, row in enumerate(table):
                            print(f"       Row {row_idx + 1}: {row}")
                    elif table:
                        # Show first few rows for smaller tables
                        print(f"     Sample rows:")
                        for row_idx, row in enumerate(table[:3]):
                            print(f"       Row {row_idx + 1}: {row}")

if __name__ == "__main__":
    pdf_path = "/var/folders/cd/w56n39qj36lfn_641_wy_m_h0000gn/T/70EB0199-E3C5-4664-8534-FFED62709FB7_Capital One_Credit Card_May 2025_Statement.pdf"
    debug_capital_one_tables(pdf_path)
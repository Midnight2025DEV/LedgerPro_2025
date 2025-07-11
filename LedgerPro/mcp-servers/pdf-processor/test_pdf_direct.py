import pdfplumber
import sys

if len(sys.argv) > 1:
    pdf_path = sys.argv[1]
    print(f"Testing PDF: {pdf_path}")
    try:
        with pdfplumber.open(pdf_path) as pdf:
            print(f"Pages: {len(pdf.pages)}")
            print(f"First page text preview:")
            first_page_text = pdf.pages[0].extract_text()
            if first_page_text:
                print(first_page_text[:500])
            else:
                print("No text found on first page")
            
            # Check for tables
            for i, page in enumerate(pdf.pages[:3]):
                tables = page.extract_tables()
                print(f"\nPage {i+1} has {len(tables)} tables")
                if tables:
                    for j, table in enumerate(tables):
                        print(f"  Table {j+1}: {len(table)} rows")
                        if table and len(table) > 0:
                            print(f"    Sample row: {table[0][:3] if len(table[0]) > 3 else table[0]}")
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
else:
    print("Please provide a PDF path")
#!/usr/bin/env python3
"""
Fix critical API issues in LedgerPro backend
"""

import os
import re
import shutil
from datetime import datetime

def backup_file(filepath):
    """Create a backup of the file before modifying"""
    backup_path = f"{filepath}.backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    shutil.copy2(filepath, backup_path)
    print(f"✅ Backed up {os.path.basename(filepath)}")
    return backup_path

def fix_net_amount_calculation():
    """Fix the $1.00 calculation error in api_server_real.py"""
    filepath = "/Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro/backend/api_server_real.py"
    
    if not os.path.exists(filepath):
        print(f"❌ File not found: {filepath}")
        return False
    
    backup_file(filepath)
    
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Fix the net_amount calculation bug
    original = '"net_amount": total_income + total_expenses,'
    fixed = '"net_amount": total_income - total_expenses,'
    
    if original in content:
        content = content.replace(original, fixed)
        with open(filepath, 'w') as f:
            f.write(content)
        print("✅ Fixed net_amount calculation (changed + to -)")
        return True
    else:
        print("⚠️  net_amount calculation already fixed or pattern not found")
        return False

def fix_csv_forex_detection():
    """Fix forex column detection in csv_processor_enhanced.py"""
    filepath = "/Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro/backend/processors/python/csv_processor_enhanced.py"
    
    if not os.path.exists(filepath):
        print(f"❌ File not found: {filepath}")
        return False
    
    backup_file(filepath)
    
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Add forex column definitions after category_columns
    forex_columns_def = '''
        
        self.forex_columns = {
            "original_amount": ["original amount", "original_amount", "instructed amount"],
            "original_currency": ["original currency", "original_currency", "instructed currency"], 
            "exchange_rate": ["exchange rate", "exchange_rate", "currency exchange rate"]
        }'''
    
    # Find where to insert (after category_columns definition)
    insert_pattern = r'(self\.category_columns = \[[^\]]+\])'
    
    if 'self.forex_columns' not in content:
        content = re.sub(insert_pattern, r'\1' + forex_columns_def, content)
        print("✅ Added forex column definitions")
    
    # Fix the process_single_header_csv to properly detect forex columns
    # Find the transaction processing loop
    if '# Check for forex data in the row' in content:
        print("⚠️  Forex detection already exists")
    else:
        # Add comprehensive forex detection
        forex_detection = '''
                # Extract standard forex columns if present
                forex_data = {}
                
                # Check for Original Amount column
                for col in ["Original Amount", "original_amount", "Instructed Amount"]:
                    if col in row_dict and row_dict[col].strip():
                        try:
                            forex_data["original_amount"] = self.parse_amount_enhanced(row_dict[col])
                        except:
                            pass
                
                # Check for Original Currency column  
                for col in ["Original Currency", "original_currency", "Instructed Currency"]:
                    if col in row_dict and row_dict[col].strip():
                        forex_data["original_currency"] = row_dict[col].strip()
                
                # Check for Exchange Rate column
                for col in ["Exchange Rate", "exchange_rate", "Currency Exchange Rate"]:
                    if col in row_dict and row_dict[col].strip():
                        try:
                            forex_data["exchange_rate"] = float(row_dict[col].strip())
                        except:
                            pass
                
                # Apply forex data if we have currency info
                if forex_data.get("original_currency") and forex_data["original_currency"] != "USD":
                    transaction["original_currency"] = forex_data["original_currency"]
                    transaction["original_amount"] = forex_data.get("original_amount", transaction["amount"])
                    
                    # Calculate exchange rate if not provided
                    if "exchange_rate" in forex_data:
                        transaction["exchange_rate"] = forex_data["exchange_rate"]
                    elif forex_data.get("original_amount") and forex_data["original_amount"] != 0:
                        transaction["exchange_rate"] = abs(transaction["amount"] / forex_data["original_amount"])
                    
                    transaction["has_forex"] = True
                else:
                    transaction["has_forex"] = False
'''
        
        # Insert before "# Store raw data"
        pattern = r'(\s+)(# Store raw data)'
        replacement = forex_detection + r'\n\1\2'
        content = re.sub(pattern, replacement, content)
        print("✅ Added comprehensive forex detection logic")
    
    with open(filepath, 'w') as f:
        f.write(content)
    
    return True

def fix_job_status_handling():
    """Ensure jobs transition to completed status properly"""
    filepath = "/Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro/backend/api_server_real.py"
    
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Ensure CSV processing sets status to "completed" not "processing_csv" at the end
    # This is already correct in the code, but let's verify
    if '"status": "completed"' in content and 'processing_jobs[job_id]["status"] = "completed"' in content:
        print("✅ Job completion status handling is correct")
        return True
    
    return False

def create_test_forex_csv():
    """Create a test CSV file with forex data"""
    csv_content = """Date,Description,Amount,Original Amount,Original Currency
2024-01-01,FOREIGN PURCHASE EUR,-55.50,-50.00,EUR
2024-01-02,INTL TRANSFER GBP,110.00,88.00,GBP
2024-01-03,TOKYO STORE JPY,-15.00,-2000,JPY
2024-01-04,DOMESTIC PURCHASE,-100.00,,
"""
    
    filepath = "/Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/test_forex.csv"
    with open(filepath, 'w') as f:
        f.write(csv_content)
    
    print(f"✅ Created test forex CSV: {filepath}")
    return filepath

def main():
    print("🔧 Fixing LedgerPro API Issues")
    print("=" * 50)
    
    # Apply fixes
    fixes_applied = 0
    
    print("\n1. Fixing net_amount calculation...")
    if fix_net_amount_calculation():
        fixes_applied += 1
    
    print("\n2. Fixing CSV forex detection...")
    if fix_csv_forex_detection():
        fixes_applied += 1
    
    print("\n3. Verifying job status handling...")
    if fix_job_status_handling():
        fixes_applied += 1
    
    print("\n4. Creating test forex CSV...")
    test_file = create_test_forex_csv()
    
    print(f"\n✅ Applied {fixes_applied} fixes successfully!")
    
    print("\n📋 Next Steps:")
    print("1. Restart the backend server")
    print("2. Test forex CSV upload:")
    print(f"   curl -X POST http://localhost:8000/api/upload -F 'file=@{test_file}'")
    print("3. Run Swift tests: swift test --filter APIIntegrationTests")

if __name__ == "__main__":
    main()

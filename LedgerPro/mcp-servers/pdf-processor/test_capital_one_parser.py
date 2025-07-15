#!/usr/bin/env python3
"""
Test the Capital One transaction parser specifically
"""
import re

def parse_amount(amount_str) -> float:
    """Parse amount string to float"""
    if not amount_str:
        return 0.0
    
    # Remove common characters
    cleaned = str(amount_str).replace("$", "").replace(",", "").replace(" ", "").strip()
    
    if not cleaned:
        return 0.0
    
    # Handle parentheses for negative
    if "(" in cleaned and ")" in cleaned:
        cleaned = "-" + cleaned.replace("(", "").replace(")", "")
    
    try:
        return float(cleaned)
    except (ValueError, TypeError):
        return 0.0

def test_capital_one_parser():
    """Test parsing of Capital One transaction text"""
    
    # Sample transaction text from the debug output
    sample_text = """Trans Date Post Date Description Amount
Apr 17 Apr 17 CAPITAL ONE MOBILE PYMTAuthDate 17-Apr - $1,000.00
Apr 27 Apr 28 CAPITAL ONE MOBILE PYMTAuthDate 27-Apr - $1,000.00
May 15 May 15 CAPITAL ONE MOBILE PYMTAuthDate 15-May - $2,000.00
JONATHAN I HERNANDEZ #9581: Transactions
Trans Date Post Date Description Amount
Apr 14 Apr 15 WOOD CITY LLCHoustonTX $253.28
Apr 14 Apr 15 WOOD CITY LLCHoustonTX $147.20
Apr 15 Apr 16 UBER* EATSCIUDAD DE MEXCDM $26.03
$518.82
MXN
19.931617365 Exchange Rate"""

    print("🧪 Testing Capital One Transaction Parser")
    print("=" * 60)
    print(f"Sample text:\n{sample_text}")
    print("=" * 60)
    
    transactions = []
    
    lines = sample_text.split('\n')
    for i, line in enumerate(lines):
        line = line.strip()
        if not line:
            continue
            
        print(f"\nLine {i+1}: '{line}'")
        
        # Skip headers and non-transaction rows
        if any(skip_phrase in line.lower() for skip_phrase in [
            "transactions", "trans date", "post date", "description", "amount",
            "continued", "visit capitalone", "total fees", "interest charge",
            "annual percentage", "your apr", "rewards summary", "jonathan", "exchange rate", "mxn"
        ]):
            print("  → SKIPPED (header/non-transaction)")
            continue
            
        # Pattern to match: Month Day Month Day Description Amount
        transaction_pattern = r'^([A-Za-z]{3}\s+\d{1,2})\s+([A-Za-z]{3}\s+\d{1,2})\s+(.+?)\s+([-$]?\$?[\d,]+\.?\d*)$'
        match = re.match(transaction_pattern, line)
        
        if match:
            trans_date, post_date, description, amount_str = match.groups()
            print(f"  → MATCHED! trans_date='{trans_date}', post_date='{post_date}', desc='{description}', amount='{amount_str}'")
            
            # Clean up description
            description = re.sub(r'\s+', ' ', description.strip())
            
            # Parse amount
            amount = parse_amount(amount_str)
            
            if amount != 0:
                transaction = {
                    "date": post_date,
                    "transaction_date": trans_date,
                    "post_date": post_date,
                    "description": description,
                    "amount": amount,
                    "bank": "capital_one",
                    "raw_line": line
                }
                transactions.append(transaction)
                print(f"  → ADDED TRANSACTION: {transaction}")
            else:
                print(f"  → AMOUNT PARSE FAILED: '{amount_str}' -> {amount}")
        else:
            print(f"  → NO MATCH for pattern")
            # Test if it looks like a transaction line
            if re.search(r'[A-Za-z]{3}\s+\d{1,2}', line):
                print(f"    Contains date-like pattern but doesn't match full regex")
    
    print(f"\n🎯 FINAL RESULT: Found {len(transactions)} transactions")
    for i, txn in enumerate(transactions, 1):
        print(f"  {i}. {txn['date']} | {txn['description']} | ${txn['amount']}")

if __name__ == "__main__":
    test_capital_one_parser()
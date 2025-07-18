#!/usr/bin/env python3
"""
PDF Processor MCP Server
Unifies PDF processing across different bank formats and integrates with existing processors
"""
import os
import json
import sys
from pathlib import Path

# Ensure stdout is unbuffered for proper MCP communication
sys.stdout.reconfigure(line_buffering=True)
from typing import Dict, List, Optional
from datetime import datetime
from mcp.server import Server, NotificationOptions
from mcp.server.models import InitializationOptions
import mcp.server.stdio
import mcp.types as types
import pdfplumber
import pandas as pd

# Add parent directory to path to import existing processors
sys.path.append(str(Path(__file__).parent.parent.parent))
sys.path.append(str(Path(__file__).parent.parent))

# Try to import existing processors
try:
    # Import the enhanced CSV processor
    sys.path.append(str(Path(__file__).parent.parent.parent / "backend" / "processors" / "python"))
    from csv_processor_enhanced import EnhancedCSVProcessor
    enhanced_processor = EnhancedCSVProcessor()
    csv_processor_available = True
    print("✅ Enhanced CSV processor loaded successfully", file=sys.stderr)
except ImportError as e:
    print(f"Import error: {e}", file=sys.stderr)
    enhanced_processor = None
    csv_processor_available = False

# Create placeholder PDF processor since financial_advisor module doesn't exist
class CamelotFinancialProcessor:
    def process_pdf(self, file_path):
        return {"transactions": [], "metadata": {"error": "CamelotProcessor not available"}}

server = Server("pdf-processor")

# Add initialization tracking
_initialized = True  # Start as initialized since we don't have complex setup

# Add a startup message
print("🚀 PDF Processor server starting...", file=sys.stderr)
print(f"   CSV processor available: {csv_processor_available}", file=sys.stderr)
print("✅ PDF Processor server ready for requests", file=sys.stderr)

@server.list_tools()
async def handle_list_tools() -> list[types.Tool]:
    """List available PDF processing tools"""
    return [
        types.Tool(
            name="process_bank_pdf",
            description="Process a bank statement PDF and extract transactions",
            inputSchema={
                "type": "object",
                "properties": {
                    "file_path": {
                        "type": "string",
                        "description": "Path to the PDF file"
                    },
                    "bank": {
                        "type": "string",
                        "description": "Optional: Bank name (auto-detected if not provided)"
                    },
                    "processor": {
                        "type": "string",
                        "description": "Processor to use: 'camelot', 'pdfplumber', or 'auto'",
                        "enum": ["camelot", "pdfplumber", "auto"],
                        "default": "auto"
                    }
                },
                "required": ["file_path"]
            }
        ),
        types.Tool(
            name="detect_bank",
            description="Detect which bank a PDF statement is from",
            inputSchema={
                "type": "object",
                "properties": {
                    "file_path": {
                        "type": "string",
                        "description": "Path to the PDF file"
                    }
                },
                "required": ["file_path"]
            }
        ),
        types.Tool(
            name="extract_pdf_text",
            description="Extract raw text from a PDF file",
            inputSchema={
                "type": "object",
                "properties": {
                    "file_path": {
                        "type": "string",
                        "description": "Path to the PDF file"
                    },
                    "page_numbers": {
                        "type": "array",
                        "items": {"type": "integer"},
                        "description": "Optional: Specific pages to extract"
                    }
                },
                "required": ["file_path"]
            }
        ),
        types.Tool(
            name="extract_pdf_tables",
            description="Extract tables from a PDF file",
            inputSchema={
                "type": "object",
                "properties": {
                    "file_path": {
                        "type": "string",
                        "description": "Path to the PDF file"
                    },
                    "page_numbers": {
                        "type": "array",
                        "items": {"type": "integer"},
                        "description": "Optional: Specific pages to extract tables from"
                    }
                },
                "required": ["file_path"]
            }
        ),
        types.Tool(
            name="process_csv_file",
            description="Process a CSV file containing financial transactions",
            inputSchema={
                "type": "object",
                "properties": {
                    "file_path": {
                        "type": "string",
                        "description": "Path to the CSV file"
                    }
                },
                "required": ["file_path"]
            }
        )
    ]

@server.call_tool()
async def handle_call_tool(
    name: str, 
    arguments: dict
) -> list[types.TextContent]:
    """Handle tool calls"""
    
    # Server is ready to handle requests
    print(f"🔧 Handling tool call: {name}", file=sys.stderr)
    
    try:
        if name == "process_bank_pdf":
            result = await process_bank_pdf(
                arguments["file_path"],
                arguments.get("bank"),
                arguments.get("processor", "auto")
            )
        elif name == "detect_bank":
            result = await detect_bank(arguments["file_path"])
        elif name == "extract_pdf_text":
            result = await extract_pdf_text(
                arguments["file_path"],
                arguments.get("page_numbers")
            )
        elif name == "extract_pdf_tables":
            result = await extract_pdf_tables(
                arguments["file_path"],
                arguments.get("page_numbers")
            )
        elif name == "process_csv_file":
            result = await process_csv_async(arguments["file_path"])
        else:
            raise ValueError(f"Unknown tool: {name}")
        
        # Convert result to JSON string with compact encoding to reduce size
        json_str = json.dumps(result, separators=(',', ':'))
        
        # Log the response size for debugging
        print(f"[DEBUG] Tool response size: {len(json_str)} bytes", file=sys.stderr)
        print(f"[DEBUG] Response type: {type(result)}, keys: {list(result.keys()) if isinstance(result, dict) else 'not a dict'}", file=sys.stderr)
        print(f"[DEBUG] JSON string first 100 chars: {json_str[:100]}...", file=sys.stderr)
        
        return [types.TextContent(
            type="text",
            text=json_str
        )]
        
    except Exception as e:
        import traceback
        error_msg = f"Error: {str(e)}\n{traceback.format_exc()}"
        print(f"[ERROR] Tool call failed: {error_msg}", file=sys.stderr)
        
        return [types.TextContent(
            type="text",
            text=json.dumps({"error": str(e), "success": False})
        )]

async def detect_bank(file_path: str) -> Dict:
    """Detect bank from PDF content"""
    
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"File not found: {file_path}")
    
    with pdfplumber.open(file_path) as pdf:
        # Extract text from first page
        first_page_text = pdf.pages[0].extract_text().lower()
        
        # Bank detection patterns
        bank_patterns = {
            "chase": ["chase bank", "jpmorgan chase", "chase.com"],
            "bank_of_america": ["bank of america", "bofa", "bankofamerica.com"],
            "wells_fargo": ["wells fargo", "wellsfargo.com"],
            "capital_one": ["capital one", "capitalone.com"],
            "citi": ["citibank", "citi bank", "citibank.com", "citi.com"],
            "usaa": ["usaa federal savings", "usaa.com"],
            "navy_federal": ["navy federal", "navyfederal.org"],
            "pnc": ["pnc bank", "pnc.com"],
            "us_bank": ["u.s. bank", "us bank", "usbank.com"],
            "td_bank": ["td bank", "tdbank.com"],
            "ally": ["ally bank", "ally.com"],
            "discover": ["discover bank", "discover.com"],
            "amex": ["american express", "americanexpress.com"],
        }
        
        detected_bank = "unknown"
        confidence = 0.0
        evidence = []
        
        for bank, patterns in bank_patterns.items():
            for pattern in patterns:
                if pattern in first_page_text:
                    detected_bank = bank
                    confidence = 0.95
                    evidence.append(f"Found '{pattern}' in text")
                    break
            if detected_bank != "unknown":
                break
        
        # Try to extract account information
        account_info = extract_account_info(first_page_text)
        
        return {
            "bank": detected_bank,
            "confidence": confidence,
            "evidence": evidence,
            "account_info": account_info,
            "first_page_preview": first_page_text[:300] + "..." if len(first_page_text) > 300 else first_page_text
        }

def extract_account_info(text: str) -> Dict:
    """Extract account information from text"""
    import re
    
    account_info = {
        "account_number": None,
        "account_type": None,
        "routing_number": None
    }
    
    # Look for account numbers (typically 4 digits at end)
    account_patterns = [
        r'account.*?(\d{4})',
        r'acct.*?(\d{4})',
        r'ending.*?(\d{4})'
    ]
    
    for pattern in account_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            account_info["account_number"] = f"****{match.group(1)}"
            break
    
    # Look for account types
    if any(word in text.lower() for word in ['checking', 'check']):
        account_info["account_type"] = "checking"
    elif any(word in text.lower() for word in ['savings', 'save']):
        account_info["account_type"] = "savings"
    elif any(word in text.lower() for word in ['credit', 'card']):
        account_info["account_type"] = "credit"
    
    return account_info

async def process_bank_pdf(file_path: str, bank: Optional[str] = None, processor: str = "auto") -> Dict:
    """Process bank PDF and extract transactions"""
    
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"File not found: {file_path}")
    
    # Auto-detect bank if not provided
    if not bank:
        detection = await detect_bank(file_path)
        bank = detection["bank"]
    
    result = {
        "file": file_path,
        "bank": bank,
        "processor_used": processor,
        "transactions": [],
        "metadata": {},
        "summary": {}
    }
    
    try:
        if processor == "camelot" or (processor == "auto" and bank in ["chase", "bank_of_america", "wells_fargo"]):
            # Use existing CamelotProcessor
            camelot_processor = CamelotFinancialProcessor()
            camelot_result = camelot_processor.process_pdf(file_path)
            
            result["processor_used"] = "camelot"
            result["transactions"] = camelot_result.get("transactions", [])
            result["metadata"] = camelot_result.get("metadata", {})
            
        else:
            # Use pdfplumber for simpler extraction
            result["processor_used"] = "pdfplumber"
            transactions = []
            
            with pdfplumber.open(file_path) as pdf:
                result["metadata"] = {
                    "pages": len(pdf.pages),
                    "bank": bank,
                    "file": file_path
                }
                
                # Extract tables from all pages
                for page_num, page in enumerate(pdf.pages):
                    tables = page.extract_tables()
                    
                    for table in tables:
                        if table and len(table) > 1:  # Has header and data
                            # Try to parse as transaction table
                            page_transactions = parse_transaction_table(table, bank)
                            transactions.extend(page_transactions)
            
            # Remove duplicates
            result["transactions"] = remove_duplicate_transactions(transactions)
        
        # Calculate summary
        transactions = result["transactions"]
        if transactions:
            # Correctly calculate debits (expenses) and credits (income/payments)
            total_debits = sum(abs(t["amount"]) for t in transactions if t["amount"] < 0)
            total_credits = sum(t["amount"] for t in transactions if t["amount"] > 0)
            
            result["summary"] = {
                "transaction_count": len(transactions),
                "total_debits": total_debits,  # Total expenses (positive value)
                "total_credits": total_credits,  # Total income/payments
                "net_amount": total_credits - total_debits,  # Income minus expenses
                "date_range": get_date_range(transactions)
            }
        
        # Set success flag
        result["success"] = True
        
    except Exception as e:
        result["error"] = str(e)
        result["transactions"] = []
        result["success"] = False
    
    return result

def parse_transaction_table(table: List[List], bank: str) -> List[Dict]:
    """Parse a table into transactions based on bank format"""
    
    transactions = []
    
    if not table or len(table) < 2:
        return transactions
    
    # Bank-specific parsing
    if bank == "capital_one":
        return parse_capital_one_transactions(table)
    
    # Generic parser for other banks
    headers = [str(h).lower() if h else "" for h in table[0]]
    
    # Find column indices
    date_idx = next((i for i, h in enumerate(headers) if "date" in h), None)
    desc_idx = next((i for i, h in enumerate(headers) if any(x in h for x in ["description", "desc", "transaction", "merchant"])), None)
    amount_idx = next((i for i, h in enumerate(headers) if any(x in h for x in ["amount", "debit", "credit"])), None)
    
    # If we can't find basic columns, try different approaches
    if date_idx is None:
        # Look for date-like patterns in first few columns
        for i in range(min(3, len(headers))):
            if any(word in headers[i] for word in ["date", "trans", "post"]):
                date_idx = i
                break
    
    if desc_idx is None:
        # Look for description-like patterns
        for i in range(len(headers)):
            if any(word in headers[i] for word in ["desc", "transaction", "merchant", "payee"]):
                desc_idx = i
                break
    
    if amount_idx is None:
        # Look for amount-like patterns
        for i in range(len(headers)):
            if any(word in headers[i] for word in ["amount", "debit", "credit", "$"]):
                amount_idx = i
                break
    
    if date_idx is None or desc_idx is None:
        return transactions
    
    # Parse rows
    for row_idx, row in enumerate(table[1:], 1):
        try:
            if len(row) > max(date_idx, desc_idx, amount_idx or 0):
                date_val = str(row[date_idx]).strip() if row[date_idx] else ""
                desc_val = str(row[desc_idx]).strip() if row[desc_idx] else ""
                amount_val = row[amount_idx] if amount_idx is not None and amount_idx < len(row) else "0"
                
                # Skip empty or header-like rows
                if not date_val or not desc_val or date_val.lower() in ["date", "transaction date"]:
                    continue
                
                transaction = {
                    "date": date_val,
                    "description": desc_val,
                    "amount": parse_amount(amount_val),
                    "bank": bank,
                    "raw_row": row,
                    "row_index": row_idx
                }
                
                # Basic validation
                if transaction["date"] and transaction["description"] and transaction["amount"] != 0:
                    transactions.append(transaction)
                    
        except Exception as e:
            # Skip problematic rows but continue processing
            continue
    
    return transactions

def parse_capital_one_transactions(table: List[List]) -> List[Dict]:
    """Parse Capital One-specific transaction format with forex support"""
    import re
    
    transactions = []
    
    for row in table:
        if not row or not row[0]:
            continue
            
        text = str(row[0]).strip()
        
        # Skip simple headers but allow text blocks with transactions
        if text.lower() in ["transactions", "transactions (continued)", "trans date post date description amount"]:
            continue
            
        # Look for transaction lines with the pattern: 
        # Month Day Month Day DESCRIPTION Amount
        # Examples: "Apr 17 Apr 17 CAPITAL ONE MOBILE PYMTAuthDate 17-Apr - $1,000.00"
        #          "Apr 14 Apr 15 WOOD CITY LLCHoustonTX $253.28"
        
        lines = text.split('\n')
        i = 0
        while i < len(lines):
            line = lines[i].strip()
            if not line:
                i += 1
                continue
                
            # Skip specific non-transaction lines but allow processing of forex data
            if any(skip_phrase in line.lower() for skip_phrase in [
                "visit capitalone", "total fees", "interest charge", "annual percentage", 
                "your apr", "rewards summary", "trans date post date description amount",
                "total transactions for this period", "hernandez #9581:", "payments, credits and adjustments"
            ]):
                i += 1
                continue
                
            # Pattern to match: Month Day Month Day Description Amount
            # This regex looks for: MMM DD MMM DD ... $amount or -$amount
            transaction_pattern = r'^([A-Za-z]{3}\s+\d{1,2})\s+([A-Za-z]{3}\s+\d{1,2})\s+(.+?)\s+([-$]?\$?[\d,]+\.?\d*)$'
            match = re.match(transaction_pattern, line)
            
            if match:
                trans_date, post_date, description, amount_str = match.groups()
                
                # Clean up description - remove extra spaces and normalize
                description = re.sub(r'\s+', ' ', description.strip())
                
                # Parse amount
                amount = parse_amount(amount_str)
                
                # Skip if amount is 0 (invalid parse)
                if amount == 0:
                    i += 1
                    continue
                
                # Apply correct sign for credit card transactions
                # Payments (positive) vs Purchases (negative)
                if "PAYMENT" in description.upper() or "PYMT" in description.upper() or "PMT" in description.upper():
                    # Payments reduce your balance (positive)
                    amount = abs(amount)
                else:
                    # All other transactions increase your balance (negative/expense)
                    amount = -abs(amount)
                
                transaction = {
                    "date": post_date,  # Use post date as the primary date
                    "transaction_date": trans_date,
                    "post_date": post_date,
                    "description": description,
                    "amount": amount,
                    "bank": "capital_one",
                    "raw_line": line
                }
                
                # Check for foreign currency data in next lines
                # Capital One format:
                # Apr 15 Apr 16 UBER* EATSCIUDAD DE MEXCDM $26.03
                # $518.82
                # MXN  
                # 19.931617365 Exchange Rate
                
                if i + 3 < len(lines):
                    next_line1 = lines[i + 1].strip()  # Original amount line
                    next_line2 = lines[i + 2].strip()  # Currency code
                    next_line3 = lines[i + 3].strip()  # Exchange rate line
                    
                    # Check if this looks like forex data
                    original_amount_match = re.match(r'^\$?([\d,]+\.?\d*)$', next_line1)
                    currency_match = re.match(r'^([A-Z]{3})$', next_line2)
                    exchange_rate_match = re.search(r'([\d.]+)\s+exchange\s+rate', next_line3, re.IGNORECASE)
                    
                    if original_amount_match and currency_match and exchange_rate_match:
                        # This is a foreign currency transaction
                        original_amount = float(original_amount_match.group(1).replace(',', ''))
                        currency_code = currency_match.group(1)
                        exchange_rate = float(exchange_rate_match.group(1))
                        
                        transaction.update({
                            "original_amount": original_amount,
                            "original_currency": currency_code,
                            "exchange_rate": exchange_rate,
                            "has_forex": True
                        })
                        
                        # Skip the forex lines we just processed
                        i += 3
                
                transactions.append(transaction)
            
            i += 1
    
    return transactions

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

def remove_duplicate_transactions(transactions: List[Dict]) -> List[Dict]:
    """Remove duplicate transactions"""
    seen = set()
    unique = []
    
    for t in transactions:
        # Create key based on date, description, and amount
        key = f"{t['date']}_{t['description'][:50]}_{t['amount']}"
        if key not in seen:
            seen.add(key)
            unique.append(t)
    
    return unique

def get_date_range(transactions: List[Dict]) -> Dict:
    """Get date range from transactions"""
    if not transactions:
        return {"start": None, "end": None}
    
    dates = [t["date"] for t in transactions if t["date"]]
    if not dates:
        return {"start": None, "end": None}
    
    return {
        "start": min(dates),
        "end": max(dates),
        "count": len(dates)
    }

async def extract_pdf_text(file_path: str, page_numbers: Optional[List[int]] = None) -> Dict:
    """Extract text from PDF"""
    
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"File not found: {file_path}")
    
    text_content = []
    
    with pdfplumber.open(file_path) as pdf:
        pages_to_extract = page_numbers or range(len(pdf.pages))
        
        for page_num in pages_to_extract:
            if page_num < len(pdf.pages):
                page = pdf.pages[page_num]
                text = page.extract_text()
                text_content.append({
                    "page": page_num + 1,
                    "text": text,
                    "char_count": len(text) if text else 0
                })
    
    return {
        "file": file_path,
        "total_pages": len(pdf.pages) if 'pdf' in locals() else 0,
        "pages_extracted": len(text_content),
        "content": text_content
    }

async def extract_pdf_tables(file_path: str, page_numbers: Optional[List[int]] = None) -> Dict:
    """Extract tables from PDF"""
    
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"File not found: {file_path}")
    
    tables_content = []
    
    with pdfplumber.open(file_path) as pdf:
        pages_to_extract = page_numbers or range(len(pdf.pages))
        
        for page_num in pages_to_extract:
            if page_num < len(pdf.pages):
                page = pdf.pages[page_num]
                tables = page.extract_tables()
                
                for table_idx, table in enumerate(tables):
                    if table:
                        tables_content.append({
                            "page": page_num + 1,
                            "table_index": table_idx,
                            "rows": len(table),
                            "columns": len(table[0]) if table else 0,
                            "data": table
                        })
    
    return {
        "file": file_path,
        "tables_found": len(tables_content),
        "tables": tables_content
    }

async def process_csv_async(file_path: str) -> Dict:
    """Process CSV file using enhanced processor"""
    
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"File not found: {file_path}")
    
    if not csv_processor_available or enhanced_processor is None:
        return {
            "file": file_path,
            "processor": "csv_processor_enhanced",
            "success": False,
            "error": "Enhanced CSV processor not available",
            "transactions": [],
            "metadata": {}
        }
    
    try:
        print(f"🎯 MCP processing CSV file: {file_path}", file=sys.stderr)
        result = enhanced_processor.process_csv_file(file_path)
        
        return {
            "file": file_path,
            "processor": "csv_processor_enhanced",
            "success": True,
            **result
        }
    except Exception as e:
        print(f"❌ MCP CSV processing error: {str(e)}", file=sys.stderr)
        return {
            "file": file_path,
            "processor": "csv_processor_enhanced",
            "success": False,
            "error": str(e),
            "transactions": [],
            "metadata": {}
        }

async def main():
    """Run the MCP server"""
    async with mcp.server.stdio.stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            InitializationOptions(
                server_name="pdf-processor",
                server_version="0.1.0",
                capabilities=server.get_capabilities(
                    notification_options=NotificationOptions(),
                    experimental_capabilities={},
                ),
            ),
        )

if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
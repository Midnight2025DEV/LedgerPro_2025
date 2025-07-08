#!/usr/bin/env python3
"""
PDF Processor MCP Server
Unifies PDF processing across different bank formats and integrates with existing processors
"""
import os
import json
import sys
from pathlib import Path
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

# Try to import existing processors
try:
    from financial_advisor.core.camelot_processor import CamelotFinancialProcessor
    from financial_advisor.csv_processor import process_csv_file
except ImportError:
    # Create placeholder classes if imports fail
    class CamelotFinancialProcessor:
        def process_pdf(self, file_path):
            return {"transactions": [], "metadata": {"error": "CamelotProcessor not available"}}
    
    def process_csv_file(file_path):
        return {"transactions": [], "metadata": {"error": "CSV processor not available"}}

server = Server("pdf-processor")

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
        
        return [types.TextContent(
            type="text",
            text=json.dumps(result, indent=2)
        )]
        
    except Exception as e:
        return [types.TextContent(
            type="text",
            text=f"Error: {str(e)}"
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
            total_debits = sum(t["amount"] for t in transactions if t["amount"] < 0)
            total_credits = sum(t["amount"] for t in transactions if t["amount"] > 0)
            
            result["summary"] = {
                "transaction_count": len(transactions),
                "total_debits": total_debits,
                "total_credits": total_credits,
                "net_amount": total_credits + total_debits,
                "date_range": get_date_range(transactions)
            }
        
    except Exception as e:
        result["error"] = str(e)
        result["transactions"] = []
    
    return result

def parse_transaction_table(table: List[List], bank: str) -> List[Dict]:
    """Parse a table into transactions based on bank format"""
    
    transactions = []
    
    if not table or len(table) < 2:
        return transactions
    
    # Simple generic parser - you can enhance this with bank-specific logic
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
    """Process CSV file using existing processor"""
    
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"File not found: {file_path}")
    
    try:
        result = process_csv_file(file_path)
        return {
            "file": file_path,
            "processor": "csv_processor",
            "success": True,
            **result
        }
    except Exception as e:
        return {
            "file": file_path,
            "processor": "csv_processor",
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
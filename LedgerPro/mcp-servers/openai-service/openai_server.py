#!/usr/bin/env python3
"""
OpenAI MCP Server for AI Financial Accountant
Provides centralized OpenAI functionality with BYOAI support
"""
import os
import json
from datetime import datetime
from typing import Dict, List, Optional
from mcp.server import Server, NotificationOptions
from mcp.server.models import InitializationOptions
import mcp.server.stdio
import mcp.types as types
from openai import OpenAI
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize MCP server
server = Server("openai-service")

def get_openai_client(api_key: Optional[str] = None) -> OpenAI:
    """Get OpenAI client with provided or default API key"""
    key = api_key or os.getenv("OPENAI_API_KEY")
    if not key:
        raise ValueError("No OpenAI API key provided. Set OPENAI_API_KEY or pass api_key parameter.")
    return OpenAI(api_key=key)

@server.list_tools()
async def handle_list_tools() -> list[types.Tool]:
    """List available OpenAI tools"""
    return [
        types.Tool(
            name="enhance_transactions",
            description="Enhance financial transactions with AI-generated categories and insights",
            inputSchema={
                "type": "object",
                "properties": {
                    "transactions": {
                        "type": "array",
                        "description": "List of transactions to enhance",
                        "items": {
                            "type": "object",
                            "properties": {
                                "date": {"type": "string"},
                                "description": {"type": "string"},
                                "amount": {"type": "number"}
                            }
                        }
                    },
                    "api_key": {
                        "type": "string",
                        "description": "Optional: User's OpenAI API key (BYOAI)"
                    }
                },
                "required": ["transactions"]
            }
        ),
        types.Tool(
            name="categorize_transaction",
            description="Categorize a single transaction",
            inputSchema={
                "type": "object",
                "properties": {
                    "description": {
                        "type": "string",
                        "description": "Transaction description"
                    },
                    "amount": {
                        "type": "number",
                        "description": "Transaction amount"
                    },
                    "api_key": {
                        "type": "string",
                        "description": "Optional: User's OpenAI API key"
                    }
                },
                "required": ["description", "amount"]
            }
        ),
        types.Tool(
            name="extract_financial_insights",
            description="Extract insights from financial data",
            inputSchema={
                "type": "object",
                "properties": {
                    "transactions": {
                        "type": "array",
                        "description": "List of transactions"
                    },
                    "period": {
                        "type": "string",
                        "description": "Time period (e.g., 'monthly', 'quarterly')"
                    },
                    "api_key": {
                        "type": "string",
                        "description": "Optional: User's OpenAI API key"
                    }
                },
                "required": ["transactions"]
            }
        ),
        types.Tool(
            name="detect_bank_from_text",
            description="Detect bank from PDF text content using AI",
            inputSchema={
                "type": "object",
                "properties": {
                    "text_content": {
                        "type": "string",
                        "description": "First page text content from PDF"
                    },
                    "api_key": {
                        "type": "string",
                        "description": "Optional: User's OpenAI API key"
                    }
                },
                "required": ["text_content"]
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
        # Get API key from arguments or environment
        api_key = arguments.pop("api_key", None)
        client = get_openai_client(api_key)
        
        if name == "enhance_transactions":
            result = await enhance_transactions(client, arguments["transactions"])
        elif name == "categorize_transaction":
            result = await categorize_transaction(
                client, 
                arguments["description"], 
                arguments["amount"]
            )
        elif name == "extract_financial_insights":
            result = await extract_financial_insights(
                client,
                arguments["transactions"],
                arguments.get("period", "monthly")
            )
        elif name == "detect_bank_from_text":
            result = await detect_bank_from_text(
                client,
                arguments["text_content"]
            )
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

async def enhance_transactions(client: OpenAI, transactions: List[Dict]) -> Dict:
    """Enhance transactions with categories and insights"""
    
    # Format transactions for the prompt
    transaction_text = "\n".join([
        f"{t['date']}: {t['description']} - ${t['amount']}"
        for t in transactions
    ])
    
    prompt = f"""Analyze these financial transactions and provide:
1. A category for each transaction (choose from: Groceries, Dining, Transportation, Utilities, Entertainment, Shopping, Healthcare, Income, Transfer, Other)
2. Any insights or patterns you notice
3. Suggestions for financial optimization

Transactions:
{transaction_text}

Return as JSON with structure:
{{
    "categorized_transactions": [
        {{"date": "...", "description": "...", "amount": 0.0, "category": "...", "confidence": 0.95}}
    ],
    "insights": ["insight 1", "insight 2"],
    "suggestions": ["suggestion 1", "suggestion 2"]
}}"""

    response = client.chat.completions.create(
        model="gpt-4",
        messages=[
            {"role": "system", "content": "You are a financial analyst expert. Always return valid JSON."},
            {"role": "user", "content": prompt}
        ],
        temperature=0.7,
        response_format={"type": "json_object"}
    )
    
    return json.loads(response.choices[0].message.content)

async def categorize_transaction(client: OpenAI, description: str, amount: float) -> Dict:
    """Categorize a single transaction"""
    
    prompt = f"""Categorize this transaction:
Description: {description}
Amount: ${amount}

Choose from categories: Groceries, Dining, Transportation, Utilities, 
Entertainment, Shopping, Healthcare, Income, Transfer, Other

Return JSON: {{"category": "...", "confidence": 0.0-1.0, "reasoning": "brief explanation"}}"""

    response = client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[{"role": "user", "content": prompt}],
        temperature=0.3,
        response_format={"type": "json_object"}
    )
    
    return json.loads(response.choices[0].message.content)

async def extract_financial_insights(
    client: OpenAI, 
    transactions: List[Dict], 
    period: str
) -> Dict:
    """Extract financial insights from transactions"""
    
    # Calculate basic stats
    total_spent = sum(t['amount'] for t in transactions if t['amount'] < 0)
    total_income = sum(t['amount'] for t in transactions if t['amount'] > 0)
    
    prompt = f"""Analyze these {period} financial transactions:
Total Income: ${total_income}
Total Spent: ${abs(total_spent)}
Net: ${total_income + total_spent}
Transaction Count: {len(transactions)}

Sample transactions:
{json.dumps(transactions[:10], indent=2)}

Provide insights on:
1. Spending patterns and trends
2. Unusual or noteworthy transactions
3. Budget recommendations
4. Savings opportunities
5. Financial health assessment

Return as JSON with actionable insights and specific recommendations."""

    response = client.chat.completions.create(
        model="gpt-4",
        messages=[
            {"role": "system", "content": "You are a personal financial advisor. Provide practical, actionable advice."},
            {"role": "user", "content": prompt}
        ],
        temperature=0.7,
        response_format={"type": "json_object"}
    )
    
    return json.loads(response.choices[0].message.content)

async def detect_bank_from_text(client: OpenAI, text_content: str) -> Dict:
    """Detect bank from PDF text content using AI"""
    
    prompt = f"""Analyze this PDF text from the first page of a bank statement and identify the bank:

Text content:
{text_content[:1000]}...

Common banks to identify:
- Chase (JPMorgan Chase)
- Bank of America
- Wells Fargo
- Capital One
- Citibank
- USAA
- Navy Federal Credit Union
- PNC Bank
- U.S. Bank
- TD Bank
- Ally Bank
- Other

Return JSON: {{
    "bank": "bank_name",
    "confidence": 0.0-1.0,
    "evidence": ["text snippet that indicates this bank"],
    "account_info": {{"account_type": "checking/savings/credit", "last_four": "1234"}}
}}"""

    response = client.chat.completions.create(
        model="gpt-4",
        messages=[
            {"role": "system", "content": "You are an expert at identifying banks from financial documents."},
            {"role": "user", "content": prompt}
        ],
        temperature=0.3,
        response_format={"type": "json_object"}
    )
    
    return json.loads(response.choices[0].message.content)

async def main():
    """Run the MCP server"""
    async with mcp.server.stdio.stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            InitializationOptions(
                server_name="openai-service",
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
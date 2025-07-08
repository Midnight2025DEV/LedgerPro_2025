#!/usr/bin/env python3
"""
Financial Analyzer MCP Server
Orchestrates PDF processing and AI enhancement for complete financial analysis
"""
import os
import json
import asyncio
import subprocess
from datetime import datetime
from typing import Dict, List, Optional
from mcp.server import Server, NotificationOptions
from mcp.server.models import InitializationOptions
import mcp.server.stdio
import mcp.types as types
import httpx

server = Server("financial-analyzer")

# Configuration for connecting to other MCP servers in local mode
MCP_SERVERS = {
    "pdf_processor": "../pdf-processor/pdf_processor_server.py",
    "openai_service": "../openai-service/openai_server.py"
}

@server.list_tools()
async def handle_list_tools() -> list[types.Tool]:
    """List available analysis tools"""
    return [
        types.Tool(
            name="analyze_statement",
            description="Complete analysis of a bank statement PDF with AI enhancement",
            inputSchema={
                "type": "object",
                "properties": {
                    "file_path": {
                        "type": "string",
                        "description": "Path to bank statement PDF"
                    },
                    "include_insights": {
                        "type": "boolean",
                        "description": "Include AI-powered insights",
                        "default": True
                    },
                    "api_key": {
                        "type": "string",
                        "description": "Optional: OpenAI API key for BYOAI"
                    },
                    "processor": {
                        "type": "string",
                        "description": "PDF processor to use",
                        "enum": ["auto", "camelot", "pdfplumber"],
                        "default": "auto"
                    }
                },
                "required": ["file_path"]
            }
        ),
        types.Tool(
            name="analyze_spending_patterns",
            description="Analyze spending patterns across multiple statements",
            inputSchema={
                "type": "object",
                "properties": {
                    "file_paths": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "List of PDF file paths"
                    },
                    "period": {
                        "type": "string",
                        "description": "Analysis period",
                        "enum": ["monthly", "quarterly", "yearly"],
                        "default": "monthly"
                    },
                    "api_key": {
                        "type": "string",
                        "description": "Optional: OpenAI API key"
                    }
                },
                "required": ["file_paths"]
            }
        ),
        types.Tool(
            name="compare_statements",
            description="Compare two bank statements to identify changes",
            inputSchema={
                "type": "object",
                "properties": {
                    "statement1_path": {
                        "type": "string",
                        "description": "Path to first statement"
                    },
                    "statement2_path": {
                        "type": "string",
                        "description": "Path to second statement"
                    },
                    "api_key": {
                        "type": "string",
                        "description": "Optional: OpenAI API key"
                    }
                },
                "required": ["statement1_path", "statement2_path"]
            }
        ),
        types.Tool(
            name="detect_financial_anomalies",
            description="Detect unusual transactions or spending patterns",
            inputSchema={
                "type": "object",
                "properties": {
                    "file_path": {
                        "type": "string",
                        "description": "Path to bank statement PDF"
                    },
                    "sensitivity": {
                        "type": "string",
                        "description": "Anomaly detection sensitivity",
                        "enum": ["low", "medium", "high"],
                        "default": "medium"
                    },
                    "api_key": {
                        "type": "string",
                        "description": "Optional: OpenAI API key"
                    }
                },
                "required": ["file_path"]
            }
        ),
        types.Tool(
            name="generate_financial_report",
            description="Generate comprehensive financial report with insights",
            inputSchema={
                "type": "object",
                "properties": {
                    "file_paths": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "List of statement PDF paths"
                    },
                    "report_type": {
                        "type": "string",
                        "description": "Type of report to generate",
                        "enum": ["summary", "detailed", "trend_analysis"],
                        "default": "summary"
                    },
                    "api_key": {
                        "type": "string",
                        "description": "Optional: OpenAI API key"
                    }
                },
                "required": ["file_paths"]
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
        if name == "analyze_statement":
            result = await analyze_statement(
                arguments["file_path"],
                arguments.get("include_insights", True),
                arguments.get("api_key"),
                arguments.get("processor", "auto")
            )
        elif name == "analyze_spending_patterns":
            result = await analyze_spending_patterns(
                arguments["file_paths"],
                arguments.get("period", "monthly"),
                arguments.get("api_key")
            )
        elif name == "compare_statements":
            result = await compare_statements(
                arguments["statement1_path"],
                arguments["statement2_path"],
                arguments.get("api_key")
            )
        elif name == "detect_financial_anomalies":
            result = await detect_financial_anomalies(
                arguments["file_path"],
                arguments.get("sensitivity", "medium"),
                arguments.get("api_key")
            )
        elif name == "generate_financial_report":
            result = await generate_financial_report(
                arguments["file_paths"],
                arguments.get("report_type", "summary"),
                arguments.get("api_key")
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

async def analyze_statement(
    file_path: str, 
    include_insights: bool = True,
    api_key: Optional[str] = None,
    processor: str = "auto"
) -> Dict:
    """Complete analysis of a bank statement"""
    
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"File not found: {file_path}")
    
    result = {
        "file": file_path,
        "analysis_timestamp": asyncio.get_event_loop().time(),
        "processing_steps": [],
        "transactions": [],
        "metadata": {},
        "summary": {},
        "ai_analysis": None,
        "errors": []
    }
    
    try:
        # Step 1: Process PDF to extract transactions
        result["processing_steps"].append("pdf_extraction")
        
        # Simulate PDF processing (in real implementation, call PDF processor MCP)
        pdf_result = await simulate_pdf_processing(file_path, processor)
        
        result["transactions"] = pdf_result.get("transactions", [])
        result["metadata"] = pdf_result.get("metadata", {})
        result["bank"] = pdf_result.get("bank", "unknown")
        
        # Step 2: Calculate basic summary
        result["processing_steps"].append("summary_calculation")
        if result["transactions"]:
            result["summary"] = calculate_transaction_summary(result["transactions"])
        
        # Step 3: Enhance with AI if requested
        if include_insights and result["transactions"]:
            result["processing_steps"].append("ai_enhancement")
            
            # Simulate AI enhancement (in real implementation, call OpenAI MCP)
            ai_insights = await simulate_ai_enhancement(result["transactions"], api_key)
            result["ai_analysis"] = ai_insights
        
        result["success"] = True
        
    except Exception as e:
        result["errors"].append(str(e))
        result["success"] = False
    
    return result

async def analyze_spending_patterns(
    file_paths: List[str],
    period: str = "monthly",
    api_key: Optional[str] = None
) -> Dict:
    """Analyze spending patterns across multiple statements"""
    
    all_transactions = []
    file_results = []
    
    # Process each file
    for file_path in file_paths:
        try:
            analysis = await analyze_statement(file_path, False, api_key)
            file_results.append({
                "file": file_path,
                "success": analysis.get("success", False),
                "transaction_count": len(analysis.get("transactions", [])),
                "summary": analysis.get("summary", {})
            })
            all_transactions.extend(analysis.get("transactions", []))
        except Exception as e:
            file_results.append({
                "file": file_path,
                "success": False,
                "error": str(e)
            })
    
    # Aggregate analysis
    result = {
        "files_analyzed": len(file_paths),
        "files_processed": len([f for f in file_results if f["success"]]),
        "total_transactions": len(all_transactions),
        "period": period,
        "file_results": file_results,
        "pattern_analysis": {},
        "trends": [],
        "recommendations": []
    }
    
    if all_transactions:
        # Calculate patterns
        result["pattern_analysis"] = analyze_transaction_patterns(all_transactions, period)
        
        # Generate AI insights if API key provided
        if api_key:
            pattern_insights = await simulate_pattern_analysis(all_transactions, period, api_key)
            result["trends"] = pattern_insights.get("trends", [])
            result["recommendations"] = pattern_insights.get("recommendations", [])
    
    return result

async def compare_statements(
    statement1_path: str,
    statement2_path: str,
    api_key: Optional[str] = None
) -> Dict:
    """Compare two bank statements to identify changes"""
    
    # Analyze both statements
    analysis1 = await analyze_statement(statement1_path, False, api_key)
    analysis2 = await analyze_statement(statement2_path, False, api_key)
    
    comparison = {
        "statement1": {
            "file": statement1_path,
            "summary": analysis1.get("summary", {}),
            "transaction_count": len(analysis1.get("transactions", []))
        },
        "statement2": {
            "file": statement2_path,
            "summary": analysis2.get("summary", {}),
            "transaction_count": len(analysis2.get("transactions", []))
        },
        "differences": {},
        "insights": []
    }
    
    # Calculate differences
    summary1 = analysis1.get("summary", {})
    summary2 = analysis2.get("summary", {})
    
    comparison["differences"] = {
        "transaction_count_change": comparison["statement2"]["transaction_count"] - comparison["statement1"]["transaction_count"],
        "spending_change": summary2.get("total_expenses", 0) - summary1.get("total_expenses", 0),
        "income_change": summary2.get("total_income", 0) - summary1.get("total_income", 0),
        "net_change": summary2.get("net_amount", 0) - summary1.get("net_amount", 0)
    }
    
    # Generate insights
    if api_key:
        comparison_insights = await simulate_comparison_analysis(summary1, summary2, api_key)
        comparison["insights"] = comparison_insights.get("insights", [])
    
    return comparison

async def detect_financial_anomalies(
    file_path: str,
    sensitivity: str = "medium",
    api_key: Optional[str] = None
) -> Dict:
    """Detect unusual transactions or spending patterns"""
    
    analysis = await analyze_statement(file_path, False, api_key)
    transactions = analysis.get("transactions", [])
    
    anomalies = {
        "file": file_path,
        "sensitivity": sensitivity,
        "anomalies_found": [],
        "statistics": {},
        "recommendations": []
    }
    
    if transactions:
        # Calculate basic statistics
        amounts = [abs(t["amount"]) for t in transactions if t["amount"] != 0]
        if amounts:
            import statistics
            anomalies["statistics"] = {
                "mean_amount": statistics.mean(amounts),
                "median_amount": statistics.median(amounts),
                "max_amount": max(amounts),
                "min_amount": min(amounts),
                "std_dev": statistics.stdev(amounts) if len(amounts) > 1 else 0
            }
            
            # Simple anomaly detection based on standard deviation
            threshold_multiplier = {"low": 3, "medium": 2, "high": 1.5}[sensitivity]
            threshold = anomalies["statistics"]["mean_amount"] + (threshold_multiplier * anomalies["statistics"]["std_dev"])
            
            for transaction in transactions:
                if abs(transaction["amount"]) > threshold:
                    anomalies["anomalies_found"].append({
                        "transaction": transaction,
                        "reason": f"Amount ${abs(transaction['amount']):.2f} exceeds threshold ${threshold:.2f}",
                        "severity": "high" if abs(transaction["amount"]) > threshold * 1.5 else "medium"
                    })
        
        # AI-powered anomaly detection if API key provided
        if api_key and anomalies["anomalies_found"]:
            ai_analysis = await simulate_anomaly_analysis(transactions, anomalies["anomalies_found"], api_key)
            anomalies["ai_insights"] = ai_analysis
    
    return anomalies

async def generate_financial_report(
    file_paths: List[str],
    report_type: str = "summary",
    api_key: Optional[str] = None
) -> Dict:
    """Generate comprehensive financial report with insights"""
    
    # Analyze all statements
    all_analyses = []
    for file_path in file_paths:
        analysis = await analyze_statement(file_path, True, api_key)
        all_analyses.append(analysis)
    
    report = {
        "report_type": report_type,
        "files_analyzed": len(file_paths),
        "generation_timestamp": asyncio.get_event_loop().time(),
        "executive_summary": {},
        "detailed_analysis": {},
        "recommendations": [],
        "charts_data": {}
    }
    
    # Aggregate data
    all_transactions = []
    total_income = 0
    total_expenses = 0
    
    for analysis in all_analyses:
        if analysis.get("success"):
            all_transactions.extend(analysis.get("transactions", []))
            summary = analysis.get("summary", {})
            total_income += summary.get("total_income", 0)
            total_expenses += summary.get("total_expenses", 0)
    
    # Executive summary
    report["executive_summary"] = {
        "total_files": len(file_paths),
        "total_transactions": len(all_transactions),
        "total_income": total_income,
        "total_expenses": total_expenses,
        "net_amount": total_income + total_expenses,
        "average_transaction": sum(abs(t["amount"]) for t in all_transactions) / len(all_transactions) if all_transactions else 0
    }
    
    # Detailed analysis based on report type
    if report_type == "detailed":
        report["detailed_analysis"] = {
            "spending_categories": analyze_spending_categories(all_transactions),
            "monthly_trends": analyze_monthly_trends(all_transactions),
            "largest_transactions": sorted(all_transactions, key=lambda x: abs(x["amount"]), reverse=True)[:10]
        }
    elif report_type == "trend_analysis":
        report["detailed_analysis"] = {
            "trends": analyze_trends(all_analyses),
            "seasonal_patterns": analyze_seasonal_patterns(all_transactions),
            "growth_metrics": calculate_growth_metrics(all_analyses)
        }
    
    # AI-powered recommendations
    if api_key:
        ai_recommendations = await simulate_report_recommendations(report["executive_summary"], api_key)
        report["recommendations"] = ai_recommendations.get("recommendations", [])
    
    return report

# Simulation functions (in real implementation, these would call actual MCP servers)

async def simulate_pdf_processing(file_path: str, processor: str) -> Dict:
    """Simulate PDF processing"""
    return {
        "transactions": [
            {"date": "2024-01-15", "description": "Grocery Store", "amount": -125.43, "bank": "chase"},
            {"date": "2024-01-16", "description": "Salary Deposit", "amount": 3500.00, "bank": "chase"},
            {"date": "2024-01-17", "description": "Coffee Shop", "amount": -5.75, "bank": "chase"},
            {"date": "2024-01-18", "description": "Gas Station", "amount": -65.20, "bank": "chase"},
            {"date": "2024-01-19", "description": "Restaurant", "amount": -45.60, "bank": "chase"},
        ],
        "metadata": {"bank": "chase", "pages": 3, "processor": processor},
        "bank": "chase"
    }

async def simulate_ai_enhancement(transactions: List[Dict], api_key: Optional[str]) -> Dict:
    """Simulate AI enhancement"""
    return {
        "categorized_transactions": [
            {**t, "category": "Groceries" if "grocery" in t["description"].lower() else "Other"}
            for t in transactions
        ],
        "insights": [
            "Dining expenses are 15% above average for this period",
            "Consider setting up automatic savings transfers",
            "Gas spending has increased 20% compared to last month"
        ],
        "suggestions": [
            "Set a monthly dining budget of $200",
            "Look for gas rewards credit cards",
            "Consider meal planning to reduce grocery costs"
        ]
    }

async def simulate_pattern_analysis(transactions: List[Dict], period: str, api_key: str) -> Dict:
    """Simulate pattern analysis"""
    return {
        "trends": [
            "Spending increases on weekends",
            "Grocery shopping typically happens on Sundays",
            "Dining expenses peak mid-month"
        ],
        "recommendations": [
            "Consider weekly meal planning",
            "Set up weekend spending alerts",
            "Review subscription services for potential savings"
        ]
    }

async def simulate_comparison_analysis(summary1: Dict, summary2: Dict, api_key: str) -> Dict:
    """Simulate comparison analysis"""
    return {
        "insights": [
            "Spending decreased by 12% in the second period",
            "Income remained stable",
            "New subscription service detected"
        ]
    }

async def simulate_anomaly_analysis(transactions: List[Dict], anomalies: List[Dict], api_key: str) -> Dict:
    """Simulate anomaly analysis"""
    return {
        "assessment": "Several large transactions detected",
        "recommendations": ["Verify large transactions", "Consider fraud protection"],
        "risk_level": "medium"
    }

async def simulate_report_recommendations(summary: Dict, api_key: str) -> Dict:
    """Simulate report recommendations"""
    return {
        "recommendations": [
            "Increase emergency fund by 10%",
            "Consider investing surplus income",
            "Review and optimize recurring expenses"
        ]
    }

# Utility functions

def calculate_transaction_summary(transactions: List[Dict]) -> Dict:
    """Calculate basic transaction summary"""
    income = sum(t["amount"] for t in transactions if t["amount"] > 0)
    expenses = sum(t["amount"] for t in transactions if t["amount"] < 0)
    
    return {
        "total_income": income,
        "total_expenses": expenses,
        "net_amount": income + expenses,
        "transaction_count": len(transactions),
        "average_transaction": sum(abs(t["amount"]) for t in transactions) / len(transactions) if transactions else 0
    }

def analyze_transaction_patterns(transactions: List[Dict], period: str) -> Dict:
    """Analyze transaction patterns"""
    # Group by categories
    categories = {}
    for t in transactions:
        category = t.get("category", "Other")
        if category not in categories:
            categories[category] = {"count": 0, "total": 0}
        categories[category]["count"] += 1
        categories[category]["total"] += abs(t["amount"])
    
    return {
        "categories": categories,
        "top_categories": sorted(categories.items(), key=lambda x: x[1]["total"], reverse=True)[:5]
    }

def analyze_spending_categories(transactions: List[Dict]) -> Dict:
    """Analyze spending by categories"""
    categories = {}
    for t in transactions:
        if t["amount"] < 0:  # Only expenses
            category = t.get("category", "Other")
            if category not in categories:
                categories[category] = 0
            categories[category] += abs(t["amount"])
    
    return dict(sorted(categories.items(), key=lambda x: x[1], reverse=True))

def analyze_monthly_trends(transactions: List[Dict]) -> Dict:
    """Analyze monthly spending trends"""
    # Simple mock implementation
    return {
        "January": 2500.00,
        "February": 2650.00,
        "March": 2400.00
    }

def analyze_trends(analyses: List[Dict]) -> List[str]:
    """Analyze trends across multiple analyses"""
    return [
        "Spending has been gradually increasing",
        "Income stability maintained",
        "New spending categories identified"
    ]

def analyze_seasonal_patterns(transactions: List[Dict]) -> Dict:
    """Analyze seasonal spending patterns"""
    return {
        "winter": {"average_spending": 2500, "top_categories": ["Utilities", "Groceries"]},
        "spring": {"average_spending": 2300, "top_categories": ["Dining", "Shopping"]},
        "summer": {"average_spending": 2800, "top_categories": ["Travel", "Entertainment"]},
        "fall": {"average_spending": 2400, "top_categories": ["Shopping", "Groceries"]}
    }

def calculate_growth_metrics(analyses: List[Dict]) -> Dict:
    """Calculate growth metrics"""
    return {
        "income_growth": "2.5% monthly",
        "expense_growth": "1.8% monthly",
        "savings_rate": "15.2%"
    }

async def main():
    """Run the MCP server"""
    async with mcp.server.stdio.stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            InitializationOptions(
                server_name="financial-analyzer",
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
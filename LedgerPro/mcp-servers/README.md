# MCP Servers for AI Financial Accountant

This directory contains Model Context Protocol (MCP) servers that provide unified access to your AI Financial Accountant functionality through Claude Desktop and other MCP clients.

**🔗 Part of the unified AI Financial Accountant architecture** - These MCP servers integrate seamlessly with our FastAPI backend, React frontend, and provide natural language access to sophisticated financial analysis capabilities.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   Claude Desktop / MCP Client               │
└─────────────────────┬───────────────────────────────────────┘
                      │ MCP Protocol
┌─────────────────────┴───────────────────────────────────────┐
│                    MCP Server Layer                         │
├─────────────────────┬─────────────────┬───────────────────────┤
│   OpenAI Service    │  PDF Processor  │  Financial Analyzer  │
│                     │                 │                      │
│ • BYOAI Support     │ • Multi-format  │ • Complete Analysis  │
│ • Transaction       │ • Bank Detection│ • Pattern Detection  │
│   Enhancement       │ • Table Extract │ • Report Generation  │
│ • Categorization    │ • Text Extract  │ • Trend Analysis     │
└─────────────────────┴─────────────────┴───────────────────────┘
                      │
┌─────────────────────┴───────────────────────────────────────┐
│              Existing Financial Processors                  │
│  • CamelotProcessor (Python) • Bank-specific Processors     │
│  • CSV Processor              • Node.js AI Integration      │
└─────────────────────────────────────────────────────────────┘
```

## 📂 Server Components

### 1. OpenAI Service (`openai-service/`)
**Centralized AI functionality with BYOAI support**

**Tools:**
- `enhance_transactions` - AI-powered transaction categorization and insights
- `categorize_transaction` - Single transaction categorization
- `extract_financial_insights` - Generate financial insights from transaction data
- `detect_bank_from_text` - AI-powered bank detection from PDF text

**Key Features:**
- ✅ Bring Your Own AI (BYOAI) - users can provide their own OpenAI API keys
- ✅ Centralized API key management
- ✅ Rate limiting and error handling
- ✅ Multiple AI models support (GPT-3.5, GPT-4)

### 2. PDF Processor (`pdf-processor/`)
**Unified PDF processing across different bank formats**

**Tools:**
- `process_bank_pdf` - Extract transactions from bank statement PDFs
- `detect_bank` - Identify bank from PDF content
- `extract_pdf_text` - Raw text extraction from PDFs
- `extract_pdf_tables` - Table extraction from PDFs
- `process_csv_file` - Process CSV transaction files

**Key Features:**
- ✅ Multi-processor support (Camelot, PDFPlumber)
- ✅ Bank-specific processing logic
- ✅ Automatic bank detection
- ✅ Integration with existing processors

### 3. Financial Analyzer (`financial-analyzer/`)
**High-level orchestration and analysis**

**Tools:**
- `analyze_statement` - Complete statement analysis with AI enhancement
- `analyze_spending_patterns` - Multi-statement pattern analysis
- `compare_statements` - Compare two statements for changes
- `detect_financial_anomalies` - Identify unusual transactions
- `generate_financial_report` - Comprehensive financial reporting

**Key Features:**
- ✅ Orchestrates other MCP servers
- ✅ Advanced analytics and reporting
- ✅ Anomaly detection
- ✅ Trend analysis across multiple periods

## 🚀 Quick Start

### 1. Test the Servers

```bash
# From the mcp-servers directory
python test_mcp_servers.py
```

This will test all three servers and generate a configuration file.

### 2. Configure Claude Desktop

Copy the generated config to Claude Desktop:

```bash
# macOS
cp claude_desktop_config.json ~/Library/Application\ Support/Claude/claude_desktop_config.json

# Linux
cp claude_desktop_config.json ~/.config/claude-desktop/claude_desktop_config.json

# Windows
cp claude_desktop_config.json %APPDATA%\Claude\claude_desktop_config.json
```

### 3. Update API Key

Edit the config file and replace `your-api-key-here` with your actual OpenAI API key:

```json
{
  "mcpServers": {
    "openai-service": {
      "env": {
        "OPENAI_API_KEY": "sk-your-actual-api-key-here"
      }
    }
  }
}
```

### 4. Restart Claude Desktop

Restart Claude Desktop to load the MCP servers.

## 🧪 Testing with Claude Desktop

Once configured, you can test with prompts like:

```
"Analyze my bank statement at /path/to/statement.pdf"
"Compare my spending patterns between these two statements"
"Detect any unusual transactions in my recent statement"
"Generate a financial report for the last 3 months"
```

## 🔧 Development Mode

### Integration with Main Architecture

These MCP servers integrate with the main AI Financial Accountant architecture:

```bash
# 1. Start the unified FastAPI server (optional - for web interface)
cd ../financial_advisor
python api_server_unified.py

# 2. Test MCP servers integration
cd ../mcp-servers
python test_mcp_servers.py

# 3. Use both interfaces simultaneously:
#    - Web interface at http://localhost:8000
#    - Natural language via Claude Desktop with MCP servers
```

### Manual Server Testing

You can test individual servers manually:

```bash
# Test OpenAI Service
cd openai-service
source venv/bin/activate
python openai_server.py

# In another terminal, send test requests via stdio
```

### Adding New Tools

To add new tools to any server:

1. Add the tool definition in `handle_list_tools()`
2. Add the implementation in `handle_call_tool()`
3. Update tests in `test_mcp_servers.py`

### Bank-Specific Processors

To add support for new banks:

1. Update bank detection patterns in `pdf_processor_server.py`
2. Add bank-specific parsing logic in `parse_transaction_table()`
3. Test with sample statements from the new bank

## 🔒 Security Considerations

### API Key Management

- ✅ API keys are stored in environment variables
- ✅ BYOAI allows users to provide their own keys
- ✅ No API keys are logged or stored permanently
- ✅ Each user session can have different API keys

### File Access

- ⚠️ MCP servers run with user permissions
- ⚠️ Always validate file paths before processing
- ⚠️ Consider sandboxing for production deployment

### Data Privacy

- ✅ No financial data is sent to external services without user consent
- ✅ All processing happens locally unless AI enhancement is requested
- ✅ Users control when and how their data is processed

## 📊 Integration Benefits

### Unified Interface
- Single point of access for all financial processing
- Consistent API across different processing engines
- Language-agnostic service composition

### Scalability
- Easy to add new banks and processors
- Microservice architecture ready for scaling
- Independent deployment of each service

### Flexibility
- Users can choose which processors to use
- BYOAI enables cost control and privacy
- Modular design allows partial adoption

## 🛠️ Troubleshooting

### Servers Won't Start

1. Check virtual environment setup:
   ```bash
   cd openai-service
   source venv/bin/activate
   pip list  # Verify mcp is installed
   ```

2. Check Python path in config
3. Verify file permissions (`chmod +x *.py`)

### Claude Desktop Can't See Servers

1. Verify config file syntax (valid JSON)
2. Check absolute paths in config
3. Restart Claude Desktop completely
4. Check Claude Desktop logs

### API Errors

1. Verify OpenAI API key is correct
2. Check rate limits and quota
3. Test API connectivity:
   ```bash
   curl -H "Authorization: Bearer $OPENAI_API_KEY" https://api.openai.com/v1/models
   ```

## 🔮 Future Enhancements

### Short-term (Next 3 months)
- **Real MCP Protocol Communication** - Replace simulation with actual MCP calls
- **Integration with Unified API** - Direct communication with api_server_unified.py
- **Enhanced Error Handling** - Robust retry logic and error recovery
- **MCP Server Auto-discovery** - Dynamic registration and discovery

### Medium-term (3-6 months)  
- **Cross-server Communication** - Data sharing between MCP servers
- **Advanced Orchestration** - Complex multi-step financial workflows
- **Bank Processor Registry** - Dynamic discovery of available processors
- **Real-time Collaboration** - Multi-user analysis sessions
- **Performance Monitoring** - Metrics and observability integration with main architecture

### Long-term (6+ months)
- **Intelligent MCP Ecosystem** - Self-healing and optimization
- **Community Marketplace** - Custom processor sharing
- **Multi-language Support** - Go, Rust, JavaScript MCP servers
- **Advanced Security** - Full sandboxing and permission management

### Community Extensions
- Additional bank format support
- Custom categorization rules  
- Export integrations (Mint, YNAB, etc.)
- Mobile app integration via unified API

## 📚 Resources

### Project Documentation
- [Main Project README](../README.md) - Complete project overview and setup
- [System Architecture](../ARCHITECTURE.md) - Comprehensive architecture documentation including MCP integration
- [API Versioning Strategy](../financial_advisor/API_VERSIONING_STRATEGY.md) - API versioning and migration guide

### MCP Protocol Resources
- [MCP Documentation](https://modelcontextprotocol.io) - Official MCP specification
- [Claude Desktop MCP Guide](https://docs.anthropic.com/claude/docs/mcp) - Claude Desktop integration guide

### Development Resources
- [Development Guide](../CLAUDE.md) - Complete development workflow and quality standards
- [Week 2 Data Validation](../WEEK_2_DATA_VALIDATION_COMPLETE.md) - Recent architectural improvements

---

**Need Help?** Check the troubleshooting section above or create an issue in the main project repository.
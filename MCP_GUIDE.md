# MCP (Model Context Protocol) Integration Guide

## 🤖 Overview

LedgerPro integrates with Model Context Protocol (MCP) servers to provide AI-powered financial analysis capabilities. MCP enables secure, standardized communication between the LedgerPro app and various AI services.

## 🏗️ Architecture

```
LedgerPro App
    ↓
MCP Bridge (Swift)
    ↓ JSON-RPC 2.0
MCP Servers (Python)
    ├── PDF Processor
    ├── Financial Analyzer  
    └── OpenAI Service
```

### Key Components

- **MCP Bridge**: Swift-based communication layer
- **MCP Servers**: Python services for specific tasks
- **Protocol**: JSON-RPC 2.0 over stdio
- **Security**: Local-only communication, no network calls

## 📁 MCP Servers

### PDF Processor (`mcp-servers/pdf-processor/`)
- **Purpose**: Advanced PDF parsing and table extraction
- **Features**: Bank statement processing, table detection
- **Status**: Active development

### Financial Analyzer (`mcp-servers/financial-analyzer/`)
- **Purpose**: Transaction analysis and insights
- **Features**: Spending patterns, trend analysis
- **Status**: Active development

### OpenAI Service (`mcp-servers/openai-service/`)
- **Purpose**: Natural language categorization
- **Features**: GPT-powered transaction categorization
- **Status**: Optional integration

## 🚀 Setup and Installation

### 1. Install Python Dependencies
```bash
cd mcp-servers
pip install -r requirements.txt
```

### 2. Configure Servers
Each server has its own configuration in the respective directory.

### 3. Test Individual Servers
```bash
# Test PDF processor
python mcp-servers/pdf-processor/pdf_processor_server.py

# Test financial analyzer
python mcp-servers/financial-analyzer/financial_analyzer_server.py
```

## 📝 Usage

### PDF Processing Workflow
1. Upload PDF through LedgerPro UI
2. MCP Bridge sends PDF to processor server
3. Server extracts tables and transactions
4. Results returned to LedgerPro for display

### Financial Analysis
1. Select transactions in LedgerPro
2. Request analysis through MCP Bridge
3. Analyzer server processes spending patterns
4. Insights displayed in LedgerPro interface

## 🔧 Configuration

### MCP Bridge Settings
Located in `Sources/LedgerPro/Services/MCP/`
- Connection timeouts
- Server paths
- Protocol settings

### Server Configuration
Each server has individual config files:
- `pdf-processor/config.json`
- `financial-analyzer/config.json`
- `openai-service/config.json`

## 📊 Performance

- **PDF Processing**: ~2-5 seconds per document
- **Analysis**: <1 second for 500 transactions
- **Memory Usage**: <100MB per server
- **Startup Time**: <3 seconds per server

## 🔒 Security

- **Local Only**: All processing happens locally
- **No Network**: Servers don't make external calls
- **Sandboxed**: Each server runs in isolation
- **Validated Input**: All data is sanitized

## 🧪 Testing

### Unit Tests
```bash
# Test MCP Bridge
swift test --filter MCPBridgeTests

# Test individual servers
python -m pytest mcp-servers/tests/
```

### Integration Tests
```bash
# Full workflow tests
swift test --filter MCPIntegrationTests
```

## 🐛 Troubleshooting

### Common Issues

**Server Won't Start**
- Check Python dependencies: `pip install -r requirements.txt`
- Verify Python version: Python 3.9+
- Check file permissions

**Connection Timeout**
- Increase timeout in MCP Bridge settings
- Check server process is running
- Verify stdio communication

**Processing Errors**
- Check input file format
- Verify server logs
- Test with sample data

### Debugging

**Enable Debug Logging**
```swift
// In MCP Bridge
logger.setLevel(.debug)
```

**Server Logs**
```bash
# View server logs
tail -f mcp-servers/logs/server.log
```

## 🚧 Development Status

- ✅ Basic MCP communication
- ✅ PDF processing server
- ✅ Error handling and timeouts
- 🚧 Financial analysis server
- 🚧 OpenAI integration
- ⏳ Advanced insights
- ⏳ Natural language queries

## 📚 References

- [MCP Specification](https://modelcontextprotocol.io/docs)
- [JSON-RPC 2.0](https://www.jsonrpc.org/specification)
- [LedgerPro Architecture](./README.md#architecture)

---

For troubleshooting specific issues, see [MCP_TROUBLESHOOTING.md](./MCP_TROUBLESHOOTING.md)
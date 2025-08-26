# MCP Integration Overview

## 🤖 Model Context Protocol (MCP) in LedgerPro

LedgerPro includes full Model Context Protocol (MCP) integration, providing local AI-powered financial analysis without sending data to external services.

## 🏗️ Architecture

LedgerPro includes three specialized MCP servers that run as child processes of the main application:

### 1. 📄 PDF Processor (`mcp-servers/pdf-processor/`)
- **Purpose**: Extracts transactions from bank statement PDFs
- **Technology**: Camelot-py, OpenCV, pandas
- **Input**: Bank statement PDFs (Capital One, Navy Federal, Chase, etc.)
- **Output**: Structured transaction data with confidence scores

### 2. 📊 Financial Analyzer (`mcp-servers/financial-analyzer/`)
- **Purpose**: Provides insights, trends, and financial analysis
- **Technology**: pandas, numpy, scikit-learn
- **Input**: Transaction data, account balances
- **Output**: Spending insights, trend analysis, budget recommendations

### 3. 🧠 OpenAI Service (`mcp-servers/openai-service/`)
- **Purpose**: AI-powered transaction categorization
- **Technology**: OpenAI API (BYOAI - Bring Your Own API Key)
- **Input**: Transaction descriptions and amounts
- **Output**: Smart categories and expense classifications

## 🚀 How It Works

### Automatic Server Management
1. **App Launch** → MCP servers start automatically as child processes
2. **Health Monitoring** → Continuous health checks ensure server availability
3. **Auto-Restart** → Failed servers are automatically restarted
4. **Graceful Shutdown** → All servers shut down cleanly when app closes

### Processing Flow
1. **File Upload** → User drags PDF to upload area
2. **Processing Choice** → Choose "Backend API" or "Local MCP Processing"
3. **Local Processing** → If MCP selected, data processed entirely on-device
4. **Results Display** → Same UI regardless of processing method

## 🖥️ User Interface

### Status Indicators
The MCP status indicator appears in the app toolbar:
- 🟢 **Green**: All servers ready and connected
- 🟠 **Orange**: Some servers active, others starting/reconnecting
- 🔴 **Red**: Servers offline or failed to start

### Processing Options
When uploading files, users see two options:
- **Use Backend API** (Default) - Traditional server processing
- **Use Local MCP Processing** - AI-powered local analysis

### Server Management
Click the MCP status indicator to view:
- Individual server status
- Connection health
- Manual server controls
- Detailed diagnostics

## 🔒 Privacy & Security

### Local-Only Processing
- **No Cloud Uploads**: All MCP processing happens on your machine
- **No Data Transmission**: Financial data never leaves your device
- **Optional API**: OpenAI integration requires your own API key
- **Secure Communication**: MCP servers communicate via local sockets

### Data Protection
- Temporary file cleanup after processing
- Encrypted inter-process communication
- No persistent storage of sensitive data
- User-controlled AI service integration

## 🛠️ Development & Debugging

### Server Logs
- Check Console.app for detailed MCP server logs
- Enable debug mode: `export LEDGERPRO_DEBUG=1`
- Run with logging: `./run_app_with_logging.sh`

### Manual Testing
- Use the test button in the upload view
- Check server status in the MCP status popover
- Monitor process list: `ps aux | grep "_server.py"`

### Makefile Commands
```bash
make check-mcp      # Check server processes
make test-mcp       # Test server functionality  
make clean-mcp      # Clean server artifacts
make mcp-setup      # Setup development environment
```

## 🔧 Configuration

### Server Ports
- PDF Processor: Auto-assigned (typically 8001)
- Financial Analyzer: Auto-assigned (typically 8002)
- OpenAI Service: Auto-assigned (typically 8003)

### Environment Variables
- `LEDGERPRO_DEBUG=1`: Enable debug logging
- `LOG_LEVEL=DEBUG`: Detailed log output
- `OPENAI_API_KEY`: For AI categorization (optional)

## 🚨 Troubleshooting

### Common Issues

#### Servers Won't Start
- **Check**: Python 3.9+ installed
- **Solution**: Ensure all MCP server dependencies installed
- **Command**: `make mcp-setup`

#### Processing Fails
- **Check**: MCP status indicator shows green
- **Solution**: Wait for all servers to be ready
- **Fallback**: Use Backend API processing option

#### PDF Processing Errors
- **Check**: File is a valid bank statement PDF
- **Solution**: Try different PDF or use Backend API
- **Logs**: Check Console.app for detailed error messages

#### Memory/Performance Issues
- **Check**: Available system memory
- **Solution**: Close other applications during processing
- **Alternative**: Use Backend API for large files

### Diagnostic Commands
```bash
# Check server processes
ps aux | grep "_server.py"

# Test MCP functionality
make test-mcp

# View detailed logs
tail -f ~/Library/Logs/LedgerPro/mcp_servers.log

# Manual server health check
curl http://127.0.0.1:8001/health  # PDF Processor
curl http://127.0.0.1:8002/health  # Financial Analyzer
curl http://127.0.0.1:8003/health  # OpenAI Service
```

## 🔮 Future Enhancements

### Planned Features
- **Natural Language Queries**: Ask questions about your finances
- **Custom Rule Engine**: User-defined categorization rules
- **Batch Processing**: Process multiple files simultaneously
- **Export Integration**: Direct export to accounting software

### Extensibility
- **Plugin Architecture**: Add custom MCP servers
- **API Integration**: Connect to additional financial services
- **Machine Learning**: Local model training on your data

## 📚 Technical Details

### Communication Protocol
- **Transport**: TCP sockets with JSON-RPC 2.0
- **Security**: localhost-only binding, no external access
- **Reliability**: Automatic reconnection and health monitoring
- **Performance**: Async processing with progress updates

### Resource Management
- **Memory**: Efficient streaming for large files
- **CPU**: Multi-core processing for parallel analysis
- **Storage**: Minimal temporary file usage
- **Network**: No external connections (except optional OpenAI)

---

**MCP Integration** brings the power of AI to your financial analysis while keeping your data private and secure! 🛡️✨
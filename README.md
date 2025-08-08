# LedgerPro 📊

<div align="center">

[![Tests](https://github.com/Midnight2025DEV/LedgerPro_2025/actions/workflows/ci.yml/badge.svg)](https://github.com/Midnight2025DEV/LedgerPro_2025/actions/workflows/ci.yml)
[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Python 3.9+](https://img.shields.io/badge/Python-3.9+-blue.svg)](https://python.org)
[![macOS 13.0+](https://img.shields.io/badge/macOS-13.0+-brightgreen.svg)](https://developer.apple.com/macos/)

**Privacy-focused financial management for Mac with AI-powered categorization**

[Features](#-features) • [Installation](#-quick-start) • [Architecture](#-architecture) • [Contributing](#-contributing)

</div>

## 🌟 Features

- 🔒 **100% Local Processing** - Your financial data never leaves your device
- 🤖 **AI-Powered Features** - Bring Your Own AI (BYOAI) with OpenAI integration
- 📈 **Pattern Learning** - Automatically creates rules from your categorization patterns
- 🏦 **Multi-Bank Support** - Works with PDF and CSV exports from major banks
- 💱 **Foreign Currency** - Automatic forex detection and conversion
- 📊 **Rich Analytics** - Interactive charts and spending insights
- ⚡ **Fast Processing** - Handle 500+ transactions in under 15 seconds

## 🏗️ Architecture

```
LedgerPro/
├── 📱 SwiftUI macOS App        # Native Mac application
├── 🚀 Python Backend          # FastAPI server for processing
│   ├── PDF Processing         # Camelot-based table extraction
│   ├── CSV Processing         # Multi-bank CSV support
│   └── API Server            # RESTful processing endpoints
├── 🤖 MCP Servers             # AI-powered analysis (optional)
│   ├── PDF Processor         # Advanced document parsing
│   ├── Financial Analyzer    # Spending pattern analysis
│   └── OpenAI Service        # Natural language categorization
└── 💾 Local Storage          # Secure local data management
```

## 🚀 Quick Start

### 1. Start the Backend Server
```bash
./start_backend.sh
# OR manually:
cd backend && python api_server_real.py
```

### 2. Optional: Configure AI Features 🤖

LedgerPro works great out of the box, but you can unlock advanced AI features:

```bash
# Set up your OpenAI API key for enhanced features
cd mcp-servers/openai-service
cp .env.example .env
# Edit .env and add your OpenAI API key
```

**Or configure through the app:**
1. Open LedgerPro
2. Go to Settings → AI Services 
3. Click "Configure API Keys"
4. Add your OpenAI API key

**💡 AI Features with API Key:**
- Smart transaction categorization
- Enhanced PDF processing
- Financial insights and analysis
- Natural language queries

See [API Keys Setup Guide](API_KEYS_SETUP.md) for detailed instructions.

### 3. Build and Run the Mac App
```bash
cd LedgerPro
swift build -c release
swift run
```

### 3. Upload Your Bank Statement
- Drag & drop PDF or CSV files into the app
- Supported formats: Capital One, Chase, Wells Fargo, Navy Federal, and more
- Processing typically takes 5-15 seconds

## 📋 Requirements

### System Requirements
- **macOS 13.0+** (for SwiftUI app)
- **Python 3.9+** (for backend processing)
- **Xcode 15.0+** (for development)

### Python Dependencies
Automatically installed via `requirements.txt`:
- FastAPI, Uvicorn (web server)
- Camelot-py, OpenCV (PDF processing)
- Pandas, NumPy (data processing)

## 🔌 API Endpoints

The backend server provides these endpoints:

- `GET /api/health` - Server health check
- `POST /api/upload` - Upload PDF/CSV files for processing
- `GET /api/jobs/{job_id}` - Check processing status
- `GET /api/transactions/{job_id}` - Retrieve processed transactions

## 💡 Key Features

### 📱 macOS App
- **Native SwiftUI Interface** - Optimized for macOS with native controls
- **Drag & Drop Upload** - Simply drag bank statements into the app
- **Real-time Processing** - Watch your transactions appear as they're processed
- **Interactive Charts** - Visual spending analysis with category breakdowns
- **Multi-account Support** - Manage transactions from multiple bank accounts
- **Secure Local Storage** - All data stays on your Mac

### 🔧 Backend Processing
- **Advanced PDF Analysis** - Uses Camelot for precise table extraction
- **Multi-Bank Support** - Handles various bank statement formats
- **Smart Categorization** - AI-powered transaction categorization
- **Duplicate Detection** - Automatically prevents duplicate transactions
- **Security First** - File validation and secure processing pipelines

### 🤖 AI-Powered Features
- **Pattern Learning** - Learns from your manual categorizations
- **Rule Generation** - Automatically creates categorization rules
- **Confidence Scoring** - Shows how confident the AI is about each categorization
- **Continuous Improvement** - Gets better with each correction you make

## 🧪 Development

### Building from Source
```bash
# Clone the repository
git clone https://github.com/Midnight2025DEV/LedgerPro_2025.git
cd LedgerPro_2025

# Set up Python backend
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt

# Start backend server
python api_server_real.py

# In a new terminal, build the Mac app
cd ../LedgerPro
swift build
swift run
```

### Running Tests
```bash
# Swift tests
cd LedgerPro && swift test

# Python tests
cd backend && python -m pytest tests/ -v
```

### Development Commands
See [CLAUDE.md](./CLAUDE.md) for comprehensive development commands and workflows.

## 🤖 MCP Integration (Optional)

LedgerPro supports Model Context Protocol (MCP) for advanced AI features:

- **Natural Language Queries** - Ask questions about your spending
- **Advanced Analytics** - AI-powered financial insights
- **Custom Analysis** - Tailored financial recommendations

For setup instructions, see [MCP_GUIDE.md](./MCP_GUIDE.md).

## 🔒 Security & Privacy

- **Local Processing Only** - No cloud uploads, all data stays on your device
- **Temporary File Cleanup** - Uploaded files are securely deleted after processing
- **Secure File Validation** - All uploads are validated before processing
- **No Data Collection** - We don't collect or transmit any financial data

## 🤝 Contributing

We welcome contributions! Please follow our workflow:

1. **Check Existing PRs**: `gh pr list`
2. **Create Feature Branch**: `git checkout -b feature/amazing-feature`
3. **Follow Git Workflow**: See [GIT_WORKFLOW.md](./GIT_WORKFLOW.md) for details
4. **Run Tests**: Ensure all tests pass before submitting
5. **Create Pull Request**: `gh pr create`

### Code Quality Standards
- ✅ All tests must pass
- ✅ Follow Swift/Python style guidelines
- ✅ Add tests for new features
- ✅ Update documentation as needed

## 📊 Performance

Benchmarked on MacBook Pro M2:
- **Import 500 transactions**: ~13.7 seconds
- **Categorization accuracy**: 95%+
- **Memory usage (1000 tx)**: <200MB
- **Pattern learning**: <5 seconds per batch

## 🚧 Roadmap

- [ ] **Receipt Scanning** - OCR support for receipt processing
- [ ] **Budget Planning** - Set and track spending budgets
- [ ] **Investment Tracking** - Portfolio and investment account support
- [ ] **Multi-device Sync** - Secure cloud synchronization
- [x] **Pattern Learning** - AI learns from corrections ✅
- [x] **Foreign Currency** - Forex detection and conversion ✅
- [x] **Comprehensive Testing** - 100+ test coverage ✅

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

### Common Issues
1. **Backend won't start** - Check Python version and dependencies
2. **PDF processing fails** - Ensure PDF contains extractable tables
3. **App won't launch** - Verify macOS 13.0+ and Xcode requirements

### Getting Help
- Check the [MCP_TROUBLESHOOTING.md](./MCP_TROUBLESHOOTING.md) for MCP-related issues
- Review [CLAUDE.md](./CLAUDE.md) for development guidance
- Open an issue on GitHub with detailed error information

---

<div align="center">
Made with ❤️ for privacy-conscious Mac users who want powerful financial management tools
</div>
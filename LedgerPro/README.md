# LedgerPro - macOS Financial Statement Processor

A complete, self-contained macOS application for processing bank and credit card statements using AI-powered analysis.

## 🏗️ Architecture

```
LedgerPro/
├── 📱 Sources/LedgerPro/       # Native SwiftUI macOS app
├── 🚀 backend/                 # Python FastAPI server
│   ├── api_server_real.py      # Main server
│   ├── requirements.txt        # Dependencies
│   ├── processors/python/      # PDF/CSV processing
│   └── config/                 # Configuration
├── 🤖 mcp-servers/             # Model Context Protocol (future)
├── 📄 Package.swift            # Swift package config
└── 🚀 start_backend.sh         # Backend startup script
```

## 🚀 Quick Start

### 1. Start the Backend Server
```bash
./start_backend.sh
```
The server will start on `http://127.0.0.1:8000`

### 2. Launch the macOS App
```bash
# Open in Xcode
open Package.swift

# Or build and run
swift run
```

## ✨ Features

### 📱 macOS App
- Native SwiftUI interface
- Drag & drop PDF/CSV upload
- Real-time transaction processing
- Financial insights and charts
- Multi-account management
- Local data storage

### 🔧 Backend Processing
- **PDF Analysis** - Advanced table extraction using Camelot
- **Multi-Bank Support** - Capital One, Navy Federal, Chase, Wells Fargo, etc.
- **AI Categorization** - Smart transaction categorization
- **Duplicate Detection** - Prevents duplicate transactions
- **Security** - File validation and secure processing

## 📋 Requirements

### System Requirements
- macOS 13.0+ (for SwiftUI app)
- Python 3.9+ (for backend)
- Xcode 15.0+ (for development)

### Python Dependencies
All dependencies are in `backend/requirements.txt`:
- FastAPI - Web framework
- Camelot-py - PDF table extraction
- Pandas - Data processing
- OpenAI - AI categorization
- And more...

## 🔧 Development

### Backend Development
```bash
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python api_server_real.py
```

### App Development
```bash
# Open in Xcode
open Package.swift

# Or use Swift CLI
swift build
swift run
```

### Testing
```bash
# Test backend health
curl http://127.0.0.1:8000/api/health

# Upload test file (requires running app)
```

## 🔌 API Endpoints

- `GET /api/health` - Server health check
- `POST /api/upload` - Upload PDF/CSV files
- `GET /api/jobs/{job_id}` - Check processing status
- `GET /api/transactions/{job_id}` - Get processed transactions

## 🤖 Future Features (MCP Integration)

The `mcp-servers/` directory contains Model Context Protocol servers for future integration:
- Natural language financial queries
- Advanced AI insights
- Automated financial planning

## 🔒 Security

- Local processing only (no cloud uploads)
- Temporary file cleanup
- Secure file validation
- Rate limiting protection

## 📝 License

[Add your license here]

## 🆘 Support

1. **Backend Issues** - Check console logs in terminal
2. **App Issues** - Check Xcode console
3. **PDF Processing** - Ensure file is a valid bank statement

---

**LedgerPro** - Transform your financial statements into actionable insights! 📊✨

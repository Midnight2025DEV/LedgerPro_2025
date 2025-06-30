# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Building and Running
- **Start backend**: `./LedgerPro/start_backend.sh` or `cd LedgerPro/backend && python api_server_real.py`
- **Build app**: `cd LedgerPro && swift build -c release` or `make build`
- **Run app**: `cd LedgerPro && swift run` or `make run`
- **Quick setup**: `cd LedgerPro && make setup` (resolves deps + checks backend)

### Development
- **Clean build**: `cd LedgerPro && make clean`
- **Run tests**: `cd LedgerPro && swift test` or `make test`
- **Format code**: `cd LedgerPro && make format` (requires swiftformat)
- **Lint code**: `cd LedgerPro && make lint` (requires swiftlint)

### Backend Development
```bash
cd LedgerPro/backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python api_server_real.py
```

### Python Linting/Testing
- **Format**: `cd LedgerPro/backend && black .`
- **Lint**: `cd LedgerPro/backend && flake8`
- **Type check**: `cd LedgerPro/backend && mypy .`
- **Security scan**: `cd LedgerPro/backend && bandit -r .`
- **Test**: `cd LedgerPro/backend && pytest`

## Architecture

LedgerPro is a dual-component financial statement processor:

### Frontend (SwiftUI macOS App)
- **Entry Point**: `Sources/LedgerPro/LedgerProApp.swift`
- **Main View**: `Sources/LedgerPro/Views/ContentView.swift`
- **Data Layer**: `FinancialDataManager` for local storage, `APIService` for backend communication
- **Key Views**: FileUploadView, TransactionListView, AccountsView, InsightsView, OverviewView
- **Models**: Transaction model with comprehensive financial data structure

### Backend (Python FastAPI Server)
- **Main Server**: `backend/api_server_real.py` - FastAPI server on port 8000
- **PDF Processing**: `backend/processors/python/camelot_processor.py` - Uses Camelot for table extraction
- **CSV Processing**: `backend/processors/python/csv_processor.py` - Handles CSV bank statements
- **Configuration**: `backend/config/` contains JSON configs for logging and app settings

### Key Integration Points
- Backend runs on `http://127.0.0.1:8000`
- API endpoints: `/api/health`, `/api/upload`, `/api/jobs/{job_id}`, `/api/transactions/{job_id}`
- Frontend communicates via URLSession-based APIService
- Asynchronous job processing with status polling

### MCP Servers (Future Features)
Located in `mcp-servers/` - Model Context Protocol servers for AI-powered financial analysis:
- `financial-analyzer/` - Core analysis engine
- `financial-api-diagnostics/` - API diagnostics
- `pdf-processor/` - Enhanced PDF processing
- `openai-service/` - OpenAI integration

## Development Notes

- Minimum macOS 13.0 required for SwiftUI features
- Backend requires Python 3.9+ with dependencies in `requirements.txt`
- Uses Camelot + OpenCV for PDF table extraction, supports multiple bank formats
- Local-only processing for security - no cloud uploads
- Transaction deduplication and AI categorization built-in
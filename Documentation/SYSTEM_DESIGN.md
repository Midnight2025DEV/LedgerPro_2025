# LedgerPro System Design

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                   LedgerPro System                                   │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                     │
│  ┌─────────────────────────────────┐     ┌────────────────────────────────────┐   │
│  │        Frontend (SwiftUI)        │     │         Backend (Python)           │   │
│  │                                  │     │                                    │   │
│  │  ┌───────────────────────────┐  │     │  ┌──────────────────────────────┐ │   │
│  │  │      User Interface       │  │     │  │      FastAPI Server          │ │   │
│  │  │  ┌──────────────────┐    │  │     │  │   (api_server_real.py)       │ │   │
│  │  │  │   ContentView     │    │  │     │  │                              │ │   │
│  │  │  ├──────────────────┤    │  │     │  │  ┌────────────────────────┐  │ │   │
│  │  │  │ FileUploadView   │    │  │     │  │  │   API Endpoints        │  │ │   │
│  │  │  ├──────────────────┤    │  │     │  │  │  /api/upload          │  │ │   │
│  │  │  │TransactionListView│    │  │     │  │  │  /api/jobs/{id}       │  │ │   │
│  │  │  ├──────────────────┤    │  │     │  │  │  /api/transactions    │  │ │   │
│  │  │  │  AccountsView    │    │  │     │  │  │  /api/health          │  │ │   │
│  │  │  ├──────────────────┤    │  │     │  │  └────────────────────────┘  │ │   │
│  │  │  │  InsightsView    │    │  │     │  └──────────────────────────────┘ │   │
│  │  │  ├──────────────────┤    │  │     │                                    │   │
│  │  │  │  OverviewView    │    │  │     │  ┌──────────────────────────────┐ │   │
│  │  │  ├──────────────────┤    │  │     │  │    Document Processors       │ │   │
│  │  │  │RulesManagementView│    │  │     │  │                              │ │   │
│  │  │  └──────────────────┘    │  │     │  │  ┌────────────────────────┐  │ │   │
│  │  └───────────────────────────┘  │     │  │  │  CamelotProcessor     │  │ │   │
│  │                                  │     │  │  │  (PDF extraction)      │  │ │   │
│  │  ┌───────────────────────────┐  │     │  │  └────────────────────────┘  │ │   │
│  │  │     Data Services         │  │     │  │  ┌────────────────────────┐  │ │   │
│  │  │                           │  │     │  │  │  CSVProcessor         │  │ │   │
│  │  │  ┌───────────────────┐   │  │     │  │  │  (CSV parsing)        │  │ │   │
│  │  │  │FinancialDataManager│   │  │     │  │  └────────────────────────┘  │ │   │
│  │  │  └───────────────────┘   │  │     │  └──────────────────────────────┘ │   │
│  │  │  ┌───────────────────┐   │  │     │                                    │   │
│  │  │  │   APIService      │◄──┼──┼─────┼───► HTTP/REST                    │   │
│  │  │  └───────────────────┘   │  │     │                                    │   │
│  │  │  ┌───────────────────┐   │  │     │  ┌──────────────────────────────┐ │   │
│  │  │  │  CategoryService  │   │  │     │  │     Job Management          │ │   │
│  │  │  └───────────────────┘   │  │     │  │  - Async Processing         │ │   │
│  │  │  ┌───────────────────┐   │  │     │  │  - Status Tracking          │ │   │
│  │  │  │ImportCategorization│   │  │     │  │  - Progress Updates         │ │   │
│  │  │  │     Service       │   │  │     │  └──────────────────────────────┘ │   │
│  │  │  └───────────────────┘   │  │     └────────────────────────────────────┘   │
│  │  └───────────────────────────┘  │                                              │
│  │                                  │     ┌────────────────────────────────────┐   │
│  │  ┌───────────────────────────┐  │     │        MCP Servers (Future)        │   │
│  │  │  Categorization Engine    │  │     │                                    │   │
│  │  │                           │  │     │  ┌──────────────────────────────┐ │   │
│  │  │  ┌───────────────────┐   │  │     │  │   financial-analyzer         │ │   │
│  │  │  │MerchantCategorizer │   │  │     │  └──────────────────────────────┘ │   │
│  │  │  └───────────────────┘   │  │     │  ┌──────────────────────────────┐ │   │
│  │  │  ┌───────────────────┐   │  │     │  │   pdf-processor             │ │   │
│  │  │  │  Rule Engine      │   │  │     │  └──────────────────────────────┘ │   │
│  │  │  │ (CategoryRule)    │   │  │     │  ┌──────────────────────────────┐ │   │
│  │  │  └───────────────────┘   │  │     │  │   openai-service            │ │   │
│  │  │  ┌───────────────────┐   │  │     │  └──────────────────────────────┘ │   │
│  │  │  │RuleSuggestionEngine│   │  │     └────────────────────────────────────┘   │
│  │  │  └───────────────────┘   │  │                                              │
│  │  │  ┌───────────────────┐   │  │                                              │
│  │  │  │PatternLearning    │   │  │                                              │
│  │  │  │    Service        │   │  │                                              │
│  │  │  └───────────────────┘   │  │                                              │
│  │  └───────────────────────────┘  │                                              │
│  └─────────────────────────────────┘                                              │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Frontend Layer (SwiftUI macOS App)

#### **User Interface Components**
- **ContentView**: Main app container with tab navigation
- **FileUploadView**: Drag-and-drop file upload interface
- **TransactionListView**: Display and manage transactions
- **AccountsView**: Bank account management
- **InsightsView**: Financial analytics and reports
- **OverviewView**: Dashboard with key metrics
- **RulesManagementView**: Create and manage categorization rules

#### **Data Services**
- **FinancialDataManager**: Core data persistence (UserDefaults)
- **APIService**: HTTP client for backend communication
- **CategoryService**: Transaction categorization logic
- **ImportCategorizationService**: Import-time categorization

#### **Categorization Engine**
- **MerchantCategorizer**: 81+ merchant database with pattern matching
- **Rule Engine**: System and custom rule processing
- **RuleSuggestionEngine**: ML-based rule suggestions
- **PatternLearningService**: Learn from user corrections

### 2. Backend Layer (Python FastAPI)

#### **API Server**
- FastAPI application running on port 8000
- Async request handling with job queue
- WebSocket support for real-time updates
- CORS enabled for frontend communication

#### **Document Processors**
- **CamelotProcessor**: PDF table extraction with bank-specific configs
- **CSVProcessor**: Multi-format CSV parsing
- Foreign currency detection and extraction
- Duplicate transaction detection

#### **Job Management**
- Async job processing with unique IDs
- Status tracking (pending, processing, completed, failed)
- Progress updates via polling/WebSocket
- Result caching with SHA256 deduplication

### 3. Data Flow

```
User Upload → Frontend → Backend API → Document Processing
     ↓                                         ↓
Display ← Categorization ← Import Service ← Transaction Data
```

### 4. Key Features

#### **Transaction Processing**
- Multi-bank format support (Capital One, Chase, Navy Federal, etc.)
- Foreign currency handling with exchange rates
- Automatic duplicate detection
- Batch processing capabilities

#### **Categorization System**
- 3-tier categorization (Merchant DB → Rules → Heuristics)
- Confidence scoring (0.0-1.0)
- Auto-categorization with visual indicators
- Learning from user corrections

#### **User Experience**
- Real-time search and filtering
- Bulk operations support
- Responsive UI with lazy loading
- Comprehensive error handling

### 5. Data Models

#### **Transaction Model**
```swift
struct Transaction {
    // Core fields
    let id: UUID
    var date: Date
    var description: String
    var amount: Double
    var category: String
    
    // Foreign currency
    var originalAmount: Double?
    var originalCurrency: String?
    var exchangeRate: Double?
    
    // Metadata
    var merchantName: String?
    var location: String?
    var paymentMethod: String?
    var notes: String?
    var tags: [String]
    
    // System fields
    var accountId: UUID?
    var jobId: String?
    var wasAutoCategorized: Bool
    var categorizationConfidence: Double?
}
```

#### **Category Rule Model**
```swift
struct CategoryRule {
    let id: UUID
    var ruleName: String
    var categoryId: UUID
    var priority: Int
    var confidence: Double
    
    // Matching conditions
    var merchantContains: String?
    var merchantExact: String?
    var descriptionContains: String?
    var amountMin: Double?
    var amountMax: Double?
    var regexPattern: String?
}
```

### 6. Security & Privacy

- **Local-first architecture**: No cloud storage of financial data
- **On-device processing**: Sensitive data never leaves user's machine
- **Secure communication**: HTTPS for API calls
- **Data encryption**: UserDefaults encryption on macOS
- **No tracking**: No analytics on transaction content

### 7. Performance Optimizations

- **Lazy loading**: Virtual scrolling for large datasets
- **Background processing**: Async filtering and categorization
- **Caching**: Pre-computed display data
- **Debouncing**: Search input optimization
- **Batch operations**: Efficient bulk updates

### 8. Future Architecture (MCP Integration)

```
Frontend ←→ MCP Bridge ←→ MCP Servers
                           ├── financial-analyzer
                           ├── pdf-processor
                           ├── openai-service
                           └── financial-api-diagnostics
```

The MCP (Model Context Protocol) servers will provide:
- Advanced AI-powered categorization
- Natural language transaction search
- Predictive analytics
- Automated financial insights

## Technology Stack

### Frontend
- **Language**: Swift 5.9+
- **Framework**: SwiftUI
- **Platform**: macOS 13.0+
- **Build**: Swift Package Manager

### Backend
- **Language**: Python 3.9+
- **Framework**: FastAPI
- **PDF Processing**: Camelot-py + OpenCV
- **Server**: Uvicorn ASGI

### Storage
- **Frontend**: UserDefaults (JSON encoded)
- **Backend**: In-memory job storage
- **Future**: Core Data / SQLite

### Communication
- **Protocol**: REST API + WebSocket
- **Format**: JSON
- **Security**: HTTPS (production)
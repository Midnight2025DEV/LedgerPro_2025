# LedgerPro Development Workflow

## Project Overview
LedgerPro is a privacy-focused Mac application for personal finance management that processes bank statements locally while leveraging AI capabilities through the Model Context Protocol (MCP).

## Development Workflow

### Current Process
We are using a collaborative workflow between Claude.ai and Claude Code:

1. **Claude.ai Chat** (Strategy & Design)
   - Generates specific prompts for implementation
   - Reviews and refines code outputs
   - Maintains project vision and architecture
   - Provides next steps and integration guidance

2. **Claude Code** (Implementation)
   - Receives prompts from Claude.ai chat
   - Implements specific components
   - Tests code locally
   - Returns results for review

3. **Workflow Steps**
   ```
   Claude.ai → Generate Prompt → Copy to Claude Code → 
   Implement → Copy Results → Paste to Claude.ai → 
   Review & Iterate
   ```

## Project Architecture

### Core Components
- **Client**: Mac desktop application
- **SwiftUI App**: Main application layer (Swift 6.0)
- **MCP Bridge**: JSON-RPC communication layer
- **Core Data**: Local storage for transactions
- **Visualization**: Swift Charts for data display

### MCP Servers
1. **PDF Processor**: Extracts transactions from bank statements
2. **Financial Analyzer**: Provides insights and trend analysis
3. **OpenAI Service**: Categorizes transactions (optional, BYOK)

### Key Features
- 100% local processing by default
- Privacy-first design
- Support for multiple bank formats
- Real-time financial insights
- Export capabilities for reports

## Current Status

### Completed
- [x] System architecture design
- [x] Project structure planning
- [ ] MCP Bridge implementation
- [ ] PDF Processor server
- [ ] Financial Analyzer server
- [ ] Core Data models
- [ ] SwiftUI interface
- [ ] File import system

### In Progress
- Setting up development workflow
- Preparing initial component implementations

## File Structure
```
LedgerPro/
├── WORKFLOW.md (this file)
├── LedgerPro.xcodeproj
├── LedgerPro/
│   ├── App/
│   ├── Models/
│   ├── Views/
│   ├── Services/
│   └── MCP/
├── MCP-Servers/
│   ├── pdf-processor/
│   ├── financial-analyzer/
│   └── openai-service/
└── Documentation/
    └── LedgerPro System Design Diagram.svg
```

## Development Guidelines

### For Claude Code Sessions
When receiving a prompt from the Claude.ai chat:
1. Focus on the specific component requested
2. Implement with production-quality code
3. Include error handling and edge cases
4. Add helpful comments for integration
5. Test the implementation if possible
6. Return complete, working code

### For Claude.ai Chat Sessions
When providing prompts:
1. Be specific about the component needed
2. Include context from previous implementations
3. Specify any dependencies or requirements
4. Indicate where the code should integrate
5. Mention any specific patterns to follow

## Integration Points

### MCP Bridge
- Handles all communication between SwiftUI app and MCP servers
- Uses JSON-RPC protocol
- Manages async operations and error handling

### Data Flow
1. User imports file → SwiftUI App
2. App sends to MCP Bridge
3. Bridge routes to appropriate MCP server
4. Server processes and returns data
5. App stores in Core Data
6. UI updates with new information

## Privacy Considerations
- All processing happens locally by default
- OpenAI integration is optional and requires user's API key
- No data leaves the device without explicit user action
- File access is sandboxed and permission-based

## Next Steps
1. Implement MCP Bridge foundation
2. Create basic PDF processor
3. Set up Core Data models
4. Build minimal SwiftUI interface
5. Test end-to-end flow with sample data

---
*This document should be updated as the project evolves to maintain accurate workflow information for all development sessions.*
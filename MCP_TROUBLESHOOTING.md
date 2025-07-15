# MCP Troubleshooting Guide

## 🚨 Common Issues and Solutions

### 1. Server Initialization Problems

#### **Server Takes Too Long to Start**
```
Error: MCP server initialization timeout after 5 seconds
```

**Solutions:**
- Increase initialization timeout in `MCPServerLauncher.swift`
- Check system resources (CPU/Memory)
- Verify Python virtual environment is activated

**Enhanced Grace Period Fix:**
```swift
// Increased timeout for slower systems
let initTimeout: TimeInterval = 10.0  // Was 5.0
```

#### **Server Process Dies Immediately**
```
Error: Server process terminated unexpectedly
```

**Solutions:**
- Check Python dependencies: `pip install -r requirements.txt`
- Verify Python version compatibility (3.9+)
- Check file permissions on server scripts
- Review server logs for startup errors

### 2. Communication Timeouts

#### **Initialization Timing Issues**
The MCP bridge occasionally fails during the critical initialization handshake.

**Root Cause:** Race condition between server startup and bridge connection attempt.

**Fix Applied:**
```swift
// Enhanced initialization with grace period
private func initializeWithGracePeriod() async throws {
    let maxRetries = 3
    var retryCount = 0
    
    while retryCount < maxRetries {
        do {
            try await performInitialization()
            return
        } catch {
            retryCount += 1
            if retryCount < maxRetries {
                await Task.sleep(nanoseconds: 500_000_000) // 500ms delay
            }
        }
    }
    throw MCPError.initializationFailed
}
```

#### **Request/Response Timeouts**
```
Error: Request timeout after 30 seconds
```

**Solutions:**
- Increase request timeout for large files
- Check server processing performance
- Monitor system resources during processing

### 3. Bridge Connection Issues

#### **Duplicate Bridge Instances**
Previous bug caused multiple MCP bridges to be created, leading to conflicts.

**Fix Applied:**
- Implemented singleton pattern for MCPBridge
- Added proper cleanup in deinitializers
- Prevented multiple server launches

```swift
// Singleton pattern implementation
class MCPBridge: ObservableObject {
    static let shared = MCPBridge()
    private init() {}
}
```

#### **Stdio Communication Failures**
```
Error: Failed to read from server stdio
```

**Solutions:**
- Verify server is writing to stdout correctly
- Check for binary data in text streams
- Ensure proper JSON formatting

### 4. Server-Specific Issues

#### **PDF Processor Server**

**Issue: Capital One table parsing fails**
```bash
# Test specific bank format
python test_capital_one_parser.py
```

**Issue: Memory usage during large PDF processing**
- Monitor with `htop` during processing
- Implement streaming for large files
- Add memory cleanup after processing

#### **Financial Analyzer Server**

**Issue: Analysis takes too long**
- Implement batch processing for large datasets
- Add progress reporting
- Cache frequently used calculations

### 5. Development and Debugging

#### **Enable Comprehensive Logging**
```swift
// In MCPBridge
private let logger = Logger(
    subsystem: "com.ledgerpro.mcp",
    category: "bridge"
)

// Enable debug level
logger.debug("MCP operation: \(operation)")
```

#### **Server Debug Mode**
```python
# In Python servers
import logging
logging.basicConfig(level=logging.DEBUG)
```

#### **Protocol Debugging**
Monitor JSON-RPC messages:
```bash
# Log all stdio communication
tail -f /tmp/mcp_communication.log
```

### 6. Performance Optimization

#### **Startup Performance**
- Lazy load server resources
- Implement connection pooling
- Cache initialization results

#### **Processing Performance**
- Stream large file processing
- Implement async operations
- Add progress indicators

### 7. Error Recovery

#### **Graceful Degradation**
When MCP servers fail, LedgerPro continues functioning with reduced features:
- PDF processing falls back to basic extraction
- Analysis features show "unavailable" status
- User can retry operations manually

#### **Automatic Recovery**
```swift
// Implemented in MCPBridge
private func attemptRecovery() async {
    await restartServers()
    try? await reinitializeConnections()
}
```

## 🔧 Diagnostic Commands

### Check Server Status
```bash
# Verify servers are running
ps aux | grep mcp

# Check server logs
tail -f mcp-servers/*/logs/*.log
```

### Test Communication
```bash
# Test stdio communication directly
echo '{"jsonrpc":"2.0","method":"ping","id":1}' | python server.py
```

### Performance Monitoring
```bash
# Monitor resource usage
htop -p $(pgrep -f mcp)
```

## 📊 Known Limitations

1. **Single Document Processing**: Currently processes one PDF at a time
2. **Memory Usage**: Large PDFs (>50MB) may cause high memory usage
3. **Startup Time**: Cold start can take 3-5 seconds
4. **Error Recovery**: Manual retry required for some failures

## 🚀 Future Improvements

- [ ] Implement connection pooling
- [ ] Add automatic error recovery
- [ ] Support batch processing
- [ ] Enhanced progress reporting
- [ ] Better resource management

## 📞 Getting Help

1. **Check Logs**: Always start with server and bridge logs
2. **Test Isolation**: Test individual components separately
3. **Resource Check**: Monitor CPU/Memory during issues
4. **Update Dependencies**: Ensure all packages are current

For additional support, see the main [MCP_GUIDE.md](./MCP_GUIDE.md) documentation.
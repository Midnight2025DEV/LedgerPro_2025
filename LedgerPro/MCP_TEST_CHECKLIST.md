# MCP Integration Test Checklist

## App Startup
- [ ] App launches without crashes
- [ ] ContentView shows MCP status monitoring output
- [ ] MCP servers attempt to start (check console)
- [ ] MCP status indicator shows in toolbar

## MCP Status Indicator
- [ ] Click status indicator - shows server details
- [ ] Status color: Red (offline), Orange (partial), Green (ready)
- [ ] Shows X/3 servers active count

## File Upload with MCP
- [ ] Click Upload button
- [ ] Select a PDF file
- [ ] Toggle "Use Local MCP Processing" appears
- [ ] Click "Test MCP" button - shows connection status
- [ ] Enable MCP toggle and upload file
- [ ] Monitor console for MCP processing activity

## Console Output to Monitor
Look for these messages:
- "🔍 Starting MCP connection monitoring..."
- "📊 Initial MCP Status:"
- "🚀 Launching [server] server..."
- "✅ [server] started successfully"
- "🎯 Processing PDF with MCP:"

## Error Scenarios
- [ ] If MCP fails, app falls back to backend API
- [ ] Error messages are clear and helpful
- [ ] Can retry MCP connection via status indicator

## Success Indicators
- [ ] Transactions extracted from PDF
- [ ] Auto-categorization applied
- [ ] Import summary shows processing method used
# Test MCP PDF Processing - Fixed Version

## What Was Fixed
- Changed from `document/process` to `tools/call` with `process_bank_pdf`
- Updated parameters to use `file_path` instead of base64 data
- Added proper response handling for Transaction objects
- Enhanced error handling and debug logging

## Test Steps
1. **Run the app** (if not already running)
2. **Click Upload** button
3. **Select a PDF** (bank statement preferred)
4. **Enable "Use Local MCP Processing"** toggle
5. **Click Upload**

## Expected Results
✅ Debug output shows: "🔍 DEBUG MCP Request: Method: tools/call"
✅ Tool name: "process_bank_pdf"
✅ File path sent correctly
✅ Transactions extracted successfully
✅ Auto-categorization applied
✅ Import summary shows MCP processing used

## Console Output to Watch For
- "🎯 Processing PDF with MCP:"
- "📡 MCP Tool Response:"
- "✅ MCP processed X transactions"
- No more "Internal error" messages

## If Errors Occur
Check for:
- File permissions issues
- Python import errors in server logs
- Malformed PDF structure
# Claude Desktop + Claude Code Workflow Guide

## Overview
This document explains the development workflow used in the LedgerPro project, combining Claude Desktop (claude.ai) with Claude Code for efficient development.

## Workflow Process

### 1. Strategy & Planning (Claude Desktop)
- Use Claude.ai for high-level planning and problem-solving
- Get specific, copyable prompts for implementation
- Review code changes and plan next steps

### 2. Implementation (Claude Code)
- Copy prompts from Claude Desktop
- Execute code changes and commands
- Return results for review

### 3. Feedback Loop
```
Claude Desktop → Generate Prompt → Copy to Claude Code → 
Execute → Copy Results → Paste to Claude Desktop → 
Review & Iterate
```

## Prompt Guidelines

### For Claude Desktop
When working in Claude Desktop, prompts should be:
- **Direct and actionable** - Like a senior engineer giving instructions
- **Copyable** - Always provided in code blocks or artifacts
- **Specific** - Include exact file paths and line numbers
- **One task at a time** - Single, focused prompts work best

### Example Good Prompt:
```
Change line 234 in CategoryPickerPopup.swift:
From: .frame(width: 600, height: 500)
To: .frame(width: 850, height: 650)
```

### Example Bad Prompt:
"Make the popup bigger and fix the layout issues"

## Manual Actions

When Jonathan needs to perform manual actions, they should be clearly marked in **BOLD**:

- **In Xcode: File → Open**
- **Navigate to: /Users/.../LedgerPro**
- **Press Cmd+Shift+K to clean**
- **Press Cmd+R to run**

## Communication Style

### What Works Best:
1. **Simple, direct prompts** - No fluff or over-explanation
2. **Senior engineer perspective** - Assume technical competence
3. **Clear separation** - Prompt first, then explanation for context
4. **Verification steps** - Include commands to check results

### Example Format:
```
PROMPT FOR CLAUDE CODE:
[Copyable prompt here]

WHAT THIS DOES:
[Brief explanation of the changes]

JONATHAN TO DO:
[Manual steps in BOLD]
```

## Project-Specific Notes

### File Paths
- Always use full paths: `/Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro`
- Project uses Swift Package Manager (not .xcodeproj)
- Main entry: Package.swift

### Common Tasks
1. **Finding the right file**: Use `grep` and `rg` commands
2. **Building**: `swift build` from project root
3. **Running**: `swift run` to test changes
4. **Clean builds**: Delete .build and DerivedData when needed

### Server Management
- Jonathan manually manages frontend/backend servers
- Never include server start/stop commands in prompts
- Focus only on code changes

## Debugging Workflow

When something isn't working:
1. **Verify file paths** - Ensure editing the correct file
2. **Check build output** - Look for compilation errors
3. **Clean and rebuild** - Force fresh compilation
4. **Verify in Xcode** - Ensure Xcode has the latest changes

## Best Practices

### DO:
- ✅ Give one clear prompt at a time
- ✅ Wait for Claude Code response before next step
- ✅ Include exact line numbers and file paths
- ✅ Provide copyable code blocks
- ✅ Mark manual actions in **BOLD**

### DON'T:
- ❌ Give multiple complex tasks in one prompt
- ❌ Assume Claude Code can see Xcode or GUI
- ❌ Include server management commands
- ❌ Use vague descriptions

## Example Workflow Session

1. **Claude Desktop**: "We need to make the category popup wider"
2. **Claude Desktop generates**:
   ```
   PROMPT FOR CLAUDE CODE:
   Change line 234 in CategoryPickerPopup.swift:
   From: .frame(width: 600, height: 500)
   To: .frame(width: 850, height: 650)
   ```
3. **Jonathan**: Copies prompt to Claude Code
4. **Claude Code**: Executes change, shows confirmation
5. **Jonathan**: Copies result back to Claude Desktop
6. **Claude Desktop**: Reviews change, suggests next step

## Troubleshooting

### Changes Not Appearing
1. Check if editing correct file: `pwd` and `find ~ -name "filename"`
2. Clean build: **In Xcode: Cmd+Shift+K**
3. Verify file was saved: Check modification time
4. Ensure Xcode opened correct project folder

### Build Errors
1. Copy exact error message to Claude Desktop
2. Get specific fix prompt
3. Apply fix in Claude Code
4. Rebuild and test

---

*This workflow has been refined through the LedgerPro project development and should be followed for all Claude-assisted development sessions.*
EOF < /dev/null
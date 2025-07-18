# Development Principles

## 🔍 ALWAYS CHECK FIRST - NO DUPLICATES

**CRITICAL RULE: Never create or build anything without first checking what already exists in the codebase.**

### Before Creating ANY File or Feature:

1. **Check if it already exists**:
   ```bash
   find . -name "*keyword*" -type f
   grep -r "feature_name" .
   ls -la | grep pattern
   ```

2. **Check GitHub for existing workflows**:
   ```bash
   gh run list
   gh api repos/{owner}/{repo}/actions/workflows
   ls -la .github/workflows/
   ```

3. **Check existing documentation**:
   ```bash
   find . -name "*.md" | head -10
   grep -r "topic" *.md
   ```

4. **Check existing services/components**:
   ```bash
   find Sources/ -name "*Service*" -type f
   find Sources/ -name "*Manager*" -type f
   ```

### Examples of What We Already Have:

- ✅ **CI/CD Pipeline** - 10 comprehensive workflows already active
- ✅ **Git Workflow** - Just created GIT_WORKFLOW.md
- ✅ **Foreign Currency Detection** - Already implemented in CSV processor
- ✅ **90+ Categorization Rules** - Already in CategoryRule+SystemRules.swift
- ✅ **Comprehensive Test Suite** - 100+ tests across multiple test files
- ✅ **MCP Integration** - Full MCP server architecture already built

### What This Prevents:

- ❌ Creating duplicate CI/CD workflows
- ❌ Building features that already exist
- ❌ Starting from scratch when we have working code
- ❌ Wasting time on redundant development
- ❌ Breaking existing functionality

## 🏗️ Before Any Development Work:

### 1. Inventory Check
```bash
# Check file structure
find . -type f -name "*.swift" | head -20
find . -type f -name "*.md" | head -10
find . -type f -name "*.yml" | head -10

# Check services
find Sources/ -name "*Service*"
find Sources/ -name "*Manager*"
find Sources/ -name "*View*" | head -10
```

### 2. Feature Check
```bash
# Check if feature exists
grep -r "feature_keyword" Sources/
rg "FeatureName" --type swift
```

### 3. Test Check
```bash
# Check existing tests
find Tests/ -name "*Test*"
grep -r "test_feature" Tests/
```

### 4. Documentation Check
```bash
# Check existing docs
find . -name "*.md" -exec grep -l "topic" {} \;
```

## 🚨 Red Flags - Stop and Check:

- Someone asks to "create" something → **CHECK FIRST**
- Someone asks to "build from scratch" → **CHECK FIRST**
- Someone asks to "implement" → **CHECK FIRST**
- You're about to write new code → **CHECK FIRST**

## ✅ Good Development Flow:

1. **Research** - What exists already?
2. **Analyze** - What can be improved/extended?
3. **Plan** - What actually needs to be built?
4. **Implement** - Build only what's missing
5. **Test** - Verify it works with existing code

## 📝 Before Creating Files:

- [ ] Checked if file already exists
- [ ] Checked if similar functionality exists
- [ ] Reviewed existing codebase structure
- [ ] Confirmed this is actually needed
- [ ] Planned integration with existing code

## 🎯 Remember:

**The best code is the code you don't have to write because it already exists and works.**

Always extend and improve existing code rather than creating new code from scratch.
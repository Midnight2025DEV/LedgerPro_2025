# LedgerPro Development Workflow

## Before Starting Any New Feature

Always perform a reconnaissance check to understand the current codebase and avoid duplicating existing functionality.

### 1. Check Git Status
```bash
git status
git branch --show-current
```
Ensure you're on the correct branch with a clean working tree.

### 2. Search for Existing Implementations

#### Check for related functionality:
```bash
# Search for keywords related to your feature
rg -i "keyword1|keyword2|keyword3" --type swift

# Find files containing specific imports
find . -name "*.swift" -type f -exec grep -l "import.*Framework" {} \;

# Look for existing models
ls Sources/LedgerPro/Models/
```

#### Example: Before implementing auto-categorization:
```bash
rg -i "auto.*categor|suggest.*category|rule.*category" --type swift
```

### 3. Examine Data Models
```bash
# Check relevant model structures
cat Sources/LedgerPro/Models/Transaction.swift
cat Sources/LedgerPro/Models/Category.swift
```

### 4. Review Services and Business Logic
```bash
# List all services
ls Sources/LedgerPro/Services/

# Check for related service methods
rg "func.*category" Sources/LedgerPro/Services/
```

### 5. Check for Existing UI Components
```bash
# Find views related to your feature
find . -name "*.swift" | xargs grep -l "YourFeature" | grep -i "view"
```

### 6. Database/Storage Check
```bash
# Check data persistence approach
find . -name "*.xcdatamodeld" -o -name "*.swift" | xargs grep -l "CoreData\|NSManagedObject\|UserDefaults\|FileManager"
```

## Benefits of This Approach

1. **Avoid Duplication**: Don't recreate existing functionality
2. **Build on Foundations**: Enhance rather than rebuild
3. **Maintain Consistency**: Follow established patterns
4. **Save Time**: Leverage existing code
5. **Better Integration**: Understand how components interact

## Real Example: Auto-Categorization Discovery

When planning to add auto-categorization, we discovered:
- ✅ `CategoryRule.swift` already exists
- ✅ `CategoryService.suggestCategory()` implemented
- ✅ Basic rule matching in place
- ✅ MCPBridge has `auto_categorize` flag

This changed our approach from "implement auto-categorization" to "enhance existing auto-categorization system."

## Feature Planning Template

Before implementing any feature:

1. **Define the feature goal**
2. **Run reconnaissance checks**
3. **Document findings**
4. **Identify:**
   - What exists
   - What can be enhanced
   - What needs to be built
5. **Create implementation plan**

## Common Search Patterns

```bash
# Find all uses of a class/struct
rg "ClassName" --type swift

# Find method implementations
rg "func methodName" --type swift

# Find protocol conformances
rg ": .*Protocol" --type swift

# Find imports
rg "^import " --type swift | sort | uniq

# Find TODOs and FIXMEs
rg "TODO|FIXME" --type swift
```

## Architectural Overview Commands

```bash
# Count lines of code by directory
find . -name "*.swift" -type f | xargs wc -l | sort -n

# List all Swift files
find . -name "*.swift" -type f | sort

# Show project structure
tree -I 'DerivedData|.build|.git' -P '*.swift' --prune
```

## Claude + Claude Code Workflow

### Working with Claude Desktop and Claude Code

1. **Strategy & Planning** (Claude Desktop)
   - High-level planning and problem-solving
   - Generate specific, copyable prompts
   - Review code changes and plan next steps

2. **Implementation** (Claude Code)
   - Execute specific commands
   - Make code changes
   - Run reconnaissance checks

3. **Prompt Format for Claude Code**
   ```
   PROMPT FOR CLAUDE CODE:
   [Specific command or code change]
   
   WHAT THIS DOES:
   [Brief explanation]
   
   JONATHAN TO DO:
   - **Action items in bold**
   ```

### Best Practices

- **One task at a time**: Keep prompts focused and specific
- **Use full paths**: Always specify complete file paths
- **Check before changing**: Run reconnaissance before implementing
- **Logical commits**: Separate concerns into different commits
- **Clear documentation**: Update docs as you go

---

*Last updated: January 2025*
*This workflow has helped prevent duplicate work and maintain code quality in the LedgerPro project.*
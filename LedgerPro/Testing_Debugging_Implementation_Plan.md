# LedgerPro Testing & Debugging Implementation Plan

## How to Use This Document
1. Execute each task in order
2. Complete the RESEARCH phase before any implementation
3. Document findings in a `FINDINGS.md` file as you go
4. Check off completed tasks by adding [✓] at the beginning of the line

---

## Phase 1: Research & Discovery [MANDATORY - DO FIRST]

### [ ] Task 1.1: Audit Existing Test Infrastructure

```bash
echo "=== RESEARCHING EXISTING TEST INFRASTRUCTURE ==="

# 1. Find all existing test files
echo "📁 Searching for test files..."
find . -name "*Test*.swift" -o -name "*test*.swift" -o -name "*Tests" -type f 2>/dev/null | sort

# 2. Check for test targets in Package.swift
echo -e "\n📦 Checking Package.swift for test targets..."
grep -n "testTarget\|.test" Package.swift || echo "No test targets found"

# 3. Look for existing XCTest imports
echo -e "\n🧪 Finding XCTest usage..."
grep -r "import XCTest" . --include="*.swift" 2>/dev/null | head -10

# 4. Find any test utilities or helpers
echo -e "\n🔧 Looking for test utilities..."
find . -path "*/Tests/*" -name "*.swift" 2>/dev/null

# 5. Check for existing test data/fixtures
echo -e "\n📎 Finding test fixtures..."
find . -name "*.pdf" -o -name "*.csv" 2>/dev/null | grep -i "test\|sample\|fixture\|mock"

# Document findings
echo -e "\n📝 Creating findings document..."
cat > FINDINGS_Tests.md << 'FINDINGS'
# Test Infrastructure Findings

## Existing Tests Found:
- [List test files here]

## Test Patterns Observed:
- [Document patterns]

## What's Missing:
- [List gaps]

## Recommendation:
- [Enhance existing / Create new]
FINDINGS
```

### [ ] Task 1.2: Audit Existing Debug/Logging Infrastructure

```bash
echo "=== RESEARCHING DEBUG/LOGGING INFRASTRUCTURE ==="

# 1. Find existing logging implementations
echo "📊 Analyzing logging patterns..."
grep -r "AppLogger\|Logger\|print(" Sources --include="*.swift" | head -20

# 2. Check for debug-only code
echo -e "\n🐛 Finding debug code blocks..."
grep -r "#if DEBUG\|#debug" Sources --include="*.swift"

# 3. Find existing debug views or menus
echo -e "\n🎛️ Looking for debug UI elements..."
grep -r "Debug\|debug" Sources --include="*.swift" | grep -i "view\|menu\|button"

# 4. Look for performance monitoring
echo -e "\n⏱️ Checking performance monitoring..."
grep -r "measure\|performance\|CFAbsoluteTime\|elapsed" Sources --include="*.swift"

# 5. Analyze error handling patterns
echo -e "\n⚠️ Examining error handling..."
grep -r "enum.*Error\|struct.*Error" Sources --include="*.swift" | head -10

# Document logging findings
cat >> FINDINGS_Debug.md << 'FINDINGS'
# Debug/Logging Infrastructure Findings

## Current Logging System:
- [AppLogger details]

## Debug Features Found:
- [List debug features]

## Performance Monitoring:
- [Current approach]

## Gaps Identified:
- [What's missing]
FINDINGS
```

---

## Phase 2: Unit Test Implementation

### [ ] Task 2.1: Enhance Transaction Model Tests

```bash
echo "=== IMPLEMENTING TRANSACTION TESTS ==="

# First, research Transaction model
echo "🔍 Analyzing Transaction model..."
grep -A 10 "struct Transaction" Sources/LedgerPro/Models/Transaction.swift

# Check for existing tests
if [ -f "Tests/LedgerProTests/TransactionTests.swift" ]; then
    echo "✅ Transaction tests exist - will enhance"
    # Add enhancement code here
else
    echo "❌ No Transaction tests found - creating new"
    
    # Create test directory if needed
    mkdir -p Tests/LedgerProTests
    
    # Generate Transaction tests
    cat > Tests/LedgerProTests/TransactionTests.swift << 'TESTFILE'
import XCTest
@testable import LedgerPro

final class TransactionTests: XCTestCase {
    
    func testForeignCurrencyConversion() {
        // TODO: Implement based on Transaction model research
    }
    
    func testDuplicateDetection() {
        // TODO: Implement based on existing logic
    }
    
    func testDateFormatting() {
        // TODO: Test date parsing edge cases
    }
    
    func testAmountCalculations() {
        // TODO: Test amount formatting and calculations
    }
}
TESTFILE
fi
```

### [ ] Task 2.2: Create/Enhance CategoryRule Tests

```bash
echo "=== IMPLEMENTING CATEGORYRULE TESTS ==="

# Research CategoryRule implementation
echo "🔍 Analyzing CategoryRule..."
find . -name "*CategoryRule*.swift" -not -path "*/\.*" | xargs grep -l "struct\|class" | head -5

# Generate tests based on findings
# [Implementation based on research]
```

---

## Phase 3: Debug Infrastructure Enhancement

### [ ] Task 3.1: Create Transaction State Inspector

```bash
echo "=== CREATING TRANSACTION STATE INSPECTOR ==="

# This is CRITICAL for the current visibility issue!

# 1. Analyze current filtering logic
echo "🔍 Understanding filter logic..."
grep -A 20 "filterTransactions\|filteredTransactions" Sources/LedgerPro/Views/TransactionListView.swift > filter_logic.txt

# 2. Create the debug inspector
cat > Sources/LedgerPro/Views/Debug/TransactionStateInspector.swift << 'INSPECTOR'
import SwiftUI

struct TransactionStateInspector: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    let filteredCount: Int
    let searchText: String
    let selectedCategory: String
    let showUncategorizedOnly: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🔍 Transaction State Inspector")
                .font(.headline)
            
            Divider()
            
            Group {
                Label("\(dataManager.transactions.count) Total Transactions", systemImage: "doc.text")
                Label("\(filteredCount) Visible Transactions", systemImage: "eye")
                Label("\(dataManager.transactions.count - filteredCount) Hidden", systemImage: "eye.slash")
                    .foregroundColor(.red)
            }
            
            Divider()
            
            Text("Active Filters:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if !searchText.isEmpty {
                Label("Search: '\(searchText)'", systemImage: "magnifyingglass")
                    .font(.caption)
            }
            
            if selectedCategory != "All" {
                Label("Category: \(selectedCategory)", systemImage: "folder")
                    .font(.caption)
            }
            
            if showUncategorizedOnly {
                Label("Showing Uncategorized Only", systemImage: "questionmark.folder")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            Divider()
            
            Button("Reset All Filters") {
                // Reset action
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}
INSPECTOR

echo "✅ Transaction State Inspector created"
```

### [ ] Task 3.2: Enhance Logging System

```bash
echo "=== ENHANCING LOGGING SYSTEM ==="

# Check current AppLogger
echo "🔍 Analyzing AppLogger..."
find . -name "*AppLogger*" -o -name "*Logger*" | xargs grep -A 10 "class\|struct" | head -20

# Enhance based on findings
# [Implementation based on research]
```

---

## Phase 4: Performance Monitoring

### [ ] Task 4.1: Add Performance Tracking

```bash
echo "=== IMPLEMENTING PERFORMANCE MONITORING ==="

# Find performance-critical code
echo "🔍 Identifying performance bottlenecks..."
grep -r "filterTransactions\|categorizeTransactions\|importFile" Sources --include="*.swift" | head -10

# Create performance utility
cat > Sources/LedgerPro/Utils/PerformanceMonitor.swift << 'PERF'
import Foundation

class PerformanceMonitor {
    static func measure<T>(_ label: String, operation: () throws -> T) rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        defer {
            let elapsed = CFAbsoluteTimeGetCurrent() - start
            AppLogger.shared.debug("⏱️ \(label): \(String(format: "%.3f", elapsed))s")
        }
        return try operation()
    }
}
PERF
```

---

## Phase 5: Quick Fixes for Current Issue

### [ ] Task 5.1: Immediate Transaction Visibility Fix

```bash
echo "=== APPLYING IMMEDIATE FIX ==="

# This fixes the "1 of 1,013" issue immediately

# Add force refresh button
cat >> Sources/LedgerPro/Views/TransactionListView.swift << 'QUICKFIX'

// Add to toolbar
Button("Force Refresh") {
    cachedFilteredTransactions = dataManager.transactions
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    cachedGroupedTransactions = Dictionary(grouping: dataManager.transactions) { 
        formatter.string(from: $0.formattedDate)
    }
    AppLogger.shared.info("🔄 Forced refresh: \(cachedFilteredTransactions.count) transactions visible")
}
.buttonStyle(.borderedProminent)
.foregroundColor(.red)
QUICKFIX
```

---

## Completion Checklist

- [ ] Phase 1: Research completed and documented
- [ ] Phase 2: Unit tests implemented
- [ ] Phase 3: Debug infrastructure created
- [ ] Phase 4: Performance monitoring added
- [ ] Phase 5: Quick fixes applied
- [ ] All findings documented in FINDINGS_*.md files
- [ ] Code committed with descriptive messages

## Next Steps

1. Review FINDINGS_*.md files
2. Run test suite: `swift test`
3. Test debug features in development build
4. Monitor performance metrics
5. Document any new issues discovered
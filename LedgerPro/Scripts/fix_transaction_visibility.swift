#!/usr/bin/env swift

import Foundation

print("🔧 Fixing Transaction Visibility Issue")
print("=====================================")

print("""
The issue is that TransactionListView filters are hiding imported transactions.

Add this to TransactionListView.onAppear:

// Listen for import completion
NotificationCenter.default.addObserver(
    forName: NSNotification.Name("TransactionsImported"),
    object: nil,
    queue: .main
) { notification in
    // Reset all filters to show imported transactions
    self.searchText = ""
    self.selectedCategory = "All"
    self.selectedCategoryObject = nil
    self.showUncategorizedOnly = false
    self.sortOrder = .dateDescending
    
    // Force refresh
    Task {
        self.lastFilterCriteria = FilterCriteria()
        await self.filterTransactions()
    }
    
    AppLogger.shared.info("📥 Import complete - reset filters to show all transactions")
}
""")

print("\n✅ This will ensure transactions are visible after import!")
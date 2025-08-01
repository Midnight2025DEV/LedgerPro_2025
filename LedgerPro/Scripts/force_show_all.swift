#\!/usr/bin/env swift

print("🚨 FORCING ALL TRANSACTIONS TO DISPLAY")
print("=====================================")

// The nuclear option isn't nuclear enough. Let's make it REALLY nuclear.

print("""
In TransactionListView, replace the entire onAppear block with this:

.onAppear {
    // NUCLEAR OPTION: Force show ALL transactions
    AppLogger.shared.info("🚨 NUCLEAR: Force showing ALL transactions on appear")
    
    // Reset EVERYTHING
    searchText = ""
    selectedCategory = "All"
    selectedCategoryObject = nil
    showUncategorizedOnly = false
    sortOrder = .dateDescending
    
    // Force immediate display without filtering
    cachedFilteredTransactions = dataManager.transactions
    cachedAutoCategorizedCount = dataManager.transactions.filter { $0.wasAutoCategorized == true }.count
    
    // Group by date
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    cachedGroupedTransactions = Dictionary(grouping: dataManager.transactions) { transaction in
        dateFormatter.string(from: transaction.formattedDate)
    }
    
    // Reset filter criteria to force refresh
    lastFilterCriteria = FilterCriteria()
    
    AppLogger.shared.info("✅ FORCED display of \\(cachedFilteredTransactions.count) transactions")
    
    // THEN run normal filtering after a delay
    Task {
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        await filterTransactions()
    }
}
""")
EOF < /dev/null
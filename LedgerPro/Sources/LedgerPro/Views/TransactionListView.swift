import SwiftUI

struct TransactionListView: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var sortOrder: SortOrder = .dateDescending
    @State private var showingFilters = false
    @State private var selectedTransaction: Transaction?
    @State private var showingDetail = false
    
    // Enhanced category filtering
    @State private var showingCategoryFilter = false
    @State private var selectedCategoryObject: Category?
    @State private var showUncategorizedOnly = false
    @EnvironmentObject private var categoryService: CategoryService
    
    // Bulk categorization state
    @State private var selectedTransactions = Set<String>()
    @State private var showBulkActions = false
    @State private var bulkCategory: Category?
    @State private var createRuleFromBulk = false
    
    // Toast state
    @State private var showToast = false
    @State private var toastMessage = ""
    
    let onTransactionSelect: (Transaction) -> Void
    
    enum SortOrder: String, CaseIterable {
        case dateDescending = "Date (Newest)"
        case dateAscending = "Date (Oldest)"
        case amountDescending = "Amount (Highest)"
        case amountAscending = "Amount (Lowest)"
        case description = "Description"
    }
    
    private var categories: [String] {
        let allCategories = Set(dataManager.transactions.map { $0.category })
        return ["All"] + allCategories.sorted()
    }
    
    private var groupedTransactions: [String: [Transaction]] {
        Dictionary(grouping: filteredTransactions) { transaction in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: transaction.formattedDate)
        }
    }
    
    private var autoCategorizedCount: Int {
        filteredTransactions.filter { $0.wasAutoCategorized == true }.count
    }
    
    private var filteredTransactions: [Transaction] {
        var filtered = dataManager.transactions
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { transaction in
                transaction.description.localizedCaseInsensitiveContains(searchText) ||
                transaction.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by category
        if selectedCategory != "All" {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Enhanced category filtering
        if let categoryObject = selectedCategoryObject {
            filtered = filtered.filter { transaction in
                // Simple name matching for now - can be enhanced later
                return transaction.category == categoryObject.name
            }
        }
        
        // Filter for uncategorized transactions
        if showUncategorizedOnly {
            filtered = filtered.filter { transaction in
                transaction.category.isEmpty || 
                transaction.category == "Uncategorized" ||
                transaction.category == "Other"
            }
        }
        
        // Sort
        switch sortOrder {
        case .dateDescending:
            filtered = filtered.sorted { $0.formattedDate > $1.formattedDate }
        case .dateAscending:
            filtered = filtered.sorted { $0.formattedDate < $1.formattedDate }
        case .amountDescending:
            filtered = filtered.sorted { $0.amount > $1.amount }
        case .amountAscending:
            filtered = filtered.sorted { $0.amount < $1.amount }
        case .description:
            filtered = filtered.sorted { $0.description < $1.description }
        }
        
        return filtered
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                TextField("Search transactions...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                
                Button(action: {
                    autoCategorizeUncategorized()
                }) {
                    Label("Auto-Categorize", systemImage: "wand.and.stars")
                }
                .help("Automatically categorize transactions based on merchant patterns")
                
                Button(action: { showingFilters.toggle() }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title2)
                }
                .help("Filters")
            }
            
            if showingFilters {
                filtersSection
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var filtersSection: some View {
        HStack {
            // Enhanced Category Filter Button
            Button(action: { showingCategoryFilter = true }) {
                HStack(spacing: 8) {
                    Image(systemName: selectedCategoryObject?.icon ?? "folder.fill")
                        .font(.caption)
                        .foregroundColor(selectedCategoryObject.flatMap { Color(hex: $0.color) } ?? .blue)
                    
                    Text(selectedCategoryObject?.name ?? "All Categories")
                        .font(.subheadline)
                        .lineLimit(1)
                    
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .frame(width: 180)
            
            Picker("Sort", selection: $sortOrder) {
                ForEach(SortOrder.allCases, id: \.self) { order in
                    Text(order.rawValue).tag(order)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 150)
            
            Spacer()
            
            Button("Clear Filters") {
                searchText = ""
                selectedCategory = "All"
                selectedCategoryObject = nil
                sortOrder = .dateDescending
            }
            .buttonStyle(.bordered)
        }
        .padding(.top, 8)
    }
    
    private var bulkActionsToolbar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Text("\(selectedTransactions.count) selected")
                    .font(.headline)
                
                Spacer()
                
                Toggle("Create Rule", isOn: $createRuleFromBulk)
                    .toggleStyle(.checkbox)
                
                Picker("Category", selection: $bulkCategory) {
                    Text("Select Category").tag(nil as Category?)
                    ForEach(categoryService.categories) { category in
                        Label(category.name, systemImage: category.icon)
                            .tag(category as Category?)
                    }
                }
                .frame(width: 200)
                
                Button("Apply") {
                    applyBulkCategory()
                }
                .disabled(bulkCategory == nil)
                
                Button("Cancel") {
                    selectedTransactions.removeAll()
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    private var contentSection: some View {
        VStack(spacing: 0) {
            // Auto-categorization stats banner
            if !filteredTransactions.isEmpty {
                AutoCategorizationStatsBanner(
                    autoCategorizedCount: autoCategorizedCount,
                    totalCount: filteredTransactions.count
                )
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            
            // Transaction List
            if filteredTransactions.isEmpty {
                emptyStateView
            } else {
                transactionListView
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No transactions found")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if !searchText.isEmpty || selectedCategory != "All" || selectedCategoryObject != nil {
                Button("Clear Filters") {
                    searchText = ""
                    selectedCategory = "All"
                    selectedCategoryObject = nil
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var transactionListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Header Row
                TransactionHeaderView(showCheckbox: !selectedTransactions.isEmpty)
                
                // Group transactions by date
                ForEach(groupedTransactions.keys.sorted(by: >), id: \.self) { dateKey in
                    let transactions = groupedTransactions[dateKey] ?? []
                    
                    // Date Separator
                    DateSeparatorView(
                        date: dateKey,
                        transactionCount: transactions.count,
                        dailyTotal: transactions.reduce(0) { $0 + $1.amount }
                    )
                    
                    // Transaction Rows
                    ForEach(transactions) { transaction in
                        DistributedTransactionRowView(
                            transaction: transaction,
                            onTransactionSelect: { selectedTransaction in
                                self.selectedTransaction = selectedTransaction
                                showingDetail = true
                            },
                            selectedTransactions: $selectedTransactions,
                            showCheckbox: !selectedTransactions.isEmpty
                        )
                        .onTapGesture {
                            if !selectedTransactions.isEmpty {
                                // In selection mode, toggle selection
                                if selectedTransactions.contains(transaction.id) {
                                    selectedTransactions.remove(transaction.id)
                                } else {
                                    selectedTransactions.insert(transaction.id)
                                }
                            } else {
                                // Normal mode, show detail
                                selectedTransaction = transaction
                                showingDetail = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            
            Divider()
            
            if !selectedTransactions.isEmpty {
                bulkActionsToolbar
            }
            
            contentSection
        }
        .navigationTitle("Transactions (\(filteredTransactions.count))")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack {
                    // Bulk Selection Toggle
                    Button(action: {
                        if selectedTransactions.isEmpty {
                            // Start bulk selection
                            if let firstTransaction = filteredTransactions.first {
                                selectedTransactions.insert(firstTransaction.id)
                            }
                        } else {
                            // Exit bulk selection
                            selectedTransactions.removeAll()
                        }
                    }) {
                        Image(systemName: selectedTransactions.isEmpty ? "checkmark.square" : "xmark.square")
                    }
                    .help(selectedTransactions.isEmpty ? "Bulk Select" : "Exit Bulk Select")
                    
                    Button(action: { dataManager.clearAllData() }) {
                        Image(systemName: "trash")
                    }
                    .help("Clear All Data")
                    
                    Button(action: { dataManager.removeDuplicates() }) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    .help("Remove Duplicates")
                }
            }
        }
        .popover(isPresented: $showingDetail, arrowEdge: .trailing) {
            if let transaction = selectedTransaction {
                TransactionDetailView(transaction: transaction)
            }
        }
        .overlay(
            Group {
                if showingCategoryFilter {
                    CategoryFilterPickerPopup(
                        selectedCategory: $selectedCategoryObject,
                        isPresented: $showingCategoryFilter
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(1000)
                }
            }
        )
        .overlay(
            Group {
                if showToast {
                    VStack {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(toastMessage)
                                .font(.headline)
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showToast = false
                            }
                        }
                    }
                }
            },
            alignment: .top
        )
        .animation(.easeInOut(duration: 0.2), value: showingCategoryFilter)
        .animation(.easeInOut(duration: 0.3), value: selectedTransactions.isEmpty)
        .animation(.easeInOut(duration: 0.2), value: showToast)
        .onAppear {
            // Load categories when view appears
            if categoryService.categories.isEmpty {
                Task {
                    await categoryService.loadCategories()
                }
            }
            
            // Listen for uncategorized filter requests
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("NavigateToUncategorized"),
                object: nil,
                queue: .main
            ) { notification in
                showUncategorizedOnly = true
                selectedCategory = "All"  // Reset other filters
                selectedCategoryObject = nil
                searchText = ""
            }
        }
    }
    
    // MARK: - Bulk Actions
    
    private func applyBulkCategory() {
        guard let category = bulkCategory else { return }
        
        let selectedTrans = dataManager.transactions.filter { 
            selectedTransactions.contains($0.id) 
        }
        
        for transaction in selectedTrans {
            dataManager.updateTransactionCategory(transactionId: transaction.id, newCategory: category)
            
            if createRuleFromBulk {
                // Create rule for this merchant
                let merchantName = extractMerchantName(from: transaction.description)
                createMerchantRule(merchantName: merchantName, category: category, transaction: transaction)
            }
        }
        
        // Clear selection
        selectedTransactions.removeAll()
        bulkCategory = nil
        createRuleFromBulk = false
        
        // Show success feedback
        toastMessage = "Categorized \(selectedTrans.count) transactions"
        showToast = true
    }
    
    private func autoCategorizeUncategorized() {
        let uncategorized = dataManager.transactions.filter { 
            $0.category.isEmpty || $0.category == "Uncategorized" || $0.category == "Other" 
        }
        
        var categorizedCount = 0
        AppLogger.shared.info("Starting auto-categorization for \(uncategorized.count) uncategorized transactions")
        
        for transaction in uncategorized {
            // Extract merchant name from description
            let merchantName = extractMerchantName(from: transaction.description)
            
            // Check against merchant mappings
            if let suggestion = categoryService.suggestCategoryForMerchant(transaction.description),
               let category = suggestion.category,
               suggestion.confidence > 0.8 {
                
                AppLogger.shared.info("Auto-categorizing '\(transaction.description)' → \(category.name)")
                dataManager.updateTransactionCategory(transactionId: transaction.id, newCategory: category)
                categorizedCount += 1
                
                // Also create a rule for future imports
                createMerchantRule(merchantName: merchantName, category: category, transaction: transaction)
            } else {
                // Fall back to rule-based categorization
                let (category, confidence) = categoryService.suggestCategory(for: transaction)
                if let category = category, confidence > 0.8 {
                    AppLogger.shared.info("Auto-categorizing '\(transaction.description)' → \(category.name) (rule-based)")
                    dataManager.updateTransactionCategory(transactionId: transaction.id, newCategory: category)
                    categorizedCount += 1
                }
            }
        }
        
        if categorizedCount > 0 {
            AppLogger.shared.info("✅ Auto-categorized \(categorizedCount) transactions")
            
            // Show success feedback
            toastMessage = "Categorized \(categorizedCount) transactions"
            showToast = true
        } else {
            AppLogger.shared.info("No transactions matched auto-categorization patterns")
            toastMessage = "No matches found for auto-categorization"
            showToast = true
        }
    }
    
    private func extractMerchantName(from description: String) -> String {
        // Use similar logic to Transaction's displayMerchantName
        if description.contains("UBER") {
            return "UBER"
        } else if description.contains("WAL-MART") || description.contains("WALMART") {
            return "WALMART"
        } else if description.contains("CHEVRON") {
            return "CHEVRON"
        } else if description.contains("NETFLIX") {
            return "NETFLIX"
        } else if description.contains("AMAZON") {
            return "AMAZON"
        } else if description.contains("STARBUCKS") {
            return "STARBUCKS"
        }
        
        // For other merchants, take first 1-3 meaningful words
        let words = description.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty && $0.count > 2 }
            .prefix(2)
        
        return words.joined(separator: " ").uppercased()
    }
    
    private func createMerchantRule(merchantName: String, category: Category, transaction: Transaction) {
        // Create a merchant-based rule
        var newRule = CategoryRule(
            categoryId: category.id,
            ruleName: "Auto: \(merchantName)"
        )
        
        // Set rule properties
        newRule.merchantContains = merchantName
        newRule.amountSign = transaction.amount < 0 ? .negative : .positive
        newRule.priority = 100 // User-generated rules get high priority
        newRule.confidence = 0.85 // Start with good confidence
        newRule.isActive = true
        
        // Save the rule
        RuleStorageService.shared.saveRule(newRule)
        AppLogger.shared.info("Created new merchant rule: \(merchantName) → \(category.name)")
    }
}

#Preview {
    NavigationView {
        TransactionListView { _ in }
            .environmentObject(FinancialDataManager())
    }
}
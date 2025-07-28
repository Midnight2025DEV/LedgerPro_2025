import SwiftUI

// MARK: - Supporting Types for Modern Transaction List

struct TransactionListView: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var sortOrder: SortOrder = .dateDescending
    @State private var showingFilters = false
    @State private var selectedTransaction: Transaction?
    @State private var showingDetail = false
    
    // MARK: - Feature Flag System
    @AppStorage("useModernTransactionList") private var useModernTransactionList = false
    @AppStorage("modernTransactionListRolloutPercentage") private var rolloutPercentage: Double = 0.0
    @State private var userInModernExperiment = false
    
    // Modern transaction list state
    @State private var modernSearchText = ""
    @State private var modernSelectedTransactions = Set<String>()
    @State private var modernActiveFilters = TransactionFilters()
    @State private var modernGroupingMode: ModernTransactionList.GroupingMode = .day
    @State private var modernIsBulkSelectionMode = false
    
    // Error handling and fallback
    @State private var modernListLoadError: Error?
    @State private var shouldFallbackToLegacy = false
    
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
    
    // Performance optimization state
    @State private var cachedFilteredTransactions: [Transaction] = []
    @State private var cachedGroupedTransactions: [String: [Transaction]] = [:]
    @State private var cachedAutoCategorizedCount: Int = 0
    @State private var filterTask: Task<Void, Never>?
    @State private var searchDebounceTask: Task<Void, Never>?
    @State private var isFiltering = false
    @State private var showingSkeletonLoader = false
    @State private var filterStartTime: CFAbsoluteTime = 0
    
    // Track last filter criteria to avoid unnecessary updates
    @State private var lastFilterCriteria = FilterCriteria()
    
    // Debug state
    @State private var showDebugInspector = false
    
    let onTransactionSelect: (Transaction) -> Void
    let initialShowUncategorizedOnly: Bool
    let triggerUncategorizedFilter: Bool
    
    init(
        onTransactionSelect: @escaping (Transaction) -> Void,
        initialShowUncategorizedOnly: Bool = false,
        triggerUncategorizedFilter: Bool = false
    ) {
        self.onTransactionSelect = onTransactionSelect
        self.initialShowUncategorizedOnly = initialShowUncategorizedOnly
        self.triggerUncategorizedFilter = triggerUncategorizedFilter
    }
    
    enum SortOrder: String, CaseIterable {
        case dateDescending = "Date (Newest)"
        case dateAscending = "Date (Oldest)"
        case amountDescending = "Amount (Highest)"
        case amountAscending = "Amount (Lowest)"
        case description = "Description"
    }
    
    // Track filter criteria changes
    private struct FilterCriteria: Equatable {
        var searchText = ""
        var selectedCategory = "All"
        var selectedCategoryObject: Category?
        var showUncategorizedOnly = false
        var sortOrder: SortOrder = .dateDescending
    }
    
    // MARK: - Feature Flag Logic
    
    /// Determines if this user should see the modern transaction list
    private var shouldUseModernList: Bool {
        // Always use modern list if explicitly enabled
        if useModernTransactionList {
            return true
        }
        
        // Check if user is in the rollout experiment
        return userInModernExperiment
    }
    
    /// Initialize user experiment participation based on rollout percentage
    private func initializeExperiment() {
        guard rolloutPercentage > 0.0 else {
            userInModernExperiment = false
            return
        }
        
        // Use a deterministic hash based on device identifier for consistent experience
        #if canImport(UIKit)
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "default"
        #else
        let deviceId = "macOS-device"
        #endif
        let hash = abs(deviceId.hashValue) % 100
        let threshold = Int(rolloutPercentage)
        
        userInModernExperiment = hash < threshold
        
        AppLogger.shared.info("🎯 Feature Flag: Modern list experiment - rollout: \(rolloutPercentage)%, user hash: \(hash), threshold: \(threshold), enabled: \(userInModernExperiment)")
        
        // Track experiment assignment
        Analytics.shared.trackExperimentAssignment(
            experimentName: "modern_transaction_list",
            variant: userInModernExperiment ? "modern" : "legacy",
            rolloutPercentage: rolloutPercentage
        )
    }
    
    /// Monitor performance differences between legacy and modern lists
    private func trackPerformanceMetrics(viewType: String, transactionCount: Int, renderTime: TimeInterval? = nil) {
        Analytics.shared.trackPerformanceMetric(
            metricName: "transaction_list_performance",
            value: renderTime ?? 0.0,
            metadata: [
                "view_type": viewType,
                "transaction_count": String(transactionCount),
                "is_experiment": String(userInModernExperiment),
                "rollout_percentage": String(rolloutPercentage)
            ]
        )
    }
    
    /// Handle accessibility requirements for 10k+ transactions
    private func optimizeForAccessibility() -> Bool {
        let transactionCount = dataManager.transactions.count
        
        // For very large datasets, enable additional optimizations
        if transactionCount > 10000 {
            AppLogger.shared.info("🔍 Large dataset detected (\(transactionCount) transactions) - enabling accessibility optimizations")
            
            // Track large dataset usage
            Analytics.shared.trackDatasetSize(
                size: transactionCount,
                viewType: shouldUseModernList ? "modern" : "legacy"
            )
            
            // Monitor memory usage for large datasets
            PerformanceMonitor.shared.recordMemoryUsage(
                context: "large_dataset_\(transactionCount)",
                itemCount: transactionCount
            )
            
            return true
        }
        
        // Monitor memory for medium datasets too
        if transactionCount > 5000 {
            PerformanceMonitor.shared.recordMemoryUsage(
                context: "medium_dataset_\(transactionCount)",
                itemCount: transactionCount
            )
        }
        
        return false
    }
    
    private var categories: [String] {
        let allCategories = Set(dataManager.transactions.map { $0.category })
        return ["All"] + allCategories.sorted()
    }
    
    // Use cached values instead of computed properties
    private var groupedTransactions: [String: [Transaction]] {
        // Use cached grouped transactions for better performance
        return cachedGroupedTransactions
    }
    
    private var autoCategorizedCount: Int {
        cachedAutoCategorizedCount
    }
    
    private var filteredTransactions: [Transaction] {
        // Use cached filtered transactions for better performance
        return cachedFilteredTransactions
    }
    
    // Enhanced async filtering with comprehensive analytics tracking
    private func filterTransactions() async {
        // Cancel any existing filter operation
        filterTask?.cancel()
        
        // Create new filter criteria
        let currentCriteria = FilterCriteria(
            searchText: searchText,
            selectedCategory: selectedCategory,
            selectedCategoryObject: selectedCategoryObject,
            showUncategorizedOnly: showUncategorizedOnly,
            sortOrder: sortOrder
        )
        
        // Skip if criteria hasn't changed
        guard currentCriteria != lastFilterCriteria else {
            await MainActor.run {
                isFiltering = false
            }
            return
        }
        
        // Capture transaction count for analytics
        let transactionCount = await MainActor.run { 
            isFiltering = true
            
            // Show skeleton loader for complex operations
            if dataManager.transactions.count > 1000 {
                showingSkeletonLoader = true
            }
            
            return dataManager.transactions.count
        }
        
        // Use enhanced performance tracking with analytics integration
        let result = await PerformanceMonitor.shared.trackFilterOperation(
            filterType: "transaction_filter",
            itemCount: transactionCount
        ) {
            // Capture current transactions once to avoid main thread access
            let allTransactions = await MainActor.run { self.dataManager.transactions }
            
            // Perform all operations on background thread for maximum performance
            return await Task.detached(priority: .userInitiated) { () -> (transactions: [Transaction], grouped: [String: [Transaction]], autoCount: Int) in
                        // DEBUG: Log what we're working with (only in debug builds)
                        #if DEBUG
                        await MainActor.run {
                            AppLogger.shared.info("🔍 TransactionListView filtering \(allTransactions.count) total transactions")
                            AppLogger.shared.info("🔍 Filter criteria: searchText='\(currentCriteria.searchText)', category='\(currentCriteria.selectedCategory)', showUncategorized=\(currentCriteria.showUncategorizedOnly)")
                        }
                        #endif
                        
                        // Perform filtering on background thread
                        var filtered = allTransactions
                    
                        // Check for cancellation
                        if Task.isCancelled { return (transactions: [], grouped: [:], autoCount: 0) }
                        
                        // Optimized search text filtering with pre-computed lowercase strings
                        if !currentCriteria.searchText.isEmpty {
                            let searchLower = currentCriteria.searchText.lowercased()
                            filtered = filtered.filter { transaction in
                                let descLower = transaction.description.lowercased()
                                let categoryLower = transaction.category.lowercased()
                                return descLower.contains(searchLower) || categoryLower.contains(searchLower)
                            }
                        }
                        
                        // Check for cancellation
                        if Task.isCancelled { return (transactions: [], grouped: [:], autoCount: 0) }
                    
                        // Filter by category
                        if currentCriteria.selectedCategory != "All" {
                            filtered = filtered.filter { $0.category == currentCriteria.selectedCategory }
                        }
                        
                        // Enhanced category filtering
                        if let categoryObject = currentCriteria.selectedCategoryObject {
                            filtered = filtered.filter { transaction in
                                return transaction.category == categoryObject.name
                            }
                        }
                        
                        // Filter for uncategorized transactions
                        if currentCriteria.showUncategorizedOnly {
                            let beforeCount = filtered.count
                            filtered = filtered.filter { transaction in
                                transaction.category.isEmpty || 
                                transaction.category == "Uncategorized" ||
                                transaction.category == "Other"
                            }
                            #if DEBUG
                            await MainActor.run {
                                AppLogger.shared.info("📝 Uncategorized filter: \(beforeCount) → \(filtered.count) transactions")
                            }
                            #endif
                        }
                    
                        // Check for cancellation
                        if Task.isCancelled { return (transactions: [], grouped: [:], autoCount: 0) }
                        
                        // Optimized sorting with precomputed values where possible
                        switch currentCriteria.sortOrder {
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
                        
                        // Check for cancellation before expensive operations
                        if Task.isCancelled { return (transactions: [], grouped: [:], autoCount: 0) }
                        
                        // Calculate auto-categorized count efficiently
                        let autoCount = filtered.lazy.filter { $0.wasAutoCategorized == true }.count
                        
                        // Group transactions by date (expensive operation) - use static formatter
                        let grouped = Dictionary(grouping: filtered) { transaction in
                            DateFormatter.apiDateFormatter.string(from: transaction.formattedDate)
                        }
                        
                        return (transactions: filtered, grouped: grouped, autoCount: autoCount)
            }.value
        }
        
        // Update UI on main thread with batch update for smooth animation
        if !Task.isCancelled {
            await MainActor.run {
                // Batch update for smooth transition
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.cachedFilteredTransactions = result.transactions
                    self.cachedGroupedTransactions = result.grouped
                    self.cachedAutoCategorizedCount = result.autoCount
                    self.lastFilterCriteria = currentCriteria
                    self.isFiltering = false
                    self.showingSkeletonLoader = false
                }
                
                // Track additional filter metrics
                Analytics.shared.track("filter_completed", properties: [
                    "original_count": transactionCount,
                    "filtered_count": result.transactions.count,
                    "filter_effectiveness": transactionCount > 0 ? (1.0 - Double(result.transactions.count) / Double(transactionCount)) : 0.0,
                    "has_search_text": !currentCriteria.searchText.isEmpty,
                    "has_category_filter": currentCriteria.selectedCategory != "All",
                    "show_uncategorized": currentCriteria.showUncategorizedOnly,
                    "sort_order": currentCriteria.sortOrder.rawValue,
                    "date_groups": result.grouped.keys.count
                ])
                
                // Memory monitoring for large datasets
                if transactionCount > 5000 {
                    PerformanceMonitor.shared.recordMemoryUsage(
                        context: "after_filter_\(transactionCount)",
                        itemCount: result.transactions.count
                    )
                }
                
                // DEBUG: Log final results
                #if DEBUG
                AppLogger.shared.info("✅ TransactionListView filter complete: \(result.transactions.count) transactions after filtering")
                AppLogger.shared.info("📅 Grouped into \(result.grouped.keys.count) date groups")
                if result.transactions.isEmpty && transactionCount > 0 {
                    AppLogger.shared.warning("⚠️ All transactions were filtered out! Original count: \(transactionCount)")
                }
                #endif
            }
        }
    }
    
    // Debounced search handler with optimized delay
    private func handleSearchChange(_ newValue: String) {
        // Cancel previous debounce task
        searchDebounceTask?.cancel()
        
        // Show immediate loading state for search
        if !newValue.isEmpty {
            isFiltering = true
        }
        
        // Create new debounced task with 250ms delay for optimal responsiveness
        searchDebounceTask = Task {
            // Wait 250ms for optimal user experience
            try? await Task.sleep(nanoseconds: 250_000_000)
            
            // Check if not cancelled
            if !Task.isCancelled {
                await filterTransactions()
            }
        }
    }
    
    // MARK: - Loading & Skeleton Views
    
    private var loadingBanner: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
            
            Text("Filtering transactions...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    private var filteringOverlay: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                ProgressView()
                Text("Filtering...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.9))
            .cornerRadius(8)
            .shadow(radius: 2)
            Spacer()
        }
        .padding()
        .transition(.opacity)
    }
    
    private var skeletonLoaderView: some View {
        VStack(spacing: 0) {
            // Header skeleton
            TransactionHeaderView(showCheckbox: false)
                .opacity(0.3)
            
            // Skeleton rows
            ForEach(0..<10, id: \.self) { index in
                SkeletonTransactionRow()
                    .opacity(0.7 - Double(index) * 0.05)
            }
        }
        .transition(.opacity)
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                HStack {
                    TextField("Search transactions...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: searchText) { _, newValue in
                            handleSearchChange(newValue)
                        }
                    
                    // Subtle loading indicator in search field
                    if isFiltering && !searchText.isEmpty {
                        ProgressView()
                            .scaleEffect(0.7)
                            .padding(.trailing, 8)
                    }
                }
                
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
            
            Button("Show All") {
                AppLogger.shared.info("🔍 Show All button clicked - bypassing all filters")
                searchText = ""
                selectedCategory = "All"
                selectedCategoryObject = nil
                showUncategorizedOnly = false
                sortOrder = .dateDescending
                lastFilterCriteria = FilterCriteria() // Force re-filter
                Task {
                    await filterTransactions()
                }
            }
            .buttonStyle(.borderedProminent)
            
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
            // Loading indicator during filtering
            if isFiltering && !showingSkeletonLoader {
                loadingBanner
            }
            
            // Auto-categorization stats banner
            if !filteredTransactions.isEmpty && !isFiltering {
                AutoCategorizationStatsBanner(
                    autoCategorizedCount: autoCategorizedCount,
                    totalCount: filteredTransactions.count
                )
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            
            // Transaction List with loading states
            if showingSkeletonLoader {
                skeletonLoaderView
            } else if filteredTransactions.isEmpty && !isFiltering {
                emptyStateView
            } else if !filteredTransactions.isEmpty {
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
            
            if dataManager.transactions.count > 0 {
                Text("\(dataManager.transactions.count) transactions are hidden by current filters")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if dataManager.transactions.count > 0 {
                Button("Show All Transactions") {
                    searchText = ""
                    selectedCategory = "All"
                    selectedCategoryObject = nil
                    showUncategorizedOnly = false
                    sortOrder = .dateDescending
                    lastFilterCriteria = FilterCriteria()
                    Task {
                        await filterTransactions()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            
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
                
                // Show loading overlay if filtering
                if isFiltering {
                    filteringOverlay
                }
                
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
        .opacity(isFiltering ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFiltering)
    }
    
    private var debugInspectorOverlay: some View {
        Group {
            if showDebugInspector {
                TransactionStateInspector(
                    filteredCount: filteredTransactions.count,
                    searchText: searchText,
                    selectedCategory: selectedCategory,
                    showUncategorizedOnly: showUncategorizedOnly,
                    sortOrder: sortOrder
                )
                .frame(maxWidth: 350)
                .padding()
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
                .animation(.easeInOut(duration: 0.3), value: showDebugInspector)
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResetAllFilters"))) { _ in
                    // Handle reset filters request from inspector
                    searchText = ""
                    selectedCategory = "All"
                    selectedCategoryObject = nil
                    showUncategorizedOnly = false
                    sortOrder = .dateDescending
                    
                    Task {
                        lastFilterCriteria = FilterCriteria()
                        await filterTransactions()
                    }
                }
            }
        }
    }
    
    var body: some View {
        Group {
            if shouldUseModernList && !shouldFallbackToLegacy {
                modernTransactionListViewWithFallback
            } else {
                legacyTransactionListView
            }
        }
        .onAppear {
            initializeExperiment()
        }
        .alert("Modern List Error", isPresented: .constant(modernListLoadError != nil)) {
            Button("Use Legacy View") {
                shouldFallbackToLegacy = true
                modernListLoadError = nil
                AppLogger.shared.error("🎯 Falling back to legacy view due to error: \(modernListLoadError?.localizedDescription ?? "unknown")")
                Analytics.shared.trackError("modern_list_fallback", error: modernListLoadError)
            }
            Button("Retry") {
                modernListLoadError = nil
                // Will retry modern list on next render
            }
        } message: {
            Text("The modern transaction list encountered an error. You can retry or fall back to the classic view.")
        }
    }
    
    // MARK: - Modern Transaction List with Error Handling
    
    private var modernTransactionListViewWithFallback: some View {
        modernTransactionListViewSafe
    }
    
    private var modernTransactionListViewSafe: some View {
        ModernTransactionList()
            .environmentObject(dataManager)
            .accessibilityIdentifier("modernTransactionList")
            .navigationTitle("Transactions (\(dataManager.transactions.count))")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    modernToolbarContent
                }
            }
            .onAppear {
                handleModernListAppear()
            }
            .onDisappear {
                Analytics.shared.trackFeatureUsage("modern_transaction_list_dismissed")
            }
            .accessibilityLabel("Modern transaction list with \(dataManager.transactions.count) transactions")
            .accessibilityHint("Swipe gestures available for transaction actions. Use grouping controls to organize by date.")
    }
    
    private func handleModernListAppear() {
        let renderStartTime = CFAbsoluteTimeGetCurrent()
        
        AppLogger.shared.info("🎯 Modern Transaction List displayed")
        Analytics.shared.trackFeatureUsage("modern_transaction_list_viewed")
        
        // Track performance and accessibility
        let transactionCount = dataManager.transactions.count
        let isLargeDataset = optimizeForAccessibility()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let renderTime = CFAbsoluteTimeGetCurrent() - renderStartTime
            trackPerformanceMetrics(
                viewType: "modern",
                transactionCount: transactionCount,
                renderTime: renderTime
            )
        }
        
        AppLogger.shared.info("🎯 Modern list: \(transactionCount) transactions, large dataset optimization: \(isLargeDataset)")
    }
    
    // MARK: - Modern Transaction List Toolbar
    
    private var modernToolbarContent: some View {
        HStack {
            // Feature flag toggle for testing
            #if DEBUG
            Button(action: {
                useModernTransactionList.toggle()
                AppLogger.shared.info("🎯 Manual toggle: useModernTransactionList = \(useModernTransactionList)")
            }) {
                Image(systemName: useModernTransactionList ? "star.fill" : "star")
            }
            .help("Toggle Modern List (Debug)")
            #endif
            
            // Standard actions
            Button(action: { dataManager.loadStoredData() }) {
                Image(systemName: "arrow.clockwise")
            }
            .help("Refresh Transactions")
            
            Button(action: { dataManager.clearAllData() }) {
                Image(systemName: "trash")
            }
            .help("Clear All Data")
        }
    }
    
    // MARK: - Legacy Transaction List View
    
    private var legacyTransactionListView: some View {
        ZStack(alignment: .topTrailing) {
            mainContent
            
            // Debug Inspector Overlay
            debugInspectorOverlay
        }
        .accessibilityIdentifier("transactionList")
        .navigationTitle("Transactions (\(filteredTransactions.count) of \(dataManager.transactions.count))")
            .onAppear {
                let renderStartTime = CFAbsoluteTimeGetCurrent()
                
                Task {
                    // Log initial state
                    AppLogger.shared.info("📱 Legacy TransactionListView appeared with \(dataManager.transactions.count) transactions")
                    
                    // Track performance and accessibility
                    let transactionCount = dataManager.transactions.count
                    let isLargeDataset = optimizeForAccessibility()
                    
                    // Track legacy list usage
                    Analytics.shared.trackFeatureUsage("legacy_transaction_list_viewed")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        let renderTime = CFAbsoluteTimeGetCurrent() - renderStartTime
                        trackPerformanceMetrics(
                            viewType: "legacy",
                            transactionCount: transactionCount,
                            renderTime: renderTime
                        )
                    }
                    
                    AppLogger.shared.info("📱 Legacy list: \(transactionCount) transactions, large dataset optimization: \(isLargeDataset)")
                    
                    // DEBUG: Log sample transactions to understand the data
                    if dataManager.transactions.count > 0 {
                        AppLogger.shared.info("📊 First 5 transactions:")
                        for (index, transaction) in dataManager.transactions.prefix(5).enumerated() {
                            AppLogger.shared.info("   \(index + 1). '\(transaction.description)' - \(transaction.formattedDate) - Category: '\(transaction.category)' - Amount: \(transaction.amount)")
                        }
                        
                        // Check date distribution
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        let dates = Set(dataManager.transactions.map { dateFormatter.string(from: $0.formattedDate) })
                        AppLogger.shared.info("📅 Transactions span \(dates.count) unique dates: \(Array(dates.sorted()).joined(separator: ", "))")
                    }
                    
                    // NUCLEAR OPTION: Always reset filters to ensure transactions are visible
                    // This guarantees users see their data after import
                    AppLogger.shared.info("🔄 Resetting all filters to ensure transactions are visible")
                    searchText = ""
                    selectedCategory = "All"
                    selectedCategoryObject = nil
                    showUncategorizedOnly = false
                    sortOrder = .dateDescending
                    lastFilterCriteria = FilterCriteria() // Force re-filter
                    
                    await filterTransactions()
                }
                
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
                    Task { @MainActor in
                        self.lastFilterCriteria = FilterCriteria()
                        await self.filterTransactions()
                    }
                    
                    AppLogger.shared.info("📥 Import complete - reset filters to show all transactions")
                }
            }
            .onChange(of: dataManager.transactions) { _, _ in
                Task {
                    await filterTransactions()
                }
            }
            .onChange(of: dataManager.lastImportTime) { _, newImportTime in
                // Reset filters when new transactions are imported
                if newImportTime != nil {
                    AppLogger.shared.info("📥 New import detected - resetting filters to show all transactions")
                    searchText = ""
                    selectedCategory = "All"
                    selectedCategoryObject = nil
                    showUncategorizedOnly = false
                    sortOrder = .dateDescending
                    
                    Task { @MainActor in
                        lastFilterCriteria = FilterCriteria()
                        await filterTransactions()
                    }
                }
            }
            .onChange(of: selectedCategory) { _, _ in
                Task {
                    await filterTransactions()
                }
            }
            .onChange(of: selectedCategoryObject) { _, _ in
                Task {
                    await filterTransactions()
                }
            }
            .onChange(of: showUncategorizedOnly) { _, _ in
                Task {
                    await filterTransactions()
                }
            }
            .onChange(of: sortOrder) { _, _ in
                Task {
                    await filterTransactions()
                }
            }
            .onChange(of: triggerUncategorizedFilter) { _, _ in
                // When triggered from ContentView, activate uncategorized filter
                showUncategorizedOnly = true
                selectedCategory = "All"
                selectedCategoryObject = nil
                searchText = ""
                Task {
                    await filterTransactions()
                }
            }
            .onAppear {
                // Set initial filter state based on parameters
                if initialShowUncategorizedOnly {
                    showUncategorizedOnly = true
                    selectedCategory = "All"
                    selectedCategoryObject = nil
                }
            }
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            headerSection
            
            Divider()
            
            if !selectedTransactions.isEmpty {
                bulkActionsToolbar
            }
            
            if isFiltering {
                ProgressView("Filtering...")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            
            contentSection
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack {
                    // Refresh Button
                    Button(action: {
                        AppLogger.shared.info("🔄 Refresh button clicked - reloading data from storage")
                        dataManager.loadStoredData()
                        
                        Task {
                            // Wait a moment for the data to load
                            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                            AppLogger.shared.info("✅ Data reload complete - found \(dataManager.transactions.count) transactions")
                            
                            // Force re-filter after reload
                            lastFilterCriteria = FilterCriteria() // Reset to force re-filter
                            await filterTransactions()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("Refresh Transactions")
                    
                    // Feature flag toggle for modern list
                    #if DEBUG
                    Button(action: {
                        useModernTransactionList.toggle()
                        AppLogger.shared.info("🎯 Manual toggle: useModernTransactionList = \(useModernTransactionList)")
                    }) {
                        Image(systemName: useModernTransactionList ? "star.fill" : "star")
                    }
                    .help("Toggle Modern List (Debug)")
                    #endif
                    
                    // DEBUG: Force Show All Button
                    Button(action: {
                        AppLogger.shared.info("🚨 DEBUG: Force showing all transactions without filters")
                        cachedFilteredTransactions = dataManager.transactions
                        
                        // Group by date without any filtering
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        cachedGroupedTransactions = Dictionary(grouping: dataManager.transactions) { transaction in
                            dateFormatter.string(from: transaction.formattedDate)
                        }
                        
                        AppLogger.shared.info("🚨 DEBUG: Forced display of \(cachedFilteredTransactions.count) transactions")
                    }) {
                        Image(systemName: "eye.fill")
                    }
                    .help("DEBUG: Force Show All")
                    
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
                    
                    // Debug Inspector Toggle
                    Button(action: { showDebugInspector.toggle() }) {
                        Image(systemName: showDebugInspector ? "eye.circle.fill" : "eye.circle")
                    }
                    .help("Toggle Debug Inspector")
                    .foregroundColor(showDebugInspector ? .blue : .primary)
                    
                    // Feature Flag Admin
                    #if DEBUG
                    Menu {
                        Button("Enable for All (100%)") {
                            rolloutPercentage = 100.0
                            initializeExperiment()
                        }
                        
                        Button("Test Rollout (50%)") {
                            rolloutPercentage = 50.0
                            initializeExperiment()
                        }
                        
                        Button("Limited Rollout (10%)") {
                            rolloutPercentage = 10.0
                            initializeExperiment()
                        }
                        
                        Button("Disable Rollout (0%)") {
                            rolloutPercentage = 0.0
                            initializeExperiment()
                        }
                        
                        Divider()
                        
                        Button("Reset All Flags") {
                            useModernTransactionList = false
                            rolloutPercentage = 0.0
                            userInModernExperiment = false
                        }
                    } label: {
                        Image(systemName: "flag.2.crossed")
                    }
                    .help("Feature Flag Admin")
                    #endif
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
            
            // Track categorization analytics
            Analytics.shared.trackTransactionCategorized(
                isAutomatic: false,
                category: category.name
            )
            
            if createRuleFromBulk {
                // Create rule for this merchant
                let merchantName = extractMerchantName(from: transaction.description)
                createMerchantRule(merchantName: merchantName, category: category, transaction: transaction)
                
                // Track rule creation
                Analytics.shared.trackRuleCreated(
                    ruleType: "merchant_pattern",
                    source: "bulk_categorization"
                )
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
                
                // Track automatic categorization
                Analytics.shared.trackTransactionCategorized(
                    isAutomatic: true,
                    category: category.name,
                    confidence: suggestion.confidence
                )
                
                // Also create a rule for future imports
                createMerchantRule(merchantName: merchantName, category: category, transaction: transaction)
            } else {
                // Fall back to rule-based categorization
                let (category, confidence) = categoryService.suggestCategory(for: transaction)
                if let category = category, confidence > 0.8 {
                    AppLogger.shared.info("Auto-categorizing '\(transaction.description)' → \(category.name) (rule-based)")
                    dataManager.updateTransactionCategory(transactionId: transaction.id, newCategory: category)
                    categorizedCount += 1
                    
                    // Track rule-based categorization
                    Analytics.shared.trackTransactionCategorized(
                        isAutomatic: true,
                        category: category.name,
                        confidence: confidence
                    )
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
        
        // Track rule creation
        Analytics.shared.trackRuleCreated(
            ruleType: "merchant_pattern",
            source: "auto_categorization"
        )
    }
}

// MARK: - Analytics Extensions


// MARK: - Skeleton Components for Loading States

struct SkeletonTransactionRow: View {
    @State private var animateGradient = false
    
    var body: some View {
        HStack(spacing: 24) {
            // Date skeleton
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(skeletonGradient)
                    .frame(width: 60, height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(skeletonGradient)
                    .frame(width: 40, height: 12)
            }
            .frame(width: 100, alignment: .leading)
            
            // Icon skeleton
            RoundedRectangle(cornerRadius: 10)
                .fill(skeletonGradient)
                .frame(width: 44, height: 44)
            
            // Details skeleton
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(skeletonGradient)
                    .frame(width: 200, height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(skeletonGradient)
                    .frame(width: 120, height: 12)
            }
            
            Spacer()
            
            // Category skeleton
            RoundedRectangle(cornerRadius: 8)
                .fill(skeletonGradient)
                .frame(width: 120, height: 32)
            
            // Amount skeleton
            VStack(alignment: .trailing, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(skeletonGradient)
                    .frame(width: 80, height: 16)
            }
            .frame(width: 140, alignment: .trailing)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 20)
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
    
    private var skeletonGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.gray.opacity(0.3),
                Color.gray.opacity(0.1),
                Color.gray.opacity(0.3)
            ],
            startPoint: animateGradient ? .leading : .trailing,
            endPoint: animateGradient ? .trailing : .leading
        )
    }
}

#Preview {
    NavigationView {
        TransactionListView { _ in }
            .environmentObject(FinancialDataManager())
    }
}
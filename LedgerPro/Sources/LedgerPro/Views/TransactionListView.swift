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
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with search and filters
            VStack(spacing: 12) {
                HStack {
                    TextField("Search transactions...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                    
                    Button(action: { showingFilters.toggle() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title2)
                    }
                    .help("Filters")
                }
                
                if showingFilters {
                    HStack {
                        // Enhanced Category Filter Button
                        Button(action: { showingCategoryFilter = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: selectedCategoryObject?.icon ?? "folder.fill")
                                    .font(.caption)
                                    .foregroundColor(selectedCategoryObject != nil ? Color(hex: selectedCategoryObject!.color) ?? .blue : .secondary)
                                
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
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
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
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Header Row
                        TransactionHeaderView()
                        
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
                                    }
                                )
                                .onTapGesture {
                                    selectedTransaction = transaction
                                    showingDetail = true
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Transactions (\(filteredTransactions.count))")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack {
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
        .animation(.easeInOut(duration: 0.2), value: showingCategoryFilter)
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
}

// MARK: - Header View
struct TransactionHeaderView: View {
    var body: some View {
        HStack(spacing: 24) {
            Text("Date")
                .frame(width: 100, alignment: .leading)
            
            Text("Merchant")
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Category")
                .frame(width: 180, alignment: .leading)
            
            Text("Payment Method")
                .frame(width: 150, alignment: .leading)
            
            Text("Amount")
                .frame(width: 140, alignment: .trailing)
        }
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundColor(.secondary)
        .textCase(.uppercase)
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Date Separator View
struct DateSeparatorView: View {
    let date: String
    let transactionCount: Int
    let dailyTotal: Double
    
    var body: some View {
        HStack {
            HStack(spacing: 16) {
                Text(formattedDate)
                    .fontWeight(.semibold)
                
                Text("\(transactionCount) transactions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(formattedTotal)
                .fontWeight(.semibold)
                .foregroundColor(dailyTotal >= 0 ? .green : .primary)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .background(Color(NSColor.unemphasizedSelectedContentBackgroundColor))
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: date) else { return date }
        
        if Calendar.current.isDateInToday(date) {
            return "Today - " + DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday - " + DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
        } else {
            return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
        }
    }
    
    private var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        let prefix = dailyTotal >= 0 ? "+" : ""
        return prefix + (formatter.string(from: NSNumber(value: dailyTotal)) ?? "$0.00")
    }
}

// MARK: - Distributed Transaction Row
struct DistributedTransactionRowView: View {
    let transaction: Transaction
    @EnvironmentObject private var dataManager: FinancialDataManager
    let onTransactionSelect: (Transaction) -> Void
    
    var body: some View {
        HStack(spacing: 24) {
            // Date Column
            VStack(alignment: .leading, spacing: 2) {
                Text(dayMonth)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                
                Text(dayOfWeek)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
            .frame(width: 100, alignment: .leading)
            
            // Merchant Column
            HStack(spacing: 16) {
                // Icon
                Image(systemName: categoryIcon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(categoryColor.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // Details
                VStack(alignment: .leading, spacing: 2) {
                    Text(merchantName)
                        .font(.system(.body, design: .default))
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    // DEBUG: Print forex data to console
                    let _ = print("🔍 Transaction: \(merchantName)")
                    let _ = print("   - originalCurrency: \(transaction.originalCurrency ?? "nil")")
                    let _ = print("   - originalAmount: \(transaction.originalAmount ?? 0)")
                    let _ = print("   - exchangeRate: \(transaction.exchangeRate ?? 0)")
                    let _ = print("   - hasForex: \(transaction.hasForex ?? false)")
                    
                    // Simplified conditional check for forex data
                    if let originalCurrency = transaction.originalCurrency,
                       !originalCurrency.isEmpty,
                       let originalAmount = transaction.originalAmount,
                       originalAmount > 0 {
                        
                        let _ = print("✅ SHOWING FOREX DATA for \(merchantName)")
                        
                        // Build display string
                        let forexText = buildForexText(currency: originalCurrency, amount: originalAmount, rate: transaction.exchangeRate)
                        
                        Text(forexText)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else {
                        let _ = print("❌ NO FOREX DATA for \(merchantName)")
                        // Show merchant location or generic subtitle when no forex data
                        Text(merchantLocation.isEmpty ? "Transaction Details" : merchantLocation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Category Column
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: categoryBadgeIcon)
                        .font(.caption)
                    
                    Text(transaction.category)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                }
                
                // Auto-categorization indicator
                // Enhanced auto-categorization indicator
                AutoCategoryIndicator(transaction: transaction)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(categoryColor.opacity(0.15))
            .foregroundColor(categoryColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(width: 180, alignment: .leading)
            .contextMenu {
                Button("Change Category") {
                    onTransactionSelect(transaction)
                }
                
                Button("Quick Categories") {
                    // Quick category options could go here
                }
                .disabled(true) // For future implementation
            }
            
            // Payment Method Column
            HStack(spacing: 8) {
                Image(systemName: paymentMethodIcon)
                    .font(.caption)
                    .opacity(0.6)
                
                Text(paymentMethod)
                    .font(.body)
            }
            .foregroundColor(.secondary)
            .frame(width: 150, alignment: .leading)
            
            // Amount Column
            Text(formattedAmount)
                .font(.system(.body, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(amountColor)
                .frame(width: 140, alignment: .trailing)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 20)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            Rectangle()
                .fill(Color(NSColor.separatorColor))
                .frame(height: 1),
            alignment: .bottom
        )
        .contentShape(Rectangle())
        .autoCategorizedStyle(transaction)
    }
    
    // MARK: - Computed Properties
    private var dayMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: transaction.formattedDate)
    }
    
    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: transaction.formattedDate)
    }
    
    private var merchantName: String {
        // Simplify long merchant names
        let desc = transaction.description
        if desc.contains("Capital One") {
            return "Capital One Mobile Payment"
        } else if desc.contains("UBER") {
            return "Uber Eats"
        } else if desc.contains("WAL-MART") || desc.contains("WALMART") {
            return "Walmart"
        } else if desc.contains("CHEVRON") {
            return "Chevron"
        } else if desc.contains("NETFLIX") {
            return "Netflix.com"
        } else if desc.contains("FARM") {
            return "Farm Roma Hipodromo"
        }
        return desc.components(separatedBy: " ").prefix(3).joined(separator: " ")
    }
    
    private var merchantLocation: String {
        let desc = transaction.description
        // Extract location info if available
        if desc.contains("Ciudad de Mexico") {
            return "Ciudad de Mexico"
        } else if desc.contains("San Diego CA") {
            return "San Diego CA"
        } else if desc.contains("Los Gatos CA") {
            return "Los Gatos CA"
        } else if desc.contains("Tijuana BCN") {
            return "Tijuana BCN"
        } else if desc.contains("AuthDate") {
            return "AuthDate " + (desc.components(separatedBy: "AuthDate ").last ?? "")
        }
        return "Transaction Details"
    }
    
    private var paymentMethod: String {
        // Get account type from data manager
        let accountType = dataManager.getAccountType(for: transaction)
        
        // For credit card statements
        if accountType == .credit {
            // Payments TO the credit card
            if transaction.isPaymentOrTransfer && transaction.amount > 0 {
                return "Bank Transfer"
            }
            // All purchases on credit card
            return "Credit Card"
        }
        
        // For checking/savings accounts
        if accountType == .checking || accountType == .savings {
            // Transfers between accounts
            if transaction.isPaymentOrTransfer {
                return "Bank Transfer"
            }
            // Regular purchases from checking
            return "Debit Card"
        }
        
        // Fallback logic if account type unknown
        if transaction.isPaymentOrTransfer {
            return "Bank Transfer"
        } else if transaction.amount < 0 {
            return "Credit Card"
        } else {
            return "Bank Deposit"
        }
    }
    
    private var paymentMethodIcon: String {
        switch paymentMethod {
        case "Bank Transfer": return "arrow.left.arrow.right"
        case "Credit Card": return "creditcard"
        case "Debit Card": return "banknote"
        case "Bank Deposit": return "plus.circle"
        default: return "creditcard"
        }
    }
    
    private var categoryIcon: String {
        switch transaction.category {
        case "Groceries": return "cart.fill"
        case "Food & Dining": return "fork.knife"
        case "Transportation": return "fuelpump.fill"
        case "Shopping": return "bag.fill"
        case "Entertainment": return "tv.fill"
        case "Bills & Utilities": return "bolt.fill"
        case "Healthcare": return "cross.fill"
        case "Travel": return "airplane"
        case "Income", "Deposits": return "plus.circle.fill"
        case "Subscription": return "tv.fill"
        case "Transfer", "Payment": return "creditcard.fill"
        default: return "circle.fill"
        }
    }
    
    private var categoryBadgeIcon: String {
        switch transaction.category {
        case "Groceries": return "leaf.fill"
        case "Food & Dining": return "fork.knife"
        case "Transportation": return "car.fill"
        case "Shopping": return "bag.fill"
        case "Entertainment": return "tv.fill"
        case "Bills & Utilities": return "bolt.fill"
        case "Healthcare": return "cross.fill"
        case "Travel": return "airplane"
        case "Income", "Deposits": return "plus.circle.fill"
        case "Subscription": return "arrow.clockwise"
        case "Transfer", "Payment": return "arrow.left.arrow.right"
        default: return "circle.fill"
        }
    }
    
    private var categoryColor: Color {
        // Handle Transfer/Payment as gray
        if transaction.description.lowercased().contains("capital one") {
            return .gray
        }
        
        switch transaction.category {
        case "Groceries": return .green
        case "Food & Dining": return .orange
        case "Transportation": return .blue
        case "Shopping": return .purple
        case "Entertainment": return .pink
        case "Bills & Utilities": return .red
        case "Healthcare": return .mint
        case "Travel": return .teal
        case "Income", "Deposits": return .green
        case "Subscription": return .indigo
        case "Transfer", "Payment": return .gray
        default: return .gray
        }
    }
    
    private var amountColor: Color {
        // Special handling for Capital One payment (Transfer)
        if transaction.description.lowercased().contains("capital one") {
            return .secondary
        }
        
        if transaction.isIncome {
            return .green
        } else {
            return .primary
        }
    }
    
    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        
        let usdAmount: String
        
        // Special handling for Capital One payment (show as transfer)
        if transaction.description.lowercased().contains("capital one") {
            usdAmount = formatter.string(from: NSNumber(value: abs(transaction.amount))) ?? "$0.00"
        } else if transaction.isExpense {
            usdAmount = "-" + (formatter.string(from: NSNumber(value: abs(transaction.amount))) ?? "$0.00")
        } else {
            usdAmount = "+" + (formatter.string(from: NSNumber(value: transaction.amount)) ?? "$0.00")
        }
        
        // Add foreign currency display if available
        if let originalAmount = transaction.originalAmount,
           let originalCurrency = transaction.originalCurrency {
            
            let foreignAmount = formatForeignCurrency(originalAmount, currency: originalCurrency)
            return "\(usdAmount)\n(\(foreignAmount))"
        }
        
        return usdAmount
    }
    
    private func formatForeignCurrency(_ amount: Double, currency: String) -> String {
        // Handle specific currency formatting
        switch currency {
        case "MXN":
            return "MXN $\(String(format: "%.2f", amount))"
        case "EUR":
            return "€\(String(format: "%.2f", amount))"
        case "GBP":
            return "£\(String(format: "%.2f", amount))"
        case "JPY":
            return "¥\(String(format: "%.0f", amount))" // No decimals for JPY
        case "CAD":
            return "CAD $\(String(format: "%.2f", amount))"
        default:
            return "\(currency) \(String(format: "%.2f", amount))"
        }
    }
    
    private func formatCurrency(_ amount: Double, currency: String) -> String {
        // Handle specific currency formatting for merchant display
        switch currency {
        case "MXN", "USD", "CAD", "AUD":
            return "$\(String(format: "%.2f", amount))"
        case "EUR":
            return "€\(String(format: "%.2f", amount))"
        case "GBP":
            return "£\(String(format: "%.2f", amount))"
        case "JPY", "CNY":
            return "¥\(String(format: "%.0f", amount))" // No decimals for JPY
        default:
            return "\(String(format: "%.2f", amount))"
        }
    }
    
    private func formatExchangeRate(_ rate: Double) -> String {
        // Format to 4 decimal places like in the statement
        return String(format: "%.4f", rate)
    }
    
    private func buildForexText(currency: String, amount: Double, rate: Double?) -> String {
        var forexText = "\(currency) \(formatCurrency(amount, currency: currency))"
        
        // Add exchange rate if available
        if let rate = rate, rate > 0 {
            forexText += " • Rate: \(formatExchangeRate(rate))"
        }
        
        return forexText
    }
}

// MARK: - Performance Optimization Data
struct TransactionDisplayData {
    let merchantName: String
    let detailedAmount: String
    let formattedDate: String
    let transactionType: String
    let categoryIcon: String
    let categoryColor: Color
    let amountColor: Color
    let confidenceText: String?
    let shortJobId: String?
    let forexInfo: ForexDisplayInfo?
    
    init(transaction: Transaction) {
        // Pre-compute all display values once
        self.merchantName = transaction.displayMerchantName
        self.detailedAmount = transaction.displayDetailAmount
        self.formattedDate = transaction.displayDate
        
        self.transactionType = {
            if transaction.description.lowercased().contains("capital one") {
                return "Transfer"
            }
            return transaction.isExpense ? "Expense" : "Income"
        }()
        
        self.categoryIcon = {
            switch transaction.category {
            case "Groceries": return "cart.fill"
            case "Food & Dining": return "fork.knife"
            case "Transportation": return "fuelpump.fill"
            case "Shopping": return "bag.fill"
            case "Entertainment": return "tv.fill"
            case "Bills & Utilities": return "bolt.fill"
            case "Healthcare": return "cross.fill"
            case "Travel": return "airplane"
            case "Income", "Deposits": return "plus.circle.fill"
            case "Subscription": return "tv.fill"
            case "Transfer", "Payment": return "creditcard.fill"
            default: return "circle.fill"
            }
        }()
        
        self.categoryColor = {
            if transaction.description.lowercased().contains("capital one") {
                return .gray
            }
            
            switch transaction.category {
            case "Groceries": return .green
            case "Food & Dining": return .orange
            case "Transportation": return .blue
            case "Shopping": return .purple
            case "Entertainment": return .pink
            case "Bills & Utilities": return .red
            case "Healthcare": return .mint
            case "Travel": return .teal
            case "Income", "Deposits": return .green
            case "Subscription": return .indigo
            case "Transfer", "Payment": return .gray
            default: return .gray
            }
        }()
        
        self.amountColor = {
            if transaction.description.lowercased().contains("capital one") {
                return .secondary
            }
            
            if transaction.isIncome {
                return .green
            } else {
                return .primary
            }
        }()
        
        self.confidenceText = transaction.confidence.map { "\(Int($0 * 100))%" }
        self.shortJobId = transaction.jobId.map { String($0.prefix(8)) + "..." }
        
        // Pre-compute forex information
        if let originalAmount = transaction.originalAmount,
           let originalCurrency = transaction.originalCurrency,
           let exchangeRate = transaction.exchangeRate {
            self.forexInfo = ForexDisplayInfo(
                originalAmount: Self.formatForeignCurrency(originalAmount, currency: originalCurrency),
                exchangeRate: String(format: "%.6f", exchangeRate),
                conversion: "\(originalCurrency) → USD"
            )
        } else {
            self.forexInfo = nil
        }
    }
    
    private static func formatForeignCurrency(_ amount: Double, currency: String) -> String {
        switch currency {
        case "MXN":
            return "MXN $\(String(format: "%.2f", amount))"
        case "EUR":
            return "€\(String(format: "%.2f", amount))"
        case "GBP":
            return "£\(String(format: "%.2f", amount))"
        case "JPY":
            return "¥\(String(format: "%.0f", amount))"
        case "CAD":
            return "CAD $\(String(format: "%.2f", amount))"
        default:
            return "\(currency) \(String(format: "%.2f", amount))"
        }
    }
}

struct ForexDisplayInfo {
    let originalAmount: String
    let exchangeRate: String
    let conversion: String
}

// MARK: - Optimized Transaction Detail View
struct TransactionDetailView: View {
    let transaction: Transaction
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: FinancialDataManager
    
    // Category editing state
    @State private var showingCategoryPicker = false
    @State private var selectedCategory: Category?
    @EnvironmentObject private var categoryService: CategoryService
    
    // Pre-computed values to avoid repeated calculations
    private let displayData: TransactionDisplayData
    
    init(transaction: Transaction) {
        self.transaction = transaction
        self.displayData = TransactionDisplayData(transaction: transaction)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Fixed Header
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Transaction Details")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button("✕") {
                        dismiss()
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.secondary)
                    .keyboardShortcut(.escape, modifiers: [])
                }
                
                Divider()
                
                // Transaction Header Info (always visible)
                HStack {
                    Image(systemName: displayData.categoryIcon)
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(displayData.categoryColor)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(displayData.merchantName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(2)
                        
                        Text(displayData.detailedAmount)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(displayData.amountColor)
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            .background(Color(NSColor.windowBackgroundColor))
            
            // Scrollable Content
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 16) {
                    // Transaction Details
                    VStack(alignment: .leading, spacing: 12) {
                        TransactionDetailRow(label: "Date", value: displayData.formattedDate)
                        
                        // Interactive Category Row
                        InteractiveCategoryRow(
                            transaction: transaction,
                            onEditCategory: { showingCategoryPicker = true }
                        )
                        
                        TransactionDetailRow(label: "Type", value: displayData.transactionType)
                        TransactionDetailRow(label: "Payment Method", value: paymentMethod)
                        
                        // Foreign Currency Information
                        if let forexInfo = displayData.forexInfo {
                            Divider()
                                .padding(.vertical, 8)
                            
                            Text("Foreign Currency Transaction")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                                .textCase(.uppercase)
                                .padding(.bottom, 4)
                            
                            TransactionDetailRow(label: "Original Amount", value: forexInfo.originalAmount)
                            TransactionDetailRow(label: "Exchange Rate", value: forexInfo.exchangeRate)
                            TransactionDetailRow(label: "USD Amount", value: transaction.formattedAmount)
                            TransactionDetailRow(label: "Conversion", value: forexInfo.conversion)
                            
                            Divider()
                                .padding(.vertical, 8)
                        }
                        
                        if let confidence = displayData.confidenceText {
                            TransactionDetailRow(label: "Confidence", value: confidence)
                        }
                        
                        if let jobId = displayData.shortJobId {
                            TransactionDetailRow(label: "Job ID", value: jobId)
                        }
                    }
                    
                    // Description Section (can be long)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        Text(transaction.description)
                            .font(.body)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
                    }
                    
                    // Bottom padding for scroll content
                    Color.clear
                        .frame(height: 1)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 520)
        .frame(minHeight: 400, maxHeight: 600)
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 8)
        .overlay(
            Group {
                if showingCategoryPicker {
                    CategoryPickerPopup(
                        selectedCategory: $selectedCategory,
                        isPresented: $showingCategoryPicker,
                        transaction: transaction
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(1000)
                }
            }
        )
        .animation(.easeInOut(duration: 0.2), value: showingCategoryPicker)
        .onAppear {
            // Load categories if needed
            if categoryService.categories.isEmpty {
                Task {
                    await categoryService.loadCategories()
                }
            }
        }
        .onChange(of: selectedCategory) { category in
            if let category = category {
                // Update the transaction category
                dataManager.updateTransactionCategory(
                    transactionId: transaction.id,
                    newCategory: category
                )
                showingCategoryPicker = false
            }
        }
    }
    
    // Only keep payment method as computed since it needs dataManager
    private var paymentMethod: String {
        // Get account type from data manager
        let accountType = dataManager.getAccountType(for: transaction)
        
        // For credit card statements
        if accountType == .credit {
            // Payments TO the credit card
            if transaction.isPaymentOrTransfer && transaction.amount > 0 {
                return "Bank Transfer"
            }
            // All purchases on credit card
            return "Credit Card"
        }
        
        // For checking/savings accounts
        if accountType == .checking || accountType == .savings {
            // Transfers between accounts
            if transaction.isPaymentOrTransfer {
                return "Bank Transfer"
            }
            // Regular purchases from checking
            return "Debit Card"
        }
        
        // Fallback logic if account type unknown
        if transaction.isPaymentOrTransfer {
            return "Bank Transfer"
        } else if transaction.amount < 0 {
            return "Credit Card"
        } else {
            return "Bank Deposit"
        }
    }
}

struct TransactionDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
                .fixedSize()
            
            Text(value)
                .font(.body)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Compatibility Bridge for Other Views
struct TransactionRowView: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            Image(systemName: categoryIcon)
                .font(.title3)
                .foregroundColor(categoryColor)
                .frame(width: 24, height: 24)
            
            // Transaction Details
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    Text(transaction.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(categoryColor.opacity(0.2))
                        .foregroundColor(categoryColor)
                        .cornerRadius(4)
                    
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Enhanced auto-categorization indicator
                    AutoCategoryIndicator(transaction: transaction)
                }
            }
            
            Spacer()
            
            // Amount
            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.displayAmount)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(transaction.isExpense ? .red : .green)
                
                Text(transaction.isExpense ? "Expense" : "Income")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
    
    private var categoryIcon: String {
        switch transaction.category {
        case "Groceries": return "cart.fill"
        case "Food & Dining": return "fork.knife"
        case "Transportation": return "car.fill"
        case "Shopping": return "bag.fill"
        case "Entertainment": return "tv.fill"
        case "Bills & Utilities": return "bolt.fill"
        case "Healthcare": return "cross.fill"
        case "Travel": return "airplane"
        case "Income", "Deposits": return "plus.circle.fill"
        default: return "circle.fill"
        }
    }
    
    private var categoryColor: Color {
        switch transaction.category {
        case "Groceries": return .green
        case "Food & Dining": return .orange
        case "Transportation": return .blue
        case "Shopping": return .purple
        case "Entertainment": return .pink
        case "Bills & Utilities": return .red
        case "Healthcare": return .mint
        case "Travel": return .teal
        case "Income", "Deposits": return .green
        default: return .gray
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: transaction.formattedDate)
    }
}

// MARK: - Interactive Category Row

struct InteractiveCategoryRow: View {
    let transaction: Transaction
    let onEditCategory: () -> Void
    
    var body: some View {
        HStack {
            Text("Category")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .frame(width: 120, alignment: .leading)
            
            Spacer()
            
            Button(action: onEditCategory) {
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: categoryIcon)
                            .font(.caption)
                        
                        Text(transaction.category)
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(categoryColor.opacity(0.15))
                    .foregroundColor(categoryColor)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            .help("Click to change category")
        }
    }
    
    private var categoryIcon: String {
        switch transaction.category {
        case "Groceries": return "cart.fill"
        case "Food & Dining": return "fork.knife"
        case "Transportation": return "car.fill"
        case "Shopping": return "bag.fill"
        case "Entertainment": return "tv.fill"
        case "Bills & Utilities": return "bolt.fill"
        case "Healthcare": return "cross.fill"
        case "Travel": return "airplane"
        case "Income", "Deposits": return "plus.circle.fill"
        default: return "circle.fill"
        }
    }
    
    private var categoryColor: Color {
        switch transaction.category {
        case "Groceries": return .green
        case "Food & Dining": return .orange
        case "Transportation": return .blue
        case "Shopping": return .purple
        case "Entertainment": return .pink
        case "Bills & Utilities": return .red
        case "Healthcare": return .mint
        case "Travel": return .teal
        case "Income", "Deposits": return .green
        default: return .gray
        }
    }
}

// MARK: - Category Filter Picker

struct CategoryFilterPickerPopup: View {
    @Binding var selectedCategory: Category?
    @Binding var isPresented: Bool
    
    @EnvironmentObject private var categoryService: CategoryService
    @State private var searchText = ""
    
    var body: some View {
        ZStack {
            // Background overlay - tap to dismiss
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // The actual popup
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    HStack {
                        Text("Filter by Category")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button(action: { isPresented = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .imageScale(.large)
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut(.escape)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Search bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .imageScale(.medium)
                        
                        TextField("Search categories...", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.body)
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .imageScale(.small)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
                }
                .background(Color(NSColor.windowBackgroundColor))
                
                Divider()
                
                // Category list
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        // All Categories option
                        CategoryFilterItem(
                            category: nil,
                            isSelected: selectedCategory == nil,
                            onSelect: {
                                selectedCategory = nil
                                isPresented = false
                            }
                        )
                        
                        // Root categories
                        ForEach(filteredCategories) { category in
                            CategoryFilterItem(
                                category: category,
                                isSelected: selectedCategory?.id == category.id,
                                onSelect: {
                                    selectedCategory = category
                                    isPresented = false
                                }
                            )
                        }
                    }
                    .padding(20)
                }
            }
            .frame(width: 400, height: 500)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 8)
            .onTapGesture {} // Prevent taps on popup from closing
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var filteredCategories: [Category] {
        if searchText.isEmpty {
            return categoryService.rootCategories
        } else {
            return categoryService.categories.filter { category in
                category.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

struct CategoryFilterItem: View {
    let category: Category?
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: category?.icon ?? "folder.fill")
                    .font(.title3)
                    .foregroundColor(category != nil ? Color(hex: category!.color) ?? .blue : .secondary)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category?.name ?? "All Categories")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if let category = category {
                        Text(category.isSystem ? "System Category" : "Custom Category")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Show all transactions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationView {
        TransactionListView { _ in }
            .environmentObject(FinancialDataManager())
    }
}
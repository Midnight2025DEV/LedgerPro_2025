import SwiftUI

// MARK: - Performance Optimized Display Data

/// Pre-computed display data for transactions to avoid expensive operations during rendering
struct TransactionDisplayData {
    let dayMonth: String
    let dayOfWeek: String
    let merchantName: String
    let merchantLocation: String
    let categoryIcon: String
    let categoryBadgeIcon: String
    let categoryColor: Color
    let formattedAmount: String
    let amountColor: Color
    
    // Static formatters for performance
    private static let dayMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    private static let dayOfWeekFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()
    
    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }()
    
    // Pre-computed merchant name mapping for performance
    private static let merchantNameMappings: [String: String] = [
        "Capital One": "Capital One Mobile Payment",
        "UBER": "Uber Eats",
        "WAL-MART": "Walmart",
        "WALMART": "Walmart",
        "CHEVRON": "Chevron",
        "NETFLIX": "Netflix.com",
        "FARM": "Farm Roma Hipodromo"
    ]
    
    // Pre-computed location mappings
    private static let locationMappings: [String: String] = [
        "Ciudad de Mexico": "Ciudad de Mexico",
        "San Diego CA": "San Diego CA",
        "Los Gatos CA": "Los Gatos CA",
        "Tijuana BCN": "Tijuana BCN"
    ]
    
    // Pre-computed category mappings for icons and colors
    private static let categoryIconMappings: [String: String] = [
        "Groceries": "cart.fill",
        "Food & Dining": "fork.knife",
        "Transportation": "fuelpump.fill",
        "Shopping": "bag.fill",
        "Entertainment": "tv.fill",
        "Bills & Utilities": "bolt.fill",
        "Healthcare": "cross.fill",
        "Travel": "airplane",
        "Income": "plus.circle.fill",
        "Deposits": "plus.circle.fill",
        "Subscription": "tv.fill",
        "Transfer": "creditcard.fill",
        "Payment": "creditcard.fill"
    ]
    
    private static let categoryBadgeIconMappings: [String: String] = [
        "Groceries": "leaf.fill",
        "Food & Dining": "fork.knife",
        "Transportation": "car.fill",
        "Shopping": "bag.fill",
        "Entertainment": "tv.fill",
        "Bills & Utilities": "bolt.fill",
        "Healthcare": "cross.fill",
        "Travel": "airplane",
        "Income": "plus.circle.fill",
        "Deposits": "plus.circle.fill",
        "Subscription": "arrow.clockwise",
        "Transfer": "arrow.left.arrow.right",
        "Payment": "arrow.left.arrow.right"
    ]
    
    private static let categoryColorMappings: [String: Color] = [
        "Groceries": .green,
        "Food & Dining": .orange,
        "Transportation": .blue,
        "Shopping": .purple,
        "Entertainment": .pink,
        "Bills & Utilities": .red,
        "Healthcare": .mint,
        "Travel": .teal,
        "Income": .green,
        "Deposits": .green,
        "Subscription": .indigo,
        "Transfer": .gray,
        "Payment": .gray
    ]
    
    init(transaction: Transaction) {
        // Pre-compute date formatting
        let date = transaction.formattedDate
        self.dayMonth = Self.dayMonthFormatter.string(from: date)
        self.dayOfWeek = Self.dayOfWeekFormatter.string(from: date)
        
        // Pre-compute merchant name
        let description = transaction.description
        var computedMerchantName = description
        
        // Check merchant mappings efficiently
        for (key, value) in Self.merchantNameMappings {
            if description.contains(key) {
                computedMerchantName = value
                break
            }
        }
        
        // If no mapping found, use first 3 words
        if computedMerchantName == description {
            computedMerchantName = description.components(separatedBy: " ").prefix(3).joined(separator: " ")
        }
        self.merchantName = computedMerchantName
        
        // Pre-compute merchant location
        var computedLocation = "Transaction Details"
        for (key, value) in Self.locationMappings {
            if description.contains(key) {
                computedLocation = value
                break
            }
        }
        if description.contains("AuthDate") {
            computedLocation = "AuthDate " + (description.components(separatedBy: "AuthDate ").last ?? "")
        }
        self.merchantLocation = computedLocation
        
        // Pre-compute category data
        let category = transaction.category
        self.categoryIcon = Self.categoryIconMappings[category] ?? "circle.fill"
        self.categoryBadgeIcon = Self.categoryBadgeIconMappings[category] ?? "circle.fill"
        
        // Handle special case for Capital One
        if description.lowercased().contains("capital one") {
            self.categoryColor = .gray
        } else {
            self.categoryColor = Self.categoryColorMappings[category] ?? .gray
        }
        
        // Pre-compute complex amount formatting with all special cases
        let usdAmount: String
        
        // Special handling for Capital One payment (show as transfer)
        if description.lowercased().contains("capital one") {
            usdAmount = Self.currencyFormatter.string(from: NSNumber(value: abs(transaction.amount))) ?? "$0.00"
            self.amountColor = .secondary
        } else if transaction.isExpense {
            usdAmount = "-" + (Self.currencyFormatter.string(from: NSNumber(value: abs(transaction.amount))) ?? "$0.00")
            self.amountColor = .primary
        } else {
            usdAmount = "+" + (Self.currencyFormatter.string(from: NSNumber(value: transaction.amount)) ?? "$0.00")
            self.amountColor = .green
        }
        
        // Add foreign currency display if available
        if let originalAmount = transaction.originalAmount,
           let originalCurrency = transaction.originalCurrency {
            let foreignAmount = Self.formatForeignCurrency(originalAmount, currency: originalCurrency)
            self.formattedAmount = "\(usdAmount)\n(\(foreignAmount))"
        } else {
            self.formattedAmount = usdAmount
        }
    }
    
    // Static method for foreign currency formatting
    private static func formatForeignCurrency(_ amount: Double, currency: String) -> String {
        // Handle specific currency formatting
        switch currency {
        case "MXN":
            return String(format: "%.2f MXN", amount)
        case "EUR":
            return String(format: "%.2f €", amount)
        case "GBP":
            return String(format: "%.2f £", amount)
        case "JPY":
            return String(format: "%.0f ¥", amount)
        case "CAD":
            return String(format: "%.2f CAD", amount)
        default:
            return String(format: "%.2f %@", amount, currency)
        }
    }
}

// MARK: - Distributed Transaction Row
struct DistributedTransactionRowView: View {
    let transaction: Transaction
    @EnvironmentObject private var dataManager: FinancialDataManager
    let onTransactionSelect: (Transaction) -> Void
    @Binding var selectedTransactions: Set<String>
    let showCheckbox: Bool
    
    // MARK: - Cached Computed Properties for Performance
    private let displayData: TransactionDisplayData
    
    init(
        transaction: Transaction,
        onTransactionSelect: @escaping (Transaction) -> Void,
        selectedTransactions: Binding<Set<String>>,
        showCheckbox: Bool
    ) {
        self.transaction = transaction
        self.onTransactionSelect = onTransactionSelect
        self._selectedTransactions = selectedTransactions
        self.showCheckbox = showCheckbox
        
        // Pre-compute expensive display data once
        self.displayData = TransactionDisplayData(transaction: transaction)
    }
    
    private var isSelected: Bool {
        selectedTransactions.contains(transaction.id)
    }
    
    var body: some View {
        HStack(spacing: 24) {
            // Bulk Selection Checkbox
            if showCheckbox {
                Button(action: {
                    if isSelected {
                        selectedTransactions.remove(transaction.id)
                    } else {
                        selectedTransactions.insert(transaction.id)
                    }
                }) {
                    Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                        .font(.system(size: 18))
                        .foregroundColor(isSelected ? .blue : .secondary)
                }
                .buttonStyle(.plain)
                .frame(width: 24)
            }
            
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
                    
                    // DEBUG: Log forex data outside view builder
                    let _ = {
                        AppLogger.shared.debug("Transaction: \(merchantName)")
                        AppLogger.shared.debug("   - originalCurrency: \(transaction.originalCurrency ?? "nil")")
                        AppLogger.shared.debug("   - originalAmount: \(transaction.originalAmount ?? 0)")
                        AppLogger.shared.debug("   - exchangeRate: \(transaction.exchangeRate ?? 0)")
                        AppLogger.shared.debug("   - hasForex: \(transaction.hasForex)")
                    }()
                    
                    // Simplified conditional check for forex data
                    if let originalCurrency = transaction.originalCurrency,
                       !originalCurrency.isEmpty,
                       let originalAmount = transaction.originalAmount,
                       originalAmount > 0 {
                        
                        let _ = AppLogger.shared.debug("SHOWING FOREX DATA for \(merchantName)")
                        
                        // Build display string
                        let forexText = buildForexText(currency: originalCurrency, amount: originalAmount, rate: transaction.exchangeRate)
                        
                        Text(forexText)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else {
                        let _ = AppLogger.shared.debug("NO FOREX DATA for \(merchantName)")
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
        .background(isSelected ? Color.blue.opacity(0.1) : Color(NSColor.controlBackgroundColor))
        .overlay(
            Rectangle()
                .fill(Color(NSColor.separatorColor))
                .frame(height: 1),
            alignment: .bottom
        )
        .overlay(
            // Selection border
            Group {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue, lineWidth: 2)
                        .padding(4)
                }
            }
        )
        .contentShape(Rectangle())
        .autoCategorizedStyle(transaction)
    }
    
    // MARK: - Optimized Computed Properties
    private var dayMonth: String {
        displayData.dayMonth
    }
    
    private var dayOfWeek: String {
        displayData.dayOfWeek
    }
    
    private var merchantName: String {
        displayData.merchantName
    }
    
    private var merchantLocation: String {
        displayData.merchantLocation
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
        displayData.categoryIcon
    }
    
    private var categoryBadgeIcon: String {
        displayData.categoryBadgeIcon
    }
    
    private var categoryColor: Color {
        displayData.categoryColor
    }
    
    private var amountColor: Color {
        displayData.amountColor
    }
    
    private var formattedAmount: String {
        displayData.formattedAmount
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

// MARK: - Simple Transaction Row View
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
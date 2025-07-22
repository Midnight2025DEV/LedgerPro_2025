import SwiftUI

// MARK: - Distributed Transaction Row
struct DistributedTransactionRowView: View {
    let transaction: Transaction
    @EnvironmentObject private var dataManager: FinancialDataManager
    let onTransactionSelect: (Transaction) -> Void
    @Binding var selectedTransactions: Set<String>
    let showCheckbox: Bool
    
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
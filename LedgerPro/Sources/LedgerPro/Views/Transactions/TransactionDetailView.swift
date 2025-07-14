import SwiftUI

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

// MARK: - Transaction Detail View
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
        .onChange(of: selectedCategory) { _, category in
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

// MARK: - Transaction Detail Row
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
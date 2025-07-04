import Foundation
import SwiftUI

@MainActor
class DashboardDataService: ObservableObject {
    @Published var monthlyTotals: [String: Decimal] = [:] // Month key -> total
    @Published var currentMonthTotal: Decimal = 0
    @Published var previousMonthTotal: Decimal = 0
    @Published var percentageChange: Double = 0
    @Published var categoryBreakdown: [CategoryBreakdown] = []
    @Published var topMerchants: [MerchantStat] = []
    @Published var recentTransactions: [Transaction] = []
    @Published var isLoading = false
    
    private let dataManager = FinancialDataManager()
    private let categoryService = CategoryService.shared
    
    struct CategoryBreakdown: Identifiable {
        let id = UUID()
        let category: Category
        let amount: Decimal
        let percentage: Double
        let transactionCount: Int
    }
    
    struct MerchantStat: Identifiable {
        let id = UUID()
        let merchantName: String
        let totalAmount: Decimal
        let transactionCount: Int
        let lastTransaction: Date
    }
    
    init() {
        loadDashboardData()
    }
    
    func loadDashboardData() {
        isLoading = true
        
        // Calculate current and previous month totals
        calculateMonthlyTotals()
        
        // Generate category breakdown
        generateCategoryBreakdown()
        
        // Get top merchants
        calculateTopMerchants()
        
        // Load recent transactions
        loadRecentTransactions()
        
        isLoading = false
    }
    
    private func calculateMonthlyTotals() {
        let calendar = Calendar.current
        let now = Date()
        
        // Get current month start and end
        let currentMonthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let currentMonthEnd = calendar.dateInterval(of: .month, for: now)?.end ?? now
        
        // Get previous month start and end
        let previousMonthDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        let previousMonthStart = calendar.dateInterval(of: .month, for: previousMonthDate)?.start ?? now
        let previousMonthEnd = calendar.dateInterval(of: .month, for: previousMonthDate)?.end ?? now
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Filter transactions for current month
        let currentMonthTransactions = dataManager.transactions.filter { transaction in
            guard let transactionDate = dateFormatter.date(from: transaction.date) else { return false }
            return transactionDate >= currentMonthStart && transactionDate < currentMonthEnd
        }
        
        // Filter transactions for previous month
        let previousMonthTransactions = dataManager.transactions.filter { transaction in
            guard let transactionDate = dateFormatter.date(from: transaction.date) else { return false }
            return transactionDate >= previousMonthStart && transactionDate < previousMonthEnd
        }
        
        // Calculate totals (expenses as positive numbers)
        currentMonthTotal = Decimal(currentMonthTransactions.filter { $0.amount < 0 }.reduce(0) { $0 + abs($1.amount) })
        previousMonthTotal = Decimal(previousMonthTransactions.filter { $0.amount < 0 }.reduce(0) { $0 + abs($1.amount) })
        
        // Calculate percentage change
        if previousMonthTotal > 0 {
            let change = currentMonthTotal - previousMonthTotal
            percentageChange = Double(truncating: (change / previousMonthTotal * 100) as NSDecimalNumber)
        } else {
            percentageChange = currentMonthTotal > 0 ? 100.0 : 0.0
        }
        
        // Build monthly totals dictionary for trends
        let last6Months = (-5...0).compactMap { monthOffset in
            calendar.date(byAdding: .month, value: monthOffset, to: now)
        }
        
        for monthDate in last6Months {
            let monthStart = calendar.dateInterval(of: .month, for: monthDate)?.start ?? monthDate
            let monthEnd = calendar.dateInterval(of: .month, for: monthDate)?.end ?? monthDate
            
            let monthTransactions = dataManager.transactions.filter { transaction in
                guard let transactionDate = dateFormatter.date(from: transaction.date) else { return false }
                return transactionDate >= monthStart && transactionDate < monthEnd
            }
            
            let monthTotal = Decimal(monthTransactions.filter { $0.amount < 0 }.reduce(0) { $0 + abs($1.amount) })
            
            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "yyyy-MM"
            let monthKey = monthFormatter.string(from: monthDate)
            
            monthlyTotals[monthKey] = monthTotal
        }
    }
    
    private func generateCategoryBreakdown() {
        let expenses = dataManager.transactions.filter { $0.amount < 0 }
        let totalExpenses = expenses.reduce(0) { $0 + abs($1.amount) }
        
        let grouped = Dictionary(grouping: expenses) { $0.category }
        
        categoryBreakdown = grouped.compactMap { categoryName, transactions in
            // Find matching category from CategoryService
            guard let category = categoryService.categories.first(where: { $0.name == categoryName }) else {
                return nil
            }
            
            let amount = Decimal(transactions.reduce(0) { $0 + abs($1.amount) })
            let percentage = totalExpenses > 0 ? (Double(truncating: amount as NSDecimalNumber) / totalExpenses) * 100 : 0
            
            return CategoryBreakdown(
                category: category,
                amount: amount,
                percentage: percentage,
                transactionCount: transactions.count
            )
        }.sorted { $0.amount > $1.amount }
    }
    
    private func calculateTopMerchants() {
        let expenses = dataManager.transactions.filter { $0.amount < 0 }
        
        // Extract merchant names from transaction descriptions
        let merchantGroups = Dictionary(grouping: expenses) { transaction in
            extractMerchantName(from: transaction.description)
        }
        
        topMerchants = merchantGroups.map { merchantName, transactions in
            let totalAmount = Decimal(transactions.reduce(0) { $0 + abs($1.amount) })
            
            // Find the most recent transaction date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let lastTransactionDate = transactions.compactMap { transaction in
                dateFormatter.date(from: transaction.date)
            }.max() ?? Date()
            
            return MerchantStat(
                merchantName: merchantName,
                totalAmount: totalAmount,
                transactionCount: transactions.count,
                lastTransaction: lastTransactionDate
            )
        }.sorted { $0.totalAmount > $1.totalAmount }
        .prefix(10)
        .map { $0 }
    }
    
    private func loadRecentTransactions() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Sort transactions by date (most recent first) and take first 10
        let sorted = dataManager.transactions.sorted { transaction1, transaction2 in
            guard let date1 = dateFormatter.date(from: transaction1.date),
                  let date2 = dateFormatter.date(from: transaction2.date) else {
                return transaction1.date > transaction2.date
            }
            return date1 > date2
        }
        
        recentTransactions = Array(sorted.prefix(10))
    }
    
    private func extractMerchantName(from description: String) -> String {
        // Simple merchant name extraction - take first 1-2 words and clean up
        let cleaned = description.uppercased()
        let words = cleaned.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .prefix(2)
        
        let merchantName = words.joined(separator: " ")
        
        // Remove common patterns
        let cleanedName = merchantName
            .replacingOccurrences(of: #"\s+#\d+"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s+\d{4,}"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleanedName.isEmpty ? "Unknown Merchant" : cleanedName
    }
    
    // MARK: - Refresh Methods
    
    func refreshData() {
        loadDashboardData()
    }
    
    func refreshCategoryBreakdown() {
        generateCategoryBreakdown()
    }
    
    func refreshMerchantData() {
        calculateTopMerchants()
    }
}

// MARK: - Formatted Properties

extension DashboardDataService.CategoryBreakdown {
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
    
    var formattedPercentage: String {
        return String(format: "%.1f%%", percentage)
    }
}

extension DashboardDataService.MerchantStat {
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: totalAmount as NSDecimalNumber) ?? "$0.00"
    }
    
    var formattedLastTransaction: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: lastTransaction)
    }
    
    var daysSinceLastTransaction: Int {
        Calendar.current.dateComponents([.day], from: lastTransaction, to: Date()).day ?? 0
    }
}

extension DashboardDataService {
    var formattedCurrentMonthTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: currentMonthTotal as NSDecimalNumber) ?? "$0.00"
    }
    
    var formattedPreviousMonthTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: previousMonthTotal as NSDecimalNumber) ?? "$0.00"
    }
    
    var formattedPercentageChange: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.positivePrefix = "+"
        return formatter.string(from: NSNumber(value: percentageChange / 100.0)) ?? "0%"
    }
    
    var isSpendingIncreasing: Bool {
        return percentageChange > 0
    }
    
    var isSpendingDecreasing: Bool {
        return percentageChange < 0
    }
    
    var isSpendingStable: Bool {
        return abs(percentageChange) < 5.0 // Within 5% considered stable
    }
}
import Foundation
import SwiftUI

@MainActor
class BudgetManager: ObservableObject {
    @Published var budgets: [Budget] = []
    @Published var isLoading = false
    @Published var lastError: String?
    
    private let dataManager: FinancialDataManager
    private let userDefaults = UserDefaults.standard
    private let budgetKey = "saved_budgets"
    
    init(dataManager: FinancialDataManager) {
        self.dataManager = dataManager
        loadBudgets()
    }
    
    // MARK: - Budget Management
    
    func createBudget(_ budget: Budget) {
        budgets.append(budget)
        saveBudgets()
        updateAllBudgetSpending()
    }
    
    func updateBudget(_ budget: Budget) {
        if let index = budgets.firstIndex(where: { $0.id == budget.id }) {
            budgets[index] = budget
            saveBudgets()
            updateBudgetSpending(budget)
        }
    }
    
    func deleteBudget(_ budgetId: UUID) {
        budgets.removeAll { $0.id == budgetId }
        saveBudgets()
    }
    
    func toggleBudgetActive(_ budgetId: UUID) {
        if let index = budgets.firstIndex(where: { $0.id == budgetId }) {
            budgets[index].isActive.toggle()
            saveBudgets()
        }
    }
    
    // MARK: - Spending Calculations
    
    func updateAllBudgetSpending() {
        for budget in budgets {
            updateBudgetSpending(budget)
        }
    }
    
    private func updateBudgetSpending(_ budget: Budget) {
        let spent = calculateSpentAmount(for: budget)
        if let index = budgets.firstIndex(where: { $0.id == budget.id }) {
            budgets[index].updateSpentAmount(spent)
        }
    }
    
    func calculateSpentAmount(for budget: Budget) -> Double {
        let relevantTransactions = dataManager.transactions.filter { transaction in
            // Filter by category
            let categoryMatches = budget.category == "All Categories" || 
                                 transaction.category == budget.category
            
            // Filter by date range
            let dateInRange = transaction.formattedDate >= budget.startDate && 
                             transaction.formattedDate <= budget.endDate
            
            // Only count expenses (negative amounts)
            let isExpense = transaction.amount < 0
            
            return categoryMatches && dateInRange && isExpense
        }
        
        return abs(relevantTransactions.reduce(0) { $0 + $1.amount })
    }
    
    // MARK: - Budget Analytics
    
    var totalBudgetedAmount: Double {
        budgets.filter { $0.isActive }.reduce(0) { $0 + $1.amount }
    }
    
    var totalSpentAmount: Double {
        budgets.filter { $0.isActive }.reduce(0) { $0 + $1.spentAmount }
    }
    
    var totalRemainingAmount: Double {
        budgets.filter { $0.isActive }.reduce(0) { $0 + $1.remainingAmount }
    }
    
    var overBudgetCount: Int {
        budgets.filter { $0.isActive && $0.isOverBudget }.count
    }
    
    var warningBudgetCount: Int {
        budgets.filter { $0.isActive && $0.shouldAlert && !$0.isOverBudget }.count
    }
    
    func getBudgetsForCategory(_ category: String) -> [Budget] {
        return budgets.filter { $0.category == category || $0.category == "All Categories" }
    }
    
    func getCategorySpending(_ category: String, in period: DateInterval? = nil) -> Double {
        let transactions = dataManager.transactions.filter { transaction in
            let categoryMatches = transaction.category == category
            let isExpense = transaction.amount < 0
            
            if let period = period {
                let dateInRange = transaction.formattedDate >= period.start && 
                                 transaction.formattedDate <= period.end
                return categoryMatches && isExpense && dateInRange
            }
            
            return categoryMatches && isExpense
        }
        
        return abs(transactions.reduce(0) { $0 + $1.amount })
    }
    
    // MARK: - Budget Recommendations
    
    func generateBudgetRecommendations() -> [BudgetRecommendation] {
        var recommendations: [BudgetRecommendation] = []
        
        // Analyze spending patterns
        let categorySpending = analyzeCategorySpending()
        
        // Recommend budgets for high-spending categories without budgets
        for (category, amount) in categorySpending {
            if !budgets.contains(where: { $0.category == category }) && amount > 100 {
                let recommendedAmount = amount * 1.1 // 10% buffer
                recommendations.append(
                    BudgetRecommendation(
                        category: category,
                        suggestedAmount: recommendedAmount,
                        reason: "Based on your average spending in this category",
                        priority: amount > 500 ? .high : .medium
                    )
                )
            }
        }
        
        return recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    private func analyzeCategorySpending() -> [String: Double] {
        let lastMonthStart = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        let lastMonthTransactions = dataManager.transactions.filter {
            $0.formattedDate >= lastMonthStart && $0.amount < 0
        }
        
        return Dictionary(grouping: lastMonthTransactions) { $0.category }
            .mapValues { transactions in
                abs(transactions.reduce(0) { $0 + $1.amount })
            }
    }
    
    // MARK: - Persistence
    
    private func saveBudgets() {
        do {
            let data = try JSONEncoder().encode(budgets)
            userDefaults.set(data, forKey: budgetKey)
        } catch {
            lastError = "Failed to save budgets: \(error.localizedDescription)"
        }
    }
    
    private func loadBudgets() {
        guard let data = userDefaults.data(forKey: budgetKey) else { return }
        
        do {
            budgets = try JSONDecoder().decode([Budget].self, from: data)
            updateAllBudgetSpending()
        } catch {
            lastError = "Failed to load budgets: \(error.localizedDescription)"
            budgets = []
        }
    }
    
    // MARK: - Period Management
    
    func checkAndAdvancePeriods() {
        let now = Date()
        var budgetsChanged = false
        
        for index in budgets.indices {
            if budgets[index].isActive && now > budgets[index].endDate {
                budgets[index].advanceToNextPeriod()
                budgetsChanged = true
            }
        }
        
        if budgetsChanged {
            saveBudgets()
            updateAllBudgetSpending()
        }
    }
}

// MARK: - Supporting Types

struct BudgetRecommendation: Identifiable {
    let id = UUID()
    let category: String
    let suggestedAmount: Double
    let reason: String
    let priority: Priority
    
    enum Priority: Int, CaseIterable {
        case low = 1
        case medium = 2
        case high = 3
        
        var label: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"  
            case .high: return "High"
            }
        }
        
        var color: Color {
            switch self {
            case .low: return .blue
            case .medium: return .orange
            case .high: return .red
            }
        }
    }
}
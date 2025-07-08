// Create new file: Sources/LedgerPro/Services/CategoryStatsProvider.swift

import SwiftUI
import Combine

struct CategoryStats {
    let spentThisMonth: Double?
    let budgetRemaining: Double?
    let frequency: Int
    let isOverBudget: Bool
    let lastUsed: Date?
}

@MainActor
class CategoryStatsProvider: ObservableObject {
    @Published private var statsCache: [UUID: CategoryStats] = [:]
    private let dataManager = FinancialDataManager.shared
    
    func stats(for category: Category) -> CategoryStats {
        if let cached = statsCache[category.id] {
            return cached
        }
        
        let stats = calculateStats(for: category)
        statsCache[category.id] = stats
        return stats
    }
    
    private func calculateStats(for category: Category) -> CategoryStats {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        let categoryTransactions = dataManager.transactions.filter { 
            $0.category == category.name 
        }
        
        let monthTransactions = categoryTransactions.filter { 
            $0.date >= startOfMonth 
        }
        
        let spent = monthTransactions
            .filter { $0.amount < 0 }
            .reduce(0) { $0 + abs($1.amount) }
        
        let frequency = categoryTransactions.count
        let lastUsed = categoryTransactions.max(by: { $0.date < $1.date })?.date
        
        // TODO: Integrate with actual budget system
        let budgetRemaining: Double? = nil
        let isOverBudget = false
        
        return CategoryStats(
            spentThisMonth: spent > 0 ? spent : nil,
            budgetRemaining: budgetRemaining,
            frequency: frequency,
            isOverBudget: isOverBudget,
            lastUsed: lastUsed
        )
    }
}
EOF < /dev/null
import Foundation

struct Budget: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var category: String
    var amount: Double
    var period: BudgetPeriod
    var startDate: Date
    var endDate: Date
    var isActive: Bool
    var alertThreshold: Double // 0.0 to 1.0 (percentage)
    var color: String
    var description: String?
    
    // Computed properties
    var remainingAmount: Double {
        max(0, amount - spentAmount)
    }
    
    var spentAmount: Double = 0 // This will be calculated dynamically
    
    var percentageUsed: Double {
        guard amount > 0 else { return 0 }
        return min(1.0, spentAmount / amount)
    }
    
    var isOverBudget: Bool {
        spentAmount > amount
    }
    
    var shouldAlert: Bool {
        percentageUsed >= alertThreshold
    }
    
    var status: BudgetStatus {
        if !isActive {
            return .inactive
        } else if isOverBudget {
            return .overBudget
        } else if shouldAlert {
            return .warning
        } else if percentageUsed > 0.5 {
            return .onTrack
        } else {
            return .good
        }
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        category: String,
        amount: Double,
        period: BudgetPeriod = .monthly,
        startDate: Date = Date(),
        alertThreshold: Double = 0.8,
        color: String = "#007AFF",
        description: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.amount = amount
        self.period = period
        self.startDate = startDate
        self.endDate = period.calculateEndDate(from: startDate)
        self.isActive = true
        self.alertThreshold = alertThreshold
        self.color = color
        self.description = description
    }
    
    mutating func updateSpentAmount(_ spent: Double) {
        self.spentAmount = spent
    }
    
    func isCurrentPeriod(for date: Date = Date()) -> Bool {
        return date >= startDate && date <= endDate
    }
    
    mutating func advanceToNextPeriod() {
        startDate = period.nextPeriodStart(from: endDate)
        endDate = period.calculateEndDate(from: startDate)
        spentAmount = 0
    }
}

enum BudgetPeriod: String, CaseIterable, Codable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"
    case custom = "Custom"
    
    var systemImage: String {
        switch self {
        case .weekly: return "calendar.badge.clock"
        case .monthly: return "calendar"
        case .quarterly: return "calendar.badge.exclamationmark"
        case .yearly: return "calendar.circle"
        case .custom: return "calendar.badge.plus"
        }
    }
    
    func calculateEndDate(from startDate: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: startDate) ?? startDate
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: startDate) ?? startDate
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: startDate) ?? startDate
        case .custom:
            return startDate // Will be set manually
        }
    }
    
    func nextPeriodStart(from endDate: Date) -> Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: endDate) ?? endDate
    }
    
    var durationInDays: Int {
        switch self {
        case .weekly: return 7
        case .monthly: return 30
        case .quarterly: return 90
        case .yearly: return 365
        case .custom: return 30 // Default
        }
    }
}

enum BudgetStatus: String, CaseIterable {
    case good = "Good"
    case onTrack = "On Track"
    case warning = "Warning"
    case overBudget = "Over Budget"
    case inactive = "Inactive"
    
    var color: String {
        switch self {
        case .good: return "#34C759"
        case .onTrack: return "#007AFF"
        case .warning: return "#FF9500"
        case .overBudget: return "#FF3B30"
        case .inactive: return "#8E8E93"
        }
    }
    
    var systemImage: String {
        switch self {
        case .good: return "checkmark.circle.fill"
        case .onTrack: return "minus.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .overBudget: return "xmark.circle.fill"
        case .inactive: return "pause.circle.fill"
        }
    }
}

// MARK: - Budget Extensions for Testing
extension Budget {
    // Sample budgets for testing and previews
    static var sampleBudgets: [Budget] {
        [
            Budget(
                name: "Groceries",
                category: "Food",
                amount: 600,
                period: .monthly,
                alertThreshold: 0.8,
                color: "#34C759",
                description: "Monthly grocery budget"
            ),
            Budget(
                name: "Dining Out",
                category: "Food",
                amount: 300,
                period: .monthly,
                alertThreshold: 0.75,
                color: "#FF9500",
                description: "Restaurants and takeout"
            ),
            Budget(
                name: "Transportation",
                category: "Transport",
                amount: 200,
                period: .monthly,
                alertThreshold: 0.9,
                color: "#007AFF",
                description: "Gas and public transit"
            ),
            Budget(
                name: "Entertainment",
                category: "Entertainment",
                amount: 150,
                period: .monthly,
                alertThreshold: 0.7,
                color: "#AF52DE",
                description: "Movies, games, and fun"
            ),
            Budget(
                name: "Utilities",
                category: "Bills",
                amount: 400,
                period: .monthly,
                alertThreshold: 0.95,
                color: "#FF3B30",
                description: "Electricity, water, internet"
            )
        ]
    }
    
    // Progress percentage for UI display
    func progressPercentage(spending: Double) -> Double {
        guard amount > 0 else { return 0 }
        return (spending / amount) * 100
    }
    
    // Check if over budget with spending parameter
    func isOverBudget(spending: Double) -> Bool {
        return spending > amount
    }
    
    // Calculate spending for this budget from transactions
    func calculateSpending(from transactions: [Transaction]) -> Double {
        return transactions
            .filter { transaction in
                // Include transactions within the budget period
                transaction.date >= startDate && transaction.date <= endDate &&
                // Match category
                transaction.category == category &&
                // Only include expenses
                transaction.amount < 0
            }
            .reduce(0) { sum, transaction in
                sum + abs(transaction.amount)
            }
    }
}
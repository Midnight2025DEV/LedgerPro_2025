import Foundation
import SwiftUI

// MARK: - Budget Model

/// Core budget data model for LedgerPro's premium budget management
struct Budget: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var amount: Double
    var period: BudgetPeriod
    var categoryIds: [String]
    var startDate: Date
    var endDate: Date? // Auto-calculated based on period
    var notifications: BudgetNotifications
    var color: String // Hex color for visual identification
    var icon: String // SF Symbol name
    var isActive: Bool
    
    // Performance tracking
    var createdAt: Date
    var updatedAt: Date
    var lastNotificationDate: Date?
    
    // Historical data
    var previousPeriodSpent: Double?
    var averageSpending: Double?
    
    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        period: BudgetPeriod = .monthly,
        categoryIds: [String] = [],
        startDate: Date = Date(),
        notifications: BudgetNotifications = BudgetNotifications(),
        color: String = "#007AFF",
        icon: String = "dollarsign.circle.fill",
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.period = period
        self.categoryIds = categoryIds
        self.startDate = startDate
        self.endDate = period.endDate(from: startDate)
        self.notifications = notifications
        self.color = color
        self.icon = icon
        self.isActive = isActive
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Budget Period

enum BudgetPeriod: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"
    case custom = "Custom"
    
    var displayName: String { rawValue }
    
    var dayCount: Int {
        switch self {
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30 // Approximate
        case .quarterly: return 90 // Approximate
        case .yearly: return 365
        case .custom: return 30 // Default
        }
    }
    
    func endDate(from startDate: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: startDate) ?? startDate
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: startDate) ?? startDate
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: startDate) ?? startDate
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: startDate) ?? startDate
        case .custom:
            return calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        }
    }
    
    func previousPeriod(from date: Date) -> DateInterval? {
        let calendar = Calendar.current
        let startDate: Date
        
        switch self {
        case .weekly:
            startDate = calendar.date(byAdding: .weekOfYear, value: -1, to: date) ?? date
        case .biweekly:
            startDate = calendar.date(byAdding: .weekOfYear, value: -2, to: date) ?? date
        case .monthly:
            startDate = calendar.date(byAdding: .month, value: -1, to: date) ?? date
        case .quarterly:
            startDate = calendar.date(byAdding: .month, value: -3, to: date) ?? date
        case .yearly:
            startDate = calendar.date(byAdding: .year, value: -1, to: date) ?? date
        case .custom:
            return nil
        }
        
        return DateInterval(start: startDate, end: date)
    }
}

// MARK: - Budget Notifications

struct BudgetNotifications: Codable, Equatable {
    var isEnabled: Bool = true
    var thresholds: [NotificationThreshold] = [
        NotificationThreshold(percentage: 50, isEnabled: true),
        NotificationThreshold(percentage: 75, isEnabled: true),
        NotificationThreshold(percentage: 90, isEnabled: true),
        NotificationThreshold(percentage: 100, isEnabled: true)
    ]
    var dailyUpdate: Bool = false
    var weeklyReport: Bool = true
    var overspendAlert: Bool = true
    var customReminders: [CustomReminder] = []
}

struct NotificationThreshold: Codable, Equatable, Identifiable {
    let id = UUID()
    var percentage: Int
    var isEnabled: Bool
    var hasBeenTriggered: Bool = false
    var lastTriggeredDate: Date?
}

struct CustomReminder: Codable, Equatable, Identifiable {
    let id = UUID()
    var message: String
    var daysBeforeEnd: Int
    var isEnabled: Bool
}

// MARK: - Budget Progress

extension Budget {
    /// Calculate current spending for this budget
    func calculateSpending(transactions: [Transaction]) -> Double {
        let calendar = Calendar.current
        let now = Date()
        
        // Filter transactions by category and date range
        let relevantTransactions = transactions.filter { transaction in
            // Check if transaction is in budget categories
            guard categoryIds.contains(transaction.category) else { return false }
            
            // Check if transaction is within budget period
            let transactionDate = transaction.formattedDate
            return transactionDate >= startDate && transactionDate <= (endDate ?? now)
        }
        
        // Sum up the absolute values (expenses are negative)
        return relevantTransactions.reduce(0) { sum, transaction in
            sum + abs(transaction.amount)
        }
    }
    
    /// Calculate progress percentage
    func progressPercentage(spending: Double) -> Double {
        guard amount > 0 else { return 0 }
        return min((spending / amount) * 100, 100)
    }
    
    /// Calculate daily average budget
    var dailyBudget: Double {
        let days = Double(period.dayCount)
        return amount / days
    }
    
    /// Calculate remaining budget
    func remainingBudget(spending: Double) -> Double {
        return max(amount - spending, 0)
    }
    
    /// Check if over budget
    func isOverBudget(spending: Double) -> Bool {
        return spending > amount
    }
    
    /// Calculate pace (spending rate)
    func spendingPace(spending: Double, currentDate: Date = Date()) -> SpendingPace {
        let calendar = Calendar.current
        let totalDays = period.dayCount
        let daysPassed = calendar.dateComponents([.day], from: startDate, to: currentDate).day ?? 0
        
        guard daysPassed > 0 && totalDays > 0 else { return .onTrack }
        
        let expectedProgress = Double(daysPassed) / Double(totalDays)
        let actualProgress = spending / amount
        
        let paceRatio = actualProgress / expectedProgress
        
        if paceRatio > 1.2 {
            return .tooFast
        } else if paceRatio < 0.8 {
            return .slow
        } else {
            return .onTrack
        }
    }
}

enum SpendingPace {
    case slow, onTrack, tooFast
    
    var displayText: String {
        switch self {
        case .slow: return "Under pace"
        case .onTrack: return "On track"
        case .tooFast: return "Over pace"
        }
    }
    
    var color: Color {
        switch self {
        case .slow: return DSColors.success.main
        case .onTrack: return DSColors.primary.main
        case .tooFast: return DSColors.warning.main
        }
    }
    
    var icon: String {
        switch self {
        case .slow: return "tortoise.fill"
        case .onTrack: return "checkmark.circle.fill"
        case .tooFast: return "hare.fill"
        }
    }
}

// MARK: - Budget Category

struct BudgetCategory: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: Color
    var monthlyAverage: Double?
    var lastMonthSpending: Double?
}

// MARK: - Budget Insights

struct BudgetInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let message: String
    let actionText: String?
    let impact: Impact
    let confidence: Double
    
    enum InsightType {
        case overspending, saving, pattern, recommendation, achievement, alert
    }
    
    enum Impact {
        case high, medium, low, optimization(Double), positive
        
        var color: Color {
            switch self {
            case .high: return DSColors.error.main
            case .medium: return DSColors.warning.main
            case .low, .positive: return DSColors.success.main
            case .optimization: return DSColors.primary.main
            }
        }
    }
}

// MARK: - Budget Report

struct BudgetReport {
    let budget: Budget
    let period: DateInterval
    let totalSpent: Double
    let dailyAverage: Double
    let categoryBreakdown: [CategorySpending]
    let insights: [BudgetInsight]
    let comparisonToPrevious: Double? // Percentage change
    
    struct CategorySpending {
        let categoryId: String
        let categoryName: String
        let amount: Double
        let percentage: Double
        let transactionCount: Int
    }
}

// MARK: - Smart Budget Suggestions

struct BudgetSuggestion {
    let amount: Double
    let reason: String
    let confidence: Double
    let basedOn: SuggestionBasis
    
    enum SuggestionBasis {
        case historicalAverage
        case similarUsers
        case expertRecommendation
        case lastPeriod
        case goalBased
    }
}

// MARK: - Sample Data

extension Budget {
    static let sampleBudgets: [Budget] = [
        Budget(
            name: "Groceries",
            amount: 600,
            period: .monthly,
            categoryIds: ["Groceries", "Food"],
            color: "#4CAF50",
            icon: "cart.fill"
        ),
        Budget(
            name: "Dining Out",
            amount: 300,
            period: .monthly,
            categoryIds: ["Restaurants", "Food & Dining"],
            color: "#FF9800",
            icon: "fork.knife"
        ),
        Budget(
            name: "Entertainment",
            amount: 200,
            period: .monthly,
            categoryIds: ["Entertainment", "Movies", "Games"],
            color: "#9C27B0",
            icon: "tv.fill"
        ),
        Budget(
            name: "Transportation",
            amount: 150,
            period: .weekly,
            categoryIds: ["Gas", "Transportation", "Uber"],
            color: "#2196F3",
            icon: "car.fill"
        )
    ]
}
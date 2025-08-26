import Foundation
import SwiftUI

// MARK: - BudgetSuggestion
struct BudgetSuggestion: Identifiable, Codable, Hashable {
    let id: UUID
    let amount: Double
    let reason: String
    let source: SuggestionSource
    let confidence: Double
    
    init(
        id: UUID = UUID(),
        amount: Double,
        reason: String,
        source: SuggestionSource,
        confidence: Double = 0.8
    ) {
        self.id = id
        self.amount = amount
        self.reason = reason
        self.source = source
        self.confidence = confidence
    }
    
    enum SuggestionSource: String, Codable, CaseIterable {
        case historicalAverage = "Historical Average"
        case expertRecommendation = "Expert Recommendation"
        case similarUsers = "Similar Users"
        case constant = "Fixed Amount"
        
        var icon: String {
            switch self {
            case .historicalAverage:
                return "chart.line.uptrend.xyaxis"
            case .expertRecommendation:
                return "star.fill"
            case .similarUsers:
                return "person.2.fill"
            case .constant:
                return "equal.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .historicalAverage:
                return DSColors.primary.main
            case .expertRecommendation:
                return DSColors.warning.main
            case .similarUsers:
                return DSColors.info.main
            case .constant:
                return DSColors.neutral.text
            }
        }
    }
}

// MARK: - BudgetCategory
struct BudgetCategory: Identifiable, Codable, Hashable {
    let id: String  // Changed to String to match usage
    let name: String
    let icon: String
    private let colorHex: String  // Store as hex string for Codable
    let subcategories: [String]
    let isDefault: Bool
    let monthlyAverage: Double?  // Added for preview displays
    
    // Computed property for Color
    var color: Color {
        Color(hex: colorHex) ?? Color.blue
    }
    
    init(
        id: String,
        name: String,
        icon: String,
        color: Color,
        subcategories: [String] = [],
        isDefault: Bool = false,
        monthlyAverage: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = color.hexString
        self.subcategories = subcategories
        self.isDefault = isDefault
        self.monthlyAverage = monthlyAverage
    }
    
    // Convenience init with String color (recommended)
    init(
        id: String,
        name: String,
        icon: String,
        colorHex: String,
        subcategories: [String] = [],
        isDefault: Bool = false,
        monthlyAverage: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.subcategories = subcategories
        self.isDefault = isDefault
        self.monthlyAverage = monthlyAverage
    }
    
    // Default budget categories
    static let defaultCategories: [BudgetCategory] = [
        BudgetCategory(
            id: "food",
            name: "Food",
            icon: "fork.knife",
            colorHex: "#34C759",
            subcategories: ["Groceries", "Dining Out", "Coffee", "Takeout"],
            isDefault: true
        ),
        BudgetCategory(
            id: "transportation",
            name: "Transportation",
            icon: "car.fill",
            colorHex: "#007AFF",
            subcategories: ["Gas", "Public Transit", "Rideshare", "Parking"],
            isDefault: true
        ),
        BudgetCategory(
            id: "entertainment",
            name: "Entertainment",
            icon: "tv.fill",
            colorHex: "#AF52DE",
            subcategories: ["Movies", "Games", "Streaming", "Events"],
            isDefault: true
        ),
        BudgetCategory(
            id: "shopping",
            name: "Shopping",
            icon: "bag.fill",
            colorHex: "#FF9500",
            subcategories: ["Clothing", "Electronics", "Home Goods", "Personal Care"],
            isDefault: true
        ),
        BudgetCategory(
            id: "bills",
            name: "Bills",
            icon: "doc.text.fill",
            colorHex: "#FF3B30",
            subcategories: ["Utilities", "Phone", "Internet", "Insurance"],
            isDefault: true
        ),
        BudgetCategory(
            id: "health",
            name: "Health",
            icon: "heart.fill",
            colorHex: "#FF2D55",
            subcategories: ["Medical", "Pharmacy", "Fitness", "Wellness"],
            isDefault: true
        ),
        BudgetCategory(
            id: "education",
            name: "Education",
            icon: "book.fill",
            colorHex: "#5856D6",
            subcategories: ["Courses", "Books", "Supplies", "Tuition"],
            isDefault: true
        ),
        BudgetCategory(
            id: "savings",
            name: "Savings",
            icon: "dollarsign.circle.fill",
            colorHex: "#32D74B",
            subcategories: ["Emergency Fund", "Retirement", "Investment", "Goal Savings"],
            isDefault: true
        )
    ]
}

// MARK: - Budget Notifications
struct BudgetNotifications: Codable, Hashable {
    let id: UUID
    let budgetId: String
    var thresholds: [NotificationThreshold]
    var isEnabled: Bool
    let notificationMethods: [NotificationMethod]
    var dailyUpdate: Bool
    var weeklyReport: Bool
    var overspendAlert: Bool
    
    init(
        id: UUID = UUID(),
        budgetId: String,
        thresholds: [NotificationThreshold] = NotificationThreshold.defaultThresholds,
        isEnabled: Bool = true,
        notificationMethods: [NotificationMethod] = [.inApp],
        dailyUpdate: Bool = false,
        weeklyReport: Bool = false,
        overspendAlert: Bool = true
    ) {
        self.id = id
        self.budgetId = budgetId
        self.thresholds = thresholds
        self.isEnabled = isEnabled
        self.notificationMethods = notificationMethods
        self.dailyUpdate = dailyUpdate
        self.weeklyReport = weeklyReport
        self.overspendAlert = overspendAlert
    }
}

struct NotificationThreshold: Codable, Hashable, Identifiable {
    let id: UUID
    let percentage: Double  // 0.0 to 1.0
    let message: String
    let priority: NotificationPriority
    var isEnabled: Bool
    
    init(
        id: UUID = UUID(),
        percentage: Double,
        message: String,
        priority: NotificationPriority = .medium,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.percentage = percentage
        self.message = message
        self.priority = priority
        self.isEnabled = isEnabled
    }
    
    static let defaultThresholds: [NotificationThreshold] = [
        NotificationThreshold(
            percentage: 0.8,
            message: "You've used 80% of your budget",
            priority: .medium
        ),
        NotificationThreshold(
            percentage: 0.9,
            message: "Warning: 90% of budget used",
            priority: .high
        ),
        NotificationThreshold(
            percentage: 1.0,
            message: "Budget limit exceeded!",
            priority: .critical
        )
    ]
}

enum NotificationMethod: String, Codable, CaseIterable {
    case inApp = "In-App"
    case push = "Push Notification"
    case email = "Email"
    case sms = "SMS"
}

enum NotificationPriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    var color: Color {
        switch self {
        case .low:
            return .gray
        case .medium:
            return .blue
        case .high:
            return .orange
        case .critical:
            return .red
        }
    }
}
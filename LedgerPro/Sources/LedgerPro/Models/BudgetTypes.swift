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
    let id: UUID
    let name: String
    let icon: String
    let color: String
    let subcategories: [String]
    let isDefault: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        color: String,
        subcategories: [String] = [],
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.subcategories = subcategories
        self.isDefault = isDefault
    }
    
    // Default budget categories
    static let defaultCategories: [BudgetCategory] = [
        BudgetCategory(
            name: "Food",
            icon: "fork.knife",
            color: "#34C759",
            subcategories: ["Groceries", "Dining Out", "Coffee", "Takeout"],
            isDefault: true
        ),
        BudgetCategory(
            name: "Transportation",
            icon: "car.fill",
            color: "#007AFF",
            subcategories: ["Gas", "Public Transit", "Rideshare", "Parking"],
            isDefault: true
        ),
        BudgetCategory(
            name: "Entertainment",
            icon: "tv.fill",
            color: "#AF52DE",
            subcategories: ["Movies", "Games", "Streaming", "Events"],
            isDefault: true
        ),
        BudgetCategory(
            name: "Shopping",
            icon: "bag.fill",
            color: "#FF9500",
            subcategories: ["Clothing", "Electronics", "Home Goods", "Personal Care"],
            isDefault: true
        ),
        BudgetCategory(
            name: "Bills",
            icon: "doc.text.fill",
            color: "#FF3B30",
            subcategories: ["Utilities", "Phone", "Internet", "Insurance"],
            isDefault: true
        ),
        BudgetCategory(
            name: "Health",
            icon: "heart.fill",
            color: "#FF2D55",
            subcategories: ["Medical", "Pharmacy", "Fitness", "Wellness"],
            isDefault: true
        ),
        BudgetCategory(
            name: "Education",
            icon: "book.fill",
            color: "#5856D6",
            subcategories: ["Courses", "Books", "Supplies", "Tuition"],
            isDefault: true
        ),
        BudgetCategory(
            name: "Savings",
            icon: "dollarsign.circle.fill",
            color: "#32D74B",
            subcategories: ["Emergency Fund", "Retirement", "Investment", "Goal Savings"],
            isDefault: true
        )
    ]
}
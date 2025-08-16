import Foundation
import SwiftUI

/// Represents an AI-generated insight about a budget
struct BudgetInsight: Identifiable, Codable, Hashable {
    let id: UUID
    let type: InsightType
    let title: String
    let message: String
    let actionText: String?
    let impact: InsightImpact
    let confidence: Double // 0.0 to 1.0
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        type: InsightType,
        title: String,
        message: String,
        actionText: String? = nil,
        impact: InsightImpact,
        confidence: Double,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.actionText = actionText
        self.impact = impact
        self.confidence = confidence
        self.createdAt = createdAt
    }
    
    /// Types of budget insights
    enum InsightType: String, Codable, CaseIterable {
        case pattern = "pattern"
        case recommendation = "recommendation"
        case achievement = "achievement"
        case alert = "alert"
        case overspending = "overspending"
        case saving = "saving"
    }
    
    /// The potential impact of the insight
    enum InsightImpact: Codable, Hashable {
        case optimization(Double) // Potential savings amount
        case positive
        case negative
        case neutral
    }
}

// MARK: - Convenience initializers for common insight types
extension BudgetInsight {
    /// Creates an overspending alert insight
    static func overspendingAlert(
        for budget: String,
        currentSpending: Double,
        budgetAmount: Double,
        confidence: Double = 0.95
    ) -> BudgetInsight {
        let overspendAmount = currentSpending - budgetAmount
        let percentageOver = (overspendAmount / budgetAmount) * 100
        
        return BudgetInsight(
            type: .overspending,
            title: "Budget Exceeded",
            message: "You've exceeded your \(budget) budget by \(overspendAmount.formatAsCurrency()) (\(Int(percentageOver))% over).",
            actionText: "Review Spending",
            impact: .negative,
            confidence: confidence
        )
    }
    
    /// Creates a saving achievement insight
    static func savingAchievement(
        for budget: String,
        savedAmount: Double,
        confidence: Double = 0.9
    ) -> BudgetInsight {
        return BudgetInsight(
            type: .saving,
            title: "Great Savings!",
            message: "You saved \(savedAmount.formatAsCurrency()) on your \(budget) budget this period.",
            actionText: nil,
            impact: .positive,
            confidence: confidence
        )
    }
    
    /// Creates a spending pattern insight
    static func spendingPattern(
        title: String,
        pattern: String,
        potentialSaving: Double? = nil,
        confidence: Double
    ) -> BudgetInsight {
        let impact: InsightImpact = potentialSaving.map { .optimization($0) } ?? .neutral
        
        return BudgetInsight(
            type: .pattern,
            title: title,
            message: pattern,
            actionText: potentialSaving != nil ? "Optimize Spending" : nil,
            impact: impact,
            confidence: confidence
        )
    }
    
    /// Creates a recommendation insight
    static func recommendation(
        title: String,
        suggestion: String,
        potentialSaving: Double,
        actionText: String,
        confidence: Double
    ) -> BudgetInsight {
        return BudgetInsight(
            type: .recommendation,
            title: title,
            message: suggestion,
            actionText: actionText,
            impact: .optimization(potentialSaving),
            confidence: confidence
        )
    }
}

// MARK: - Helper extension for currency formatting
fileprivate extension Double {
    func formatAsCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }
}
import Foundation
import SwiftUI

/// Model representing an AI-generated financial insight
struct FinancialInsight: Identifiable {
    let id: String
    let type: InsightType
    let title: String
    let description: String
    let action: String
    let icon: String
    let createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        type: InsightType,
        title: String,
        description: String,
        action: String = "",
        icon: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.action = action
        self.icon = icon
        self.createdAt = createdAt
    }
    
    /// Type of financial insight
    enum InsightType {
        case positive
        case warning
        case neutral
        
        var color: Color {
            switch self {
            case .positive:
                return DSColors.success.main
            case .warning:
                return DSColors.warning.main
            case .neutral:
                return DSColors.primary.main
            }
        }
    }
}

// MARK: - Sample Data

extension FinancialInsight {
    static let sampleInsights = [
        FinancialInsight(
            id: "1",
            type: .positive,
            title: "Great savings progress!",
            description: "You're 78% towards your $2,000 monthly savings target with $1,560 saved so far.",
            action: "View progress",
            icon: "target"
        ),
        FinancialInsight(
            id: "2",
            type: .warning,
            title: "Budget threshold exceeded",
            description: "Your entertainment spending of $320 has exceeded the $250 monthly budget by 28%.",
            action: "Adjust budget",
            icon: "exclamationmark.triangle.fill"
        ),
        FinancialInsight(
            id: "3",
            type: .neutral,
            title: "New spending pattern detected",
            description: "You've spent 25% more on groceries this month ($340 vs $270 average). This could be due to recent price increases.",
            action: "View grocery trends",
            icon: "cart.fill"
        )
    ]
}

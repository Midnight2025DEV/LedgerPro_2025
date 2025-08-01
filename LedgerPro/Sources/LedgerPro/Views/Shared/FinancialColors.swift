import SwiftUI

extension Color {
    // MARK: - Transaction Colors (Semantic)
    static let income = Color(red: 0.2, green: 0.8, blue: 0.4)      // Monarch-style green
    static let expense = Color(red: 0.9, green: 0.3, blue: 0.3)     // Clear red for spending
    static let transfer = Color(red: 0.5, green: 0.5, blue: 0.6)    // Neutral gray
    static let pending = Color(red: 1.0, green: 0.6, blue: 0.2)     // Warning orange
    
    // MARK: - Category Colors (Distinct)
    static let foodDining = Color(red: 1.0, green: 0.5, blue: 0.3)
    static let shopping = Color(red: 0.3, green: 0.6, blue: 0.9)
    static let transport = Color(red: 0.6, green: 0.4, blue: 0.8)
    static let utilities = Color(red: 0.2, green: 0.7, blue: 0.7)
    static let entertainment = Color(red: 0.9, green: 0.3, blue: 0.6)
    static let healthcare = Color(red: 0.1, green: 0.7, blue: 0.5)
    static let education = Color(red: 0.5, green: 0.4, blue: 0.8)
    
    // MARK: - Status Colors
    static let success = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let warning = Color(red: 1.0, green: 0.6, blue: 0.2)
    static let error = Color(red: 0.9, green: 0.3, blue: 0.3)
}

// MARK: - Transaction Amount Color Helper
extension Transaction {
    var amountColor: Color {
        if amount >= 0 {
            return .income
        } else {
            return .expense
        }
    }
    
    var semanticCategoryColor: Color {
        switch category.lowercased() {
        case "food & dining", "restaurants", "groceries":
            return .foodDining
        case "shopping", "retail":
            return .shopping
        case "transport", "transportation", "gas", "parking":
            return .transport
        case "utilities", "bills", "phone", "internet":
            return .utilities
        case "entertainment", "movies", "games":
            return .entertainment
        case "healthcare", "medical", "pharmacy":
            return .healthcare
        case "education", "books", "courses":
            return .education
        default:
            return .secondary
        }
    }
}
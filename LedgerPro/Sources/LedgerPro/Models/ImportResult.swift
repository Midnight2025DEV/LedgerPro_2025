import Foundation

struct ImportResult {
    let totalTransactions: Int
    let categorizedCount: Int
    let highConfidenceCount: Int
    let uncategorizedCount: Int
    let categorizedTransactions: [(Transaction, Category, Double)] // transaction, category, confidence
    let uncategorizedTransactions: [Transaction]
    
    var successRate: Double {
        guard totalTransactions > 0 else { return 0 }
        return Double(categorizedCount) / Double(totalTransactions)
    }
    
    var summaryMessage: String {
        return """
        Import Summary:
        • Total: \(totalTransactions) transactions
        • Auto-categorized: \(categorizedCount) (\(Int(successRate * 100))%)
        • High confidence: \(highConfidenceCount)
        • Need review: \(uncategorizedCount)
        """
    }
}
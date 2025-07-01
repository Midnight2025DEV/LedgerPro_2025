import Foundation

/// Comprehensive analytics and insights for category spending patterns
struct CategoryInsights: Codable {
    let categoryId: UUID
    let period: DateInterval
    var generatedAt: Date = Date()
    
    // MARK: - Basic Metrics
    
    var totalSpent: Decimal
    var transactionCount: Int
    var monthlyAverage: Decimal
    var weeklyAverage: Decimal
    var dailyAverage: Decimal
    
    // MARK: - Budget & Goals
    
    var budgetAmount: Decimal?
    var percentOfBudget: Double?
    var budgetRemaining: Decimal?
    var daysUntilBudgetReset: Int?
    
    // MARK: - Comparative Metrics
    
    var percentOfTotalSpending: Double
    var percentOfTotalIncome: Double?
    var rankAmongCategories: Int?
    var previousPeriodComparison: PeriodComparison?
    
    // MARK: - Trends & Patterns
    
    var trend: TrendDirection
    var trendStrength: Double // 0.0 to 1.0
    var seasonality: SeasonalityPattern?
    var averageTransactionAmount: Decimal
    var medianTransactionAmount: Decimal
    var largestTransaction: TransactionSummary?
    var smallestTransaction: TransactionSummary?
    
    // MARK: - Merchant Analysis
    
    var topMerchants: [MerchantSummary]
    var merchantDiversity: Double // 0.0 to 1.0, higher = more diverse spending
    var newMerchantsThisPeriod: [MerchantSummary]
    
    // MARK: - Timing Patterns
    
    var dayOfWeekDistribution: [Int: Decimal] // Day (1-7) -> Amount
    var timeOfDayDistribution: [Int: Decimal] // Hour (0-23) -> Amount
    var monthlyDistribution: [Int: Decimal] // Month (1-12) -> Amount
    
    // MARK: - Anomalies & Alerts
    
    var unusualActivity: [AnomalyAlert]
    var spendingVelocity: SpendingVelocity
    var predictedNextTransaction: TransactionPrediction?
    
    // MARK: - Computed Properties
    
    /// Returns the formatted total spent as currency
    var formattedTotalSpent: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: totalSpent as NSDecimalNumber) ?? "$0.00"
    }
    
    /// Returns the budget utilization as a percentage (0-100)
    var budgetUtilization: Double {
        guard let budget = budgetAmount, budget > 0 else { return 0.0 }
        return Double(truncating: (totalSpent / budget * 100) as NSDecimalNumber)
    }
    
    /// Determines if the budget is exceeded
    var isBudgetExceeded: Bool {
        guard let budget = budgetAmount else { return false }
        return totalSpent > budget
    }
    
    /// Returns the number of days in the analysis period
    var periodDays: Int {
        return Calendar.current.dateComponents([.day], from: period.start, to: period.end).day ?? 0
    }
    
    /// Returns the spending rate per day
    var dailySpendingRate: Decimal {
        guard periodDays > 0 else { return 0 }
        return totalSpent / Decimal(periodDays)
    }
    
    /// Returns the most active day of the week for this category
    var mostActiveDay: (dayOfWeek: Int, amount: Decimal)? {
        return dayOfWeekDistribution.max { $0.value < $1.value }.map { ($0.key, $0.value) }
    }
    
    /// Returns the most active hour of the day for this category
    var mostActiveHour: (hour: Int, amount: Decimal)? {
        return timeOfDayDistribution.max { $0.value < $1.value }.map { ($0.key, $0.value) }
    }
}

// MARK: - Supporting Structures

/// Trend direction with strength indicator
enum TrendDirection: String, Codable {
    case increasing = "increasing"
    case decreasing = "decreasing"
    case stable = "stable"
    case volatile = "volatile"
    
    var displayName: String {
        switch self {
        case .increasing: return "Increasing"
        case .decreasing: return "Decreasing"
        case .stable: return "Stable"
        case .volatile: return "Volatile"
        }
    }
    
    var emoji: String {
        switch self {
        case .increasing: return "📈"
        case .decreasing: return "📉"
        case .stable: return "➡️"
        case .volatile: return "📊"
        }
    }
}

/// Seasonality patterns for spending
enum SeasonalityPattern: String, Codable {
    case none = "none"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case seasonal = "seasonal"
    case holiday = "holiday"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .none: return "No Pattern"
        case .monthly: return "Monthly Pattern"
        case .quarterly: return "Quarterly Pattern"
        case .seasonal: return "Seasonal Pattern"
        case .holiday: return "Holiday Pattern"
        case .custom: return "Custom Pattern"
        }
    }
}

/// Comparison with previous period
struct PeriodComparison: Codable {
    let previousPeriod: DateInterval
    let previousTotalSpent: Decimal
    let percentChange: Double
    let absoluteChange: Decimal
    let transactionCountChange: Int
    
    var isIncrease: Bool {
        return percentChange > 0
    }
    
    var isDecrease: Bool {
        return percentChange < 0
    }
    
    var isStable: Bool {
        return abs(percentChange) < 5.0 // Within 5% considered stable
    }
    
    var formattedPercentChange: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.positivePrefix = "+"
        return formatter.string(from: NSNumber(value: percentChange / 100.0)) ?? "0%"
    }
    
    var formattedAbsoluteChange: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.positivePrefix = "+"
        return formatter.string(from: absoluteChange as NSDecimalNumber) ?? "$0.00"
    }
}

/// Merchant spending summary
struct MerchantSummary: Codable {
    let merchantName: String
    let transactionCount: Int
    let totalAmount: Decimal
    let averageAmount: Decimal
    let firstSeen: Date
    let lastSeen: Date
    let frequency: TransactionFrequency
    
    var formattedTotalAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: totalAmount as NSDecimalNumber) ?? "$0.00"
    }
    
    var formattedAverageAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: averageAmount as NSDecimalNumber) ?? "$0.00"
    }
    
    var daysSinceLastTransaction: Int {
        return Calendar.current.dateComponents([.day], from: lastSeen, to: Date()).day ?? 0
    }
}

// TransactionFrequency is defined in CategoryRule.swift

/// Simplified transaction summary for insights
struct TransactionSummary: Codable {
    let transactionId: UUID
    let date: Date
    let merchantName: String
    let amount: Decimal
    let description: String
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

/// Anomaly detection alerts
struct AnomalyAlert: Codable {
    let type: AnomalyType
    let severity: AlertSeverity
    let message: String
    let detectedAt: Date
    let relatedTransactions: [UUID]
    let suggestedAction: String?
    
    var displayMessage: String {
        return "\(severity.emoji) \(message)"
    }
}

enum AnomalyType: String, Codable {
    case unusualAmount = "unusual_amount"
    case newMerchant = "new_merchant"
    case frequencyChange = "frequency_change"
    case budgetOverrun = "budget_overrun"
    case duplicateTransaction = "duplicate_transaction"
    case outlierAmount = "outlier_amount"
    case suspiciousPattern = "suspicious_pattern"
    
    var displayName: String {
        switch self {
        case .unusualAmount: return "Unusual Amount"
        case .newMerchant: return "New Merchant"
        case .frequencyChange: return "Frequency Change"
        case .budgetOverrun: return "Budget Overrun"
        case .duplicateTransaction: return "Duplicate Transaction"
        case .outlierAmount: return "Outlier Amount"
        case .suspiciousPattern: return "Suspicious Pattern"
        }
    }
}

enum AlertSeverity: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var emoji: String {
        switch self {
        case .low: return "ℹ️"
        case .medium: return "⚠️"
        case .high: return "🚨"
        case .critical: return "🔴"
        }
    }
    
    var displayName: String {
        switch self {
        case .low: return "Info"
        case .medium: return "Warning"
        case .high: return "Alert"
        case .critical: return "Critical"
        }
    }
}

/// Spending velocity analysis
struct SpendingVelocity: Codable {
    let currentVelocity: Decimal // Amount per day
    let averageVelocity: Decimal
    let velocityTrend: TrendDirection
    let projectedMonthlySpend: Decimal
    let accelerationFactor: Double // Rate of velocity change
    
    var isAccelerating: Bool {
        return accelerationFactor > 1.1
    }
    
    var isDecelerating: Bool {
        return accelerationFactor < 0.9
    }
    
    var isStable: Bool {
        return !isAccelerating && !isDecelerating
    }
    
    var formattedCurrentVelocity: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return "\(formatter.string(from: currentVelocity as NSDecimalNumber) ?? "$0.00")/day"
    }
    
    var formattedProjectedMonthly: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: projectedMonthlySpend as NSDecimalNumber) ?? "$0.00"
    }
}

/// Prediction for next transaction in this category
struct TransactionPrediction: Codable {
    let predictedDate: Date
    let predictedAmount: Decimal
    let predictedMerchant: String?
    let confidence: Double // 0.0 to 1.0
    let basedOnPattern: String
    
    var daysUntilPredicted: Int {
        return Calendar.current.dateComponents([.day], from: Date(), to: predictedDate).day ?? 0
    }
    
    var formattedPredictedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: predictedAmount as NSDecimalNumber) ?? "$0.00"
    }
    
    var formattedConfidence: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: confidence)) ?? "0%"
    }
    
    var confidenceLevel: String {
        switch confidence {
        case 0.8...1.0: return "High"
        case 0.6..<0.8: return "Medium"
        case 0.4..<0.6: return "Low"
        default: return "Very Low"
        }
    }
}

// MARK: - Insights Factory

extension CategoryInsights {
    /// Creates basic insights from a collection of transactions
    static func create(
        categoryId: UUID,
        transactions: [Transaction],
        period: DateInterval,
        budgetAmount: Decimal? = nil,
        totalSpending: Decimal? = nil,
        totalIncome: Decimal? = nil
    ) -> CategoryInsights {
        
        let categoryTransactions = transactions.filter { _ in
            // This will be enhanced when CategoryService is implemented to match by categoryId
            true
        }
        
        // Basic calculations
        let totalSpent = categoryTransactions.reduce(Decimal(0)) { sum, transaction in
            sum + Decimal(abs(transaction.amount))
        }
        
        let transactionCount = categoryTransactions.count
        let periodDays = Calendar.current.dateComponents([.day], from: period.start, to: period.end).day ?? 1
        
        let dailyAverage = totalSpent / Decimal(max(1, periodDays))
        let weeklyAverage = dailyAverage * 7
        let monthlyAverage = dailyAverage * 30
        
        // Merchant analysis
        let merchantGroups = Dictionary(grouping: categoryTransactions) { transaction in
            transaction.description.components(separatedBy: " ").first ?? "Unknown"
        }
        
        let topMerchants = merchantGroups.map { merchantName, transactions in
            let merchantTotal = transactions.reduce(Decimal(0)) { sum, transaction in
                sum + Decimal(abs(transaction.amount))
            }
            let merchantAverage = merchantTotal / Decimal(transactions.count)
            
            return MerchantSummary(
                merchantName: merchantName,
                transactionCount: transactions.count,
                totalAmount: merchantTotal,
                averageAmount: merchantAverage,
                firstSeen: transactions.map(\.formattedDate).min() ?? Date(),
                lastSeen: transactions.map(\.formattedDate).max() ?? Date(),
                frequency: .irregular // Would be calculated based on transaction patterns
            )
        }.sorted { $0.totalAmount > $1.totalAmount }.prefix(5).map { $0 }
        
        // Calculate percentages
        let percentOfTotalSpending = totalSpending != nil && totalSpending! > 0 ?
            Double(truncating: (totalSpent / totalSpending! * 100) as NSDecimalNumber) : 0.0
        
        let percentOfTotalIncome = totalIncome != nil && totalIncome! > 0 ?
            Double(truncating: (totalSpent / totalIncome! * 100) as NSDecimalNumber) : nil
        
        // Budget calculations
        let percentOfBudget = budgetAmount != nil && budgetAmount! > 0 ?
            Double(truncating: (totalSpent / budgetAmount! * 100) as NSDecimalNumber) : nil
        
        let budgetRemaining = budgetAmount != nil ? budgetAmount! - totalSpent : nil
        
        return CategoryInsights(
            categoryId: categoryId,
            period: period,
            totalSpent: totalSpent,
            transactionCount: transactionCount,
            monthlyAverage: monthlyAverage,
            weeklyAverage: weeklyAverage,
            dailyAverage: dailyAverage,
            budgetAmount: budgetAmount,
            percentOfBudget: percentOfBudget,
            budgetRemaining: budgetRemaining,
            daysUntilBudgetReset: nil,
            percentOfTotalSpending: percentOfTotalSpending,
            percentOfTotalIncome: percentOfTotalIncome,
            rankAmongCategories: nil,
            previousPeriodComparison: nil,
            trend: .stable,
            trendStrength: 0.5,
            seasonality: nil,
            averageTransactionAmount: transactionCount > 0 ? totalSpent / Decimal(transactionCount) : 0,
            medianTransactionAmount: 0, // Would be calculated
            largestTransaction: nil,
            smallestTransaction: nil,
            topMerchants: Array(topMerchants),
            merchantDiversity: 0.5,
            newMerchantsThisPeriod: [],
            dayOfWeekDistribution: [:],
            timeOfDayDistribution: [:],
            monthlyDistribution: [:],
            unusualActivity: [],
            spendingVelocity: SpendingVelocity(
                currentVelocity: dailyAverage,
                averageVelocity: dailyAverage,
                velocityTrend: .stable,
                projectedMonthlySpend: monthlyAverage,
                accelerationFactor: 1.0
            ),
            predictedNextTransaction: nil
        )
    }
}
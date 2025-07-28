//
//  InsightsOverviewComponents.swift
//  LedgerPro
//
//  Overview components for the Insights view including financial health,
//  key metrics, and account performance visualizations
//

import SwiftUI
import Charts

// Extract lines 249-532 from InsightsView.swift
// This includes:
// - InsightOverviewView
// - FinancialHealthCard
// - KeyMetricsGrid
// - MetricCard
// - SpendingDistributionChart
// - AccountPerformanceView
// - AccountPerformanceRow
struct InsightOverviewView: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    
    var body: some View {
        LazyVStack(spacing: 20) {
            // Financial Health Score
            FinancialHealthCard()
            
            // Key Metrics
            KeyMetricsGrid()
            
            // Spending Distribution
            SpendingDistributionChart()
            
            // Account Performance
            AccountPerformanceView()
        }
        .padding()
    }
}

struct FinancialHealthCard: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    
    private var healthScore: Int {
        let summary = dataManager.summary
        var score = 50
        
        if summary.netSavings > 0 { score += 25 }
        if summary.totalExpenses < summary.totalIncome * 0.8 { score += 15 }
        if dataManager.bankAccounts.count > 1 { score += 10 }
        
        return min(100, score)
    }
    
    private var healthLevel: (String, Color) {
        switch healthScore {
        case 80...100: return ("Excellent", .green)
        case 60...79: return ("Good", .blue)
        case 40...59: return ("Fair", .yellow)
        default: return ("Needs Improvement", .red)
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Financial Health Score")
                .font(.title2)
                .fontWeight(.bold)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 12)
                
                Circle()
                    .trim(from: 0, to: Double(healthScore) / 100)
                    .stroke(healthLevel.1, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: healthScore)
                
                VStack {
                    Text("\(healthScore)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(healthLevel.1)
                    Text(healthLevel.0)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 150, height: 150)
            
            Text("Based on \(dataManager.transactions.count) transactions across \(dataManager.bankAccounts.count) accounts")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
}

struct KeyMetricsGrid: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    
    private var savingsRate: Double {
        let summary = dataManager.summary
        guard summary.totalIncome > 0 else { return 0 }
        return (summary.netSavings / summary.totalIncome) * 100
    }
    
    private var expenseRatio: Double {
        let summary = dataManager.summary
        guard summary.totalIncome > 0 else { return 0 }
        return (summary.totalExpenses / summary.totalIncome) * 100
    }
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            InsightMetricCard(
                title: "Savings Rate",
                value: String(format: "%.1f%%", savingsRate),
                trend: savingsRate >= 20 ? .positive : savingsRate >= 10 ? .neutral : .negative,
                icon: "banknote.fill"
            )
            
            InsightMetricCard(
                title: "Expense Ratio",
                value: String(format: "%.1f%%", expenseRatio),
                trend: expenseRatio <= 70 ? .positive : expenseRatio <= 85 ? .neutral : .negative,
                icon: "chart.pie.fill"
            )
            
            InsightMetricCard(
                title: "Avg Transaction",
                value: averageTransactionAmount(),
                trend: .neutral,
                icon: "arrow.left.arrow.right"
            )
            
            InsightMetricCard(
                title: "Active Accounts",
                value: "\(dataManager.bankAccounts.filter { $0.isActive }.count)",
                trend: .neutral,
                icon: "building.columns.fill"
            )
        }
    }
    
    private func averageTransactionAmount() -> String {
        guard !dataManager.transactions.isEmpty else { return "$0.00" }
        
        let total = dataManager.transactions.reduce(0) { $0 + abs($1.amount) }
        let average = total / Double(dataManager.transactions.count)
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: average)) ?? "$0.00"
    }
}

struct InsightMetricCard: View {
    let title: String
    let value: String
    let trend: TrendDirection
    let icon: String
    
    enum TrendDirection {
        case positive, neutral, negative
        
        var color: Color {
            switch self {
            case .positive: return .green
            case .neutral: return .blue
            case .negative: return .red
            }
        }
        
        var systemImage: String {
            switch self {
            case .positive: return "arrow.up.circle.fill"
            case .neutral: return "minus.circle.fill"
            case .negative: return "arrow.down.circle.fill"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(trend.color)
                Spacer()
                Image(systemName: trend.systemImage)
                    .foregroundColor(trend.color)
                    .font(.caption)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct SpendingDistributionChart: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    @EnvironmentObject private var categoryService: CategoryService
    
    private var categoryData: [EnhancedCategorySpending] {
        let expenses = dataManager.transactions.filter { $0.amount < 0 }
        let grouped = Dictionary(grouping: expenses) { $0.category }
        
        return grouped.map { categoryName, transactions in
            let total = transactions.reduce(0) { $0 + abs($1.amount) }
            let categoryObject = categoryService.categories.first { $0.name == categoryName }
            
            return EnhancedCategorySpending(
                category: categoryName,
                amount: total,
                categoryObject: categoryObject
            )
        }.sorted { $0.amount > $1.amount }.prefix(8).map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Category Spending")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("All Categories")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !categoryData.isEmpty {
                Chart(categoryData, id: \.category) { data in
                    BarMark(
                        x: .value("Category", data.shortName),
                        y: .value("Amount", data.amount)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [data.color, data.color.opacity(0.7)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(6)
                }
                .frame(height: 220)
                .chartXAxis {
                    AxisMarks(preset: .aligned, values: .automatic(desiredCount: 8)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2]))
                            .foregroundStyle(Color.secondary.opacity(0.3))
                        AxisValueLabel {
                            if let category = value.as(String.self) {
                                Text(category.truncated(to: 8))
                                    .font(.caption2)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.secondary.opacity(0.3))
                        AxisValueLabel(format: .currency(code: "USD").precision(.fractionLength(0)))
                            .font(.caption2)
                    }
                }
            } else {
                VStack {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No spending data available")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct AccountPerformanceView: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account Performance")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                ForEach(dataManager.bankAccounts) { account in
                    AccountPerformanceRow(account: account)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

// Enhanced category spending for charts
struct EnhancedCategorySpending: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
    let categoryObject: Category?
    
    var shortName: String {
        return category.truncated(to: 12)
    }
    
    var color: Color {
        if let categoryObject = categoryObject,
           let color = Color(hex: categoryObject.color) {
            return color
        }
        return .gray
    }
    
    var icon: String {
        return categoryObject?.icon ?? "circle.fill"
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}


struct AccountPerformanceRow: View {
    let account: BankAccount
    @EnvironmentObject private var dataManager: FinancialDataManager
    
    private var summary: FinancialSummary {
        dataManager.getSummary(for: account.id)
    }
    
    var body: some View {
        HStack {
            Image(systemName: account.accountType.systemImage)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.headline)
                Text(account.institution)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(summary.formattedBalance)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("\(summary.transactionCount) transactions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
    }
}

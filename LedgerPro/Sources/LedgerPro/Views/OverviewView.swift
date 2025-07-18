import SwiftUI
import Charts

struct OverviewView: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    @StateObject private var dashboardService = DashboardDataService()
    @State private var selectedAccountId: String? = nil // Track selected account
    
    var body: some View {
        VStack(spacing: 0) {
            // Account Filter Bar
            AccountFilterBar(selectedAccountId: $selectedAccountId)
                .padding(.horizontal)
                .padding(.vertical, 8)
            
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Context-Aware Quick Stats Grid
                    ContextAwareQuickStatsGrid(
                        dashboardService: dashboardService,
                        selectedAccountId: selectedAccountId
                    )
                    
                    // Charts Section
                    HStack(spacing: 20) {
                        // Spending Chart (filtered by account if selected)
                        ContextAwareSpendingChart(selectedAccountId: selectedAccountId)
                            .frame(minHeight: 300)
                        
                        // Category Breakdown (filtered by account if selected)
                        CategoryBreakdownView(dashboardService: dashboardService)
                            .frame(minWidth: 300, minHeight: 300)
                    }
                    
                    // Top Merchants
                    TopMerchantsView(dashboardService: dashboardService)
                    
                    // Recent Transactions
                    ContextAwareRecentTransactions(selectedAccountId: selectedAccountId)
                }
                .padding()
            }
        }
        .navigationTitle(navigationTitle)
        .onAppear {
            dashboardService.refreshData()
        }
    }
    
    private var navigationTitle: String {
        if let accountId = selectedAccountId,
           let account = dataManager.getAccount(for: accountId) {
            return "\(account.displayName) Overview"
        }
        return "Financial Overview"
    }
}

// MARK: - Account Filter Bar

struct AccountFilterBar: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    @Binding var selectedAccountId: String?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All Accounts
                FilterChip(
                    title: "All Accounts",
                    systemImage: "wallet.fill",
                    isSelected: selectedAccountId == nil,
                    count: dataManager.transactions.count
                ) {
                    withAnimation {
                        selectedAccountId = nil
                    }
                }
                
                // Individual Accounts
                ForEach(dataManager.bankAccounts) { account in
                    FilterChip(
                        title: account.displayName,
                        systemImage: account.accountType.systemImage,
                        isSelected: selectedAccountId == account.id,
                        count: dataManager.getTransactions(for: account.id).count,
                        accountType: account.accountType
                    ) {
                        withAnimation {
                            selectedAccountId = account.id
                        }
                    }
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let count: Int
    let accountType: BankAccount.AccountType?
    let action: () -> Void
    
    init(title: String, systemImage: String, isSelected: Bool, count: Int, accountType: BankAccount.AccountType? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.isSelected = isSelected
        self.count = count
        self.accountType = accountType
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 14))
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                
                Text("(\(count))")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? accentColor : Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
    }
    
    private var accentColor: Color {
        if let accountType = accountType {
            switch accountType {
            case .checking: return .blue
            case .savings: return .green
            case .credit: return .orange
            case .investment: return .purple
            case .loan: return .red
            }
        }
        return .blue
    }
}

// MARK: - Context-Aware Components

struct ContextAwareQuickStatsGrid: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    @ObservedObject var dashboardService: DashboardDataService
    let selectedAccountId: String?
    
    private var contextSummary: ContextAwareFinancialSummary {
        let summary = dataManager.getContextAwareSummary(for: selectedAccountId)
        AppLogger.shared.debug("ContextAwareQuickStatsGrid - Account ID: \(selectedAccountId ?? "nil")", category: "Overview")
        AppLogger.shared.debug("Account Type: \(summary.accountType)", category: "Overview")
        AppLogger.shared.debug("Primary Metrics Count: \(summary.primaryMetrics.count)", category: "Overview")
        for (index, metric) in summary.primaryMetrics.enumerated() {
            AppLogger.shared.debug("Metric \(index): \(metric.title) = \(metric.formattedValue)", category: "Overview")
        }
        return summary
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Account Type Indicator
            if let accountId = selectedAccountId,
               let account = dataManager.getAccount(for: accountId) {
                HStack {
                    Image(systemName: account.accountType.systemImage)
                        .foregroundColor(account.accountType.color)
                    Text("\(account.accountType.displayName) Account")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(account.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
            
            // Primary Metrics Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: min(4, contextSummary.primaryMetrics.count)), spacing: 16) {
                ForEach(contextSummary.primaryMetrics.indices, id: \.self) { index in
                    ContextAwareStatCard(metric: contextSummary.primaryMetrics[index])
                }
            }
            
            // Secondary Metrics (if any)
            if !contextSummary.secondaryMetrics.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: min(3, contextSummary.secondaryMetrics.count)), spacing: 12) {
                    ForEach(contextSummary.secondaryMetrics.indices, id: \.self) { index in
                        ContextAwareStatCard(metric: contextSummary.secondaryMetrics[index])
                            .scaleEffect(0.9) // Slightly smaller for secondary metrics
                    }
                }
            }
            
            // Context-Aware Insights
            if !contextSummary.insights.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Insights")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    ForEach(contextSummary.insights, id: \.self) { insight in
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(insight)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Context-Aware Recommendations
            if !contextSummary.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommendations")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    ForEach(contextSummary.recommendations, id: \.self) { recommendation in
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text(recommendation)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct ContextAwareStatCard: View {
    let metric: ContextMetric
    
    init(metric: ContextMetric) {
        self.metric = metric
        AppLogger.shared.debug("ContextAwareStatCard - \(metric.title): \(metric.formattedValue)", category: "Overview")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: metric.icon)
                    .foregroundColor(metric.color)
                Spacer()
                Image(systemName: metric.trend.icon)
                    .foregroundColor(metric.trend.color)
                    .font(.caption)
            }
            
            Text(metric.formattedValue)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(metric.title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(metric.description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 1)
        .help(metric.description) // Tooltip on hover
    }
}

struct ContextAwareSpendingChart: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    let selectedAccountId: String?
    
    private var chartData: [DailySpending] {
        let transactions = selectedAccountId != nil 
            ? dataManager.getTransactions(for: selectedAccountId!)
            : dataManager.transactions
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let grouped = Dictionary(grouping: transactions) { transaction in
            transaction.date
        }
        
        let accountType = selectedAccountId != nil 
            ? dataManager.getAccount(for: selectedAccountId)?.accountType
            : nil
        
        let dailyData = grouped.compactMap { date, dayTransactions -> DailySpending? in
            guard let parsedDate = dateFormatter.date(from: date) else { return nil }
            
            let expenses = dayTransactions.filter { $0.amount < 0 }.reduce(0) { $0 + abs($1.amount) }
            
            // Context-aware income calculation
            let income: Double
            if accountType == .credit {
                // For credit cards, show payments
                income = dayTransactions.filter { $0.isPayment && $0.amount > 0 }.reduce(0) { $0 + $1.amount }
            } else {
                // For other accounts, show actual income
                income = dayTransactions.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
            }
            
            return DailySpending(
                date: parsedDate,
                expenses: expenses,
                income: income
            )
        }
        
        let sortedData = dailyData.sorted { $0.date < $1.date }
        return sortedData.count <= 30 ? sortedData : Array(sortedData.suffix(20))
    }
    
    private var chartTitle: String {
        if let accountId = selectedAccountId,
           let account = dataManager.getAccount(for: accountId) {
            switch account.accountType {
            case .credit:
                return "Charges & Payments"
            case .checking, .savings:
                return "Income & Expenses"
            case .investment:
                return "Deposits & Withdrawals"
            case .loan:
                return "Payments & Charges"
            }
        }
        return "Spending Trends"
    }
    
    private var incomeLegendLabel: String {
        if let accountId = selectedAccountId,
           let account = dataManager.getAccount(for: accountId),
           account.accountType == .credit {
            return "Payments"
        }
        return "Income"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(chartTitle)
                .font(.title2)
                .fontWeight(.bold)
            
            if !chartData.isEmpty {
                Chart(chartData) { data in
                    BarMark(
                        x: .value("Date", data.date, unit: .day),
                        y: .value("Expenses", data.expenses)
                    )
                    .foregroundStyle(.red.gradient)
                    .opacity(0.8)
                    
                    if data.income > 0 {
                        BarMark(
                            x: .value("Date", data.date, unit: .day),
                            y: .value(incomeLegendLabel, data.income)
                        )
                        .foregroundStyle(.green.gradient)
                        .opacity(0.8)
                    }
                }
                .frame(height: 250)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: max(1, chartData.count / 5))) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.secondary.opacity(0.3))
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
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
                .chartLegend(position: .top, spacing: 20) {
                    HStack(spacing: 20) {
                        Label("Expenses", systemImage: "minus.circle.fill")
                            .foregroundColor(.red)
                        Label(incomeLegendLabel, systemImage: "plus.circle.fill")
                            .foregroundColor(.green)
                    }
                    .font(.caption)
                }
                .chartBackground { chartProxy in
                    Color(NSColor.controlBackgroundColor)
                }
                .padding(.horizontal, 8)
            } else {
                VStack {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No data available")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct ContextAwareRecentTransactions: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    let selectedAccountId: String?
    
    private var recentTransactions: [Transaction] {
        let transactions = selectedAccountId != nil
            ? dataManager.getTransactions(for: selectedAccountId!)
            : dataManager.transactions
        
        let sorted = transactions.sorted { $0.formattedDate > $1.formattedDate }
        return Array(sorted.prefix(5))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Transactions")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                NavigationLink("View All") {
                    TransactionListView { _ in }
                }
            }
            
            if !recentTransactions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(recentTransactions) { transaction in
                        TransactionRowView(transaction: transaction)
                        
                        if transaction.id != recentTransactions.last?.id {
                            Divider()
                        }
                    }
                }
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                .shadow(radius: 1)
            } else {
                VStack {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No transactions available")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 100)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Existing Components from Original File
// (Keep the existing components that weren't replaced)

struct CategoryBreakdownView: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    @ObservedObject var dashboardService: DashboardDataService
    
    private var categoryData: [CategorySpending] {
        return dashboardService.categoryBreakdown.map { breakdown in
            CategorySpending(
                category: breakdown.category.name,
                amount: Double(truncating: breakdown.amount as NSDecimalNumber)
            )
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending by Category")
                .font(.title2)
                .fontWeight(.bold)
            
            if !categoryData.isEmpty {
                if #available(macOS 14.0, *) {
                    Chart(categoryData) { data in
                        SectorMark(
                            angle: .value("Amount", data.amount),
                            innerRadius: .ratio(0.5),
                            angularInset: 2
                        )
                        .foregroundStyle(colorForCategory(data.category))
                    }
                    .chartLegend(position: .trailing, alignment: .center)
                } else {
                    // Fallback for older macOS versions
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(categoryData.prefix(5)) { data in
                            HStack {
                                Circle()
                                    .fill(colorForCategory(data.category))
                                    .frame(width: 12, height: 12)
                                Text(data.category)
                                    .font(.caption)
                                Spacer()
                                Text(data.amount.formatAsCurrency())
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding()
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(8)
                }
            } else {
                VStack {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No category data available")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
    
    private func colorForCategory(_ categoryName: String) -> Color {
        if let breakdown = dashboardService.categoryBreakdown.first(where: { $0.category.name == categoryName }),
           let color = Color(hex: breakdown.category.color) {
            return color
        }
        return Color.forCategory(categoryName) // Fallback to existing method
    }
}

// TopMerchantsView is implemented separately in Components/TopMerchantsView.swift

// MARK: - Data Models
struct DailySpending: Identifiable {
    let id: UUID
    let date: Date
    let expenses: Double
    let income: Double
    
    init(date: Date, expenses: Double, income: Double) {
        self.id = UUID()
        self.date = date
        self.expenses = expenses
        self.income = income
    }
}

struct CategorySpending: Identifiable {
    let id: UUID
    let category: String
    let amount: Double
    
    init(category: String, amount: Double) {
        self.id = UUID()
        self.category = category
        self.amount = amount
    }
}

#Preview {
    OverviewView()
        .environmentObject(FinancialDataManager())
}
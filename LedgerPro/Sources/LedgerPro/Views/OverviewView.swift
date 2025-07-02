import SwiftUI
import Charts

struct OverviewView: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Quick Stats Grid
                QuickStatsGrid()
                
                // Charts Section
                HStack(spacing: 20) {
                    // Spending Chart
                    SpendingChartView()
                        .frame(minHeight: 300)
                    
                    // Category Breakdown
                    CategoryBreakdownView()
                        .frame(minWidth: 300, minHeight: 300)
                }
                
                // Recent Transactions
                RecentTransactionsView()
            }
            .padding()
        }
        .navigationTitle("Financial Overview")
    }
}

struct QuickStatsGrid: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
            StatCard(
                title: "Total Income",
                value: dataManager.summary.formattedIncome,
                change: dataManager.summary.incomeChange ?? "+0%",
                color: .green,
                icon: "arrow.up.circle.fill"
            )
            
            StatCard(
                title: "Total Expenses",
                value: dataManager.summary.formattedExpenses,
                change: dataManager.summary.expensesChange ?? "+0%",
                color: .red,
                icon: "arrow.down.circle.fill"
            )
            
            StatCard(
                title: "Net Savings",
                value: dataManager.summary.formattedSavings,
                change: dataManager.summary.savingsChange ?? "+0%",
                color: dataManager.summary.netSavings >= 0 ? .green : .red,
                icon: "banknote.fill"
            )
            
            StatCard(
                title: "Available Balance",
                value: dataManager.summary.formattedBalance,
                change: dataManager.summary.balanceChange ?? "+0%",
                color: .blue,
                icon: "banknote.fill"
            )
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let change: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
                Text(change)
                    .font(.caption)
                    .foregroundColor(changeColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(changeColor.opacity(0.1))
                    .cornerRadius(4)
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
    
    private var changeColor: Color {
        if change.starts(with: "+") {
            return .green
        } else if change.starts(with: "-") {
            return .red
        }
        return .secondary
    }
}

struct SpendingChartView: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    
    private var chartData: [DailySpending] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Group transactions by date
        let grouped = Dictionary(grouping: dataManager.transactions) { transaction in
            transaction.date
        }
        
        // Create daily spending data and limit to recent dates for readability
        let dailyData = grouped.compactMap { date, transactions -> DailySpending? in
            guard let parsedDate = dateFormatter.date(from: date) else { return nil }
            
            let expenses = transactions.filter { $0.amount < 0 }.reduce(0) { $0 + abs($1.amount) }
            
            // Exclude payments and transfers from income calculation
            let income = transactions.filter { $0.isActualIncome }.reduce(0) { $0 + $1.amount }
            
            return DailySpending(
                date: parsedDate,
                expenses: expenses,
                income: income
            )
        }
        
        // Sort and limit for better readability
        let sortedData = dailyData.sorted { $0.date < $1.date }
        
        // If we have data, show recent portion or all data if less than 30 days total
        if sortedData.count <= 30 {
            return sortedData // Show all data if reasonable amount
        } else {
            // Show last 20 data points for better chart readability
            return Array(sortedData.suffix(20))
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Trends")
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
                    
                    BarMark(
                        x: .value("Date", data.date, unit: .day),
                        y: .value("Income", data.income)
                    )
                    .foregroundStyle(.green.gradient)
                    .opacity(0.8)
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
                        Label("Income", systemImage: "plus.circle.fill")
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
                    Text("No spending data available")
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

struct CategoryBreakdownView: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    
    private var categoryData: [CategorySpending] {
        let expenses = dataManager.transactions.filter { $0.amount < 0 }
        let grouped = Dictionary(grouping: expenses) { $0.category }
        
        return grouped.map { category, transactions in
            let total = transactions.reduce(0) { $0 + abs($1.amount) }
            return CategorySpending(category: category, amount: total)
        }.sorted { $0.amount > $1.amount }
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
                        .foregroundStyle(Color.forCategory(data.category))
                    }
                    .chartLegend(position: .trailing, alignment: .center)
                } else {
                    // Fallback for older macOS versions
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(categoryData.prefix(5)) { data in
                            HStack {
                                Circle()
                                    .fill(Color.forCategory(data.category))
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
}

struct RecentTransactionsView: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    
    private var recentTransactions: [Transaction] {
        let sorted = dataManager.transactions.sorted { $0.formattedDate > $1.formattedDate }
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
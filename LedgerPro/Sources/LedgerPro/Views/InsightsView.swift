import SwiftUI
import Charts

struct InsightsView: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    @EnvironmentObject private var apiService: APIService
    @State private var selectedInsightTab: InsightTab = .overview
    @State private var isGeneratingInsights = false
    @State private var aiInsights: [AIInsight] = []
    
    enum InsightTab: String, CaseIterable {
        case overview = "Overview"
        case spending = "Spending"
        case trends = "Trends"
        case ai = "AI Analysis"
        
        var systemImage: String {
            switch self {
            case .overview: return "chart.bar.fill"
            case .spending: return "creditcard.fill"
            case .trends: return "chart.line.uptrend.xyaxis"
            case .ai: return "brain"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Picker
            Picker("Insight Type", selection: $selectedInsightTab) {
                ForEach(InsightTab.allCases, id: \.self) { tab in
                    Label(tab.rawValue, systemImage: tab.systemImage)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            ScrollView {
                switch selectedInsightTab {
                case .overview:
                    InsightOverviewView()
                case .spending:
                    SpendingInsightsView()
                case .trends:
                    TrendInsightsView()
                case .ai:
                    AIInsightsView(
                        insights: aiInsights,
                        isGenerating: isGeneratingInsights,
                        onGenerateInsights: generateAIInsights
                    )
                }
            }
        }
        .navigationTitle("Financial Insights")
        .onAppear {
            loadStoredInsights()
        }
    }
    
    private func generateAIInsights() {
        isGeneratingInsights = true
        
        // Simulate AI analysis (in real app, this would call MCP servers)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            aiInsights = generateMockInsights()
            isGeneratingInsights = false
            saveInsights()
        }
    }
    
    private func generateMockInsights() -> [AIInsight] {
        let summary = dataManager.summary
        var insights: [AIInsight] = []
        
        // Spending Analysis
        if summary.totalExpenses > summary.totalIncome * 0.8 {
            insights.append(AIInsight(
                type: .warning,
                title: "High Spending Alert",
                description: "Your expenses are \(Int((summary.totalExpenses / summary.totalIncome) * 100))% of your income. Consider reviewing discretionary spending.",
                confidence: 0.9,
                category: "Spending"
            ))
        }
        
        // Savings Opportunity
        if summary.netSavings > 0 {
            insights.append(AIInsight(
                type: .positive,
                title: "Great Savings Performance",
                description: "You're saving \(summary.formattedSavings) this period. Consider investing in a high-yield savings account or index funds.",
                confidence: 0.85,
                category: "Savings"
            ))
        }
        
        // Category Analysis
        let categorySpending = analyzeCategorySpending()
        if let topCategory = categorySpending.first, topCategory.percentage > 30 {
            insights.append(AIInsight(
                type: .info,
                title: "Top Spending Category",
                description: "\(topCategory.category) accounts for \(Int(topCategory.percentage))% of your expenses (\(topCategory.formattedAmount)). This is your largest expense category.",
                confidence: 0.95,
                category: "Categories"
            ))
        }
        
        // Transaction Patterns
        let transactionCount = dataManager.transactions.count
        if transactionCount > 100 {
            insights.append(AIInsight(
                type: .info,
                title: "Transaction Volume Analysis",
                description: "You have \(transactionCount) transactions analyzed. Your average transaction is \(averageTransactionAmount()).",
                confidence: 0.8,
                category: "Patterns"
            ))
        }
        
        return insights
    }
    
    private func analyzeCategorySpending() -> [CategorySpendingAnalysis] {
        let expenses = dataManager.transactions.filter { $0.amount < 0 }
        let totalExpenses = expenses.reduce(0) { $0 + abs($1.amount) }
        
        let grouped = Dictionary(grouping: expenses) { $0.category }
        
        return grouped.map { category, transactions in
            let amount = transactions.reduce(0) { $0 + abs($1.amount) }
            let percentage = totalExpenses > 0 ? (amount / totalExpenses) * 100 : 0
            
            return CategorySpendingAnalysis(
                category: category,
                amount: amount,
                percentage: percentage
            )
        }.sorted { $0.amount > $1.amount }
    }
    
    private func averageTransactionAmount() -> String {
        let total = dataManager.transactions.reduce(0) { $0 + abs($1.amount) }
        let average = total / Double(dataManager.transactions.count)
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: average)) ?? "$0.00"
    }
    
    private func loadStoredInsights() {
        if let data = UserDefaults.standard.data(forKey: "ai_insights") {
            do {
                aiInsights = try JSONDecoder().decode([AIInsight].self, from: data)
            } catch {
                print("Failed to load insights: \(error)")
            }
        }
    }
    
    private func saveInsights() {
        do {
            let data = try JSONEncoder().encode(aiInsights)
            UserDefaults.standard.set(data, forKey: "ai_insights")
        } catch {
            print("Failed to save insights: \(error)")
        }
    }
}

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
            MetricCard(
                title: "Savings Rate",
                value: String(format: "%.1f%%", savingsRate),
                trend: savingsRate >= 20 ? .positive : savingsRate >= 10 ? .neutral : .negative,
                icon: "banknote.fill"
            )
            
            MetricCard(
                title: "Expense Ratio",
                value: String(format: "%.1f%%", expenseRatio),
                trend: expenseRatio <= 70 ? .positive : expenseRatio <= 85 ? .neutral : .negative,
                icon: "chart.pie.fill"
            )
            
            MetricCard(
                title: "Avg Transaction",
                value: averageTransactionAmount(),
                trend: .neutral,
                icon: "arrow.left.arrow.right"
            )
            
            MetricCard(
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

struct MetricCard: View {
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
            Text("Spending Distribution")
                .font(.title2)
                .fontWeight(.bold)
            
            if !categoryData.isEmpty {
                Chart(categoryData) { data in
                    BarMark(
                        x: .value("Category", data.category),
                        y: .value("Amount", data.amount)
                    )
                    .foregroundStyle(.blue.gradient)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(preset: .aligned, values: .automatic(desiredCount: 6)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
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

// Placeholder views for other insight tabs
struct SpendingInsightsView: View {
    var body: some View {
        VStack {
            Text("Spending Insights")
                .font(.title)
            Text("Detailed spending analysis coming soon...")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct TrendInsightsView: View {
    var body: some View {
        VStack {
            Text("Trend Analysis")
                .font(.title)
            Text("Historical trend analysis coming soon...")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct AIInsightsView: View {
    let insights: [AIInsight]
    let isGenerating: Bool
    let onGenerateInsights: () -> Void
    
    var body: some View {
        LazyVStack(spacing: 16) {
            HStack {
                Text("AI-Powered Insights")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: onGenerateInsights) {
                    if isGenerating {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("Generate Insights")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isGenerating)
            }
            
            if insights.isEmpty && !isGenerating {
                VStack(spacing: 12) {
                    Image(systemName: "brain")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No AI insights generated yet")
                        .foregroundColor(.secondary)
                    Text("Click 'Generate Insights' to analyze your financial data")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            } else {
                ForEach(insights) { insight in
                    AIInsightCard(insight: insight)
                }
            }
        }
        .padding()
    }
}

struct AIInsightCard: View {
    let insight: AIInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: insight.type.systemImage)
                    .foregroundColor(insight.type.color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .font(.headline)
                    
                    Text(insight.category)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(insight.type.color.opacity(0.2))
                        .foregroundColor(insight.type.color)
                        .cornerRadius(4)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Confidence")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(Int(insight.confidence * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            
            Text(insight.description)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(insight.type.color.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(insight.type.color.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(8)
    }
}

// MARK: - Supporting Models
struct AIInsight: Identifiable, Codable {
    let id: UUID
    let type: InsightType
    let title: String
    let description: String
    let confidence: Double
    let category: String
    
    init(type: InsightType, title: String, description: String, confidence: Double, category: String) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.description = description
        self.confidence = confidence
        self.category = category
    }
    
    enum InsightType: String, Codable {
        case positive, warning, info
        
        var color: Color {
            switch self {
            case .positive: return .green
            case .warning: return .orange
            case .info: return .blue
            }
        }
        
        var systemImage: String {
            switch self {
            case .positive: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
}

struct CategorySpendingAnalysis {
    let category: String
    let amount: Double
    let percentage: Double
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

#Preview {
    NavigationView {
        InsightsView()
            .environmentObject(FinancialDataManager())
            .environmentObject(APIService())
    }
}
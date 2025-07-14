import SwiftUI
import Charts

struct InsightsView: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    @EnvironmentObject private var apiService: APIService
    @EnvironmentObject private var categoryService: CategoryService
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
            // Enhanced Tab Picker
            VStack(spacing: 16) {
                HStack {
                    Text("Financial Insights")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: { 
                        generateAIInsights() 
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: isGeneratingInsights ? "arrow.clockwise" : "sparkles")
                                .font(.caption)
                            Text(isGeneratingInsights ? "Analyzing..." : "AI Insights")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(isGeneratingInsights)
                }
                
                // Custom Tab Picker
                HStack(spacing: 0) {
                    ForEach(InsightTab.allCases, id: \.self) { tab in
                        Button(action: { selectedInsightTab = tab }) {
                            VStack(spacing: 8) {
                                Image(systemName: tab.systemImage)
                                    .font(.title3)
                                    .foregroundColor(selectedInsightTab == tab ? .white : .secondary)
                                
                                Text(tab.rawValue)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(selectedInsightTab == tab ? .white : .secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedInsightTab == tab ? 
                                          LinearGradient(
                                            gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                          ) : 
                                          LinearGradient(
                                            gradient: Gradient(colors: [Color.clear]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                          )
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(NSColor.windowBackgroundColor))
            
            ScrollView {
                switch selectedInsightTab {
                case .overview:
                    InsightOverviewView()
                        .environmentObject(categoryService)
                case .spending:
                    SpendingInsightsView()
                        .environmentObject(categoryService)
                case .trends:
                    TrendInsightsView()
                        .environmentObject(categoryService)
                case .ai:
                    AIInsightsView(
                        insights: aiInsights,
                        isGenerating: isGeneratingInsights,
                        onGenerateInsights: generateAIInsights
                    )
                }
            }
        }
        .navigationTitle("")
        .onAppear {
            loadStoredInsights()
            Task {
                if categoryService.categories.isEmpty {
                    await categoryService.loadCategories()
                }
            }
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
        
        return grouped.map { categoryName, transactions in
            let amount = transactions.reduce(0) { $0 + abs($1.amount) }
            let percentage = totalExpenses > 0 ? (amount / totalExpenses) * 100 : 0
            
            // Try to find matching category from CategoryService for enhanced data
            let categoryObject = categoryService.categories.first { $0.name == categoryName }
            
            return CategorySpendingAnalysis(
                category: categoryName,
                amount: amount,
                percentage: percentage,
                categoryObject: categoryObject
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
                AppLogger.shared.error("Failed to load insights: \(error)")
            }
        }
    }
    
    private func saveInsights() {
        do {
            let data = try JSONEncoder().encode(aiInsights)
            UserDefaults.standard.set(data, forKey: "ai_insights")
        } catch {
            AppLogger.shared.error("Failed to save insights: \(error)")
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
    @EnvironmentObject private var dataManager: FinancialDataManager
    @EnvironmentObject private var categoryService: CategoryService
    @State private var selectedPeriod: SpendingPeriod = .thisMonth
    @State private var selectedCategory: CategorySpendingAnalysis?
    @State private var showingCategoryDetail = false
    
    enum SpendingPeriod: String, CaseIterable {
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case last3Months = "Last 3 Months"
        case thisYear = "This Year"
    }
    
    var body: some View {
        LazyVStack(spacing: 24) {
            // Period Selector
            VStack(spacing: 16) {
                HStack {
                    Text("Spending Analysis")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(SpendingPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 150)
                }
                
                // Total spending card
                TotalSpendingCard(period: selectedPeriod)
            }
            
            // Enhanced Category Charts
            CategorySpendingCharts(
                selectedCategory: $selectedCategory,
                showingDetail: $showingCategoryDetail
            )
            
            // Top Categories List
            TopCategoriesList(
                selectedCategory: $selectedCategory,
                showingDetail: $showingCategoryDetail
            )
        }
        .padding()
        .sheet(item: $selectedCategory) { category in
            CategoryDetailInsightsView(category: category)
        }
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

// MARK: - Enhanced Chart Components

struct TotalSpendingCard: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    let period: SpendingInsightsView.SpendingPeriod
    
    private var totalSpending: Double {
        let expenses = dataManager.transactions.filter { $0.amount < 0 }
        return expenses.reduce(0) { $0 + abs($1.amount) }
    }
    
    private var transactionCount: Int {
        return dataManager.transactions.filter { $0.amount < 0 }.count
    }
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Total Spending")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(formattedSpending)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("\(transactionCount) transactions • \(period.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.red.opacity(0.2), .red.opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.red)
            }
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var formattedSpending: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: totalSpending)) ?? "$0.00"
    }
}

struct CategorySpendingCharts: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    @EnvironmentObject private var categoryService: CategoryService
    @Binding var selectedCategory: CategorySpendingAnalysis?
    @Binding var showingDetail: Bool
    
    private var categoryData: [EnhancedCategorySpending] {
        let expenses = dataManager.transactions.filter { $0.amount < 0 }
        let grouped = Dictionary(grouping: expenses) { $0.category }
        
        let enhancedData = grouped.map { categoryName, transactions in
            let total = transactions.reduce(0) { $0 + abs($1.amount) }
            // Try exact match first
            let categoryObject = categoryService.categories.first { $0.name == categoryName }
                ?? categoryService.categories.first { $0.name.lowercased().contains(categoryName.lowercased()) }
                ?? categoryService.categories.first { categoryName.lowercased().contains($0.name.lowercased()) }
            AppLogger.shared.debug("Category: '\(categoryName)'")
            print("   Found object: \(categoryObject?.name ?? "NOT FOUND")")
            print("   Available categories containing this word:")
            for cat in categoryService.categories where cat.name.lowercased().contains(categoryName.lowercased()) {
                print("   - '\(cat.name)' (color: \(cat.color))")
            }
            
            if categoryObject == nil {
                AppLogger.shared.warning("Creating missing category: \(categoryName)")
                // You might want to create the category here or use a default
            }
            
            let categorySpending = EnhancedCategorySpending(
                category: categoryName,
                amount: total,
                categoryObject: categoryObject
            )
            
            AppLogger.shared.debug("Category: \(categoryName), Color: \(categorySpending.color), Icon: \(categorySpending.icon)")
            
            return categorySpending
        }
        
        let sortedData = enhancedData.sorted { $0.amount > $1.amount }
        
        // Debug logging for chart data
        print("🎨 INSIGHTS CHART DATA:")
        let allCategories = grouped.map { categoryName, transactions in
            let total = transactions.reduce(0) { $0 + abs($1.amount) }
            return (categoryName, total)
        }.sorted { $0.1 > $1.1 }
        print("All categories before filtering:")
        for (cat, amount) in allCategories {
            print("  - \(cat): $\(String(format: "%.2f", amount)) (\(String(format: "%.1f%%", amount/allCategories.map{$0.1}.reduce(0,+)*100)))")
        }
        print("All categories shown: \(allCategories.map{$0.0})")
        
        return sortedData
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Pie Chart (macOS 14.0+)
            if #available(macOS 14.0, *) {
                CategoryPieChart(data: categoryData)
            }
            
            // Enhanced Bar Chart
            EnhancedBarChart(data: categoryData)
        }
        .onAppear {
            print("📊 CategoryService has \(categoryService.categories.count) categories loaded")
            for cat in categoryService.categories.prefix(5) {
                print("  - \(cat.name): \(cat.color)")
            }
            
            // Force reload categories to get updated colors
            Task {
                do {
                    try await categoryService.reloadCategories()
                    print("✅ Categories reloaded with updated colors")
                } catch {
                    print("❌ Failed to reload categories: \(error)")
                }
            }
        }
    }
}

// FIXED: Pie chart interaction now working with DragGesture for precise click detection
// - Direct clicks on pie slices select categories via DragGesture with minimumDistance: 0
// - Legend items are clickable buttons that toggle category selection
// - Hover effects work on legend items
// - Click outside the donut or click same category to deselect
@available(macOS 14.0, *)
struct CategoryPieChart: View {
    let data: [EnhancedCategorySpending]
    @State private var hoveredCategory: String?
    
    var totalAmount: Double {
        data.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Breakdown")
                .font(.title2)
                .fontWeight(.bold)
            
            if !data.isEmpty {
                Chart(data, id: \.category) { item in
                    let _ = print("🎨 Rendering segment: \(item.category), Color: \(item.color)")
                    SectorMark(
                        angle: .value("Amount", item.amount),
                        innerRadius: .ratio(0.4),
                        angularInset: 5
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [item.color, item.color.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(hoveredCategory == nil || hoveredCategory == item.category ? 1.0 : 0.3)
                }
                .frame(height: 250)
                .contentShape(Rectangle())
                .overlay(
                    GeometryReader { geometry in
                        Color.clear
                            .contentShape(Rectangle())
                            .allowsHitTesting(true)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onEnded { value in
                                        let location = value.location
                                        print("🎯 TAP ON CHART at location: \(location)")
                                        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                                        let distance = sqrt(pow(location.x - center.x, 2) + pow(location.y - center.y, 2))
                                        print("📍 Center: \(center), Distance: \(distance)")
                                        
                                        // Check if within donut ring
                                        let outerRadius = min(geometry.size.width, geometry.size.height) * 0.45
                                        let innerRadius = outerRadius * 0.4
                                        
                                        if distance >= innerRadius && distance <= outerRadius {
                                            let angle = atan2(location.y - center.y, location.x - center.x)
                                            let degrees = angle * 180 / .pi
                                            let normalizedDegrees = degrees < 0 ? degrees + 360 : degrees
                                            let chartAngle = (normalizedDegrees + 90).truncatingRemainder(dividingBy: 360)
                                            
                                            print("📐 Chart angle: \(chartAngle)°")
                                            let tappedCategory = categoryForAngle(chartAngle)
                                            print("🎯 Tapped category: \(tappedCategory ?? "nil")")
                                            
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                if hoveredCategory == tappedCategory {
                                                    hoveredCategory = nil
                                                } else {
                                                    hoveredCategory = tappedCategory
                                                }
                                            }
                                        } else {
                                            print("🎯 Click outside donut ring")
                                        }
                                    }
                            )
                    }
                )
                .chartBackground { chartProxy in
                    // Center text display only
                    VStack(spacing: 4) {
                        if let hoveredCategory = hoveredCategory,
                           let selectedData = data.first(where: { $0.category == hoveredCategory }) {
                            Text(selectedData.category)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                            Text(selectedData.formattedAmount)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        } else {
                            Text("Total")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                            Text(NumberFormatter.currency.string(from: NSNumber(value: totalAmount)) ?? "$0.00")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.2), value: hoveredCategory)
                }
                
                // Enhanced Legend with click support
                CategoryLegend(data: data, hoveredCategory: $hoveredCategory)
            } else {
                Text("No spending data available")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func categoryForAngle(_ angle: Double) -> String? {
        // Calculate cumulative angles to determine which category is at the given angle
        let total = totalAmount
        var cumulativeAngle: Double = 0
        
        print("🔍 Looking for angle: \(angle)° in categories:")
        for item in data {
            let itemAngle = (item.amount / total) * 360
            let endAngle = cumulativeAngle + itemAngle
            print("  📊 \(item.category): \(cumulativeAngle)° to \(endAngle)° (size: \(itemAngle)°)")
            
            if angle >= cumulativeAngle && angle < endAngle {
                print("  ✅ Found match: \(item.category)")
                return item.category
            }
            cumulativeAngle += itemAngle
        }
        print("  ❌ No category found for angle \(angle)°")
        
        return nil
    }
}

struct CategoryLegend: View {
    let data: [EnhancedCategorySpending]
    @Binding var hoveredCategory: String?
    
    init(data: [EnhancedCategorySpending], hoveredCategory: Binding<String?> = .constant(nil)) {
        self.data = data
        self._hoveredCategory = hoveredCategory
    }
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ForEach(data) { item in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if hoveredCategory == item.category {
                            hoveredCategory = nil
                        } else {
                            hoveredCategory = item.category
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        // Enhanced icon with category icon
                        ZStack {
                            Circle()
                                .fill(item.color.opacity(0.2))
                                .frame(width: 20, height: 20)
                            
                            Image(systemName: item.icon)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(item.color)
                        }
                        
                        Text(item.shortName)
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundColor(hoveredCategory == nil || hoveredCategory == item.category ? .primary : .secondary)
                        
                        Spacer()
                        
                        Text(item.formattedAmount)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(hoveredCategory == nil || hoveredCategory == item.category ? .primary : .secondary)
                    }
                }
                .buttonStyle(.plain)
                .scaleEffect(hoveredCategory == item.category ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: hoveredCategory)
                .onHover { isHovering in
                    if isHovering && hoveredCategory != item.category {
                        hoveredCategory = item.category
                    }
                }
            }
        }
    }
}

struct EnhancedBarChart: View {
    let data: [EnhancedCategorySpending]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category Comparison")
                .font(.title2)
                .fontWeight(.bold)
            
            if !data.isEmpty {
                Chart(data, id: \.category) { item in
                    BarMark(
                        x: .value("Amount", item.amount),
                        y: .value("Category", item.shortName)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [item.color, item.color.opacity(0.7)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(6)
                }
                .frame(height: 300)
                .chartXAxis {
                    AxisMarks(position: .bottom) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2]))
                            .foregroundStyle(Color.secondary.opacity(0.3))
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(formatAmount(amount))
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let category = value.as(String.self),
                               let categoryData = data.first(where: { $0.shortName == category }) {
                                HStack(spacing: 4) {
                                    Image(systemName: categoryData.icon)
                                        .font(.system(size: 8, weight: .medium))
                                        .foregroundColor(categoryData.color)
                                    
                                    Text(category)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func formatAmount(_ amount: Double) -> String {
        if amount >= 1000 {
            return String(format: "$%.1fK", amount / 1000)
        } else {
            return String(format: "$%.0f", amount)
        }
    }
}

struct TopCategoriesList: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    @EnvironmentObject private var categoryService: CategoryService
    @Binding var selectedCategory: CategorySpendingAnalysis?
    @Binding var showingDetail: Bool
    
    private var categoryAnalysis: [CategorySpendingAnalysis] {
        let expenses = dataManager.transactions.filter { $0.amount < 0 }
        let totalExpenses = expenses.reduce(0) { $0 + abs($1.amount) }
        let grouped = Dictionary(grouping: expenses) { $0.category }
        
        return grouped.map { categoryName, transactions in
            let amount = transactions.reduce(0) { $0 + abs($1.amount) }
            let percentage = totalExpenses > 0 ? (amount / totalExpenses) * 100 : 0
            let categoryObject = categoryService.categories.first { $0.name == categoryName }
            
            return CategorySpendingAnalysis(
                category: categoryName,
                amount: amount,
                percentage: percentage,
                categoryObject: categoryObject
            )
        }.sorted { $0.amount > $1.amount }.prefix(8).map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Spending Categories")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVStack(spacing: 12) {
                ForEach(categoryAnalysis) { category in
                    CategorySpendingRow(
                        category: category,
                        onTap: {
                            selectedCategory = category
                            showingDetail = true
                        }
                    )
                }
            }
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct CategorySpendingRow: View {
    let category: CategorySpendingAnalysis
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Category Icon
                ZStack {
                    Circle()
                        .fill(category.color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: category.icon)
                        .font(.title3)
                        .foregroundColor(category.color)
                }
                
                // Category Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.category)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("\(String(format: "%.1f", category.percentage))% of spending")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Amount and Arrow
                VStack(alignment: .trailing, spacing: 4) {
                    Text(category.formattedAmount)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .background(Color.clear)
    }
}

struct CategoryDetailInsightsView: View {
    let category: CategorySpendingAnalysis
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Category Header
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(category.color.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: category.icon)
                            .font(.title)
                            .foregroundColor(category.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.category)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(category.formattedAmount)
                            .font(.title3)
                            .foregroundColor(category.color)
                    }
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                Text("Detailed category insights coming soon...")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Category Details")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CategorySpendingAnalysis: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
    let percentage: Double
    let categoryObject: Category?
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    var icon: String {
        return categoryObject?.icon ?? "circle.fill"
    }
    
    var color: Color {
        if let categoryObject = categoryObject,
           let color = Color(hex: categoryObject.color) {
            return color
        }
        return .gray
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

// MARK: - Color Hex Extension
extension Color {
    static func fromHex(_ hex: String) -> Color {
        // Use the existing hex initializer from Category model, fallback to gray
        return Color(hex: hex) ?? .gray
    }
}

#Preview {
    NavigationView {
        InsightsView()
            .environmentObject(FinancialDataManager())
            .environmentObject(APIService())
    }
}
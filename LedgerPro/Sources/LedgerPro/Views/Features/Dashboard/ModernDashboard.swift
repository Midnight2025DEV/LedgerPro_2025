import SwiftUI

/// Modern Dashboard - World-class financial command center
///
/// A premium dashboard experience that rivals Monarch Money with sophisticated
/// animations, glass morphism, and intelligent financial insights.
struct ModernDashboard: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    @State private var selectedTimeframe: Timeframe = .month
    @State private var showQuickActions = false
    @State private var scrollOffset: CGFloat = 0
    @State private var hasAppeared = false
    @State private var isLoading = true
    
    // Performance optimization
    @State private var visibleElements: Set<String> = []
    
    enum Timeframe: String, CaseIterable {
        case week = "7D"
        case month = "1M"
        case quarter = "3M"
        case year = "1Y"
        
        var displayName: String {
            switch self {
            case .week: return "This Week"
            case .month: return "This Month"
            case .quarter: return "This Quarter"
            case .year: return "This Year"
            }
        }
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            case .year: return 365
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background with subtle gradient
            backgroundGradient
            
            // Main content
            if isLoading {
                DashboardSkeleton()
                    .transition(.opacity)
            } else {
                dashboardContent
            }
            
            // Quick actions overlay
            QuickActionsButton(isExpanded: $showQuickActions)
                .offset(x: -20, y: -20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .onAppear {
            loadDashboardData()
        }
        .refreshable {
            await refreshDashboard()
        }
    }
    
    // MARK: - Background
    
    @ViewBuilder
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                DSColors.neutral.background,
                DSColors.neutral.backgroundSecondary,
                DSColors.primary.p50.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private var dashboardContent: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    // Hero section with parallax effect
                    heroSection
                        .offset(y: scrollOffset * 0.3) // Parallax effect
                        .scaleEffect(1 - scrollOffset * 0.0005) // Subtle scale
                    
                    // Greeting and timeframe selector
                    greetingSection
                        .padding(.top, DSSpacing.xl)
                    
                    // Quick stats grid
                    quickStatsSection
                        .padding(.top, DSSpacing.xl)
                    
                    // Insights section
                    insightsSection
                        .padding(.top, DSSpacing.xl)
                    
                    // Enhanced spending chart
                    spendingChartSection
                        .padding(.top, DSSpacing.xl)
                    
                    // Recent transactions preview
                    recentTransactionsSection
                        .padding(.top, DSSpacing.xl)
                    
                    // Bottom padding for floating button
                    Color.clear
                        .frame(height: 100)
                }
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
        }
        .opacity(hasAppeared ? 1.0 : 0.0)
        .offset(y: hasAppeared ? 0 : 20)
        .animation(DSAnimations.common.standardTransition, value: hasAppeared)
    }
    
    // MARK: - Hero Section
    
    @ViewBuilder
    private var heroSection: some View {
        VStack(spacing: 0) {
            BalanceHeroCard(
                balance: totalBalance,
                change: balanceChange,
                trend: balanceTrend,
                timeframe: selectedTimeframe
            )
            .padding(.horizontal, DSSpacing.xl)
            .onAppear {
                visibleElements.insert("hero")
            }
        }
        .background(
            // Subtle background effect
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 0)
                    .fill(
                        LinearGradient(
                            colors: [
                                DSColors.primary.p500.opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: geometry.size.height + 100)
                    .offset(y: -50)
            }
        )
    }
    
    // MARK: - Greeting Section
    
    @ViewBuilder
    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text(timeBasedGreeting)
                        .font(DSTypography.title.title2)
                        .foregroundColor(DSColors.neutral.text)
                    
                    Text("Here's your financial overview")
                        .font(DSTypography.body.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                }
                
                Spacer()
                
                // Timeframe selector
                TimeframePicker(selectedTimeframe: $selectedTimeframe)
            }
        }
        .padding(.horizontal, DSSpacing.xl)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                visibleElements.insert("greeting")
            }
        }
    }
    
    // MARK: - Quick Stats Section
    
    @ViewBuilder
    private var quickStatsSection: some View {
        QuickStatsGrid(
            income: monthlyIncome,
            expenses: monthlyExpenses,
            savings: monthlySavings,
            transactions: transactionCount,
            timeframe: selectedTimeframe,
            isVisible: visibleElements.contains("stats")
        )
        .padding(.horizontal, DSSpacing.xl)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                visibleElements.insert("stats")
            }
        }
    }
    
    // MARK: - Insights Section
    
    @ViewBuilder
    private var insightsSection: some View {
        if !insights.isEmpty {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                HStack {
                    Text("Smart Insights")
                        .font(DSTypography.title.title3)
                        .foregroundColor(DSColors.neutral.text)
                    
                    Spacer()
                    
                    Button("View All") {
                        // Navigate to insights
                    }
                    .font(DSTypography.body.medium)
                    .foregroundColor(DSColors.primary.main)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DSSpacing.lg) {
                        ForEach(insights.prefix(3), id: \.id) { insight in
                            InsightCard(insight: insight)
                                .frame(width: 280)
                        }
                    }
                    .padding(.horizontal, DSSpacing.xl)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    visibleElements.insert("insights")
                }
            }
        }
    }
    
    // MARK: - Spending Chart Section
    
    @ViewBuilder
    private var spendingChartSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            HStack {
                Text("Spending Trends")
                    .font(DSTypography.title.title3)
                    .foregroundColor(DSColors.neutral.text)
                
                Spacer()
                
                Button("Export") {
                    // Export functionality
                }
                .font(DSTypography.body.medium)
                .foregroundColor(DSColors.primary.main)
            }
            .padding(.horizontal, DSSpacing.xl)
            
            EnhancedSpendingChart(
                data: spendingData,
                timeframe: selectedTimeframe
            )
            .frame(height: 250)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                visibleElements.insert("chart")
            }
        }
    }
    
    // MARK: - Recent Transactions Section
    
    @ViewBuilder
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            HStack {
                Text("Recent Activity")
                    .font(DSTypography.title.title3)
                    .foregroundColor(DSColors.neutral.text)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to transactions
                }
                .font(DSTypography.body.medium)
                .foregroundColor(DSColors.primary.main)
            }
            .padding(.horizontal, DSSpacing.xl)
            
            LazyVStack(spacing: DSSpacing.sm) {
                ForEach(recentTransactions.prefix(5), id: \.id) { transaction in
                    RecentTransactionRow(transaction: transaction)
                        .padding(.horizontal, DSSpacing.xl)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                visibleElements.insert("transactions")
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var timeBasedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning!"
        case 12..<17: return "Good afternoon!"
        case 17..<22: return "Good evening!"
        default: return "Good evening!"
        }
    }
    
    private var totalBalance: Double {
        dataManager.summary.availableBalance
    }
    
    private var balanceChange: String {
        // Calculate balance change based on timeframe
        let change = calculateBalanceChange(for: selectedTimeframe)
        return change >= 0 ? "+\(change.formatAsPercentage())" : "\(change.formatAsPercentage())"
    }
    
    private var balanceTrend: [Double] {
        // Generate balance trend data for sparkline
        generateBalanceTrend(for: selectedTimeframe)
    }
    
    private var monthlyIncome: Double {
        dataManager.transactions
            .filter { $0.amount > 0 && $0.formattedDate >= startOfMonth }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var monthlyExpenses: Double {
        dataManager.transactions
            .filter { $0.amount < 0 && $0.formattedDate >= startOfMonth }
            .reduce(0) { $0 + abs($1.amount) }
    }
    
    private var monthlySavings: Double {
        monthlyIncome - monthlyExpenses
    }
    
    private var transactionCount: Int {
        dataManager.transactions
            .filter { $0.formattedDate >= startOfPeriod(selectedTimeframe) }
            .count
    }
    
    private var startOfMonth: Date {
        Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
    }
    
    private var insights: [FinancialInsight] {
        generateInsights()
    }
    
    private var spendingData: [SpendingDataPoint] {
        generateSpendingData(for: selectedTimeframe)
    }
    
    private var recentTransactions: [Transaction] {
        Array(dataManager.transactions
            .sorted { $0.formattedDate > $1.formattedDate }
            .prefix(10))
    }
    
    // MARK: - Helper Methods
    
    private func loadDashboardData() {
        // Simulate loading delay for smooth UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(DSAnimations.common.smoothFade) {
                isLoading = false
                hasAppeared = true
            }
        }
    }
    
    private func refreshDashboard() async {
        // Simulate refresh
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        await MainActor.run {
            withAnimation(DSAnimations.common.smoothFade) {
                // Refresh data
                dataManager.loadStoredData()
            }
        }
    }
    
    private func calculateBalanceChange(for timeframe: Timeframe) -> Double {
        // Simplified calculation - would be more sophisticated in real app
        Double.random(in: -10...15)
    }
    
    private func generateBalanceTrend(for timeframe: Timeframe) -> [Double] {
        // Generate sample trend data
        let baseBalance = totalBalance
        return (0..<timeframe.days).map { day in
            baseBalance + Double.random(in: -1000...1000) * Double(day) / Double(timeframe.days)
        }
    }
    
    private func startOfPeriod(_ timeframe: Timeframe) -> Date {
        Calendar.current.date(byAdding: .day, value: -timeframe.days, to: Date()) ?? Date()
    }
    
    private func generateInsights() -> [FinancialInsight] {
        // Generate AI-powered insights
        [
            FinancialInsight(
                id: "spending-up",
                type: .warning,
                title: "Spending increased 15%",
                description: "Your dining expenses are higher than usual this month",
                action: "Review dining budget",
                icon: "chart.line.uptrend.xyaxis"
            ),
            FinancialInsight(
                id: "savings-goal",
                type: .positive,
                title: "On track for savings goal",
                description: "You're 78% towards your monthly savings target",
                action: "View progress",
                icon: "target"
            ),
            FinancialInsight(
                id: "subscription",
                type: .neutral,
                title: "Unused subscription detected",
                description: "Netflix subscription shows no activity in 30 days",
                action: "Review subscriptions",
                icon: "tv.circle"
            )
        ]
    }
    
    private func generateSpendingData(for timeframe: Timeframe) -> [SpendingDataPoint] {
        // Generate sample spending data
        let days = timeframe.days
        return (0..<days).map { day in
            SpendingDataPoint(
                date: Calendar.current.date(byAdding: .day, value: -days + day, to: Date()) ?? Date(),
                amount: Double.random(in: 50...500),
                category: ["Food", "Transport", "Shopping", "Entertainment"].randomElement() ?? "Other"
            )
        }
    }
}

// MARK: - Supporting Types


struct SpendingDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
    let category: String
}

// MARK: - Timeframe Picker

struct TimeframePicker: View {
    @Binding var selectedTimeframe: ModernDashboard.Timeframe
    
    var body: some View {
        HStack(spacing: DSSpacing.xs) {
            ForEach(ModernDashboard.Timeframe.allCases, id: \.self) { timeframe in
                Button(timeframe.rawValue) {
                    withAnimation(DSAnimations.common.quickFeedback) {
                        selectedTimeframe = timeframe
                    }
                }
                .font(DSTypography.caption.regular)
                .foregroundColor(selectedTimeframe == timeframe ? .white : DSColors.neutral.textSecondary)
                .padding(.horizontal, DSSpacing.sm)
                .padding(.vertical, DSSpacing.xs)
                .background(
                    Capsule()
                        .fill(selectedTimeframe == timeframe ? DSColors.primary.main : Color.clear)
                )
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(DSColors.neutral.border, lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Recent Transaction Row

struct RecentTransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: DSSpacing.md) {
            // Category icon
            Circle()
                .fill(DSColors.category.color(for: transaction.category))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: categoryIcon)
                        .font(DSTypography.body.medium)
                        .foregroundColor(.white)
                )
            
            // Transaction details
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(transaction.description.components(separatedBy: " ").prefix(3).joined(separator: " "))
                    .font(DSTypography.body.medium)
                    .foregroundColor(DSColors.neutral.text)
                    .lineLimit(1)
                
                Text(relativeDateString)
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
            }
            
            Spacer()
            
            // Amount
            Text(transaction.displayAmount)
                .font(DSTypography.financial.currency)
                .foregroundColor(transaction.isExpense ? DSColors.error.main : DSColors.success.main)
        }
        .padding(DSSpacing.md)
        .background(.ultraThinMaterial)
        .cornerRadius(DSSpacing.radius.lg)
        .shadow(color: DSColors.neutral.n200, radius: 1, x: 0, y: 1)
    }
    
    private var categoryIcon: String {
        switch transaction.category {
        case "Food & Dining": return "fork.knife"
        case "Transportation": return "car.fill"
        case "Shopping": return "bag.fill"
        case "Entertainment": return "tv.fill"
        default: return "circle.fill"
        }
    }
    
    private var relativeDateString: String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(transaction.formattedDate) {
            return "Today"
        } else if calendar.isDateInYesterday(transaction.formattedDate) {
            return "Yesterday"
        } else {
            let days = calendar.dateComponents([.day], from: transaction.formattedDate, to: now).day ?? 0
            return "\(days) days ago"
        }
    }
}

// MARK: - Scroll Offset Preference

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    func onScrollOffsetChange(_ action: @escaping (CGFloat) -> Void) -> some View {
        self.background(
            GeometryReader { geometry in
                Color.clear
                    .preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geometry.frame(in: .named("scroll")).minY
                    )
            }
        )
        .onPreferenceChange(ScrollOffsetPreferenceKey.self, perform: action)
    }
}

// MARK: - Dashboard Skeleton

struct DashboardSkeleton: View {
    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            // Hero skeleton
            RoundedRectangle(cornerRadius: DSSpacing.radius.standard)
                .fill(.ultraThinMaterial)
                .frame(height: 200)
                .padding(.horizontal, DSSpacing.xl)
            
            // Stats grid skeleton
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DSSpacing.lg), count: 2), spacing: DSSpacing.lg) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: DSSpacing.radius.standard)
                        .fill(.ultraThinMaterial)
                        .frame(height: 120)
                }
            }
            .padding(.horizontal, DSSpacing.xl)
            
            Spacer()
        }
        .padding(.top, DSSpacing.xl)
    }
}

// MARK: - Preview

#Preview {
    ModernDashboard()
        .environmentObject(FinancialDataManager())
}
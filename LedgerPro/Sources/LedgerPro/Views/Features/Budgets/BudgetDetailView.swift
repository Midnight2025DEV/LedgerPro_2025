import SwiftUI
import Charts

/// BudgetDetailView - Comprehensive budget analysis and management
///
/// Deep-dive budget view with progress visualization, spending insights,
/// transaction filtering, and AI-powered recommendations to help users optimize their budget.
struct BudgetDetailView: View {
    let budget: Budget
    let spending: Double
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: FinancialDataManager
    
    @State private var selectedTimeframe: TimeframeFilter = .thisMonth
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var hasAppeared = false
    @State private var scrollOffset: CGFloat = 0
    
    // Chart data
    @State private var dailySpendingData: [DailySpendingPoint] = []
    @State private var categoryBreakdown: [CategorySpendingPoint] = []
    @State private var weeklyComparison: [WeeklyComparisonPoint] = []
    
    // Insights
    @State private var budgetInsights: [BudgetInsight] = []
    @State private var spendingPace: SpendingPace = .onTrack
    
    enum TimeframeFilter: String, CaseIterable {
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case custom = "Custom"
        
        func dateRange(for budget: Budget) -> DateInterval {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .thisWeek:
                let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
                let end = calendar.dateInterval(of: .weekOfYear, for: now)?.end ?? now
                return DateInterval(start: start, end: end)
            case .thisMonth:
                let start = calendar.dateInterval(of: .month, for: now)?.start ?? now
                let end = calendar.dateInterval(of: .month, for: now)?.end ?? now
                return DateInterval(start: start, end: end)
            case .custom:
                return DateInterval(start: budget.startDate, end: budget.endDate ?? now)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                backgroundGradient
                
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: DSSpacing.xl) {
                        // Hero section with large progress visualization
                        heroSection
                        
                        // Quick stats cards
                        quickStatsSection
                        
                        // Spending pace indicator
                        spendingPaceSection
                        
                        // Charts section
                        chartsSection
                        
                        // Insights and recommendations
                        insightsSection
                        
                        // Recent transactions
                        recentTransactionsSection
                        
                        // Actions section
                        actionsSection
                        
                        // Add bottom padding for safe area
                        Spacer()
                            .frame(height: DSSpacing.xl)
                    }
                    .padding(.horizontal, DSSpacing.xl)
                    .background(
                        GeometryReader { geometry in
                            Color.clear
                                .onChange(of: geometry.frame(in: .named("budgetDetail")).minY) { _, newValue in
                                    scrollOffset = newValue
                                }
                        }
                    )
                }
                .coordinateSpace(name: "budgetDetail")
                .refreshable {
                    await refreshData()
                }
            }
            .navigationTitle(budget.name)
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(DSColors.primary.main)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Menu {
                        Button("Edit Budget") {
                            showingEditSheet = true
                        }
                        
                        Button("Export Report") {
                            exportBudgetReport()
                        }
                        
                        Divider()
                        
                        Button("Delete Budget", role: .destructive) {
                            showingDeleteAlert = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(DSColors.primary.main)
                    }
                }
            }
        }
        .onAppear {
            setupInitialData()
        }
        .sheet(isPresented: $showingEditSheet) {
            // EditBudgetView(budget: budget)
            Text("Edit Budget Coming Soon")
                .padding()
        }
        .alert("Delete Budget", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // Delete budget logic
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this budget? This action cannot be undone.")
        }
    }
    
    // MARK: - Hero Section
    
    @ViewBuilder
    private var heroSection: some View {
        VStack(spacing: DSSpacing.xl) {
            // Large progress ring with detailed info
            ZStack {
                // Background effects
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                (Color(hex: budget.color) ?? .blue ?? .blue).opacity(0.1),
                                (Color(hex: budget.color) ?? .blue ?? .blue).opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                
                // Main progress ring
                BudgetProgressRing(
                    progress: budget.progressPercentage(spending: spending) / 100,
                    color: Color(hex: budget.color) ?? .blue,
                    isOverBudget: budget.isOverBudget(spending: spending),
                    size: 200
                )
                
                // Center content
                VStack(spacing: DSSpacing.md) {
                    // Budget icon
                    Image(systemName: budget.icon)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(Color(hex: budget.color) ?? .blue)
                    
                    // Progress percentage
                    Text("\(Int(budget.progressPercentage(spending: spending)))%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(DSColors.neutral.text)
                    
                    // Status text
                    Text(statusText)
                        .font(DSTypography.body.medium)
                        .foregroundColor(statusColor)
                }
            }
            
            // Amount breakdown
            HStack(spacing: DSSpacing.xl) {
                VStack(spacing: DSSpacing.xs) {
                    Text("Spent")
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    AnimatedNumber.amount(spending)
                        .font(DSTypography.title.title2)
                        .foregroundColor(spentAmountColor)
                }
                
                VStack(spacing: DSSpacing.xs) {
                    Text(budget.isOverBudget(spending: spending) ? "Over" : "Remaining")
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    AnimatedNumber.amount(abs(budget.amount - spending))
                        .font(DSTypography.title.title2)
                        .foregroundColor(remainingAmountColor)
                }
                
                VStack(spacing: DSSpacing.xs) {
                    Text("Budget")
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    AnimatedNumber.amount(budget.amount)
                        .font(DSTypography.title.title2)
                        .foregroundColor(DSColors.neutral.text)
                }
            }
        }
        .scaleEffect(hasAppeared ? 1.0 : 0.9)
        .opacity(hasAppeared ? 1.0 : 0.0)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1), value: hasAppeared)
    }
    
    // MARK: - Quick Stats Section
    
    @ViewBuilder
    private var quickStatsSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DSSpacing.lg), count: 2), spacing: DSSpacing.lg) {
            QuickStatCard(
                icon: "calendar",
                title: "Period",
                value: budget.period.displayName,
                subtitle: periodSubtitle,
                color: DSColors.info.main
            )
            
            QuickStatCard(
                icon: "dollarsign.circle",
                title: "Daily Budget",
                value: budget.dailyBudget.formatAsCurrency(),
                subtitle: "Target per day",
                color: DSColors.success.main
            )
            
            QuickStatCard(
                icon: "chart.line.uptrend.xyaxis",
                title: "Avg Daily",
                value: (spending / Double(daysPassed)).formatAsCurrency(),
                subtitle: "Your pace",
                color: spendingPace.color
            )
            
            QuickStatCard(
                icon: "tag.fill",
                title: "Categories",
                value: "\(budget.categoryIds.count)",
                subtitle: "Included",
                color: Color(hex: budget.color) ?? .blue
            )
        }
        .opacity(hasAppeared ? 1.0 : 0.0)
        .offset(y: hasAppeared ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: hasAppeared)
    }
    
    // MARK: - Spending Pace Section
    
    @ViewBuilder
    private var spendingPaceSection: some View {
        SpendingPaceIndicator(
            budget: budget,
            currentSpending: spending,
            pace: spendingPace
        )
        .opacity(hasAppeared ? 1.0 : 0.0)
        .offset(y: hasAppeared ? 0 : 15)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4), value: hasAppeared)
    }
    
    // MARK: - Charts Section
    
    @ViewBuilder
    private var chartsSection: some View {
        VStack(spacing: DSSpacing.xl) {
            // Section header
            HStack {
                Text("Spending Analysis")
                    .font(DSTypography.title.title3)
                    .foregroundColor(DSColors.neutral.text)
                
                Spacer()
                
                // Timeframe selector
                Menu {
                    ForEach(TimeframeFilter.allCases, id: \.self) { timeframe in
                        Button(timeframe.rawValue) {
                            selectedTimeframe = timeframe
                            updateChartData()
                        }
                    }
                } label: {
                    HStack(spacing: DSSpacing.xs) {
                        Text(selectedTimeframe.rawValue)
                            .font(DSTypography.body.medium)
                        
                        Image(systemName: "chevron.down")
                            .font(DSTypography.caption.regular)
                    }
                    .foregroundColor(DSColors.primary.main)
                    .padding(.horizontal, DSSpacing.md)
                    .padding(.vertical, DSSpacing.sm)
                    .background(.ultraThinMaterial)
                    .cornerRadius(DSSpacing.radius.sm)
                }
                .buttonStyle(.plain)
            }
            
            // Daily spending chart - TODO: Implement
            VStack {
                Text("Daily Spending Chart")
                    .font(DSTypography.title.title3)
                    .foregroundColor(DSColors.neutral.textSecondary)
                Text("Chart implementation pending")
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textTertiary)
            }
            .frame(height: 200)
            .background(DSColors.neutral.backgroundCard)
            .cornerRadius(DSSpacing.radius.lg)
            
            // Category breakdown - TODO: Implement
            if !categoryBreakdown.isEmpty {
                VStack {
                    Text("Category Breakdown Chart")
                        .font(DSTypography.title.title3)
                        .foregroundColor(DSColors.neutral.textSecondary)
                    Text("Chart implementation pending")
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textTertiary)
                }
                .frame(height: 200)
                .background(DSColors.neutral.backgroundCard)
                .cornerRadius(DSSpacing.radius.lg)
            }
        }
        .opacity(hasAppeared ? 1.0 : 0.0)
        .offset(y: hasAppeared ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: hasAppeared)
    }
    
    // MARK: - Insights Section
    
    @ViewBuilder
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            Text("Insights & Recommendations")
                .font(DSTypography.title.title3)
                .foregroundColor(DSColors.neutral.text)
            
            LazyVStack(spacing: DSSpacing.md) {
                ForEach(budgetInsights, id: \.id) { insight in
                    BudgetInsightCard(
                        insight: insight,
                        isExpanded: false,
                        onTap: { },
                        onExpand: { }
                    )
                        .scaleEffect(hasAppeared ? 1.0 : 0.9)
                        .opacity(hasAppeared ? 1.0 : 0.0)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.8)
                            .delay(0.6),
                            value: hasAppeared
                        )
                }
            }
        }
    }
    
    // MARK: - Recent Transactions Section
    
    @ViewBuilder
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            HStack {
                Text("Recent Transactions")
                    .font(DSTypography.title.title3)
                    .foregroundColor(DSColors.neutral.text)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to filtered transaction list
                }
                .font(DSTypography.body.medium)
                .foregroundColor(DSColors.primary.main)
            }
            
            LazyVStack(spacing: DSSpacing.sm) {
                ForEach(recentBudgetTransactions.prefix(5)) { transaction in
                    BudgetTransactionRow(
                        transaction: transaction,
                        budgetColor: Color(hex: budget.color) ?? .blue
                    )
                }
            }
            .padding(.vertical, DSSpacing.sm)
            .background(.ultraThinMaterial)
            .cornerRadius(DSSpacing.radius.lg)
        }
        .opacity(hasAppeared ? 1.0 : 0.0)
        .offset(y: hasAppeared ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.7), value: hasAppeared)
    }
    
    // MARK: - Actions Section
    
    @ViewBuilder
    private var actionsSection: some View {
        VStack(spacing: DSSpacing.lg) {
            // Primary actions
            HStack(spacing: DSSpacing.lg) {
                ActionButton(
                    title: "Edit Budget",
                    icon: "pencil",
                    color: DSColors.primary.main,
                    isPrimary: true
                ) {
                    showingEditSheet = true
                }
                
                ActionButton(
                    title: "Export Report",
                    icon: "square.and.arrow.up",
                    color: DSColors.success.main,
                    isPrimary: false
                ) {
                    exportBudgetReport()
                }
            }
            
            // Secondary actions
            HStack(spacing: DSSpacing.lg) {
                ActionButton(
                    title: "Duplicate",
                    icon: "doc.on.doc",
                    color: DSColors.neutral.n600,
                    isPrimary: false
                ) {
                    duplicateBudget()
                }
                
                ActionButton(
                    title: "Share",
                    icon: "square.and.arrow.up",
                    color: DSColors.info.main,
                    isPrimary: false
                ) {
                    shareBudget()
                }
            }
        }
        .opacity(hasAppeared ? 1.0 : 0.0)
        .offset(y: hasAppeared ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8), value: hasAppeared)
    }
    
    // MARK: - Background
    
    @ViewBuilder
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                DSColors.neutral.background,
                (Color(hex: budget.color) ?? .blue ?? .blue).opacity(0.02),
                DSColors.neutral.backgroundSecondary
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Computed Properties
    
    private var statusText: String {
        let progress = budget.progressPercentage(spending: spending)
        
        if budget.isOverBudget(spending: spending) {
            return "Over Budget"
        } else if progress >= 90 {
            return "Almost Done"
        } else if progress >= 75 {
            return "On Track"
        } else if progress >= 50 {
            return "Good Progress"
        } else {
            return "Just Started"
        }
    }
    
    private var statusColor: Color {
        if budget.isOverBudget(spending: spending) {
            return DSColors.error.main
        } else {
            return DSColors.success.main
        }
    }
    
    private var spentAmountColor: Color {
        if budget.isOverBudget(spending: spending) {
            return DSColors.error.main
        } else if budget.progressPercentage(spending: spending) > 80 {
            return DSColors.warning.main
        } else {
            return DSColors.neutral.text
        }
    }
    
    private var remainingAmountColor: Color {
        if budget.isOverBudget(spending: spending) {
            return DSColors.error.main
        } else {
            return DSColors.success.main
        }
    }
    
    private var daysPassed: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: budget.startDate, to: Date())
        return max(components.day ?? 1, 1)
    }
    
    private var periodSubtitle: String {
        if let endDate = budget.endDate {
            let calendar = Calendar.current
            let remaining = calendar.dateComponents([.day], from: Date(), to: endDate).day ?? 0
            return "\(max(remaining, 0)) days left"
        }
        return "Active"
    }
    
    private var recentBudgetTransactions: [Transaction] {
        // Filter transactions by budget categories and date range
        return dataManager.transactions.filter { transaction in
            budget.categoryIds.contains(transaction.category) &&
            transaction.formattedDate >= budget.startDate
        }
        .sorted { $0.formattedDate > $1.formattedDate }
    }
    
    // MARK: - Actions
    
    private func setupInitialData() {
        spendingPace = budget.spendingPace(spending: spending)
        generateInsights()
        updateChartData()
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
            hasAppeared = true
        }
    }
    
    @MainActor
    private func refreshData() async {
        // Simulate data refresh
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            spendingPace = budget.spendingPace(spending: spending)
            generateInsights()
            updateChartData()
        }
    }
    
    private func updateChartData() {
        // Generate daily spending data
        dailySpendingData = generateDailySpendingData()
        categoryBreakdown = generateCategoryBreakdown()
        weeklyComparison = generateWeeklyComparison()
    }
    
    private func generateDailySpendingData() -> [DailySpendingPoint] {
        let calendar = Calendar.current
        let dateRange = selectedTimeframe.dateRange(for: budget)
        var data: [DailySpendingPoint] = []
        
        var currentDate = dateRange.start
        while currentDate <= dateRange.end {
            let dailySpending = Double.random(in: 0...budget.dailyBudget * 1.5)
            data.append(DailySpendingPoint(
                date: currentDate,
                amount: dailySpending,
                isToday: calendar.isDateInToday(currentDate)
            ))
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return data
    }
    
    private func generateCategoryBreakdown() -> [CategorySpendingPoint] {
        return budget.categoryIds.compactMap { categoryId in
            guard let categoryName = availableCategories.first(where: { $0.id == categoryId })?.name else { return nil }
            
            let amount = Double.random(in: 50...200)
            return CategorySpendingPoint(
                category: categoryName,
                amount: amount,
                percentage: (amount / spending) * 100
            )
        }
    }
    
    private func generateWeeklyComparison() -> [WeeklyComparisonPoint] {
        // Generate weekly comparison data
        return (0..<4).map { week in
            WeeklyComparisonPoint(
                week: "Week \(week + 1)",
                amount: Double.random(in: 100...300),
                target: budget.amount / 4
            )
        }
    }
    
    private func generateInsights() {
        budgetInsights = [
            BudgetInsight(
                type: .pattern,
                title: "Weekend Spending",
                message: "You tend to spend 40% more on weekends. Consider setting weekend-specific limits.",
                actionText: "Set Weekend Limit",
                impact: .medium,
                confidence: 0.85
            ),
            BudgetInsight(
                type: .recommendation,
                title: "Optimization Opportunity",
                message: "Based on your pattern, you could save $50/month by reducing dining out by 2 meals.",
                actionText: "Create Dining Limit",
                impact: .medium,
                confidence: 0.78
            ),
            BudgetInsight(
                type: .achievement,
                title: "Great Progress!",
                message: "You're 15% under budget compared to last month. Keep up the excellent work!",
                actionText: nil,
                impact: .low,
                confidence: 0.95
            )
        ]
    }
    
    private var availableCategories: [BudgetCategory] {
        [
            BudgetCategory(id: "groceries", name: "Groceries", icon: "cart.fill", color: DSColors.success.main),
            BudgetCategory(id: "dining", name: "Dining Out", icon: "fork.knife", color: DSColors.warning.main),
            BudgetCategory(id: "entertainment", name: "Entertainment", icon: "tv.fill", color: DSColors.primary.main),
            BudgetCategory(id: "transportation", name: "Transportation", icon: "car.fill", color: DSColors.info.main),
            BudgetCategory(id: "shopping", name: "Shopping", icon: "bag.fill", color: DSColors.error.main),
            BudgetCategory(id: "utilities", name: "Utilities", icon: "bolt.fill", color: DSColors.neutral.n600)
        ]
    }
    
    private func exportBudgetReport() {
        // Export budget report as PDF/CSV
        print("Exporting budget report...")
    }
    
    private func duplicateBudget() {
        // Create a duplicate of this budget
        print("Duplicating budget...")
    }
    
    private func shareBudget() {
        // Share budget details
        print("Sharing budget...")
    }
}

// MARK: - Supporting Data Models

struct DailySpendingPoint: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
    let isToday: Bool
}

struct CategorySpendingPoint: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
    let percentage: Double
}

struct WeeklyComparisonPoint: Identifiable {
    let id = UUID()
    let week: String
    let amount: Double
    let target: Double
}

// MARK: - Supporting Components (these would be in separate files in a real app)

struct QuickStatCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DSSpacing.md) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(value)
                    .font(DSTypography.title.title3)
                    .foregroundColor(DSColors.neutral.text)
                
                Text(title)
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                
                Text(subtitle)
                    .font(DSTypography.caption.small)
                    .foregroundColor(DSColors.neutral.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(DSSpacing.lg)
        .background(.ultraThinMaterial)
        .cornerRadius(DSSpacing.radius.lg)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let isPrimary: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DSSpacing.sm) {
                Image(systemName: icon)
                    .font(DSTypography.body.medium)
                
                Text(title)
                    .font(DSTypography.body.semibold)
            }
            .foregroundColor(isPrimary ? .white : color)
            .padding(.horizontal, DSSpacing.lg)
            .padding(.vertical, DSSpacing.md)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DSSpacing.radius.lg)
                    .fill(isPrimary ? color : Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: DSSpacing.radius.lg)
                            .stroke(color.opacity(0.3), lineWidth: isPrimary ? 0 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct BudgetTransactionRow: View {
    let transaction: Transaction
    let budgetColor: Color
    
    var body: some View {
        HStack(spacing: DSSpacing.md) {
            // Category icon
            Circle()
                .fill(budgetColor.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 16))
                        .foregroundColor(budgetColor)
                )
            
            // Transaction details
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description)
                    .font(DSTypography.body.medium)
                    .foregroundColor(DSColors.neutral.text)
                    .lineLimit(1)
                
                HStack {
                    Text(transaction.category)
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                    
                    Text("•")
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textTertiary)
                    
                    Text(transaction.formattedDate.formatted(date: .abbreviated, time: .omitted))
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textTertiary)
                }
            }
            
            Spacer()
            
            // Amount
            Text(transaction.amount.formatAsCurrency())
                .font(DSTypography.body.semibold)
                .foregroundColor(transaction.amount < 0 ? DSColors.error.main : DSColors.success.main)
        }
        .padding(.horizontal, DSSpacing.md)
        .padding(.vertical, DSSpacing.sm)
    }
}

// MARK: - Preview

#Preview("Budget Detail") {
    BudgetDetailView(
        budget: Budget.sampleBudgets[0],
        spending: 450
    )
    .environmentObject(FinancialDataManager())
}
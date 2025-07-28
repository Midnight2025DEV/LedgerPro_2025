import SwiftUI

/// Budget Dashboard - World-class budget management interface
///
/// Premium budget overview with glass morphism design, interactive progress visualization,
/// and intelligent insights that make users WANT to budget.
struct BudgetDashboard: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    @State private var budgets: [Budget] = Budget.sampleBudgets
    @State private var selectedPeriod: PeriodFilter = .thisMonth
    @State private var showingCreateBudget = false
    @State private var hasAppeared = false
    @State private var scrollOffset: CGFloat = 0
    
    // Quick insights
    @State private var totalBudget: Double = 0
    @State private var totalSpent: Double = 0
    @State private var budgetsOnTrack: Int = 0
    @State private var budgetsOverspent: Int = 0
    
    enum PeriodFilter: String, CaseIterable {
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case thisQuarter = "This Quarter"
        case thisYear = "This Year"
        
        var dateRange: DateInterval {
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
            case .thisQuarter:
                let quarter = calendar.component(.quarter, from: now)
                let year = calendar.component(.year, from: now)
                let monthStart = (quarter - 1) * 3 + 1
                let start = calendar.date(from: DateComponents(year: year, month: monthStart, day: 1)) ?? now
                let end = calendar.date(byAdding: DateComponents(month: 3, day: -1), to: start) ?? now
                return DateInterval(start: start, end: end)
            case .thisYear:
                let start = calendar.dateInterval(of: .year, for: now)?.start ?? now
                let end = calendar.dateInterval(of: .year, for: now)?.end ?? now
                return DateInterval(start: start, end: end)
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: DSSpacing.xl) {
                    // Header Section
                    headerSection
                    
                    // Hero Card - Total Budget Overview
                    heroCard
                    
                    // Quick Insights Banner
                    quickInsightsBanner
                    
                    // Budget Grid
                    budgetGrid
                    
                    // Add padding at bottom for FAB
                    Spacer()
                        .frame(height: 100)
                }
                .padding(.horizontal, DSSpacing.xl)
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .onChange(of: geometry.frame(in: .named("budgetScroll")).minY) { _, newValue in
                                scrollOffset = newValue
                            }
                    }
                )
            }
            .coordinateSpace(name: "budgetScroll")
            .background(dashboardBackground)
            .refreshable {
                await refreshBudgets()
            }
            
            // Floating Action Button
            createBudgetFAB
        }
        .navigationTitle("Budgets")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .onAppear {
            setupInitialState()
        }
        .sheet(isPresented: $showingCreateBudget) {
            CreateBudgetView()
                .environmentObject(dataManager)
        }
    }
    
    // MARK: - Header Section
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: DSSpacing.lg) {
            // Period Selector
            HStack {
                Text("Overview")
                    .font(DSTypography.title.title2)
                    .foregroundColor(DSColors.neutral.text)
                
                Spacer()
                
                Menu {
                    ForEach(PeriodFilter.allCases, id: \.self) { period in
                        Button(period.rawValue) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                selectedPeriod = period
                                calculateOverviewMetrics()
                            }
                        }
                    }
                } label: {
                    HStack(spacing: DSSpacing.sm) {
                        Text(selectedPeriod.rawValue)
                            .font(DSTypography.body.medium)
                            .foregroundColor(DSColors.primary.main)
                        
                        Image(systemName: "chevron.down")
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.primary.main)
                    }
                    .padding(.horizontal, DSSpacing.md)
                    .padding(.vertical, DSSpacing.sm)
                    .background(.ultraThinMaterial)
                    .cornerRadius(DSSpacing.radius.lg)
                }
                .buttonStyle(.plain)
            }
        }
        .opacity(hasAppeared ? 1.0 : 0.0)
        .offset(y: hasAppeared ? 0 : -20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: hasAppeared)
    }
    
    // MARK: - Hero Card
    
    @ViewBuilder
    private var heroCard: some View {
        VStack(spacing: 0) {
            // Main content
            VStack(spacing: DSSpacing.lg) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text("Total Budget")
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        AnimatedNumber(value: totalBudget, format: .currency())
                            .font(DSTypography.title.largeTitle)
                            .foregroundColor(DSColors.neutral.text)
                    }
                    
                    Spacer()
                    
                    // Progress Circle
                    ZStack {
                        Circle()
                            .stroke(DSColors.neutral.n200.opacity(0.3), lineWidth: 8)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: progressPercentage)
                            .stroke(
                                LinearGradient(
                                    colors: progressGradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 1.0, dampingFraction: 0.8), value: progressPercentage)
                        
                        Text("\(Int(progressPercentage * 100))%")
                            .font(DSTypography.body.semibold)
                            .foregroundColor(DSColors.neutral.text)
                    }
                }
                
                // Spending breakdown
                HStack(spacing: DSSpacing.xl) {
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text("Spent")
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                        
                        AnimatedNumber(value: totalSpent, format: .currency())
                            .font(DSTypography.body.semibold)
                            .foregroundColor(spentColor)
                    }
                    
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text("Remaining")
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                        
                        AnimatedNumber(value: max(totalBudget - totalSpent, 0), format: .currency())
                            .font(DSTypography.body.semibold)
                            .foregroundColor(remainingColor)
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal, DSSpacing.xl)
            .padding(.vertical, DSSpacing.lg)
        }
        .background(heroCardBackground)
        .cornerRadius(DSSpacing.radius.xl)
        .shadow(
            color: .black.opacity(0.1),
            radius: 20,
            x: 0,
            y: 8
        )
        .scaleEffect(hasAppeared ? 1.0 : 0.95)
        .opacity(hasAppeared ? 1.0 : 0.0)
        .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.2), value: hasAppeared)
    }
    
    @ViewBuilder
    private var heroCardBackground: some View {
        RoundedRectangle(cornerRadius: DSSpacing.radius.xl)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: DSSpacing.radius.xl)
                    .fill(
                        LinearGradient(
                            colors: [
                                DSColors.primary.p50.opacity(0.1),
                                DSColors.primary.p100.opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DSSpacing.radius.xl)
                    .stroke(
                        LinearGradient(
                            colors: [
                                DSColors.primary.main.opacity(0.3),
                                DSColors.primary.main.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
    
    // MARK: - Quick Insights Banner
    
    @ViewBuilder
    private var quickInsightsBanner: some View {
        HStack(spacing: DSSpacing.lg) {
            // On Track Budgets
            InsightPill(
                icon: "checkmark.circle.fill",
                count: budgetsOnTrack,
                label: "On Track",
                color: DSColors.success.main
            )
            
            // Over Budget
            InsightPill(
                icon: "exclamationmark.triangle.fill",
                count: budgetsOverspent,
                label: "Over Budget",
                color: DSColors.error.main
            )
            
            Spacer()
        }
        .opacity(hasAppeared ? 1.0 : 0.0)
        .offset(y: hasAppeared ? 0 : 10)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: hasAppeared)
    }
    
    // MARK: - Budget Grid
    
    @ViewBuilder
    private var budgetGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: DSSpacing.lg), count: 2),
            spacing: DSSpacing.lg
        ) {
            ForEach(Array(budgets.enumerated()), id: \.element.id) { index, budget in
                BudgetCard(
                    budget: budget,
                    spending: budget.calculateSpending(transactions: dataManager.transactions)
                )
                .scaleEffect(hasAppeared ? 1.0 : 0.8)
                .opacity(hasAppeared ? 1.0 : 0.0)
                .animation(
                    .spring(response: 0.6, dampingFraction: 0.8)
                    .delay(0.4 + Double(index) * 0.1),
                    value: hasAppeared
                )
            }
        }
    }
    
    // MARK: - Create Budget FAB
    
    @ViewBuilder
    private var createBudgetFAB: some View {
        Button(action: {
            #if canImport(UIKit)
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            #endif
            
            showingCreateBudget = true
        }) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                DSColors.primary.main,
                                DSColors.primary.p700
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(
                        color: DSColors.primary.main.opacity(0.4),
                        radius: 12,
                        x: 0,
                        y: 6
                    )
                
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(hasAppeared ? 1.0 : 0.5)
        .opacity(hasAppeared ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.8), value: hasAppeared)
        .padding(.trailing, DSSpacing.xl)
        .padding(.bottom, DSSpacing.xl)
    }
    
    // MARK: - Background
    
    @ViewBuilder
    private var dashboardBackground: some View {
        LinearGradient(
            colors: [
                DSColors.neutral.background,
                DSColors.neutral.backgroundSecondary,
                DSColors.neutral.background
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Computed Properties
    
    private var progressPercentage: Double {
        guard totalBudget > 0 else { return 0 }
        return min(totalSpent / totalBudget, 1.0)
    }
    
    private var progressGradientColors: [Color] {
        let percentage = progressPercentage
        if percentage < 0.5 {
            return [DSColors.success.main, DSColors.success.s400]
        } else if percentage < 0.8 {
            return [DSColors.warning.main, DSColors.warning.w400]
        } else {
            return [DSColors.error.main, DSColors.error.e400]
        }
    }
    
    private var spentColor: Color {
        if progressPercentage > 1.0 {
            return DSColors.error.main
        } else if progressPercentage > 0.8 {
            return DSColors.warning.main
        } else {
            return DSColors.neutral.text
        }
    }
    
    private var remainingColor: Color {
        if totalSpent > totalBudget {
            return DSColors.error.main
        } else {
            return DSColors.success.main
        }
    }
    
    // MARK: - Actions
    
    private func setupInitialState() {
        calculateOverviewMetrics()
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
            hasAppeared = true
        }
    }
    
    private func calculateOverviewMetrics() {
        let dateRange = selectedPeriod.dateRange
        
        totalBudget = budgets.reduce(0) { $0 + $1.amount }
        totalSpent = budgets.reduce(0) { sum, budget in
            sum + budget.calculateSpending(transactions: dataManager.transactions)
        }
        
        budgetsOnTrack = budgets.filter { budget in
            let spending = budget.calculateSpending(transactions: dataManager.transactions)
            return !budget.isOverBudget(spending: spending)
        }.count
        
        budgetsOverspent = budgets.filter { budget in
            let spending = budget.calculateSpending(transactions: dataManager.transactions)
            return budget.isOverBudget(spending: spending)
        }.count
    }
    
    @MainActor
    private func refreshBudgets() async {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            calculateOverviewMetrics()
        }
    }
}

// MARK: - Insight Pill Component

struct InsightPill: View {
    let icon: String
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DSSpacing.sm) {
            Image(systemName: icon)
                .font(DSTypography.caption.regular)
                .foregroundColor(color)
            
            Text("\(count)")
                .font(DSTypography.body.semibold)
                .foregroundColor(DSColors.neutral.text)
            
            Text(label)
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.neutral.textSecondary)
        }
        .padding(.horizontal, DSSpacing.md)
        .padding(.vertical, DSSpacing.sm)
        .background(.ultraThinMaterial)
        .cornerRadius(DSSpacing.radius.lg)
    }
}

// MARK: - Preview

#Preview("Budget Dashboard") {
    NavigationView {
        BudgetDashboard()
            .environmentObject(FinancialDataManager())
    }
}
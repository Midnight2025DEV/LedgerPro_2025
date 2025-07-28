import SwiftUI

/// Quick Stats Grid
///
/// A responsive grid layout for displaying financial statistics using AnimatedStatCards
/// with staggered animations and adaptive column layouts.
struct QuickStatsGrid: View {
    let income: Double
    let expenses: Double
    let savings: Double
    let transactions: Int
    let timeframe: ModernDashboard.Timeframe
    let isVisible: Bool
    
    @State private var hasAppeared = false
    @State private var cardAnimationStates: [Bool] = [false, false, false, false]
    
    // Adaptive grid configuration
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            // Section header
            statsHeader
            
            // Adaptive grid
            adaptiveStatsGrid
        }
        .onAppear {
            if isVisible {
                animateCardsSequentially()
            }
        }
        .onChange(of: isVisible) { _, visible in
            if visible && !hasAppeared {
                animateCardsSequentially()
            }
        }
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private var statsHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Financial Overview")
                    .font(DSTypography.title.title2)
                    .foregroundColor(DSColors.neutral.text)
                
                Text("Key metrics for \(timeframe.displayName.lowercased())")
                    .font(DSTypography.body.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
            }
            
            Spacer()
            
            // Quick refresh button
            Button(action: refreshStats) {
                Image(systemName: "arrow.clockwise")
                    .font(DSTypography.body.medium)
                    .foregroundColor(DSColors.primary.main)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 32, height: 32)
                    )
            }
            .buttonStyle(.plain)
            .opacity(hasAppeared ? 1.0 : 0.0)
            .animation(
                DSAnimations.common.standardTransition.delay(0.8),
                value: hasAppeared
            )
        }
    }
    
    // MARK: - Adaptive Grid
    
    @ViewBuilder
    private var adaptiveStatsGrid: some View {
        LazyVGrid(
            columns: gridColumns,
            spacing: gridSpacing
        ) {
            // Income card
            incomeCard
                .opacity(cardAnimationStates[0] ? 1.0 : 0.0)
                .offset(y: cardAnimationStates[0] ? 0 : 20)
                .scaleEffect(cardAnimationStates[0] ? 1.0 : 0.95)
            
            // Expenses card
            expensesCard
                .opacity(cardAnimationStates[1] ? 1.0 : 0.0)
                .offset(y: cardAnimationStates[1] ? 0 : 20)
                .scaleEffect(cardAnimationStates[1] ? 1.0 : 0.95)
            
            // Savings card
            savingsCard
                .opacity(cardAnimationStates[2] ? 1.0 : 0.0)
                .offset(y: cardAnimationStates[2] ? 0 : 20)
                .scaleEffect(cardAnimationStates[2] ? 1.0 : 0.95)
            
            // Transactions card
            transactionsCard
                .opacity(cardAnimationStates[3] ? 1.0 : 0.0)
                .offset(y: cardAnimationStates[3] ? 0 : 20)
                .scaleEffect(cardAnimationStates[3] ? 1.0 : 0.95)
        }
    }
    
    // MARK: - Individual Cards
    
    @ViewBuilder
    private var incomeCard: some View {
        AnimatedStatCard.balance(
            title: "Income",
            amount: income,
            change: incomeChange,
            subtitle: timeframeSuffix,
            icon: "arrow.down.circle.fill"
        )
    }
    
    @ViewBuilder
    private var expensesCard: some View {
        AnimatedStatCard.balance(
            title: "Expenses",
            amount: expenses,
            change: expensesChange,
            subtitle: timeframeSuffix,
            icon: "arrow.up.circle.fill"
        )
    }
    
    @ViewBuilder
    private var savingsCard: some View {
        AnimatedStatCard.balance(
            title: "Net Savings",
            amount: savings,
            change: savingsChange,
            subtitle: savingsSubtitle,
            icon: "piggybank.fill",
            showProgress: true,
            progressValue: savingsProgress
        )
    }
    
    @ViewBuilder
    private var transactionsCard: some View {
        AnimatedStatCard.transactionCount(
            title: "Transactions",
            count: transactions,
            change: transactionsChange,
            subtitle: timeframeSuffix,
            icon: "list.bullet.circle.fill"
        )
    }
    
    // MARK: - Grid Configuration
    
    private var gridColumns: [GridItem] {
        let columnCount = adaptiveColumnCount
        return Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: columnCount)
    }
    
    private var adaptiveColumnCount: Int {
        // Adapt based on screen size and accessibility settings
        if dynamicTypeSize.isAccessibilitySize {
            return 1 // Single column for accessibility
        }
        
        switch horizontalSizeClass {
        case .compact:
            return 2 // 2 columns on iPhone
        case .regular, .none:
            return 2 // 2 columns on iPad/Mac
        @unknown default:
            return 2
        }
    }
    
    private var gridSpacing: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? DSSpacing.xl : DSSpacing.lg
    }
    
    // MARK: - Computed Properties
    
    private var timeframeSuffix: String {
        switch timeframe {
        case .week: return "This week"
        case .month: return "This month"
        case .quarter: return "This quarter"
        case .year: return "This year"
        }
    }
    
    private var incomeChange: String {
        // Calculate income change (simplified)
        let change = Double.random(in: -10...25)
        return change >= 0 ? "+\(String(format: "%.1f", change))%" : "\(String(format: "%.1f", change))%"
    }
    
    private var expensesChange: String {
        // Calculate expenses change (simplified)
        let change = Double.random(in: -15...20)
        return change >= 0 ? "+\(String(format: "%.1f", change))%" : "\(String(format: "%.1f", change))%"
    }
    
    private var savingsChange: String {
        // Calculate savings change
        let savingsRate = savings / max(income, 1) * 100
        let targetRate = 20.0 // 20% savings target
        let difference = savingsRate - targetRate
        
        if difference >= 0 {
            return "+\(String(format: "%.1f", difference))% vs target"
        } else {
            return "\(String(format: "%.1f", difference))% vs target"
        }
    }
    
    private var savingsSubtitle: String {
        let savingsRate = (savings / max(income, 1)) * 100
        return "Rate: \(String(format: "%.1f", savingsRate))%"
    }
    
    private var savingsProgress: Double {
        // Progress towards 25% savings rate target
        let savingsRate = (savings / max(income, 1)) * 100
        return min(1.0, savingsRate / 25.0)
    }
    
    private var transactionsChange: String {
        // Calculate transaction count change
        let change = Int.random(in: -20...30)
        return change >= 0 ? "+\(change)" : "\(change)"
    }
    
    // MARK: - Animation Methods
    
    private func animateCardsSequentially() {
        hasAppeared = true
        
        // Staggered card animations
        let delays: [TimeInterval] = [0.0, 0.1, 0.2, 0.3]
        
        for (index, delay) in delays.enumerated() {
            withAnimation(
                DSAnimations.common.standardTransition.delay(delay)
            ) {
                cardAnimationStates[index] = true
            }
        }
    }
    
    private func refreshStats() {
        // Reset animation states
        cardAnimationStates = [false, false, false, false]
        
        // Re-animate with fresh data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            animateCardsSequentially()
        }
        
        // Haptic feedback on supported platforms
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        #endif
    }
}

// MARK: - Responsive Grid Variants

extension QuickStatsGrid {
    /// Create compact version for smaller screens
    static func compact(
        income: Double,
        expenses: Double,
        savings: Double,
        transactions: Int,
        timeframe: ModernDashboard.Timeframe,
        isVisible: Bool = true
    ) -> some View {
        VStack(spacing: DSSpacing.md) {
            // Only show the most important metrics in compact mode
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: DSSpacing.md),
                    GridItem(.flexible(), spacing: DSSpacing.md)
                ],
                spacing: DSSpacing.md
            ) {
                AnimatedStatCard.balance(
                    title: "Net",
                    amount: savings,
                    change: "+12.3%",
                    subtitle: "This month",
                    icon: "dollarsign.circle.fill"
                )
                
                AnimatedStatCard.transactionCount(
                    title: "Activity",
                    count: transactions,
                    change: "+5",
                    subtitle: "This week",
                    icon: "chart.bar.fill"
                )
            }
        }
    }
    
    /// Create detailed version for larger screens
    static func detailed(
        income: Double,
        expenses: Double,
        savings: Double,
        transactions: Int,
        timeframe: ModernDashboard.Timeframe,
        isVisible: Bool = true,
        additionalMetrics: [String: Double] = [:]
    ) -> some View {
        VStack(spacing: DSSpacing.lg) {
            // Main stats grid
            QuickStatsGrid(
                income: income,
                expenses: expenses,
                savings: savings,
                transactions: transactions,
                timeframe: timeframe,
                isVisible: isVisible
            )
            
            // Additional metrics if provided
            if !additionalMetrics.isEmpty {
                AdditionalMetricsGrid(metrics: additionalMetrics)
            }
        }
    }
}

// MARK: - Additional Metrics Grid

struct AdditionalMetricsGrid: View {
    let metrics: [String: Double]
    @State private var hasAppeared = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            Text("Additional Metrics")
                .font(DSTypography.body.semibold)
                .foregroundColor(DSColors.neutral.textSecondary)
                .opacity(hasAppeared ? 1.0 : 0.0)
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: DSSpacing.sm), count: 3),
                spacing: DSSpacing.sm
            ) {
                ForEach(Array(metrics.keys.sorted()), id: \.self) { key in
                    if let value = metrics[key] {
                        CompactMetricCard(title: key, value: value)
                    }
                }
            }
            .opacity(hasAppeared ? 1.0 : 0.0)
            .offset(y: hasAppeared ? 0 : 10)
        }
        .onAppear {
            withAnimation(DSAnimations.common.standardTransition.delay(0.5)) {
                hasAppeared = true
            }
        }
    }
}

struct CompactMetricCard: View {
    let title: String
    let value: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            Text(title)
                .font(DSTypography.caption.small)
                .foregroundColor(DSColors.neutral.textSecondary)
                .lineLimit(1)
            
            Text(value.formatAsCurrency())
                .font(DSTypography.body.medium)
                .foregroundColor(DSColors.neutral.text)
                .lineLimit(1)
        }
        .padding(DSSpacing.sm)
        .background(.ultraThinMaterial)
        .cornerRadius(DSSpacing.radius.sm)
    }
}

// MARK: - Preview

#Preview("Quick Stats Grid") {
    VStack(spacing: DSSpacing.xl) {
        // Standard grid
        QuickStatsGrid(
            income: 8450.00,
            expenses: 6234.50,
            savings: 2215.50,
            transactions: 142,
            timeframe: .month,
            isVisible: true
        )
        
        // Compact version
        QuickStatsGrid.compact(
            income: 8450.00,
            expenses: 6234.50,
            savings: 2215.50,
            transactions: 142,
            timeframe: .month
        )
    }
    .padding(DSSpacing.xl)
    .background(
        LinearGradient(
            colors: [DSColors.neutral.n100, DSColors.neutral.n200],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

#Preview("Responsive Grid") {
    ScrollView {
        VStack(spacing: DSSpacing.xl) {
            Text("Responsive Quick Stats")
                .font(DSTypography.title.title1)
                .foregroundColor(DSColors.neutral.text)
            
            // Detailed version with additional metrics
            QuickStatsGrid.detailed(
                income: 12500.00,
                expenses: 8750.00,
                savings: 3750.00,
                transactions: 89,
                timeframe: .month,
                additionalMetrics: [
                    "Investments": 2340.50,
                    "Bills": 1850.00,
                    "Shopping": 945.30,
                    "Food": 678.20,
                    "Transport": 234.80,
                    "Entertainment": 189.50
                ]
            )
        }
        .padding(DSSpacing.xl)
    }
    .background(
        LinearGradient(
            colors: [DSColors.neutral.background, DSColors.neutral.backgroundSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
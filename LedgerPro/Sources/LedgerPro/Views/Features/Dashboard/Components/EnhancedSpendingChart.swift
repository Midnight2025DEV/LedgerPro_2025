import SwiftUI
import Charts

/// Enhanced Spending Chart
///
/// A sophisticated chart component for visualizing spending trends with gradient fills,
/// smooth animations, and interactive elements for the modern dashboard.
@available(macOS 13.0, iOS 16.0, *)
struct ModernSpendingChart: View {
    let data: [SpendingDataPoint]
    let timeframe: ModernDashboard.Timeframe
    
    @State private var animationProgress: CGFloat = 0
    @State private var selectedDataPoint: SpendingDataPoint?
    @State private var hoveredCategory: String?
    @State private var hasAppeared = false
    
    // Chart configuration
    private let chartHeight: CGFloat = 250
    private let animationDuration: TimeInterval = 1.2
    
    var body: some View {
        VStack(spacing: 0) {
            // Chart container with glass morphism
            GlassCard(
                gradient: chartGradient,
                padding: DSSpacing.lg,
                enableBorderAnimation: false
            ) {
                VStack(spacing: DSSpacing.md) {
                    // Chart header with legend
                    chartHeader
                    
                    // Main chart
                    mainChart
                    
                    // Chart footer with insights
                    chartFooter
                }
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: animationDuration).delay(0.2)
            ) {
                animationProgress = 1.0
                hasAppeared = true
            }
        }
    }
    
    // MARK: - Chart Header
    
    @ViewBuilder
    private var chartHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Spending Breakdown")
                    .font(DSTypography.body.semibold)
                    .foregroundColor(DSColors.neutral.text)
                
                Text("by category • \(timeframe.displayName.lowercased())")
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
            }
            
            Spacer()
            
            // Category legend
            categoryLegend
        }
    }
    
    @ViewBuilder
    private var categoryLegend: some View {
        HStack(spacing: DSSpacing.sm) {
            ForEach(topCategories.prefix(4), id: \.self) { category in
                LegendItem(
                    category: category,
                    color: categoryColor(for: category),
                    isHighlighted: hoveredCategory == category
                )
                .onTapGesture {
                    withAnimation(DSAnimations.common.quickFeedback) {
                        hoveredCategory = hoveredCategory == category ? nil : category
                    }
                }
            }
        }
        .opacity(hasAppeared ? 1.0 : 0.0)
        .animation(
            DSAnimations.common.standardTransition.delay(0.5),
            value: hasAppeared
        )
    }
    
    // MARK: - Main Chart
    
    @ViewBuilder
    private var mainChart: some View {
        Chart(animatedData, id: \.id) { dataPoint in
            let color = categoryColor(for: dataPoint.category)
            let opacity = hoveredCategory == nil || hoveredCategory == dataPoint.category ? 1.0 : 0.3
            
            AreaMark(
                x: .value("Date", dataPoint.date),
                y: .value("Amount", dataPoint.amount)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        color.opacity(0.6),
                        color.opacity(0.2),
                        color.opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .opacity(opacity)
            
            LineMark(
                x: .value("Date", dataPoint.date),
                y: .value("Amount", dataPoint.amount)
            )
            .foregroundStyle(color)
            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            .opacity(opacity)
            
            // Data points
            PointMark(
                x: .value("Date", dataPoint.date),
                y: .value("Amount", dataPoint.amount)
            )
            .foregroundStyle(color)
            .symbol(.circle)
            .symbolSize(selectedDataPoint?.id == dataPoint.id ? 80 : 40)
            .opacity(opacity)
        }
        .frame(height: chartHeight)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: timeframe.days / 5)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .font(DSTypography.caption.small)
                    .foregroundStyle(DSColors.neutral.textTertiary)
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(DSColors.neutral.border.opacity(0.3))
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisValueLabel(format: .currency(code: "USD"))
                    .font(DSTypography.caption.small)
                    .foregroundStyle(DSColors.neutral.textTertiary)
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(DSColors.neutral.border.opacity(0.3))
            }
        }
        .chartBackground { _ in
            Rectangle()
                .fill(.clear)
        }
        .chartPlotStyle { plotArea in
            plotArea
                .background(
                    LinearGradient(
                        colors: [
                            DSColors.neutral.backgroundCard.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        // Remove chartAngleSelection as it's not applicable for this chart type
        .chartBackground { _ in
            // Interactive overlay for selection
            Rectangle()
                .fill(.clear)
        }
        .animation(
            .easeInOut(duration: animationDuration),
            value: animationProgress
        )
        .animation(
            DSAnimations.common.quickFeedback,
            value: hoveredCategory
        )
    }
    
    // MARK: - Chart Footer
    
    @ViewBuilder
    private var chartFooter: some View {
        HStack {
            // Total spending
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Total Spending")
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                AnimatedNumber.amount(totalSpending)
                    .font(DSTypography.title.title3)
                    .foregroundColor(DSColors.neutral.text)
            }
            
            Spacer()
            
            // Average per day
            VStack(alignment: .trailing, spacing: DSSpacing.xs) {
                Text("Daily Average")
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                AnimatedNumber.amount(averageDaily)
                    .font(DSTypography.body.semibold)
                    .foregroundColor(DSColors.neutral.textSecondary)
            }
        }
        .opacity(hasAppeared ? 1.0 : 0.0)
        .offset(y: hasAppeared ? 0 : 10)
        .animation(
            DSAnimations.common.standardTransition.delay(0.8),
            value: hasAppeared
        )
    }
    
    // MARK: - Computed Properties
    
    private var animatedData: [SpendingDataPoint] {
        let visibleCount = Int(Double(data.count) * Double(animationProgress))
        return Array(data.prefix(visibleCount))
    }
    
    private var topCategories: [String] {
        let categoryTotals = Dictionary(grouping: data, by: \.category)
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
        
        return categoryTotals.sorted { $0.value > $1.value }
            .map(\.key)
    }
    
    private var totalSpending: Double {
        data.reduce(0) { $0 + $1.amount }
    }
    
    private var averageDaily: Double {
        totalSpending / Double(max(timeframe.days, 1))
    }
    
    private var chartGradient: LinearGradient {
        LinearGradient(
            colors: [
                DSColors.primary.p50.opacity(0.1),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Helper Methods
    
    private func categoryColor(for category: String) -> Color {
        // Assign consistent colors to categories
        let colors: [Color] = [
            DSColors.primary.main,
            DSColors.success.main,
            DSColors.warning.main,
            DSColors.error.main,
            DSColors.neutral.n600,
            DSColors.primary.p300,
            DSColors.success.s300,
            DSColors.warning.w300
        ]
        
        let index = abs(category.hashValue) % colors.count
        return colors[index]
    }
    
    private func selectDataPoint(at location: CGPoint, in geometry: GeometryProxy) {
        // Find closest data point to tap location
        // This is a simplified implementation
        // For now, just select the first data point as a placeholder
        // TODO: Implement proper point selection based on location
        if let closest = data.first {
            withAnimation(DSAnimations.common.quickFeedback) {
                selectedDataPoint = selectedDataPoint?.id == closest.id ? nil : closest
            }
        }
    }
}

// MARK: - Legend Item

struct LegendItem: View {
    let category: String
    let color: Color
    let isHighlighted: Bool
    
    var body: some View {
        HStack(spacing: DSSpacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .scaleEffect(isHighlighted ? 1.2 : 1.0)
            
            Text(category)
                .font(DSTypography.caption.small)
                .foregroundColor(isHighlighted ? color : DSColors.neutral.textSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, DSSpacing.xs)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(isHighlighted ? color.opacity(0.1) : Color.clear)
        )
        .animation(DSAnimations.common.quickFeedback, value: isHighlighted)
    }
}

// MARK: - Fallback Chart for older OS versions

@available(macOS 12.0, iOS 15.0, *)
struct FallbackSpendingChart: View {
    let data: [SpendingDataPoint]
    let timeframe: ModernDashboard.Timeframe
    
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        GlassCard(
            gradient: LinearGradient(
                colors: [DSColors.primary.p50.opacity(0.1), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            padding: DSSpacing.lg
        ) {
            VStack(spacing: DSSpacing.lg) {
                // Header
                HStack {
                    Text("Spending Trends")
                        .font(DSTypography.body.semibold)
                        .foregroundColor(DSColors.neutral.text)
                    
                    Spacer()
                    
                    Text(timeframe.displayName)
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                }
                
                // Simple bar chart representation
                VStack(spacing: DSSpacing.sm) {
                    ForEach(categoryData, id: \.category) { item in
                        HStack {
                            Text(item.category)
                                .font(DSTypography.caption.regular)
                                .foregroundColor(DSColors.neutral.text)
                                .frame(width: 80, alignment: .leading)
                            
                            GeometryReader { geometry in
                                HStack(spacing: 0) {
                                    Rectangle()
                                        .fill(categoryColor(for: item.category))
                                        .frame(width: geometry.size.width * item.percentage * animationProgress)
                                        .cornerRadius(2)
                                    
                                    Spacer(minLength: 0)
                                }
                            }
                            .frame(height: 8)
                            
                            Text(item.amount.formatAsCurrency())
                                .font(DSTypography.caption.small)
                                .foregroundColor(DSColors.neutral.textSecondary)
                                .frame(width: 80, alignment: .trailing)
                        }
                    }
                }
                
                // Total
                HStack {
                    Text("Total")
                        .font(DSTypography.body.semibold)
                        .foregroundColor(DSColors.neutral.text)
                    
                    Spacer()
                    
                    Text(totalSpending.formatAsCurrency())
                        .font(DSTypography.body.semibold)
                        .foregroundColor(DSColors.primary.main)
                }
                .padding(.top, DSSpacing.sm)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
                animationProgress = 1.0
            }
        }
    }
    
    private var categoryData: [(category: String, amount: Double, percentage: Double)] {
        let categoryTotals = Dictionary(grouping: data, by: \.category)
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
        
        let total = categoryTotals.values.reduce(0, +)
        
        return categoryTotals.map { (category, amount) in
            (category: category, amount: amount, percentage: total > 0 ? amount / total : 0)
        }
        .sorted { $0.amount > $1.amount }
        .prefix(5)
        .map { $0 }
    }
    
    private var totalSpending: Double {
        data.reduce(0) { $0 + $1.amount }
    }
    
    private func categoryColor(for category: String) -> Color {
        let colors: [Color] = [
            DSColors.primary.main,
            DSColors.success.main,
            DSColors.warning.main,
            DSColors.error.main,
            DSColors.neutral.n600
        ]
        
        let index = abs(category.hashValue) % colors.count
        return colors[index]
    }
}

// MARK: - Unified Chart View

struct SpendingChartWrapper: View {
    let data: [SpendingDataPoint]
    let timeframe: ModernDashboard.Timeframe
    
    var body: some View {
        if #available(macOS 13.0, iOS 16.0, *) {
            ModernSpendingChart(data: data, timeframe: timeframe)
        } else {
            FallbackSpendingChart(data: data, timeframe: timeframe)
        }
    }
}

// Type alias for external usage
typealias EnhancedSpendingChart = SpendingChartWrapper

// MARK: - Preview

#Preview("Enhanced Spending Chart") {
    let sampleData: [SpendingDataPoint] = [
        SpendingDataPoint(date: Calendar.current.date(byAdding: .day, value: -30, to: Date())!, amount: 150, category: "Food"),
        SpendingDataPoint(date: Calendar.current.date(byAdding: .day, value: -25, to: Date())!, amount: 80, category: "Transport"),
        SpendingDataPoint(date: Calendar.current.date(byAdding: .day, value: -20, to: Date())!, amount: 200, category: "Shopping"),
        SpendingDataPoint(date: Calendar.current.date(byAdding: .day, value: -15, to: Date())!, amount: 120, category: "Food"),
        SpendingDataPoint(date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!, amount: 90, category: "Entertainment"),
        SpendingDataPoint(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, amount: 160, category: "Food"),
        SpendingDataPoint(date: Date(), amount: 110, category: "Transport")
    ]
    
    VStack(spacing: DSSpacing.xl) {
        if #available(macOS 13.0, iOS 16.0, *) {
            EnhancedSpendingChart(data: sampleData, timeframe: .month)
        } else {
            FallbackSpendingChart(data: sampleData, timeframe: .month)
        }
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
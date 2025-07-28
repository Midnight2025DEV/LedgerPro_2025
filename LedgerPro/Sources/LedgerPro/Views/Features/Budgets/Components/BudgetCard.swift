import SwiftUI
import Charts

/// BudgetCard - Premium individual budget display component
///
/// Features glass morphism design, animated progress ring, spending pace indicators,
/// mini sparkline chart, and delightful interactions that encourage good budgeting habits.
struct BudgetCard: View {
    let budget: Budget
    let spending: Double
    
    @State private var hasAppeared = false
    @State private var isHovered = false
    @State private var showingDetail = false
    @State private var pulseAnimation = false
    
    // Sparkline data
    @State private var dailySpending: [BudgetDailySpending] = []
    
    private var progressPercentage: Double {
        budget.progressPercentage(spending: spending)
    }
    
    private var isOverBudget: Bool {
        budget.isOverBudget(spending: spending)
    }
    
    private var spendingPace: SpendingPace {
        budget.spendingPace(spending: spending)
    }
    
    var body: some View {
        Button(action: {
            #if canImport(UIKit)
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            #endif
            showingDetail = true
        }) {
            VStack(spacing: 0) {
                // Main card content
                VStack(spacing: DSSpacing.lg) {
                    // Header with icon and name
                    headerSection
                    
                    // Progress ring
                    progressRingSection
                    
                    // Amount information
                    amountSection
                    
                    // Pace indicator
                    paceSection
                    
                    // Mini sparkline
                    sparklineSection
                }
                .padding(DSSpacing.lg)
            }
            .background(cardBackground)
            .cornerRadius(DSSpacing.radius.xl)
            .shadow(
                color: isOverBudget ? DSColors.error.main.opacity(0.2) : .black.opacity(0.08),
                radius: isOverBudget ? 16 : 12,
                x: 0,
                y: isOverBudget ? 8 : 6
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            generateSparklineData()
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                hasAppeared = true
            }
            
            // Start pulse animation for over budget
            if isOverBudget {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                }
            }
        }
        .sheet(isPresented: $showingDetail) {
            BudgetDetailView(budget: budget, spending: spending)
        }
    }
    
    // MARK: - Header Section
    
    @ViewBuilder
    private var headerSection: some View {
        HStack {
            // Budget icon with color
            ZStack {
                Circle()
                    .fill((Color(hex: budget.color) ?? .blue ?? .blue).opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: budget.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: budget.color) ?? .blue)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(budget.name)
                    .font(DSTypography.body.semibold)
                    .foregroundColor(DSColors.neutral.text)
                    .lineLimit(1)
                
                Text(budget.period.displayName)
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Progress Ring Section
    
    @ViewBuilder
    private var progressRingSection: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(DSColors.neutral.n200.opacity(0.3), lineWidth: 8)
                .frame(width: 80, height: 80)
            
            // Progress ring with gradient
            Circle()
                .trim(from: 0, to: hasAppeared ? CGFloat(progressPercentage / 100) : 0)
                .stroke(
                    AngularGradient(
                        colors: progressGradientColors,
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 1.2, dampingFraction: 0.8), value: hasAppeared)
            
            // Over budget pulse effect
            if isOverBudget {
                Circle()
                    .stroke(DSColors.error.main.opacity(0.3), lineWidth: 12)
                    .frame(width: 88, height: 88)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .opacity(pulseAnimation ? 0.0 : 0.5)
            }
            
            // Center content
            VStack(spacing: 2) {
                Text("\(Int(progressPercentage))%")
                    .font(DSTypography.body.semibold)
                    .foregroundColor(DSColors.neutral.text)
                
                if isOverBudget {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(DSColors.error.main)
                }
            }
        }
    }
    
    // MARK: - Amount Section
    
    @ViewBuilder
    private var amountSection: some View {
        VStack(spacing: DSSpacing.xs) {
            // Spent amount
            HStack {
                Text("Spent")
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                
                Spacer()
                
                AnimatedNumber(value: spending, format: .currency())
                    .font(DSTypography.body.semibold)
                    .foregroundColor(spentAmountColor)
            }
            
            // Budget amount
            HStack {
                Text("Budget")
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                
                Spacer()
                
                AnimatedNumber(value: budget.amount, format: .currency())
                    .font(DSTypography.caption.regular).fontWeight(.medium)
                    .foregroundColor(DSColors.neutral.textTertiary)
            }
            
            // Remaining/Over amount
            if let remainingAmount = remainingAmountInfo {
                HStack {
                    Text(remainingAmount.label)
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                    
                    Spacer()
                    
                    AnimatedNumber(value: remainingAmount.amount, format: .currency())
                        .font(DSTypography.caption.regular).fontWeight(.semibold)
                        .foregroundColor(remainingAmount.color)
                }
            }
        }
    }
    
    // MARK: - Pace Section
    
    @ViewBuilder 
    private var paceSection: some View {
        HStack(spacing: DSSpacing.sm) {
            Image(systemName: spendingPace.icon)
                .font(.system(size: 14))
                .foregroundColor(spendingPace.color)
            
            Text(spendingPace.displayText)
                .font(DSTypography.caption.regular).fontWeight(.medium)
                .foregroundColor(spendingPace.color)
            
            Spacer()
            
            // Days remaining
            if let daysRemaining = calculateDaysRemaining() {
                Text("\(daysRemaining)d left")
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textTertiary)
            }
        }
        .padding(.horizontal, DSSpacing.sm)
        .padding(.vertical, DSSpacing.xs)
        .background(spendingPace.color.opacity(0.1))
        .cornerRadius(DSSpacing.radius.sm)
    }
    
    // MARK: - Sparkline Section
    
    @ViewBuilder
    private var sparklineSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            Text("Daily Spending")
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.neutral.textTertiary)
            
            if #available(macOS 13.0, iOS 16.0, *) {
                Chart(dailySpending) { data in
                    LineMark(
                        x: .value("Day", data.date),
                        y: .value("Amount", data.amount)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: budget.color) ?? .blue ?? .blue, (Color(hex: budget.color) ?? .blue ?? .blue).opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartLegend(.hidden)
                .frame(height: 32)
            } else {
                // Fallback sparkline for older OS versions
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(dailySpending.prefix(7), id: \.date) { data in
                        Rectangle()
                            .fill(Color(hex: budget.color) ?? .blue)
                            .frame(width: 3, height: max(2, CGFloat(data.amount / maxDailySpendig) * 20))
                            .cornerRadius(1)
                    }
                }
                .frame(height: 32)
            }
        }
    }
    
    // MARK: - Card Background
    
    @ViewBuilder
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: DSSpacing.radius.xl)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: DSSpacing.radius.xl)
                    .fill(
                        LinearGradient(
                            colors: [
                                (Color(hex: budget.color) ?? .blue ?? .blue).opacity(0.08),
                                (Color(hex: budget.color) ?? .blue ?? .blue).opacity(0.03),
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
                                (Color(hex: budget.color) ?? .blue ?? .blue).opacity(0.3),
                                (Color(hex: budget.color) ?? .blue ?? .blue).opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isOverBudget ? 2 : 1
                    )
            )
    }
    
    // MARK: - Computed Properties
    
    private var progressGradientColors: [Color] {
        let percentage = progressPercentage / 100
        let budgetColor = Color(hex: budget.color) ?? .blue
        
        if percentage > 1.0 {
            return [DSColors.error.main, DSColors.error.e600]
        } else if percentage > 0.8 {
            return [DSColors.warning.main, budgetColor]
        } else {
            return [budgetColor, budgetColor.opacity(0.6)]
        }
    }
    
    private var spentAmountColor: Color {
        if isOverBudget {
            return DSColors.error.main
        } else if progressPercentage > 80 {
            return DSColors.warning.main
        } else {
            return DSColors.neutral.text
        }
    }
    
    private var remainingAmountInfo: (label: String, amount: Double, color: Color)? {
        let remaining = budget.amount - spending
        
        if remaining >= 0 {
            return ("Remaining", remaining, DSColors.success.main)
        } else {
            return ("Over", abs(remaining), DSColors.error.main)
        }
    }
    
    private var maxDailySpendig: Double {
        dailySpending.map(\.amount).max() ?? 1
    }
    
    // MARK: - Helper Methods
    
    private func calculateDaysRemaining() -> Int? {
        guard let endDate = budget.endDate else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: now, to: endDate)
        return max(components.day ?? 0, 0)
    }
    
    private func generateSparklineData() {
        let calendar = Calendar.current
        let now = Date()
        var data: [BudgetDailySpending] = []
        
        // Generate last 7 days of spending data
        for i in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: now) {
                // Simulate daily spending with some randomness
                let baseAmount = budget.dailyBudget
                let variation = Double.random(in: 0.5...1.5)
                let amount = baseAmount * variation
                
                data.append(BudgetDailySpending(date: date, amount: amount))
            }
        }
        
        dailySpending = data
    }
}

// MARK: - Budget Daily Spending Model

struct BudgetDailySpending: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
}

// MARK: - Enhanced Budget Card Variants

extension BudgetCard {
    /// Compact version for smaller grids
    static func compact(budget: Budget, spending: Double) -> some View {
        CompactBudgetCard(budget: budget, spending: spending)
    }
    
    /// Large featured version for hero sections
    static func featured(budget: Budget, spending: Double) -> some View {
        FeaturedBudgetCard(budget: budget, spending: spending)
    }
}

// MARK: - Compact Budget Card

struct CompactBudgetCard: View {
    let budget: Budget
    let spending: Double
    
    @State private var hasAppeared = false
    
    private var progressPercentage: Double {
        budget.progressPercentage(spending: spending)
    }
    
    var body: some View {
        HStack(spacing: DSSpacing.md) {
            // Progress ring (smaller)
            ZStack {
                Circle()
                    .stroke(DSColors.neutral.n200.opacity(0.3), lineWidth: 4)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: hasAppeared ? CGFloat(progressPercentage / 100) : 0)
                    .stroke(Color(hex: budget.color) ?? .blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8, dampingFraction: 0.8), value: hasAppeared)
                
                Text("\(Int(progressPercentage))%")
                    .font(DSTypography.caption.small)
                    .foregroundColor(DSColors.neutral.text)
            }
            
            // Budget info
            VStack(alignment: .leading, spacing: 2) {
                Text(budget.name)
                    .font(DSTypography.body.medium)
                    .foregroundColor(DSColors.neutral.text)
                    .lineLimit(1)
                
                HStack {
                    AnimatedNumber(value: spending, format: .currency())
                        .font(DSTypography.caption.regular).fontWeight(.medium)
                        .foregroundColor(DSColors.neutral.textSecondary)
                    
                    Text("of")
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textTertiary)
                    
                    AnimatedNumber(value: budget.amount, format: .currency())
                        .font(DSTypography.caption.regular).fontWeight(.medium)
                        .foregroundColor(DSColors.neutral.textSecondary)
                }
            }
            
            Spacer()
        }
        .padding(DSSpacing.md)
        .background(.ultraThinMaterial)
        .cornerRadius(DSSpacing.radius.lg)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                hasAppeared = true
            }
        }
    }
}

// MARK: - Featured Budget Card

struct FeaturedBudgetCard: View {
    let budget: Budget
    let spending: Double
    
    @State private var hasAppeared = false
    @State private var showingInsights = false
    
    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            // Main budget info with large progress ring
            HStack {
                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    // Header
                    HStack {
                        Image(systemName: budget.icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(Color(hex: budget.color) ?? .blue)
                        
                        Text(budget.name)
                            .font(DSTypography.title.title2)
                            .foregroundColor(DSColors.neutral.text)
                        
                        Spacer()
                    }
                    
                    // Amounts
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        HStack {
                            Text("Budget:")
                                .font(DSTypography.body.regular)
                                .foregroundColor(DSColors.neutral.textSecondary)
                            
                            AnimatedNumber(value: budget.amount, format: .currency())
                                .font(DSTypography.body.semibold)
                                .foregroundColor(DSColors.neutral.text)
                        }
                        
                        HStack {
                            Text("Spent:")
                                .font(DSTypography.body.regular)
                                .foregroundColor(DSColors.neutral.textSecondary)
                            
                            AnimatedNumber(value: spending, format: .currency())
                                .font(DSTypography.body.semibold)
                                .foregroundColor(spending > budget.amount ? DSColors.error.main : DSColors.neutral.text)
                        }
                    }
                }
                
                Spacer()
                
                // Large progress ring
                ZStack {
                    Circle()
                        .stroke(DSColors.neutral.n200.opacity(0.3), lineWidth: 12)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: hasAppeared ? CGFloat(budget.progressPercentage(spending: spending) / 100) : 0)
                        .stroke(
                            AngularGradient(
                                colors: [Color(hex: budget.color) ?? .blue, (Color(hex: budget.color) ?? .blue ?? .blue).opacity(0.5)],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 1.5, dampingFraction: 0.8), value: hasAppeared)
                    
                    Text("\(Int(budget.progressPercentage(spending: spending)))%")
                        .font(DSTypography.title.title1)
                        .foregroundColor(DSColors.neutral.text)
                }
            }
            
            // Quick insights toggle
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showingInsights.toggle()
                }
            }) {
                HStack {
                    Text("View Insights")
                        .font(DSTypography.body.medium)
                        .foregroundColor(DSColors.primary.main)
                    
                    Image(systemName: showingInsights ? "chevron.up" : "chevron.down")
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.primary.main)
                }
            }
            .buttonStyle(.plain)
            
            if showingInsights {
                BudgetInsights(budget: budget, currentSpending: spending, insights: [])
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .padding(DSSpacing.xl)
        .background(.ultraThinMaterial)
        .cornerRadius(DSSpacing.radius.xl)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                hasAppeared = true
            }
        }
    }
}

// MARK: - Preview

#Preview("Budget Cards") {
    ScrollView {
        LazyVStack(spacing: DSSpacing.xl) {
            // Regular card
            BudgetCard(
                budget: Budget.sampleBudgets[0],
                spending: 450
            )
            .frame(width: 200)
            
            // Compact card
            BudgetCard.compact(
                budget: Budget.sampleBudgets[1],
                spending: 280
            )
            
            // Featured card
            BudgetCard.featured(
                budget: Budget.sampleBudgets[2],
                spending: 120
            )
        }
        .padding()
    }
    .background(
        LinearGradient(
            colors: [DSColors.neutral.background, DSColors.neutral.backgroundSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
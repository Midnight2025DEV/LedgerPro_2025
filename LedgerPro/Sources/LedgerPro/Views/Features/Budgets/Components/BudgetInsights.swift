import SwiftUI

/// BudgetInsights - AI-powered budget recommendations and insights
///
/// Intelligent budget insight system that analyzes spending patterns, provides
/// actionable recommendations, and helps users optimize their financial habits.
struct BudgetInsights: View {
    let budget: Budget
    let currentSpending: Double
    let insights: [BudgetInsight]
    
    @State private var selectedInsight: BudgetInsight?
    @State private var hasAppeared = false
    @State private var showingDetail = false
    @State private var expandedInsights: Set<UUID> = []
    
    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            // Header section
            insightsHeader
            
            // Summary metrics
            summaryMetricsSection
            
            // Insights grid
            insightsGrid
            
            // AI recommendations
            aiRecommendationsSection
            
            // Trends and patterns
            trendsSection
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1)) {
                hasAppeared = true
            }
        }
        .sheet(item: $selectedInsight) { insight in
            InsightDetailView(insight: insight, budget: budget)
        }
    }
    
    // MARK: - Insights Header
    
    @ViewBuilder
    private var insightsHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Budget Insights")
                    .font(DSTypography.title.title2)
                    .foregroundColor(DSColors.neutral.text)
                
                Text("AI-powered recommendations to optimize your budget")
                    .font(DSTypography.body.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
            }
            
            Spacer()
            
            // Insight quality indicator
            insightQualityBadge
        }
        .scaleEffect(hasAppeared ? 1.0 : 0.9)
        .opacity(hasAppeared ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: hasAppeared)
    }
    
    @ViewBuilder
    private var insightQualityBadge: some View {
        HStack(spacing: DSSpacing.xs) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DSColors.primary.main)
            
            Text("AI Analysis")
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.primary.main)
        }
        .padding(.horizontal, DSSpacing.md)
        .padding(.vertical, DSSpacing.sm)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(DSColors.primary.main.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Summary Metrics Section
    
    @ViewBuilder
    private var summaryMetricsSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DSSpacing.md), count: 3), spacing: DSSpacing.md) {
            InsightMetric(
                title: "Insights",
                value: "\(insights.count)",
                subtitle: "Generated",
                icon: "lightbulb.fill",
                color: DSColors.warning.main
            )
            
            InsightMetric(
                title: "Confidence",
                value: "\(Int(overallConfidence * 100))%",
                subtitle: "Average",
                icon: "chart.line.uptrend.xyaxis",
                color: DSColors.success.main
            )
            
            InsightMetric(
                title: "Potential",
                value: potentialSavings.formatAsCurrency(),
                subtitle: "Savings",
                icon: "dollarsign.circle.fill",
                color: DSColors.primary.main
            )
        }
        .opacity(hasAppeared ? 1.0 : 0.0)
        .offset(y: hasAppeared ? 0 : 15)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: hasAppeared)
    }
    
    // MARK: - Insights Grid
    
    @ViewBuilder
    private var insightsGrid: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            Text("Key Insights")
                .font(DSTypography.title.title3)
                .foregroundColor(DSColors.neutral.text)
            
            LazyVStack(spacing: DSSpacing.md) {
                ForEach(Array(insights.enumerated()), id: \.element.id) { index, insight in
                    BudgetInsightCard(
                        insight: insight,
                        isExpanded: expandedInsights.contains(insight.id),
                        onTap: {
                            selectedInsight = insight
                        },
                        onExpand: {
                            toggleExpansion(for: insight.id)
                        }
                    )
                    .scaleEffect(hasAppeared ? 1.0 : 0.9)
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.8)
                        .delay(0.3 + Double(index) * 0.1),
                        value: hasAppeared
                    )
                }
            }
        }
    }
    
    // MARK: - AI Recommendations Section
    
    @ViewBuilder
    private var aiRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            HStack {
                Text("AI Recommendations")
                    .font(DSTypography.title.title3)
                    .foregroundColor(DSColors.neutral.text)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to full recommendations view
                }
                .font(DSTypography.body.medium)
                .foregroundColor(DSColors.primary.main)
            }
            
            LazyVStack(spacing: DSSpacing.sm) {
                ForEach(topRecommendations, id: \.id) { recommendation in
                    RecommendationCard(
                        recommendation: recommendation,
                        onAction: {
                            handleRecommendationAction(recommendation)
                        }
                    )
                }
            }
        }
        .opacity(hasAppeared ? 1.0 : 0.0)
        .offset(y: hasAppeared ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: hasAppeared)
    }
    
    // MARK: - Trends Section
    
    @ViewBuilder
    private var trendsSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            Text("Spending Patterns")
                .font(DSTypography.title.title3)
                .foregroundColor(DSColors.neutral.text)
            
            LazyVStack(spacing: DSSpacing.md) {
                PatternCard(
                    title: "Weekly Trends",
                    description: "You spend 35% more on weekends",
                    icon: "calendar.badge.exclamationmark",
                    color: DSColors.warning.main,
                    trend: .increasing
                )
                
                PatternCard(
                    title: "Monthly Pattern",
                    description: "Highest spending in the first week",
                    icon: "chart.bar.fill",
                    color: DSColors.info.main,
                    trend: .stable
                )
                
                PatternCard(
                    title: "Category Shift",
                    description: "Dining out increased by 15% this month",
                    icon: "arrow.up.right.circle.fill",
                    color: DSColors.error.main,
                    trend: .increasing
                )
            }
        }
        .opacity(hasAppeared ? 1.0 : 0.0)
        .offset(y: hasAppeared ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: hasAppeared)
    }
    
    // MARK: - Computed Properties
    
    private var overallConfidence: Double {
        guard !insights.isEmpty else { return 0 }
        return insights.reduce(0) { $0 + $1.confidence } / Double(insights.count)
    }
    
    private var potentialSavings: Double {
        insights.compactMap { insight in
            if case .optimization(let potential) = insight.impact {
                return potential
            }
            return nil
        }.reduce(0, +)
    }
    
    private var topRecommendations: [AIRecommendation] {
        [
            AIRecommendation(
                id: UUID(),
                title: "Reduce Weekend Spending",
                description: "Set a weekend spending limit to save $120/month",
                action: "Create Weekend Budget",
                priority: .high,
                potentialSaving: 120,
                confidence: 0.87
            ),
            AIRecommendation(
                id: UUID(),
                title: "Optimize Dining Budget",
                description: "Switch 2 restaurant meals to home cooking",
                action: "Set Dining Limit",
                priority: .medium,
                potentialSaving: 80,
                confidence: 0.75
            ),
            AIRecommendation(
                id: UUID(),
                title: "Consolidate Subscriptions",
                description: "Cancel 3 unused subscriptions found",
                action: "Review Subscriptions",
                priority: .low,
                potentialSaving: 45,
                confidence: 0.92
            )
        ]
    }
    
    // MARK: - Actions
    
    private func toggleExpansion(for insightId: UUID) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            if expandedInsights.contains(insightId) {
                expandedInsights.remove(insightId)
            } else {
                expandedInsights.insert(insightId)
            }
        }
    }
    
    private func handleRecommendationAction(_ recommendation: AIRecommendation) {
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        #endif
        
        // Handle recommendation action based on type
    }
}

// MARK: - Supporting Components

struct InsightMetric: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DSSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )
            
            VStack(spacing: DSSpacing.xs) {
                Text(value)
                    .font(DSTypography.body.semibold)
                    .foregroundColor(DSColors.neutral.text)
                
                Text(title)
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                
                Text(subtitle)
                    .font(DSTypography.caption.small)
                    .foregroundColor(DSColors.neutral.textTertiary)
            }
        }
        .padding(DSSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .cornerRadius(DSSpacing.radius.lg)
    }
}

struct BudgetInsightCard: View {
    let insight: BudgetInsight
    let isExpanded: Bool
    let onTap: () -> Void
    let onExpand: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            // Header with icon and confidence
            HStack {
                HStack(spacing: DSSpacing.sm) {
                    Image(systemName: insight.type.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(insight.type.color)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(insight.type.color.opacity(0.15))
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(insight.title)
                            .font(DSTypography.body.semibold)
                            .foregroundColor(DSColors.neutral.text)
                        
                        Text(insight.type.displayName)
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                    }
                }
                
                Spacer()
                
                // Confidence badge
                HStack(spacing: DSSpacing.xs) {
                    Circle()
                        .fill(confidenceColor)
                        .frame(width: 8, height: 8)
                    
                    Text("\(Int(insight.confidence * 100))%")
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                }
            }
            
            // Message
            Text(insight.message)
                .font(DSTypography.body.regular)
                .foregroundColor(DSColors.neutral.text)
                .lineLimit(isExpanded ? nil : 2)
                .animation(.easeInOut(duration: 0.3), value: isExpanded)
            
            // Expanded content
            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            
            // Action buttons
            HStack {
                if let actionText = insight.actionText {
                    Button(actionText) {
                        onTap()
                    }
                    .font(DSTypography.body.medium)
                    .foregroundColor(DSColors.primary.main)
                    .padding(.horizontal, DSSpacing.md)
                    .padding(.vertical, DSSpacing.sm)
                    .background(.ultraThinMaterial)
                    .cornerRadius(DSSpacing.radius.sm)
                }
                
                Spacer()
                
                Button(isExpanded ? "Less" : "More") {
                    onExpand()
                }
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.neutral.textSecondary)
            }
        }
        .padding(DSSpacing.lg)
        .background(insightCardBackground)
        .cornerRadius(DSSpacing.radius.xl)
    }
    
    @ViewBuilder
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            // Impact visualization
            if case .optimization(let potential) = insight.impact {
                HStack {
                    Text("Potential Savings:")
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                    
                    Spacer()
                    
                    Text(potential.formatAsCurrency())
                        .font(DSTypography.body.semibold)
                        .foregroundColor(DSColors.success.main)
                }
                .padding(.horizontal, DSSpacing.md)
                .padding(.vertical, DSSpacing.sm)
                .background(DSColors.success.main.opacity(0.1))
                .cornerRadius(DSSpacing.radius.sm)
            }
            
            // Additional details
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Analysis Details:")
                    .font(DSTypography.body.semibold)
                    .foregroundColor(DSColors.neutral.text)
                
                Text(generateDetailedAnalysis())
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                    .lineLimit(nil)
            }
        }
    }
    
    @ViewBuilder
    private var insightCardBackground: some View {
        RoundedRectangle(cornerRadius: DSSpacing.radius.xl)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: DSSpacing.radius.xl)
                    .fill(
                        LinearGradient(
                            colors: [
                                insight.type.color.opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DSSpacing.radius.xl)
                    .stroke(insight.type.color.opacity(0.2), lineWidth: 1)
            )
    }
    
    private var confidenceColor: Color {
        if insight.confidence >= 0.8 {
            return DSColors.success.main
        } else if insight.confidence >= 0.6 {
            return DSColors.warning.main
        } else {
            return DSColors.error.main
        }
    }
    
    private func generateDetailedAnalysis() -> String {
        switch insight.type {
        case .pattern:
            return "Based on 3 months of transaction data, this pattern occurs consistently and affects your budget by an average of 12% monthly."
        case .recommendation:
            return "This recommendation is generated from similar user behaviors and spending optimization strategies with proven results."
        case .achievement:
            return "Your spending discipline has improved significantly. This positive trend indicates successful budget management."
        case .alert:
            return "Early detection of potential budget strain. Taking action now can prevent over-spending and maintain financial health."
        case .overspending:
            return "Budget overspending detected. Immediate action recommended to prevent further financial strain."
        case .saving:
            return "Great job staying under budget! This savings pattern shows excellent financial discipline."
        }
    }
}

struct RecommendationCard: View {
    let recommendation: AIRecommendation
    let onAction: () -> Void
    
    var body: some View {
        HStack(spacing: DSSpacing.md) {
            // Priority indicator
            VStack {
                Circle()
                    .fill(recommendation.priority.color)
                    .frame(width: 8, height: 8)
                
                Text(recommendation.priority.displayName)
                    .font(DSTypography.caption.small)
                    .foregroundColor(DSColors.neutral.textTertiary)
                    .rotationEffect(.degrees(-90))
                    .fixedSize()
            }
            .frame(width: 20)
            
            // Content
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(recommendation.title)
                    .font(DSTypography.body.semibold)
                    .foregroundColor(DSColors.neutral.text)
                
                Text(recommendation.description)
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                    .lineLimit(2)
                
                HStack {
                    Text("Save \(recommendation.potentialSaving.formatAsCurrency())")
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.success.main)
                    
                    Spacer()
                    
                    Text("\(Int(recommendation.confidence * 100))% confidence")
                        .font(DSTypography.caption.small)
                        .foregroundColor(DSColors.neutral.textTertiary)
                }
            }
            
            // Action button
            Button(recommendation.action) {
                onAction()
            }
            .font(DSTypography.caption.regular).fontWeight(.medium)
            .foregroundColor(DSColors.primary.main)
            .padding(.horizontal, DSSpacing.sm)
            .padding(.vertical, DSSpacing.xs)
            .background(.ultraThinMaterial)
            .cornerRadius(DSSpacing.radius.sm)
        }
        .padding(DSSpacing.md)
        .background(.ultraThinMaterial)
        .cornerRadius(DSSpacing.radius.lg)
    }
}

struct PatternCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let trend: SpendingTrend
    
    var body: some View {
        HStack(spacing: DSSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )
            
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(title)
                    .font(DSTypography.body.semibold)
                    .foregroundColor(DSColors.neutral.text)
                
                Text(description)
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Trend indicator
            Image(systemName: trend.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(trend.color)
        }
        .padding(DSSpacing.md)
        .background(.ultraThinMaterial)
        .cornerRadius(DSSpacing.radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DSSpacing.radius.lg)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Insight Detail View

struct InsightDetailView: View {
    let insight: BudgetInsight
    let budget: Budget
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DSSpacing.xl) {
                    // Header
                    VStack(alignment: .leading, spacing: DSSpacing.md) {
                        HStack {
                            Image(systemName: insight.type.icon)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(insight.type.color)
                            
                            Text(insight.title)
                                .font(DSTypography.title.title2)
                                .foregroundColor(DSColors.neutral.text)
                        }
                        
                        Text(insight.message)
                            .font(DSTypography.body.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                    }
                    
                    // Detailed analysis would go here
                    Text("Detailed analysis and actionable recommendations would be displayed here with charts, comparisons, and step-by-step guidance.")
                        .font(DSTypography.body.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                        .padding(DSSpacing.lg)
                        .background(.ultraThinMaterial)
                        .cornerRadius(DSSpacing.radius.lg)
                }
                .padding()
            }
            .navigationTitle("Insight Details")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Models

struct AIRecommendation: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let action: String
    let priority: RecommendationPriority
    let potentialSaving: Double
    let confidence: Double
    
    enum RecommendationPriority {
        case high, medium, low
        
        var color: Color {
            switch self {
            case .high: return DSColors.error.main
            case .medium: return DSColors.warning.main
            case .low: return DSColors.success.main
            }
        }
        
        var displayName: String {
            switch self {
            case .high: return "HIGH"
            case .medium: return "MED"
            case .low: return "LOW"
            }
        }
    }
}

enum SpendingTrend {
    case increasing, decreasing, stable
    
    var icon: String {
        switch self {
        case .increasing: return "arrow.up.right"
        case .decreasing: return "arrow.down.right"
        case .stable: return "minus"
        }
    }
    
    var color: Color {
        switch self {
        case .increasing: return DSColors.error.main
        case .decreasing: return DSColors.success.main
        case .stable: return DSColors.neutral.textSecondary
        }
    }
}

// MARK: - Extensions

extension BudgetInsight.InsightType {
    var icon: String {
        switch self {
        case .pattern: return "chart.xyaxis.line"
        case .recommendation: return "lightbulb.fill"
        case .achievement: return "trophy.fill"
        case .alert: return "exclamationmark.triangle.fill"
        case .overspending: return "exclamationmark.circle.fill"
        case .saving: return "checkmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .pattern: return DSColors.info.main
        case .recommendation: return DSColors.warning.main
        case .achievement: return DSColors.success.main
        case .alert: return DSColors.error.main
        case .overspending: return DSColors.error.main
        case .saving: return DSColors.success.main
        }
    }
    
    var displayName: String {
        switch self {
        case .pattern: return "Pattern"
        case .recommendation: return "Recommendation"
        case .achievement: return "Achievement"
        case .alert: return "Warning"
        case .overspending: return "Overspending"
        case .saving: return "Saving"
        }
    }
}

// MARK: - Preview

#Preview("Budget Insights") {
    ScrollView {
        BudgetInsights(
            budget: Budget(
                name: "Dining Out",
                amount: 600,
                period: .monthly
            ),
            currentSpending: 450,
            insights: [
                BudgetInsight(
                    type: .pattern,
                    title: "Weekend Spending Pattern",
                    message: "You consistently spend 40% more on weekends compared to weekdays.",
                    actionText: "Set Weekend Limit",
                    impact: .optimization(120),
                    confidence: 0.85
                ),
                BudgetInsight(
                    type: .recommendation,
                    title: "Dining Optimization",
                    message: "Consider cooking 2 more meals at home to save money while maintaining your dining experience.",
                    actionText: "Create Meal Plan",
                    impact: .optimization(80),
                    confidence: 0.78
                ),
                BudgetInsight(
                    type: .achievement,
                    title: "Budget Discipline",
                    message: "Excellent work! You're 15% under budget compared to last month.",
                    actionText: nil,
                    impact: .positive,
                    confidence: 0.95
                )
            ]
        )
    }
    .padding()
    .background(
        LinearGradient(
            colors: [DSColors.neutral.background, DSColors.neutral.backgroundSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
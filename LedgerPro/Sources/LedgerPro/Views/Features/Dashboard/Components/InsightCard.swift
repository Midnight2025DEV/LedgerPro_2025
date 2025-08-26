import SwiftUI

/// AI-Powered Insight Card
///
/// A sophisticated insight card that displays AI-generated financial insights
/// with glass morphism effects, animated icons, and contextual actions.
struct InsightCard: View {
    let insight: FinancialInsight
    @State private var hasAppeared = false
    @State private var isHovered = false
    @State private var isDismissed = false
    @State private var showFeedbackOptions = false
    
    var body: some View {
        if !isDismissed {
            GlassCard(
                gradient: insightGradient,
                padding: DSSpacing.lg,
                cornerRadius: 16,
                enableBorderAnimation: true
            ) {
                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    // Header with icon and dismiss
                    insightHeader
                    
                    // Main content
                    insightContent
                    
                    // Action button if applicable
                    if !insight.action.isEmpty {
                        actionButton
                    }
                    
                    // Feedback options
                    if showFeedbackOptions {
                        feedbackSection
                    }
                }
            }
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .opacity(hasAppeared ? 1.0 : 0.0)
            .offset(x: hasAppeared ? 0 : -20)
            .onHover { hovering in
                withAnimation(DSAnimations.common.gentleBounce) {
                    isHovered = hovering
                }
            }
            .onAppear {
                withAnimation(
                    DSAnimations.common.standardTransition.delay(Double.random(in: 0...0.4))
                ) {
                    hasAppeared = true
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            ))
        }
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private var insightHeader: some View {
        HStack {
            // Animated insight icon
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(insight.type.color.opacity(0.4), lineWidth: 1)
                    )
                
                Image(systemName: insight.icon)
                    .font(DSTypography.body.medium)
                    .foregroundColor(insight.type.color)
                    .scaleEffect(hasAppeared ? 1.0 : 0.8)
                    .rotationEffect(.degrees(hasAppeared ? 0 : -180))
                    .animation(
                        DSAnimations.common.gentleBounce.delay(0.2),
                        value: hasAppeared
                    )
            }
            
            // Insight type indicator
            insightTypeChip
            
            Spacer()
            
            // Dismiss and feedback buttons
            HStack(spacing: DSSpacing.xs) {
                Button(action: {
                    withAnimation(DSAnimations.common.quickFeedback) {
                        showFeedbackOptions.toggle()
                    }
                }) {
                    Image(systemName: "hand.thumbsup")
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                }
                .buttonStyle(.plain)
                .opacity(isHovered ? 1.0 : 0.7)
                
                Button(action: dismissInsight) {
                    Image(systemName: "xmark.circle.fill")
                        .font(DSTypography.body.medium)
                        .foregroundColor(DSColors.neutral.textSecondary)
                }
                .buttonStyle(.plain)
                .opacity(isHovered ? 1.0 : 0.7)
            }
            .animation(DSAnimations.common.quickFeedback, value: isHovered)
        }
    }
    
    @ViewBuilder
    private var insightTypeChip: some View {
        Text(insight.type.displayName)
            .font(DSTypography.caption.small)
            .foregroundColor(insight.type.color)
            .textCase(.uppercase)
            .tracking(0.5)
            .padding(.horizontal, DSSpacing.xs)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(insight.type.color.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(insight.type.color.opacity(0.3), lineWidth: 0.5)
                    )
            )
            .scaleEffect(hasAppeared ? 1.0 : 0.8)
            .opacity(hasAppeared ? 1.0 : 0.0)
            .animation(
                DSAnimations.common.standardTransition.delay(0.1),
                value: hasAppeared
            )
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var insightContent: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            // Title with highlighted metrics
            insightTitle
            
            // Description with smart formatting
            insightDescription
        }
    }
    
    @ViewBuilder
    private var insightTitle: some View {
        Text(insight.title)
            .font(DSTypography.title.title3)
            .foregroundColor(DSColors.neutral.text)
            .fontWeight(.semibold)
    }
    
    @ViewBuilder
    private var insightDescription: some View {
        Text(formatDescriptionWithHighlights(insight.description))
            .font(DSTypography.body.regular)
            .foregroundColor(DSColors.neutral.textSecondary)
            .lineLimit(3)
            .multilineTextAlignment(.leading)
    }
    
    // MARK: - Action Button
    
    @ViewBuilder
    private var actionButton: some View {
        Button(action: {
            // Handle insight action
            handleInsightAction()
        }) {
            HStack(spacing: DSSpacing.sm) {
                Text(insight.action)
                    .font(DSTypography.body.medium)
                    .foregroundColor(.white)
                
                Image(systemName: "arrow.right")
                    .font(DSTypography.caption.regular)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, DSSpacing.md)
            .padding(.vertical, DSSpacing.sm)
            .background(
                LinearGradient(
                    colors: [
                        insight.type.color,
                        insight.type.color.opacity(0.8)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(DSSpacing.radius.lg)
            .shadow(
                color: insight.type.color.opacity(0.3),
                radius: 4,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(hasAppeared ? 1.0 : 0.9)
        .opacity(hasAppeared ? 1.0 : 0.0)
        .animation(
            DSAnimations.common.standardTransition.delay(0.3),
            value: hasAppeared
        )
    }
    
    // MARK: - Feedback Section
    
    @ViewBuilder
    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Divider()
                .overlay(DSColors.neutral.border)
            
            Text("Was this insight helpful?")
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.neutral.textSecondary)
            
            HStack(spacing: DSSpacing.sm) {
                feedbackButton(
                    title: "Yes",
                    icon: "hand.thumbsup.fill",
                    color: DSColors.success.main,
                    action: { submitFeedback(helpful: true) }
                )
                
                feedbackButton(
                    title: "No",
                    icon: "hand.thumbsdown.fill",
                    color: DSColors.error.main,
                    action: { submitFeedback(helpful: false) }
                )
                
                feedbackButton(
                    title: "Not relevant",
                    icon: "minus.circle.fill",
                    color: DSColors.neutral.n400,
                    action: { submitFeedback(helpful: nil) }
                )
                
                Spacer()
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
    
    @ViewBuilder
    private func feedbackButton(
        title: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: DSSpacing.xs) {
                Image(systemName: icon)
                    .font(DSTypography.caption.small)
                Text(title)
                    .font(DSTypography.caption.small)
            }
            .foregroundColor(color)
            .padding(.horizontal, DSSpacing.xs)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(color.opacity(0.1))
                    .overlay(
                        Capsule()
                            .stroke(color.opacity(0.2), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Computed Properties
    
    private var insightGradient: LinearGradient {
        LinearGradient(
            colors: [
                insight.type.color.opacity(0.15),
                insight.type.color.opacity(0.05),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Helper Methods
    
    private func formatDescriptionWithHighlights(_ text: String) -> AttributedString {
        var attributedString = AttributedString(text)
        
        // Highlight percentages
        let percentageRegex = try? NSRegularExpression(pattern: "\\d+(\\.\\d+)?%", options: [])
        let range = NSRange(location: 0, length: text.count)
        
        percentageRegex?.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
            if let matchRange = match?.range,
               let swiftRange = Range(matchRange, in: text) {
                let attributedRange = AttributedString.Index(swiftRange.lowerBound, within: attributedString)!..<AttributedString.Index(swiftRange.upperBound, within: attributedString)!
                attributedString[attributedRange].foregroundColor = insight.type.color
                attributedString[attributedRange].font = DSTypography.body.medium
            }
        }
        
        // Highlight currency amounts
        let currencyRegex = try? NSRegularExpression(pattern: "\\$[\\d,]+(\\.\\d{2})?", options: [])
        currencyRegex?.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
            if let matchRange = match?.range,
               let swiftRange = Range(matchRange, in: text) {
                let attributedRange = AttributedString.Index(swiftRange.lowerBound, within: attributedString)!..<AttributedString.Index(swiftRange.upperBound, within: attributedString)!
                attributedString[attributedRange].foregroundColor = insight.type.color
                attributedString[attributedRange].font = DSTypography.body.medium
            }
        }
        
        return attributedString
    }
    
    private func dismissInsight() {
        withAnimation(DSAnimations.common.standardTransition) {
            isDismissed = true
        }
    }
    
    private func handleInsightAction() {
        // Handle insight-specific actions
        switch insight.id {
        case "spending-up":
            // Navigate to spending breakdown
            break
        case "savings-goal":
            // Show savings progress
            break
        case "subscription":
            // Navigate to subscription management
            break
        default:
            break
        }
    }
    
    private func submitFeedback(helpful: Bool?) {
        // Submit feedback to analytics
        withAnimation(DSAnimations.common.quickFeedback) {
            showFeedbackOptions = false
        }
        
        // Auto-dismiss after feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            dismissInsight()
        }
    }
}

// MARK: - Extensions

extension FinancialInsight.InsightType {
    var displayName: String {
        switch self {
        case .positive: return "Insight"
        case .warning: return "Alert"
        case .neutral: return "Tip"
        }
    }
}

// Note: Font extension not needed as DSTypography provides Font objects directly

// MARK: - Preview

#Preview("Insight Cards") {
    VStack(spacing: DSSpacing.lg) {
        // Positive insight
        InsightCard(insight: FinancialInsight(
            id: "savings",
            type: .positive,
            title: "Great savings progress!",
            description: "You're 78% towards your $2,000 monthly savings target with $1,560 saved so far.",
            action: "View progress",
            icon: "target"
        ))
        
        // Warning insight
        InsightCard(insight: FinancialInsight(
            id: "budget",
            type: .warning,
            title: "Budget threshold exceeded",
            description: "Your entertainment spending of $320 has exceeded the $250 monthly budget by 28%.",
            action: "Adjust budget",
            icon: "exclamationmark.triangle.fill"
        ))
        
        // Preview insight
        InsightCard(insight: FinancialInsight(
            id: "sample",
            type: .warning,
            title: "Spending increased 15%",
            description: "Your dining expenses of $450 are 15% higher than usual this month. Consider reviewing your dining budget.",
            action: "Review dining budget",
            icon: "chart.line.uptrend.xyaxis"
        ))
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

#Preview("Insight Card Showcase") {
    ScrollView {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            Text("AI-Powered Insights")
                .font(DSTypography.title.title1)
                .foregroundColor(DSColors.neutral.text)
            
            // Different insight types
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                ForEach([
                    FinancialInsight(
                        id: "spending-pattern",
                        type: .neutral,
                        title: "New spending pattern detected",
                        description: "You've spent 25% more on groceries this month ($340 vs $270 average). This could be due to recent price increases.",
                        action: "View grocery trends",
                        icon: "cart.fill"
                    ),
                    FinancialInsight(
                        id: "investment-opportunity",
                        type: .positive,
                        title: "Investment opportunity",
                        description: "Your emergency fund goal of $5,000 is complete! Consider investing the excess $1,200 for better returns.",
                        action: "Explore investments",
                        icon: "chart.line.uptrend.xyaxis"
                    ),
                    FinancialInsight(
                        id: "subscription-waste",
                        type: .warning,
                        title: "Unused subscription found",
                        description: "Your Spotify Premium subscription ($9.99/month) shows no activity in the last 45 days.",
                        action: "Manage subscriptions",
                        icon: "music.note.tv"
                    )
                ], id: \.id) { insight in
                    InsightCard(insight: insight)
                }
            }
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
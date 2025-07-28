import SwiftUI

/// Balance Hero Card - The main focal point of the dashboard
///
/// A sophisticated hero card displaying the user's total balance with animated numbers,
/// trend visualization, and premium glass morphism effects.
struct BalanceHeroCard: View {
    let balance: Double
    let change: String
    let trend: [Double]
    let timeframe: ModernDashboard.Timeframe
    
    @State private var hasAppeared = false
    @State private var sparklineAnimationProgress: CGFloat = 0
    @State private var isHovered = false
    
    var body: some View {
        GlassCard(
            gradient: balanceGradient,
            padding: DSSpacing.xl,
            cornerRadius: 20,
            enableBorderAnimation: true
        ) {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                // Header with balance label and menu
                cardHeader
                
                // Main balance display
                balanceSection
                
                // Trend visualization
                trendSection
                
                // Footer with accounts summary
                footerSection
            }
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(DSAnimations.common.gentleBounce) {
                isHovered = hovering
            }
        }
        .onAppear {
            withAnimation(DSAnimations.common.standardTransition.delay(0.2)) {
                hasAppeared = true
            }
            
            // Animate sparkline
            withAnimation(
                .easeInOut(duration: 1.5).delay(0.5)
            ) {
                sparklineAnimationProgress = 1.0
            }
        }
    }
    
    // MARK: - Card Header
    
    @ViewBuilder
    private var cardHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Total Balance")
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Text("All accounts included")
                    .font(DSTypography.caption.small)
                    .foregroundColor(DSColors.neutral.textTertiary)
            }
            
            Spacer()
            
            // Menu button
            Button(action: {
                // Show balance options menu
            }) {
                Image(systemName: "ellipsis.circle.fill")
                    .font(DSTypography.title.title3)
                    .foregroundColor(DSColors.neutral.textSecondary)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 32, height: 32)
                    )
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1.0 : 0.7)
            .animation(DSAnimations.common.quickFeedback, value: isHovered)
        }
    }
    
    // MARK: - Balance Section
    
    @ViewBuilder
    private var balanceSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            // Main balance with animation
            HStack(alignment: .firstTextBaseline, spacing: DSSpacing.sm) {
                AnimatedNumber.largeAmount(balance)
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .offset(x: hasAppeared ? 0 : -20)
                
                Spacer()
                
                // Change indicator with enhanced styling
                changeIndicator
            }
            
            // Net worth subtitle
            HStack(spacing: DSSpacing.sm) {
                Text("Net Worth")
                    .font(DSTypography.body.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                
                // Trend arrow
                Image(systemName: trendArrowIcon)
                    .font(DSTypography.caption.regular)
                    .foregroundColor(changeColor)
                    .rotationEffect(.degrees(hasAppeared ? 0 : -90))
                    .animation(
                        DSAnimations.common.gentleBounce.delay(0.8),
                        value: hasAppeared
                    )
                
                Text("trending \(trendDirection)")
                    .font(DSTypography.caption.regular)
                    .foregroundColor(changeColor)
            }
        }
    }
    
    // MARK: - Trend Section
    
    @ViewBuilder
    private var trendSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            HStack {
                Text("Balance Trend")
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Spacer()
                
                Text(timeframe.displayName)
                    .font(DSTypography.caption.small)
                    .foregroundColor(DSColors.neutral.textTertiary)
            }
            
            // Sparkline chart
            SparklineChart(
                data: trend,
                color: changeColor,
                animationProgress: sparklineAnimationProgress
            )
            .frame(height: 60)
        }
    }
    
    // MARK: - Footer Section
    
    @ViewBuilder
    private var footerSection: some View {
        VStack(spacing: DSSpacing.md) {
            Divider()
                .overlay(DSColors.neutral.border)
            
            HStack(spacing: DSSpacing.lg) {
                // Checking account preview
                AccountPreview(
                    name: "Checking",
                    balance: balance * 0.3,
                    icon: "banknote.fill",
                    color: DSColors.primary.main
                )
                
                // Savings account preview
                AccountPreview(
                    name: "Savings",
                    balance: balance * 0.5,
                    icon: "piggybank.fill",
                    color: DSColors.success.main
                )
                
                // Investment preview
                AccountPreview(
                    name: "Investments",
                    balance: balance * 0.2,
                    icon: "chart.line.uptrend.xyaxis",
                    color: DSColors.warning.main
                )
            }
        }
    }
    
    // MARK: - Change Indicator
    
    @ViewBuilder
    private var changeIndicator: some View {
        HStack(spacing: DSSpacing.xs) {
            Image(systemName: changeIconName)
                .font(DSTypography.caption.small)
                .foregroundColor(changeColor)
            
            Text(change)
                .font(DSTypography.body.semibold)
                .foregroundColor(changeColor)
        }
        .padding(.horizontal, DSSpacing.md)
        .padding(.vertical, DSSpacing.sm)
        .background(
            Capsule()
                .fill(changeColor.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(changeColor.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(hasAppeared ? 1.0 : 0.8)
        .opacity(hasAppeared ? 1.0 : 0.0)
        .animation(
            DSAnimations.common.gentleBounce.delay(0.6),
            value: hasAppeared
        )
    }
    
    // MARK: - Computed Properties
    
    private var balanceGradient: LinearGradient {
        if changeColor == DSColors.success.main {
            return LinearGradient(
                colors: [
                    DSColors.success.s50.opacity(0.4),
                    DSColors.success.s100.opacity(0.2),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if changeColor == DSColors.error.main {
            return LinearGradient(
                colors: [
                    DSColors.error.e50.opacity(0.4),
                    DSColors.error.e100.opacity(0.2),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    DSColors.primary.p50.opacity(0.4),
                    DSColors.primary.p100.opacity(0.2),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var changeColor: Color {
        if change.starts(with: "+") {
            return DSColors.success.main
        } else if change.starts(with: "-") {
            return DSColors.error.main
        }
        return DSColors.neutral.textSecondary
    }
    
    private var changeIconName: String {
        if change.starts(with: "+") {
            return "arrow.up.right"
        } else if change.starts(with: "-") {
            return "arrow.down.right"
        }
        return "minus"
    }
    
    private var trendArrowIcon: String {
        if change.starts(with: "+") {
            return "arrow.up"
        } else if change.starts(with: "-") {
            return "arrow.down"
        }
        return "minus"
    }
    
    private var trendDirection: String {
        if change.starts(with: "+") {
            return "up"
        } else if change.starts(with: "-") {
            return "down"
        }
        return "flat"
    }
}

// MARK: - Account Preview

struct AccountPreview: View {
    let name: String
    let balance: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            HStack(spacing: DSSpacing.xs) {
                Image(systemName: icon)
                    .font(DSTypography.caption.regular)
                    .foregroundColor(color)
                
                Text(name)
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                
                Spacer()
            }
            
            Text(balance.formatAsCurrency())
                .font(DSTypography.body.semibold)
                .foregroundColor(DSColors.neutral.text)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Sparkline Chart

struct SparklineChart: View {
    let data: [Double]
    let color: Color
    let animationProgress: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            if !data.isEmpty {
                ZStack {
                    // Background gradient fill
                    sparklineFill(width: width, height: height)
                        .fill(
                            LinearGradient(
                                colors: [
                                    color.opacity(0.3),
                                    color.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .clipShape(sparklinePath(width: width, height: height))
                    
                    // Main line
                    sparklinePath(width: width, height: height)
                        .trim(from: 0, to: animationProgress)
                        .stroke(
                            LinearGradient(
                                colors: [color.opacity(0.8), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(
                                lineWidth: 2,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                    
                    // Data points
                    ForEach(data.indices, id: \.self) { index in
                        if index < Int(Double(data.count) * Double(animationProgress)) {
                            let point = dataPoint(at: index, width: width, height: height)
                            Circle()
                                .fill(color)
                                .frame(width: 3, height: 3)
                                .position(point)
                                .opacity(0.8)
                        }
                    }
                }
            } else {
                // Empty state
                RoundedRectangle(cornerRadius: 4)
                    .fill(DSColors.neutral.n200.opacity(0.3))
                    .frame(height: 2)
                    .frame(maxWidth: .infinity)
                    .position(x: width / 2, y: height / 2)
            }
        }
    }
    
    private func sparklinePath(width: CGFloat, height: CGFloat) -> Path {
        guard !data.isEmpty else { return Path() }
        
        let minValue = data.min() ?? 0
        let maxValue = data.max() ?? 1
        let range = maxValue - minValue
        
        var path = Path()
        
        for (index, value) in data.enumerated() {
            let x = (CGFloat(index) / CGFloat(data.count - 1)) * width
            let normalizedValue = range > 0 ? (value - minValue) / range : 0.5
            let y = height - (normalizedValue * height * 0.8) - (height * 0.1) // 10% padding
            
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        return path
    }
    
    private func sparklineFill(width: CGFloat, height: CGFloat) -> Path {
        guard !data.isEmpty else { return Path() }
        
        var path = sparklinePath(width: width, height: height)
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
    
    private func dataPoint(at index: Int, width: CGFloat, height: CGFloat) -> CGPoint {
        guard !data.isEmpty && index < data.count else { return .zero }
        
        let minValue = data.min() ?? 0
        let maxValue = data.max() ?? 1
        let range = maxValue - minValue
        
        let x = (CGFloat(index) / CGFloat(data.count - 1)) * width
        let normalizedValue = range > 0 ? (data[index] - minValue) / range : 0.5
        let y = height - (normalizedValue * height * 0.8) - (height * 0.1)
        
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Convenience Initializers

extension BalanceHeroCard {
    /// Create hero card with sample data for preview
    static func preview() -> BalanceHeroCard {
        BalanceHeroCard(
            balance: 47234.56,
            change: "+8.7%",
            trend: [
                45000, 45200, 44800, 46100, 47000, 46800, 47234
            ],
            timeframe: .month
        )
    }
    
    /// Create hero card with error state
    static func errorState() -> BalanceHeroCard {
        BalanceHeroCard(
            balance: 0,
            change: "0%",
            trend: [],
            timeframe: .month
        )
    }
}

// MARK: - Preview

#Preview("Balance Hero Card") {
    VStack(spacing: DSSpacing.xl) {
        // Normal state
        BalanceHeroCard.preview()
        
        // With negative change
        BalanceHeroCard(
            balance: 42890.34,
            change: "-3.2%",
            trend: [
                45000, 44500, 44200, 43800, 43500, 43100, 42890
            ],
            timeframe: .week
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
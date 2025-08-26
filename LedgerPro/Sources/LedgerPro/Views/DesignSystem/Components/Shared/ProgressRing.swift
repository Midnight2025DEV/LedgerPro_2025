import SwiftUI

/// Animated circular progress ring component
///
/// A sophisticated progress ring with gradient strokes, smooth animations,
/// and optional center content for displaying percentages or icons.
struct ProgressRing: View {
    let progress: Double // 0.0 to 1.0
    let size: CGFloat
    let strokeWidth: CGFloat
    let gradient: LinearGradient
    let backgroundColor: Color
    let animationDuration: TimeInterval
    let showPercentage: Bool
    let centerIcon: String?
    let centerContent: AnyView?
    
    @State private var animatedProgress: Double = 0
    @State private var isAnimating = false
    
    init(
        progress: Double,
        size: CGFloat = 80,
        strokeWidth: CGFloat = 6,
        gradient: LinearGradient? = nil,
        backgroundColor: Color = DSColors.neutral.n200,
        animationDuration: TimeInterval = 1.0,
        showPercentage: Bool = true,
        centerIcon: String? = nil,
        centerContent: AnyView? = nil
    ) {
        self.progress = max(0, min(1, progress)) // Clamp between 0 and 1
        self.size = size
        self.strokeWidth = strokeWidth
        self.backgroundColor = backgroundColor
        self.animationDuration = animationDuration
        self.showPercentage = showPercentage
        self.centerIcon = centerIcon
        self.centerContent = centerContent
        
        // Default gradient based on progress value
        if let customGradient = gradient {
            self.gradient = customGradient
        } else {
            // Dynamic gradient based on progress
            if progress >= 0.8 {
                self.gradient = LinearGradient(
                    colors: [DSColors.success.s400, DSColors.success.s600],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else if progress >= 0.5 {
                self.gradient = LinearGradient(
                    colors: [DSColors.primary.p400, DSColors.primary.p600],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else if progress >= 0.3 {
                self.gradient = LinearGradient(
                    colors: [DSColors.warning.w400, DSColors.warning.w600],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                self.gradient = LinearGradient(
                    colors: [DSColors.error.e400, DSColors.error.e600],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(backgroundColor, lineWidth: strokeWidth)
                .frame(width: size, height: size)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    gradient,
                    style: StrokeStyle(
                        lineWidth: strokeWidth,
                        lineCap: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90)) // Start from top
                .shadow(
                    color: DSColors.primary.main.opacity(0.3),
                    radius: strokeWidth / 2,
                    x: 0,
                    y: 1
                )
            
            // Center content
            centerView
                .frame(width: size - strokeWidth * 2, height: size - strokeWidth * 2)
        }
        .onAppear {
            animateProgress()
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(DSAnimations.Easing.easeInOut(duration: animationDuration)) {
                animatedProgress = newValue
            }
        }
    }
    
    // MARK: - Center Content
    
    @ViewBuilder
    private var centerView: some View {
        if let centerContent = centerContent {
            centerContent
        } else if let centerIcon = centerIcon {
            Image(systemName: centerIcon)
                .font(.system(size: size * 0.25, weight: .semibold))
                .foregroundColor(iconColor)
        } else if showPercentage {
            VStack(spacing: 2) {
                Text("\(Int(animatedProgress * 100))")
                    .font(.system(size: size * 0.18, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
                    .contentTransition(.numericText(value: animatedProgress * 100))
                
                Text("%")
                    .font(.system(size: size * 0.08, weight: .medium))
                    .foregroundColor(textColor.opacity(0.7))
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var textColor: Color {
        if animatedProgress >= 0.8 {
            return DSColors.success.main
        } else if animatedProgress >= 0.5 {
            return DSColors.primary.main
        } else if animatedProgress >= 0.3 {
            return DSColors.warning.main
        } else {
            return DSColors.error.main
        }
    }
    
    private var iconColor: Color {
        return textColor
    }
    
    // MARK: - Animation
    
    private func animateProgress() {
        withAnimation(
            .spring(
                response: animationDuration * 0.6,
                dampingFraction: 0.8,
                blendDuration: 0
            )
            .delay(0.1) // Small delay for better visual impact
        ) {
            animatedProgress = progress
        }
    }
}

// MARK: - Convenience Initializers

extension ProgressRing {
    /// Financial progress ring for budget tracking
    static func budget(
        spent: Double,
        total: Double,
        size: CGFloat = 80,
        strokeWidth: CGFloat = 6
    ) -> ProgressRing {
        let progress = total > 0 ? spent / total : 0
        
        return ProgressRing(
            progress: progress,
            size: size,
            strokeWidth: strokeWidth,
            gradient: budgetGradient(for: progress),
            showPercentage: true
        )
    }
    
    /// Goal progress ring for savings targets
    static func goal(
        current: Double,
        target: Double,
        size: CGFloat = 80,
        strokeWidth: CGFloat = 6,
        icon: String = "target"
    ) -> ProgressRing {
        let progress = target > 0 ? current / target : 0
        
        return ProgressRing(
            progress: progress,
            size: size,
            strokeWidth: strokeWidth,
            gradient: goalGradient(for: progress),
            showPercentage: false,
            centerIcon: icon
        )
    }
    
    /// Performance ring for investment returns
    static func performance(
        percentage: Double,
        size: CGFloat = 80,
        strokeWidth: CGFloat = 6
    ) -> ProgressRing {
        // Convert percentage to 0-1 scale (assuming 100% = perfect performance)
        let progress = max(0, min(1, percentage / 100))
        
        return ProgressRing(
            progress: progress,
            size: size,
            strokeWidth: strokeWidth,
            gradient: performanceGradient(for: percentage),
            showPercentage: true
        )
    }
    
    /// Category spending ring
    static func categorySpending(
        percentage: Double,
        category: String,
        size: CGFloat = 60,
        strokeWidth: CGFloat = 4
    ) -> ProgressRing {
        let progress = max(0, min(1, percentage / 100))
        let categoryColor = DSColors.category.color(for: category)
        
        return ProgressRing(
            progress: progress,
            size: size,
            strokeWidth: strokeWidth,
            gradient: LinearGradient(
                colors: [categoryColor.opacity(0.8), categoryColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            showPercentage: true
        )
    }
    
    /// Small indicator ring
    static func indicator(
        progress: Double,
        size: CGFloat = 24,
        strokeWidth: CGFloat = 3,
        color: Color = DSColors.primary.main
    ) -> ProgressRing {
        ProgressRing(
            progress: progress,
            size: size,
            strokeWidth: strokeWidth,
            gradient: LinearGradient(
                colors: [color.opacity(0.8), color],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            showPercentage: false
        )
    }
}

// MARK: - Gradient Helpers

extension ProgressRing {
    private static func budgetGradient(for progress: Double) -> LinearGradient {
        if progress <= 0.75 {
            // Good spending - green gradient
            return LinearGradient(
                colors: [DSColors.success.s400, DSColors.success.s600],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if progress <= 0.9 {
            // Warning - yellow gradient
            return LinearGradient(
                colors: [DSColors.warning.w400, DSColors.warning.w600],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Over budget - red gradient
            return LinearGradient(
                colors: [DSColors.error.e400, DSColors.error.e600],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private static func goalGradient(for progress: Double) -> LinearGradient {
        if progress >= 1.0 {
            // Goal achieved - success gradient
            return LinearGradient(
                colors: [DSColors.success.s400, DSColors.success.s600],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if progress >= 0.75 {
            // Close to goal - primary gradient
            return LinearGradient(
                colors: [DSColors.primary.p400, DSColors.primary.p600],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Starting progress - neutral gradient
            return LinearGradient(
                colors: [DSColors.neutral.n400, DSColors.neutral.n600],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private static func performanceGradient(for percentage: Double) -> LinearGradient {
        if percentage >= 10 {
            // Excellent performance
            return LinearGradient(
                colors: [DSColors.success.s300, DSColors.success.s600],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if percentage >= 0 {
            // Positive performance
            return LinearGradient(
                colors: [DSColors.primary.p400, DSColors.primary.p600],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Negative performance
            return LinearGradient(
                colors: [DSColors.error.e400, DSColors.error.e600],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Multi-Ring Progress

/// Multiple concentric progress rings for complex data
struct MultiProgressRing: View {
    let rings: [RingData]
    let size: CGFloat
    
    struct RingData {
        let progress: Double
        let gradient: LinearGradient
        let strokeWidth: CGFloat
        
        init(
            progress: Double,
            gradient: LinearGradient,
            strokeWidth: CGFloat = 6
        ) {
            self.progress = progress
            self.gradient = gradient
            self.strokeWidth = strokeWidth
        }
    }
    
    init(rings: [RingData], size: CGFloat = 120) {
        self.rings = rings
        self.size = size
    }
    
    var body: some View {
        ZStack {
            ForEach(rings.indices, id: \.self) { index in
                let ring = rings[index]
                let ringSize = size - CGFloat(index * 20)
                
                ProgressRing(
                    progress: ring.progress,
                    size: ringSize,
                    strokeWidth: ring.strokeWidth,
                    gradient: ring.gradient,
                    showPercentage: false
                )
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Add a small progress indicator
    func progressIndicator(
        progress: Double,
        color: Color = DSColors.primary.main
    ) -> some View {
        self.overlay(
            ProgressRing.indicator(
                progress: progress,
                color: color
            ),
            alignment: .topTrailing
        )
    }
}

// MARK: - Preview

#Preview("Progress Rings") {
    ScrollView {
        VStack(spacing: DSSpacing.xl) {
            // Basic progress rings
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                Text("Basic Progress Rings")
                    .font(DSTypography.title.title2)
                    .foregroundColor(DSColors.neutral.text)
                
                HStack(spacing: DSSpacing.xl) {
                    VStack {
                        ProgressRing(progress: 0.75)
                        Text("75% Complete")
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                    }
                    
                    VStack {
                        ProgressRing(progress: 0.45, centerIcon: "chart.bar.fill")
                        Text("Performance")
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                    }
                    
                    VStack {
                        ProgressRing(progress: 0.92, size: 60, strokeWidth: 4)
                        Text("Goal Progress")
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                    }
                }
            }
            .cleanGlassCard()
            
            // Financial progress rings
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                Text("Financial Progress")
                    .font(DSTypography.title.title2)
                    .foregroundColor(DSColors.neutral.text)
                
                HStack(spacing: DSSpacing.xl) {
                    VStack {
                        ProgressRing.budget(spent: 2750, total: 3000)
                        Text("Monthly Budget")
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                        Text("$2,750 / $3,000")
                            .font(DSTypography.caption.small)
                            .foregroundColor(DSColors.neutral.textTertiary)
                    }
                    
                    VStack {
                        ProgressRing.goal(current: 15000, target: 20000, icon: "house.fill")
                        Text("House Fund")
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                        Text("$15K / $20K")
                            .font(DSTypography.caption.small)
                            .foregroundColor(DSColors.neutral.textTertiary)
                    }
                    
                    VStack {
                        ProgressRing.performance(percentage: 12.5)
                        Text("Portfolio")
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                        Text("+12.5% YTD")
                            .font(DSTypography.caption.small)
                            .foregroundColor(DSColors.success.main)
                    }
                }
            }
            .cleanGlassCard()
            
            // Category spending
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                Text("Category Spending")
                    .font(DSTypography.title.title2)
                    .foregroundColor(DSColors.neutral.text)
                
                HStack(spacing: DSSpacing.lg) {
                    VStack {
                        ProgressRing.categorySpending(percentage: 65, category: "Food & Dining")
                        Text("Food & Dining")
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                    }
                    
                    VStack {
                        ProgressRing.categorySpending(percentage: 42, category: "Transportation")
                        Text("Transportation")
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                    }
                    
                    VStack {
                        ProgressRing.categorySpending(percentage: 88, category: "Shopping")
                        Text("Shopping")
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                    }
                    
                    VStack {
                        ProgressRing.categorySpending(percentage: 23, category: "Healthcare")
                        Text("Healthcare")
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                    }
                }
            }
            .cleanGlassCard()
            
            // Multi-ring example
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                Text("Multi-Ring Progress")
                    .font(DSTypography.title.title2)
                    .foregroundColor(DSColors.neutral.text)
                
                HStack(spacing: DSSpacing.xl) {
                    VStack {
                        MultiProgressRing(
                            rings: [
                                .init(
                                    progress: 0.8,
                                    gradient: LinearGradient(
                                        colors: [DSColors.primary.p400, DSColors.primary.p600],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                ),
                                .init(
                                    progress: 0.6,
                                    gradient: LinearGradient(
                                        colors: [DSColors.success.s400, DSColors.success.s600],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                ),
                                .init(
                                    progress: 0.9,
                                    gradient: LinearGradient(
                                        colors: [DSColors.warning.w400, DSColors.warning.w600],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            ]
                        )
                        
                        Text("Portfolio Allocation")
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                    }
                }
            }
            .cleanGlassCard()
        }
        .padding(DSSpacing.xl)
    }
    .background(
        LinearGradient(
            colors: [DSColors.neutral.n100, DSColors.neutral.n200],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
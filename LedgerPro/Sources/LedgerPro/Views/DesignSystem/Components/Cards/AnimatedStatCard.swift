import SwiftUI

/// Premium animated stat card component
///
/// Enhanced version of StatCard using glass morphism, animated numbers,
/// progress rings, and smooth transitions for a premium financial UI.
struct AnimatedStatCard: View {
    let title: String
    let value: String
    let numericValue: Double?
    let change: String
    let subtitle: String?
    let color: Color
    let icon: String
    let showProgressRing: Bool
    let progressValue: Double?
    let enableMicroInteractions: Bool
    
    @State private var isPressed = false
    @State private var isHovered = false
    @State private var hasAppeared = false
    
    // Gesture handling for micro-interactions
    @GestureState private var dragState = DragState.inactive
    
    enum DragState {
        case inactive
        case pressing
        case dragging(translation: CGSize)
        
        var translation: CGSize {
            switch self {
            case .inactive, .pressing:
                return .zero
            case .dragging(let translation):
                return translation
            }
        }
        
        var isActive: Bool {
            switch self {
            case .inactive:
                return false
            case .pressing, .dragging:
                return true
            }
        }
    }
    
    init(
        title: String,
        value: String,
        numericValue: Double? = nil,
        change: String,
        subtitle: String? = nil,
        color: Color,
        icon: String,
        showProgressRing: Bool = false,
        progressValue: Double? = nil,
        enableMicroInteractions: Bool = true
    ) {
        self.title = title
        self.value = value
        self.numericValue = numericValue
        self.change = change
        self.subtitle = subtitle
        self.color = color
        self.icon = icon
        self.showProgressRing = showProgressRing
        self.progressValue = progressValue
        self.enableMicroInteractions = enableMicroInteractions
    }
    
    var body: some View {
        GlassCard(
            gradient: cardGradient,
            padding: DSSpacing.component.cardPadding,
            enableHoverEffect: enableMicroInteractions
        ) {
            cardContent
        }
        .scaleEffect(combinedScale)
        .offset(dragState.translation)
        .animation(DSAnimations.financial.categorization, value: dragState.isActive)
        .animation(DSAnimations.common.gentleBounce, value: isHovered)
        .onHover { hovering in
            if enableMicroInteractions {
                isHovered = hovering
            }
        }
        .simultaneousGesture(
            enableMicroInteractions ? 
            DragGesture(coordinateSpace: .local)
                .updating($dragState) { drag, state, _ in
                    if drag.translation.width < 5 && drag.translation.height < 5 {
                        state = .pressing
                    } else {
                        state = .dragging(translation: CGSize(width: drag.translation.width * 0.1, height: drag.translation.height * 0.1)) // Damped drag
                    }
                }
                .onEnded { _ in
                    // Micro-interaction complete - could trigger haptic feedback
                    #if os(iOS)
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    #endif
                }
            : nil
        )
        .onAppear {
            withAnimation(
                DSAnimations.common.standardTransition.delay(Double.random(in: 0...0.3))
            ) {
                hasAppeared = true
            }
        }
    }
    
    // MARK: - Card Content
    
    @ViewBuilder
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            // Header with icon and change indicator
            cardHeader
            
            // Main value display
            mainValueSection
            
            // Title and subtitle
            titleSection
            
            // Optional progress ring
            if showProgressRing, let progressValue = progressValue {
                progressSection(progressValue)
            }
        }
        .opacity(hasAppeared ? 1.0 : 0.0)
        .offset(y: hasAppeared ? 0 : 20)
    }
    
    @ViewBuilder
    private var cardHeader: some View {
        HStack {
            // Icon with glass effect
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
                
                Image(systemName: icon)
                    .font(DSTypography.body.medium)
                    .foregroundColor(color)
            }
            
            Spacer()
            
            // Change indicator with enhanced styling
            changeIndicator
        }
    }
    
    @ViewBuilder
    private var mainValueSection: some View {
        HStack(alignment: .firstTextBaseline) {
            // Animated numeric value if available
            if let numericValue = numericValue {
                AnimatedNumber(value: numericValue, format: .currency())
            } else {
                Text(value)
                    .font(DSTypography.display.display3)
                    .fontWeight(.bold)
                    .foregroundColor(DSColors.neutral.text)
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            Text(title)
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.neutral.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(DSTypography.caption.small)
                    .foregroundColor(DSColors.neutral.textTertiary)
                    .lineLimit(1)
            }
        }
    }
    
    @ViewBuilder
    private func progressSection(_ progress: Double) -> some View {
        HStack {
            ProgressRing.indicator(
                progress: progress,
                size: 20,
                strokeWidth: 2,
                color: color
            )
            
            Text("\(Int(progress * 100))% of goal")
                .font(DSTypography.caption.small)
                .foregroundColor(DSColors.neutral.textTertiary)
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var changeIndicator: some View {
        HStack(spacing: DSSpacing.xs) {
            // Change direction icon
            Image(systemName: changeIconName)
                .font(DSTypography.caption.small)
                .foregroundColor(changeColor)
            
            Text(change)
                .font(DSTypography.caption.regular)
                .fontWeight(.medium)
                .foregroundColor(changeColor)
        }
        .padding(.horizontal, DSSpacing.xs)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(changeColor.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(changeColor.opacity(0.2), lineWidth: 0.5)
                )
        )
    }
    
    // MARK: - Computed Properties
    
    private var combinedScale: CGFloat {
        let hoverScale: CGFloat = isHovered ? 1.02 : 1.0
        let pressScale: CGFloat = dragState.isActive ? 0.98 : 1.0
        return hoverScale * pressScale
    }
    
    private var cardGradient: LinearGradient? {
        if changeColor == DSColors.success.main {
            return LinearGradient(
                colors: [
                    DSColors.success.s50.opacity(0.3),
                    DSColors.success.s100.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if changeColor == DSColors.error.main {
            return LinearGradient(
                colors: [
                    DSColors.error.e50.opacity(0.3),
                    DSColors.error.e100.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    color.opacity(0.05),
                    color.opacity(0.02)
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
}

// MARK: - Convenience Initializers

extension AnimatedStatCard {
    /// Create card for financial balance with automatic formatting
    static func balance(
        title: String,
        amount: Double,
        change: String,
        subtitle: String? = nil,
        icon: String = "dollarsign.circle.fill",
        showProgress: Bool = false,
        progressValue: Double? = nil
    ) -> AnimatedStatCard {
        AnimatedStatCard(
            title: title,
            value: amount.formatAsCurrency(),
            numericValue: amount,
            change: change,
            subtitle: subtitle,
            color: DSColors.primary.main,
            icon: icon,
            showProgressRing: showProgress,
            progressValue: progressValue
        )
    }
    
    /// Create card for transaction count
    static func transactionCount(
        title: String,
        count: Int,
        change: String,
        subtitle: String? = nil,
        icon: String = "list.bullet.circle.fill"
    ) -> AnimatedStatCard {
        AnimatedStatCard(
            title: title,
            value: "\(count)",
            numericValue: Double(count),
            change: change,
            subtitle: subtitle,
            color: DSColors.neutral.n600,
            icon: icon
        )
    }
    
    /// Create card for percentage metrics
    static func percentage(
        title: String,
        percentage: Double,
        change: String,
        subtitle: String? = nil,
        icon: String = "percent",
        showProgress: Bool = true
    ) -> AnimatedStatCard {
        AnimatedStatCard(
            title: title,
            value: "\(String(format: "%.1f", percentage))%",
            numericValue: percentage,
            change: change,
            subtitle: subtitle,
            color: DSColors.warning.main,
            icon: icon,
            showProgressRing: showProgress,
            progressValue: percentage / 100
        )
    }
    
    /// Create card for account balance with specific styling
    static func account(
        title: String,
        balance: Double,
        change: String,
        accountType: String? = nil,
        icon: String = "banknote.fill"
    ) -> AnimatedStatCard {
        let cardColor = balance >= 0 ? DSColors.success.main : DSColors.error.main
        
        return AnimatedStatCard(
            title: title,
            value: balance.formatAsCurrency(),
            numericValue: balance,
            change: change,
            subtitle: accountType,
            color: cardColor,
            icon: icon
        )
    }
    
    /// Create card for investment performance
    static func investment(
        title: String,
        value: Double,
        changePercentage: Double,
        subtitle: String? = nil,
        icon: String = "chart.line.uptrend.xyaxis.circle.fill"
    ) -> AnimatedStatCard {
        let changeText = changePercentage >= 0 ? 
            "+\(String(format: "%.1f", changePercentage))%" : 
            "\(String(format: "%.1f", changePercentage))%"
        
        return AnimatedStatCard(
            title: title,
            value: value.formatAsCurrency(),
            numericValue: value,
            change: changeText,
            subtitle: subtitle,
            color: changePercentage >= 0 ? DSColors.success.main : DSColors.error.main,
            icon: icon,
            showProgressRing: true,
            progressValue: min(1.0, max(0.0, (changePercentage + 50) / 100)) // Scale -50% to +50% -> 0 to 1
        )
    }
}

// MARK: - Grid Layouts

/// Grid container for multiple animated stat cards
struct AnimatedStatGrid: View {
    let cards: [AnimatedStatCard]
    let columns: Int
    let spacing: CGFloat
    
    init(
        cards: [AnimatedStatCard],
        columns: Int = 2,
        spacing: CGFloat = DSSpacing.lg
    ) {
        self.cards = cards
        self.columns = columns
        self.spacing = spacing
    }
    
    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns),
            spacing: spacing
        ) {
            ForEach(cards.indices, id: \.self) { index in
                cards[index]
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply animated stat card styling to any view
    func animatedStatCardStyle() -> some View {
        self
            .padding(DSSpacing.component.cardPadding)
            .background(.ultraThinMaterial)
            .cornerRadius(DSSpacing.radius.standard)
            .shadow(
                color: DSColors.primary.p500.opacity(0.1),
                radius: 8,
                x: 0,
                y: 2
            )
    }
}

// MARK: - Preview

#Preview("Animated Stat Cards") {
    ScrollView {
        VStack(spacing: DSSpacing.xl) {
            // Financial cards
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                Text("Financial Overview")
                    .font(DSTypography.title.title2)
                    .foregroundColor(DSColors.neutral.text)
                
                AnimatedStatGrid(cards: [
                    .balance(
                        title: "Total Balance",
                        amount: 25847.50,
                        change: "+5.2%",
                        subtitle: "vs last month"
                    ),
                    
                    .account(
                        title: "Checking",
                        balance: 5423.89,
                        change: "+12.3%",
                        accountType: "Chase ****1234"
                    ),
                    
                    .investment(
                        title: "Portfolio",
                        value: 45230.67,
                        changePercentage: 8.7,
                        subtitle: "YTD Performance"
                    ),
                    
                    .transactionCount(
                        title: "Transactions",
                        count: 142,
                        change: "+15",
                        subtitle: "This month"
                    )
                ])
            }
            .cleanGlassCard()
            
            // Performance cards
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                Text("Performance Metrics")
                    .font(DSTypography.title.title2)
                    .foregroundColor(DSColors.neutral.text)
                
                AnimatedStatGrid(cards: [
                    .percentage(
                        title: "Savings Rate",
                        percentage: 23.5,
                        change: "+2.1%",
                        subtitle: "Target: 25%",
                        icon: "piggybank.fill"
                    ),
                    
                    .percentage(
                        title: "Budget Used",
                        percentage: 78.3,
                        change: "-5.2%",
                        subtitle: "Remaining: $654",
                        icon: "chart.pie.fill"
                    )
                ])
            }
            .cleanGlassCard()
            
            // Single large card
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                Text("Featured Metric")
                    .font(DSTypography.title.title2)
                    .foregroundColor(DSColors.neutral.text)
                
                AnimatedStatCard.investment(
                    title: "Net Worth",
                    value: 127834.56,
                    changePercentage: 12.8,
                    subtitle: "All accounts included",
                    icon: "crown.fill"
                )
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
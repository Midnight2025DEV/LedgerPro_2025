import SwiftUI

/// Premium Components Showcase
///
/// Interactive demonstration of LedgerPro's premium components,
/// showing the transformation from basic cards to glass morphism designs.
struct PremiumComponentsShowcase: View {
    @State private var selectedDemo: DemoType = .comparison
    @State private var animatedValues = AnimatedValues()
    @State private var showPerformanceMetrics = false
    @State private var isLegacyMode = false
    
    // Demo data that changes over time
    struct AnimatedValues {
        var balance: Double = 25847.50
        var change: String = "+5.2%"
        var transactions: Int = 142
        var portfolioValue: Double = 45230.67
        var portfolioChange: Double = 8.7
        var savingsRate: Double = 23.5
        var budgetUsed: Double = 78.3
    }
    
    enum DemoType: String, CaseIterable {
        case comparison = "Side-by-Side Comparison"
        case interactive = "Interactive Demo"
        case performance = "Performance Showcase"
        case variations = "Card Variations"
        
        var icon: String {
            switch self {
            case .comparison: return "square.split.2x1"
            case .interactive: return "hand.tap"
            case .performance: return "speedometer"
            case .variations: return "rectangle.3.group"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            PremiumShowcaseSidebar(selectedDemo: $selectedDemo, isLegacyMode: $isLegacyMode)
        } detail: {
            // Main content
            ScrollView {
                VStack(alignment: .leading, spacing: DSSpacing.xl) {
                    // Header
                    PremiumShowcaseHeader(selectedDemo: selectedDemo, showPerformanceMetrics: $showPerformanceMetrics)
                    
                    // Content based on selected demo
                    Group {
                        switch selectedDemo {
                        case .comparison:
                            ComparisonDemo(isLegacyMode: isLegacyMode, animatedValues: animatedValues)
                        case .interactive:
                            InteractiveDemo(animatedValues: $animatedValues)
                        case .performance:
                            PerformanceDemo(showMetrics: showPerformanceMetrics)
                        case .variations:
                            VariationsDemo()
                        }
                    }
                    .animation(DSAnimations.common.standardTransition, value: selectedDemo)
                }
                .padding(DSSpacing.xl)
            }
            .background(
                LinearGradient(
                    colors: [DSColors.neutral.backgroundSecondary, DSColors.neutral.background],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        .navigationTitle("Premium Components")
        .onAppear {
            startValueAnimation()
        }
    }
    
    // MARK: - Value Animation
    
    private func startValueAnimation() {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(DSAnimations.financial.amountChange) {
                animatedValues.balance += Double.random(in: -500...1000)
                animatedValues.portfolioValue += Double.random(in: -2000...3000)
                animatedValues.transactions += Int.random(in: -2...5)
                animatedValues.portfolioChange = Double.random(in: -5...15)
                animatedValues.savingsRate = Double.random(in: 15...35)
                animatedValues.budgetUsed = Double.random(in: 60...95)
                
                // Update change percentage
                let changePercentage = Double.random(in: -10...15)
                animatedValues.change = changePercentage >= 0 ? 
                    "+\(String(format: "%.1f", changePercentage))%" : 
                    "\(String(format: "%.1f", changePercentage))%"
            }
        }
    }
}

// MARK: - Sidebar

struct PremiumShowcaseSidebar: View {
    @Binding var selectedDemo: PremiumComponentsShowcase.DemoType
    @Binding var isLegacyMode: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            Text("Premium Components")
                .font(DSTypography.title.title2)
                .foregroundColor(DSColors.neutral.text)
                .padding(.bottom, DSSpacing.sm)
            
            // Demo type selection
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                ForEach(PremiumComponentsShowcase.DemoType.allCases, id: \.self) { demo in
                    DemoSelectionRow(
                        demo: demo,
                        isSelected: selectedDemo == demo,
                        onSelect: { selectedDemo = demo }
                    )
                }
            }
            
            Divider()
                .padding(.vertical, DSSpacing.md)
            
            // Legacy mode toggle
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Options")
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Toggle("Legacy Mode", isOn: $isLegacyMode)
                    .font(DSTypography.body.medium)
                    .foregroundColor(DSColors.neutral.text)
            }
            
            Spacer()
            
            // Component status
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Component Status")
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                StatusRow(title: "GlassCard", status: .ready)
                StatusRow(title: "AnimatedNumber", status: .ready)
                StatusRow(title: "ProgressRing", status: .ready)
                StatusRow(title: "AnimatedStatCard", status: .ready)
            }
            .cleanGlassCard(padding: DSSpacing.md)
        }
        .padding(DSSpacing.lg)
        .frame(width: 280)
    }
}

struct DemoSelectionRow: View {
    let demo: PremiumComponentsShowcase.DemoType
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: DSSpacing.md) {
                Image(systemName: demo.icon)
                    .font(DSTypography.body.medium)
                    .foregroundColor(isSelected ? .white : DSColors.primary.main)
                    .frame(width: DSSpacing.icon.md)
                
                Text(demo.rawValue)
                    .font(DSTypography.body.medium)
                    .foregroundColor(isSelected ? .white : DSColors.neutral.text)
                
                Spacer()
            }
            .padding(.horizontal, DSSpacing.md)
            .padding(.vertical, DSSpacing.sm)
            .background(isSelected ? DSColors.primary.main : Color.clear)
            .cornerRadius(DSSpacing.radius.lg)
        }
        .buttonStyle(.plain)
        .selectionScale(isSelected: isSelected)
    }
}

struct StatusRow: View {
    let title: String
    let status: ComponentStatus
    
    enum ComponentStatus {
        case ready, inProgress, planned
        
        var color: Color {
            switch self {
            case .ready: return DSColors.success.main
            case .inProgress: return DSColors.warning.main
            case .planned: return DSColors.neutral.n400
            }
        }
        
        var icon: String {
            switch self {
            case .ready: return "checkmark.circle.fill"
            case .inProgress: return "clock.circle.fill"
            case .planned: return "circle"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: DSSpacing.sm) {
            Image(systemName: status.icon)
                .font(DSTypography.caption.regular)
                .foregroundColor(status.color)
            
            Text(title)
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.neutral.text)
            
            Spacer()
        }
    }
}

// MARK: - Header

struct PremiumShowcaseHeader: View {
    let selectedDemo: PremiumComponentsShowcase.DemoType
    @Binding var showPerformanceMetrics: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                HStack {
                    Image(systemName: selectedDemo.icon)
                        .font(DSTypography.display.display3)
                        .foregroundColor(DSColors.primary.main)
                    
                    Text(selectedDemo.rawValue)
                        .font(DSTypography.display.display3)
                        .foregroundColor(DSColors.neutral.text)
                }
                
                Text(descriptionForDemo(selectedDemo))
                    .font(DSTypography.body.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
            }
            
            Spacer()
            
            if selectedDemo == .performance {
                Button("Show Metrics") {
                    showPerformanceMetrics.toggle()
                }
                .interactiveButtonStyle()
            }
        }
        .cleanGlassCard()
    }
    
    private func descriptionForDemo(_ demo: PremiumComponentsShowcase.DemoType) -> String {
        switch demo {
        case .comparison:
            return "Compare legacy StatCard with new AnimatedStatCard side by side"
        case .interactive:
            return "Interactive demo with live value changes and animations"
        case .performance:
            return "Performance metrics and optimization showcase"
        case .variations:
            return "Different card styles and component variations"
        }
    }
}

// MARK: - Demo Views

struct ComparisonDemo: View {
    let isLegacyMode: Bool
    let animatedValues: PremiumComponentsShowcase.AnimatedValues
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            // Legacy vs New comparison
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                Text(isLegacyMode ? "Legacy Design" : "New vs Legacy Design")
                    .font(DSTypography.title.title2)
                    .foregroundColor(DSColors.neutral.text)
                
                if isLegacyMode {
                    // Show only legacy for comparison
                    HStack(spacing: DSSpacing.lg) {
                        legacyCard
                        legacyCard2
                    }
                } else {
                    // Show both side by side
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: DSSpacing.lg),
                        GridItem(.flexible(), spacing: DSSpacing.lg)
                    ], spacing: DSSpacing.lg) {
                        VStack(alignment: .leading, spacing: DSSpacing.md) {
                            Text("New Premium Design")
                                .font(DSTypography.body.semibold)
                                .foregroundColor(DSColors.success.main)
                            
                            AnimatedStatCard.balance(
                                title: "Total Balance",
                                amount: animatedValues.balance,
                                change: animatedValues.change,
                                subtitle: "vs last month"
                            )
                        }
                        
                        VStack(alignment: .leading, spacing: DSSpacing.md) {
                            Text("Legacy Design")
                                .font(DSTypography.body.semibold)
                                .foregroundColor(DSColors.neutral.textSecondary)
                            
                            legacyCard
                        }
                    }
                }
            }
            .cleanGlassCard()
            
            // Feature comparison
            FeatureComparisonTable()
        }
    }
    
    @ViewBuilder
    private var legacyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.blue)
                Spacer()
                Text(animatedValues.change)
                    .font(.caption)
                    .foregroundColor(animatedValues.change.starts(with: "+") ? .green : .red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background((animatedValues.change.starts(with: "+") ? Color.green : Color.red).opacity(0.1))
                    .cornerRadius(4)
            }
            
            Text(animatedValues.balance.formatAsCurrency())
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Total Balance")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("vs last month")
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
    
    @ViewBuilder
    private var legacyCard2: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "list.bullet.circle.fill")
                    .foregroundColor(.gray)
                Spacer()
                Text("+15")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(4)
            }
            
            Text("\(animatedValues.transactions)")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Transactions")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("This month")
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct FeatureComparisonTable: View {
    let features = [
        ("Glass Morphism", true, false),
        ("Animated Numbers", true, false),
        ("Hover Effects", true, false),
        ("Gradient Borders", true, false),
        ("Progress Rings", true, false),
        ("Micro-interactions", true, false),
        ("Performance Optimized", true, true),
        ("Dark Mode Support", true, true)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            Text("Feature Comparison")
                .font(DSTypography.title.title2)
                .foregroundColor(DSColors.neutral.text)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Feature")
                        .font(DSTypography.body.semibold)
                        .foregroundColor(DSColors.neutral.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("New Design")
                        .font(DSTypography.body.semibold)
                        .foregroundColor(DSColors.success.main)
                        .frame(width: 100)
                    
                    Text("Legacy")
                        .font(DSTypography.body.semibold)
                        .foregroundColor(DSColors.neutral.textSecondary)
                        .frame(width: 100)
                }
                .padding(DSSpacing.md)
                .background(DSColors.neutral.backgroundSecondary)
                
                // Feature rows
                ForEach(features.indices, id: \.self) { index in
                    let (feature, hasNew, hasLegacy) = features[index]
                    
                    HStack {
                        Text(feature)
                            .font(DSTypography.body.regular)
                            .foregroundColor(DSColors.neutral.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Image(systemName: hasNew ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(hasNew ? DSColors.success.main : DSColors.error.main)
                            .frame(width: 100)
                        
                        Image(systemName: hasLegacy ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(hasLegacy ? DSColors.success.main : DSColors.error.main)
                            .frame(width: 100)
                    }
                    .padding(DSSpacing.md)
                    .background(index % 2 == 0 ? Color.clear : DSColors.neutral.backgroundSecondary.opacity(0.5))
                }
            }
            .background(DSColors.neutral.backgroundCard)
            .cornerRadius(DSSpacing.radius.lg)
            .shadowCard()
        }
        .cleanGlassCard()
    }
}

struct InteractiveDemo: View {
    @Binding var animatedValues: PremiumComponentsShowcase.AnimatedValues
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            // Interactive controls
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                Text("Interactive Controls")
                    .font(DSTypography.title.title2)
                    .foregroundColor(DSColors.neutral.text)
                
                HStack(spacing: DSSpacing.lg) {
                    Button("📈 Market Up") {
                        withAnimation(DSAnimations.financial.amountChange) {
                            animatedValues.balance += 1000
                            animatedValues.portfolioValue += 2000
                            animatedValues.portfolioChange += 2.5
                            animatedValues.change = "+\(String(format: "%.1f", animatedValues.portfolioChange))%"
                        }
                    }
                    .secondaryButtonStyle()
                    
                    Button("📉 Market Down") {
                        withAnimation(DSAnimations.financial.amountChange) {
                            animatedValues.balance -= 800
                            animatedValues.portfolioValue -= 1500
                            animatedValues.portfolioChange -= 1.8
                            animatedValues.change = "\(String(format: "%.1f", animatedValues.portfolioChange))%"
                        }
                    }
                    .secondaryButtonStyle()
                    
                    Button("💰 Add Transaction") {
                        withAnimation(DSAnimations.financial.categorization) {
                            animatedValues.transactions += Int.random(in: 1...5)
                        }
                    }
                    .secondaryButtonStyle()
                    
                    Button("🎯 Random Update") {
                        withAnimation(DSAnimations.financial.amountChange) {
                            animatedValues.balance = Double.random(in: 15000...35000)
                            animatedValues.portfolioValue = Double.random(in: 30000...60000)
                            animatedValues.savingsRate = Double.random(in: 15...35)
                            animatedValues.budgetUsed = Double.random(in: 60...95)
                        }
                    }
                    .interactiveButtonStyle()
                }
            }
            .cleanGlassCard()
            
            // Live animated cards
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                Text("Live Animation Demo")
                    .font(DSTypography.title.title2)
                    .foregroundColor(DSColors.neutral.text)
                
                AnimatedStatGrid(cards: [
                    AnimatedStatCard.balance(
                        title: "Total Balance",
                        amount: animatedValues.balance,
                        change: animatedValues.change,
                        subtitle: "Interactive demo"
                    ),
                    
                    AnimatedStatCard.investment(
                        title: "Portfolio",
                        value: animatedValues.portfolioValue,
                        changePercentage: animatedValues.portfolioChange,
                        subtitle: "Live updates"
                    ),
                    
                    AnimatedStatCard.transactionCount(
                        title: "Transactions",
                        count: animatedValues.transactions,
                        change: "+\(animatedValues.transactions % 10)",
                        subtitle: "Click to add more"
                    ),
                    
                    AnimatedStatCard.percentage(
                        title: "Savings Rate",
                        percentage: animatedValues.savingsRate,
                        change: "+2.1%",
                        subtitle: "Target: 25%",
                        icon: "piggybank.fill"
                    )
                ])
            }
            .cleanGlassCard()
        }
    }
}

struct PerformanceDemo: View {
    let showMetrics: Bool
    @State private var renderTime: TimeInterval = 0
    @State private var frameRate: Double = 60
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            if showMetrics {
                PerformanceMetricsView(renderTime: renderTime, frameRate: frameRate)
            }
            
            // Performance test with many cards
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                Text("Performance Test - 20 Animated Cards")
                    .font(DSTypography.title.title2)
                    .foregroundColor(DSColors.neutral.text)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DSSpacing.md), count: 4), spacing: DSSpacing.md) {
                    ForEach(0..<20, id: \.self) { index in
                        AnimatedStatCard(
                            title: "Card \(index + 1)",
                            value: "$\(String(format: "%.0f", Double.random(in: 1000...50000)))",
                            numericValue: Double.random(in: 1000...50000),
                            change: Double.random(in: -10...15) >= 0 ? "+\(String(format: "%.1f", Double.random(in: 0...15)))%" : "-\(String(format: "%.1f", Double.random(in: 0...10)))%",
                            subtitle: "Performance test",
                            color: [DSColors.primary.main, DSColors.success.main, DSColors.warning.main, DSColors.error.main].randomElement()!,
                            icon: ["dollarsign.circle.fill", "chart.bar.fill", "creditcard.fill", "banknote.fill"].randomElement()!,
                            enableMicroInteractions: false // Disable for performance test
                        )
                    }
                }
            }
            .cleanGlassCard()
            .onAppear {
                measurePerformance()
            }
        }
    }
    
    private func measurePerformance() {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        DispatchQueue.main.async {
            let endTime = CFAbsoluteTimeGetCurrent()
            renderTime = endTime - startTime
            
            // Simulate frame rate measurement
            frameRate = 60.0 - (renderTime * 100) // Simplified calculation
        }
    }
}

struct PerformanceMetricsView: View {
    let renderTime: TimeInterval
    let frameRate: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            Text("Performance Metrics")
                .font(DSTypography.title.title2)
                .foregroundColor(DSColors.neutral.text)
            
            HStack(spacing: DSSpacing.xl) {
                MetricCard(
                    title: "Render Time",
                    value: "\(String(format: "%.3f", renderTime))s",
                    status: renderTime < 0.016 ? .excellent : renderTime < 0.033 ? .good : .poor
                )
                
                MetricCard(
                    title: "Frame Rate",
                    value: "\(Int(frameRate)) FPS",
                    status: frameRate >= 55 ? .excellent : frameRate >= 45 ? .good : .poor
                )
                
                MetricCard(
                    title: "Memory Usage",
                    value: "12.3 MB",
                    status: .good
                )
                
                MetricCard(
                    title: "GPU Usage",
                    value: "8.2%",
                    status: .excellent
                )
            }
        }
        .cleanGlassCard()
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let status: PerformanceStatus
    
    enum PerformanceStatus {
        case excellent, good, poor
        
        var color: Color {
            switch self {
            case .excellent: return DSColors.success.main
            case .good: return DSColors.warning.main
            case .poor: return DSColors.error.main
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text(title)
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.neutral.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            Text(value)
                .font(DSTypography.title.title3)
                .foregroundColor(status.color)
            
            HStack(spacing: DSSpacing.xs) {
                Circle()
                    .fill(status.color)
                    .frame(width: 6, height: 6)
                
                Text(status == .excellent ? "Excellent" : status == .good ? "Good" : "Poor")
                    .font(DSTypography.caption.small)
                    .foregroundColor(status.color)
            }
        }
        .padding(DSSpacing.md)
        .background(DSColors.neutral.backgroundCard)
        .cornerRadius(DSSpacing.radius.lg)
        .shadowCard()
    }
}

struct VariationsDemo: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            // Glass card variations
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                Text("Glass Card Variations")
                    .font(DSTypography.title.title2)
                    .foregroundColor(DSColors.neutral.text)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DSSpacing.lg), count: 2), spacing: DSSpacing.lg) {
                    GlassCard(enableBorderAnimation: false) {
                        VStack(alignment: .leading, spacing: DSSpacing.sm) {
                            Text("Clean Glass")
                                .font(DSTypography.body.semibold)
                            Text("Minimal glass morphism effect")
                                .font(DSTypography.caption.regular)
                                .foregroundColor(DSColors.neutral.textSecondary)
                        }
                    }
                    
                    GlassCard(gradient: LinearGradient(colors: [DSColors.primary.main.opacity(0.1), DSColors.primary.main.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)) {
                        VStack(alignment: .leading, spacing: DSSpacing.sm) {
                            Text("Primary Glass")
                                .font(DSTypography.body.semibold)
                            Text("With primary color gradient")
                                .font(DSTypography.caption.regular)
                                .foregroundColor(DSColors.neutral.textSecondary)
                        }
                    }
                    
                    GlassCard(gradient: LinearGradient(colors: [DSColors.success.main.opacity(0.1), DSColors.success.main.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)) {
                        VStack(alignment: .leading, spacing: DSSpacing.sm) {
                            Text("Success Glass")
                                .font(DSTypography.body.semibold)
                            Text("For positive financial metrics")
                                .font(DSTypography.caption.regular)
                                .foregroundColor(DSColors.neutral.textSecondary)
                        }
                    }
                    
                    GlassCard(gradient: LinearGradient(colors: [DSColors.error.main.opacity(0.1), DSColors.error.main.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)) {
                        VStack(alignment: .leading, spacing: DSSpacing.sm) {
                            Text("Error Glass")
                                .font(DSTypography.body.semibold)
                            Text("For alerts and warnings")
                                .font(DSTypography.caption.regular)
                                .foregroundColor(DSColors.neutral.textSecondary)
                        }
                    }
                }
            }
            .cleanGlassCard()
            
            // Progress ring variations
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                Text("Progress Ring Variations")
                    .font(DSTypography.title.title2)
                    .foregroundColor(DSColors.neutral.text)
                
                HStack(spacing: DSSpacing.xl) {
                    VStack {
                        ProgressRing.budget(spent: 2750, total: 3000)
                        Text("Budget Ring")
                            .font(DSTypography.caption.regular)
                    }
                    
                    VStack {
                        ProgressRing.goal(current: 15000, target: 20000, icon: "house.fill")
                        Text("Goal Ring")
                            .font(DSTypography.caption.regular)
                    }
                    
                    VStack {
                        ProgressRing.performance(percentage: 12.5)
                        Text("Performance Ring")
                            .font(DSTypography.caption.regular)
                    }
                    
                    VStack {
                        ProgressRing.indicator(progress: 0.75, size: 32, color: DSColors.primary.main)
                        Text("Indicator Ring")
                            .font(DSTypography.caption.regular)
                    }
                }
            }
            .cleanGlassCard()
        }
    }
}

// MARK: - Preview

#Preview {
    PremiumComponentsShowcase()
        .frame(minWidth: 1400, minHeight: 900)
}
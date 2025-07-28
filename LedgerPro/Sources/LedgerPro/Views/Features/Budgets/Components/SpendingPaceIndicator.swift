import SwiftUI

/// SpendingPaceIndicator - Visual pace tracking with projections
///
/// Intelligent spending pace visualization that shows current trajectory,
/// projected outcomes, and actionable recommendations to help users stay on track.
struct SpendingPaceIndicator: View {
    let budget: Budget
    let currentSpending: Double
    let pace: SpendingPace
    
    @State private var hasAppeared = false
    @State private var showingProjection = false
    @State private var animatedProgress: Double = 0
    
    // Calculated properties
    private var daysInPeriod: Int {
        budget.period.dayCount
    }
    
    private var daysPassed: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: budget.startDate, to: Date())
        return max(components.day ?? 1, 1)
    }
    
    private var daysRemaining: Int {
        max(daysInPeriod - daysPassed, 0)
    }
    
    private var expectedSpending: Double {
        let progress = Double(daysPassed) / Double(daysInPeriod)
        return budget.amount * progress
    }
    
    private var projectedTotal: Double {
        if daysPassed == 0 { return 0 }
        let dailyAverage = currentSpending / Double(daysPassed)
        return dailyAverage * Double(daysInPeriod)
    }
    
    private var projectedOverage: Double {
        max(projectedTotal - budget.amount, 0)
    }
    
    private var recommendedDailySpending: Double {
        if daysRemaining == 0 { return 0 }
        let remaining = max(budget.amount - currentSpending, 0)
        return remaining / Double(daysRemaining)
    }
    
    var body: some View {
        VStack(spacing: DSSpacing.lg) {
            // Header with pace status
            paceHeaderSection
            
            // Visual pace indicator
            paceVisualizationSection
            
            // Projection details
            if showingProjection {
                projectionDetailsSection
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            
            // Quick recommendations
            recommendationsSection
        }
        .padding(DSSpacing.lg)
        .background(paceCardBackground)
        .cornerRadius(DSSpacing.radius.xl)
        .shadow(
            color: pace.color.opacity(0.1),
            radius: 12,
            x: 0,
            y: 6
        )
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1)) {
                hasAppeared = true
                animatedProgress = Double(daysPassed) / Double(daysInPeriod)
            }
        }
    }
    
    // MARK: - Pace Header Section
    
    @ViewBuilder
    private var paceHeaderSection: some View {
        HStack {
            // Pace icon and status
            HStack(spacing: DSSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(pace.color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: pace.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(pace.color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Spending Pace")
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                    
                    Text(pace.displayText)
                        .font(DSTypography.body.semibold)
                        .foregroundColor(pace.color)
                }
            }
            
            Spacer()
            
            // Toggle projection details
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showingProjection.toggle()
                }
            }) {
                HStack(spacing: DSSpacing.xs) {
                    Text("Details")
                        .font(DSTypography.caption.regular)
                    
                    Image(systemName: showingProjection ? "chevron.up" : "chevron.down")
                        .font(DSTypography.caption.regular)
                }
                .foregroundColor(DSColors.primary.main)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Pace Visualization Section
    
    @ViewBuilder
    private var paceVisualizationSection: some View {
        VStack(spacing: DSSpacing.md) {
            // Progress bar with pace indicator
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(DSColors.neutral.n200.opacity(0.3))
                        .frame(height: 12)
                    
                    // Expected progress track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(DSColors.neutral.n300.opacity(0.5))
                        .frame(
                            width: geometry.size.width * CGFloat(Double(daysPassed) / Double(daysInPeriod)),
                            height: 12
                        )
                    
                    // Actual spending progress
                    RoundedRectangle(cornerRadius: 6)
                        .fill(progressGradient)
                        .frame(
                            width: hasAppeared ? geometry.size.width * CGFloat(min(currentSpending / budget.amount, 1.0)) : 0,
                            height: 12
                        )
                        .animation(.spring(response: 1.0, dampingFraction: 0.8), value: hasAppeared)
                    
                    // Pace indicator marker
                    paceMarker(in: geometry)
                }
            }
            .frame(height: 12)
            
            // Progress labels
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Day \(daysPassed) of \(daysInPeriod)")
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                    
                    Text("\(daysRemaining) days left")
                        .font(DSTypography.caption.small)
                        .foregroundColor(DSColors.neutral.textTertiary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: DSSpacing.xs) {
                        Text("Spent:")
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                        
                        AnimatedNumber(value: currentSpending, format: .currency())
                            .font(DSTypography.body.semibold)
                            .foregroundColor(spentAmountColor)
                    }
                    
                    HStack(spacing: DSSpacing.xs) {
                        Text("Expected:")
                            .font(DSTypography.caption.small)
                            .foregroundColor(DSColors.neutral.textTertiary)
                        
                        Text(expectedSpending.formatAsCurrency())
                            .font(DSTypography.caption.small)
                            .foregroundColor(DSColors.neutral.textTertiary)
                    }
                }
            }
        }
    }
    
    // MARK: - Pace Marker
    
    @ViewBuilder
    private func paceMarker(in geometry: GeometryProxy) -> some View {
        let markerPosition = geometry.size.width * CGFloat(Double(daysPassed) / Double(daysInPeriod))
        
        VStack {
            // Marker line
            Rectangle()
                .fill(DSColors.primary.main)
                .frame(width: 2, height: 20)
                .offset(x: markerPosition - 1)
            
            Spacer()
        }
        .frame(height: 12)
    }
    
    // MARK: - Projection Details Section
    
    @ViewBuilder
    private var projectionDetailsSection: some View {
        VStack(spacing: DSSpacing.lg) {
            // Projection summary
            HStack(spacing: DSSpacing.xl) {
                ProjectionStat(
                    title: "Projected Total",
                    value: projectedTotal.formatAsCurrency(),
                    subtitle: projectedTotal > budget.amount ? "Over budget" : "Within budget",
                    color: projectedTotal > budget.amount ? DSColors.error.main : DSColors.success.main
                )
                
                if projectedOverage > 0 {
                    ProjectionStat(
                        title: "Projected Overage",
                        value: projectedOverage.formatAsCurrency(),
                        subtitle: "Over budget",
                        color: DSColors.error.main
                    )
                }
            }
            
            // Spending trajectory chart
            trajectoryChart
        }
    }
    
    // MARK: - Trajectory Chart
    
    @ViewBuilder
    private var trajectoryChart: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text("Spending Trajectory")
                .font(DSTypography.body.semibold)
                .foregroundColor(DSColors.neutral.text)
            
            GeometryReader { geometry in
                ZStack(alignment: .bottomLeading) {
                    // Chart background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(DSColors.neutral.n100.opacity(0.3))
                    
                    // Budget line
                    Path { path in
                        let startPoint = CGPoint(x: 0, y: geometry.size.height)
                        let endPoint = CGPoint(x: geometry.size.width, y: 0)
                        path.move(to: startPoint)
                        path.addLine(to: endPoint)
                    }
                    .stroke(DSColors.neutral.n400, style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    
                    // Actual spending curve
                    actualSpendingPath(in: geometry)
                    
                    // Projected spending line
                    projectedSpendingPath(in: geometry)
                    
                    // Current position marker
                    currentPositionMarker(in: geometry)
                }
            }
            .frame(height: 100)
            
            // Chart legend
            HStack(spacing: DSSpacing.lg) {
                ChartLegendItem(
                    color: DSColors.neutral.n400,
                    label: "Budget Line",
                    isDashed: true
                )
                
                ChartLegendItem(
                    color: pace.color,
                    label: "Actual",
                    isDashed: false
                )
                
                ChartLegendItem(
                    color: DSColors.warning.main.opacity(0.7),
                    label: "Projected",
                    isDashed: true
                )
            }
        }
    }
    
    // MARK: - Chart Paths
    
    @ViewBuilder
    private func actualSpendingPath(in geometry: GeometryProxy) -> some View {
        Path { path in
            let pointsCount = daysPassed
            guard pointsCount > 0 else { return }
            
            let stepX = geometry.size.width / CGFloat(daysInPeriod)
            let maxY = geometry.size.height
            
            // Generate curve points (simplified for demo)
            var points: [CGPoint] = []
            for day in 0...daysPassed {
                let x = CGFloat(day) * stepX
                let spending = (currentSpending / Double(daysPassed)) * Double(day)
                let y = maxY - (CGFloat(spending / budget.amount) * maxY)
                points.append(CGPoint(x: x, y: max(0, y)))
            }
            
            // Create smooth curve
            if points.count > 1 {
                path.move(to: points[0])
                for i in 1..<points.count {
                    path.addLine(to: points[i])
                }
            }
        }
        .stroke(
            LinearGradient(
                colors: [pace.color, pace.color.opacity(0.6)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: 3, lineCap: .round)
        )
    }
    
    @ViewBuilder
    private func projectedSpendingPath(in geometry: GeometryProxy) -> some View {
        if daysRemaining > 0 {
            Path { path in
                let currentX = (CGFloat(daysPassed) / CGFloat(daysInPeriod)) * geometry.size.width
                let currentY = geometry.size.height - (CGFloat(currentSpending / budget.amount) * geometry.size.height)
                
                let endX = geometry.size.width
                let endY = geometry.size.height - (CGFloat(projectedTotal / budget.amount) * geometry.size.height)
                
                path.move(to: CGPoint(x: currentX, y: currentY))
                path.addLine(to: CGPoint(x: endX, y: max(0, endY)))
            }
            .stroke(
                DSColors.warning.main.opacity(0.7),
                style: StrokeStyle(lineWidth: 2, dash: [3, 3])
            )
        }
    }
    
    @ViewBuilder
    private func currentPositionMarker(in geometry: GeometryProxy) -> some View {
        let currentX = (CGFloat(daysPassed) / CGFloat(daysInPeriod)) * geometry.size.width
        let currentY = geometry.size.height - (CGFloat(currentSpending / budget.amount) * geometry.size.height)
        
        Circle()
            .fill(pace.color)
            .frame(width: 8, height: 8)
            .position(x: currentX, y: max(4, currentY))
            .shadow(color: pace.color.opacity(0.5), radius: 4)
    }
    
    // MARK: - Recommendations Section
    
    @ViewBuilder
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            Text("Recommendations")
                .font(DSTypography.body.semibold)
                .foregroundColor(DSColors.neutral.text)
            
            LazyVStack(spacing: DSSpacing.sm) {
                ForEach(recommendations, id: \.text) { recommendation in
                    PaceRecommendationRow(recommendation: recommendation)
                }
            }
        }
    }
    
    // MARK: - Card Background
    
    @ViewBuilder
    private var paceCardBackground: some View {
        RoundedRectangle(cornerRadius: DSSpacing.radius.xl)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: DSSpacing.radius.xl)
                    .fill(
                        LinearGradient(
                            colors: [
                                pace.color.opacity(0.05),
                                pace.color.opacity(0.02),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DSSpacing.radius.xl)
                    .stroke(pace.color.opacity(0.2), lineWidth: 1)
            )
    }
    
    // MARK: - Computed Properties
    
    private var progressGradient: LinearGradient {
        let progress = currentSpending / budget.amount
        
        if progress > 1.0 {
            return LinearGradient(
                colors: [DSColors.error.main, DSColors.error.e600],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else if progress > 0.8 {
            return LinearGradient(
                colors: [DSColors.warning.main, pace.color],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return LinearGradient(
                colors: [pace.color, pace.color.opacity(0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    private var spentAmountColor: Color {
        if currentSpending > budget.amount {
            return DSColors.error.main
        } else if currentSpending > budget.amount * 0.8 {
            return DSColors.warning.main
        } else {
            return DSColors.neutral.text
        }
    }
    
    private var recommendations: [PaceRecommendation] {
        var recs: [PaceRecommendation] = []
        
        switch pace {
        case .tooFast:
            if daysRemaining > 0 {
                recs.append(PaceRecommendation(
                    icon: "slowmo",
                    text: "Reduce daily spending to \(recommendedDailySpending.formatAsCurrency()) to stay on budget",
                    type: .warning
                ))
            }
            
            if projectedOverage > 0 {
                recs.append(PaceRecommendation(
                    icon: "exclamationmark.triangle",
                    text: "At current pace, you'll be over budget by \(projectedOverage.formatAsCurrency())",
                    type: .error
                ))
            }
            
        case .slow:
            let surplus = budget.amount - projectedTotal
            if surplus > 0 {
                recs.append(PaceRecommendation(
                    icon: "plus.circle",
                    text: "You're on track to have \(surplus.formatAsCurrency()) left over",
                    type: .success
                ))
            }
            
        case .onTrack:
            recs.append(PaceRecommendation(
                icon: "checkmark.circle",
                text: "Perfect pace! Keep up the great work",
                type: .success
            ))
        }
        
        return recs
    }
}

// MARK: - Supporting Components

struct ProjectionStat: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            Text(title)
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.neutral.textSecondary)
            
            Text(value)
                .font(DSTypography.body.semibold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(DSTypography.caption.small)
                .foregroundColor(DSColors.neutral.textTertiary)
        }
    }
}

struct ChartLegendItem: View {
    let color: Color
    let label: String
    let isDashed: Bool
    
    var body: some View {
        HStack(spacing: DSSpacing.xs) {
            if isDashed {
                Rectangle()
                    .fill(color)
                    .frame(width: 16, height: 2)
                    .mask(
                        HStack(spacing: 2) {
                            ForEach(0..<3) { _ in
                                Rectangle()
                                    .frame(width: 3, height: 2)
                            }
                        }
                    )
            } else {
                Rectangle()
                    .fill(color)
                    .frame(width: 16, height: 3)
                    .cornerRadius(1.5)
            }
            
            Text(label)
                .font(DSTypography.caption.small)
                .foregroundColor(DSColors.neutral.textSecondary)
        }
    }
}

struct PaceRecommendationRow: View {
    let recommendation: PaceRecommendation
    
    var body: some View {
        HStack(spacing: DSSpacing.sm) {
            Image(systemName: recommendation.icon)
                .font(.system(size: 14))
                .foregroundColor(recommendation.type.color)
                .frame(width: 20)
            
            Text(recommendation.text)
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.neutral.text)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(.horizontal, DSSpacing.sm)
        .padding(.vertical, DSSpacing.xs)
        .background(recommendation.type.backgroundColor)
        .cornerRadius(DSSpacing.radius.sm)
    }
}

// MARK: - Supporting Models

struct PaceRecommendation {
    let icon: String
    let text: String
    let type: RecommendationType
    
    enum RecommendationType {
        case success, warning, error
        
        var color: Color {
            switch self {
            case .success: return DSColors.success.main
            case .warning: return DSColors.warning.main
            case .error: return DSColors.error.main
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .success: return DSColors.success.main.opacity(0.1)
            case .warning: return DSColors.warning.main.opacity(0.1)
            case .error: return DSColors.error.main.opacity(0.1)
            }
        }
    }
}

// MARK: - Preview

#Preview("Spending Pace Indicator") {
    ScrollView {
        VStack(spacing: DSSpacing.xl) {
            // On track pace
            SpendingPaceIndicator(
                budget: Budget(
                    name: "Groceries",
                    amount: 600,
                    period: .monthly
                ),
                currentSpending: 300,
                pace: .onTrack
            )
            
            // Too fast pace
            SpendingPaceIndicator(
                budget: Budget(
                    name: "Dining",
                    amount: 400,
                    period: .monthly
                ),
                currentSpending: 350,
                pace: .tooFast
            )
            
            // Slow pace
            SpendingPaceIndicator(
                budget: Budget(
                    name: "Entertainment",
                    amount: 200,
                    period: .monthly
                ),
                currentSpending: 80,
                pace: .slow
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
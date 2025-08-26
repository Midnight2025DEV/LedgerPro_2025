import SwiftUI

/// Animated number component for smooth value transitions
///
/// Provides smooth count-up/down animations when values change,
/// with currency formatting and color transitions for financial data.
struct AnimatedNumber: View {
    let value: Double
    let format: NumberFormat
    let animationDuration: TimeInterval
    let font: Font
    let positiveColor: Color
    let negativeColor: Color
    let neutralColor: Color
    
    @State private var displayValue: Double = 0
    @State private var isFirstAppearance = true
    
    // Performance optimization - only animate visible numbers
    @State private var isVisible = false
    @Environment(\.isEnabled) private var isEnabled
    
    enum NumberFormat {
        case currency(code: String = "USD")
        case percentage(decimals: Int = 1)
        case decimal(decimals: Int = 2)
        case integer
        case custom(formatter: NumberFormatter)
        
        func formatted(_ value: Double) -> String {
            switch self {
            case .currency(let code):
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.currencyCode = code
                return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
                
            case .percentage(let decimals):
                let formatter = NumberFormatter()
                formatter.numberStyle = .percent
                formatter.minimumFractionDigits = decimals
                formatter.maximumFractionDigits = decimals
                return formatter.string(from: NSNumber(value: value / 100)) ?? "0%"
                
            case .decimal(let decimals):
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.minimumFractionDigits = decimals
                formatter.maximumFractionDigits = decimals
                return formatter.string(from: NSNumber(value: value)) ?? "0.00"
                
            case .integer:
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.maximumFractionDigits = 0
                return formatter.string(from: NSNumber(value: value)) ?? "0"
                
            case .custom(let formatter):
                return formatter.string(from: NSNumber(value: value)) ?? "0"
            }
        }
    }
    
    init(
        value: Double,
        format: NumberFormat = .currency(),
        animationDuration: TimeInterval = 0.8,
        font: Font = DSTypography.financial.currency,
        positiveColor: Color = DSColors.success.main,
        negativeColor: Color = DSColors.error.main,
        neutralColor: Color = DSColors.neutral.text
    ) {
        self.value = value
        self.format = format
        self.animationDuration = animationDuration
        self.font = font
        self.positiveColor = positiveColor
        self.negativeColor = negativeColor
        self.neutralColor = neutralColor
    }
    
    var body: some View {
        Text(format.formatted(displayValue))
            .font(font)
            .foregroundColor(valueColor)
            .contentTransition(.numericText(value: displayValue))
            .onAppear {
                // Performance: Only animate if component is visible
                DispatchQueue.main.async {
                    isVisible = true
                    animateToValue()
                }
            }
            .onChange(of: value) { _, newValue in
                if isVisible && isEnabled {
                    animateToValue(to: newValue)
                } else {
                    // Instant update if animations disabled or not visible
                    displayValue = newValue
                }
            }
            #if canImport(UIKit)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                // Re-animate when app becomes active (handles background transitions)
                if isVisible {
                    animateToValue()
                }
            }
            #elseif canImport(AppKit)
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                // Re-animate when app becomes active (handles background transitions)
                if isVisible {
                    animateToValue()
                }
            }
            #endif
    }
    
    // MARK: - Computed Properties
    
    private var valueColor: Color {
        if abs(displayValue) < 0.01 {
            return neutralColor
        }
        
        return displayValue >= 0 ? positiveColor : negativeColor
    }
    
    // MARK: - Animation Logic
    
    private func animateToValue(to targetValue: Double? = nil) {
        let target = targetValue ?? value
        
        // Skip animation if values are essentially the same
        if abs(displayValue - target) < 0.01 {
            return
        }
        
        // Determine animation characteristics based on value change
        let valueDifference = abs(target - displayValue)
        let duration = isFirstAppearance ? animationDuration : min(animationDuration, max(0.3, valueDifference / 10000))
        
        // Use spring physics for natural motion
        withAnimation(
            .spring(
                response: duration * 0.6,
                dampingFraction: 0.8,
                blendDuration: 0
            )
        ) {
            displayValue = target
        }
        
        isFirstAppearance = false
    }
}

// MARK: - Convenience Initializers

extension AnimatedNumber {
    /// Large financial amount with prominent styling
    static func largeAmount(
        _ value: Double,
        currencyCode: String = "USD"
    ) -> AnimatedNumber {
        AnimatedNumber(
            value: value,
            format: .currency(code: currencyCode),
            animationDuration: 1.0,
            font: DSTypography.financial.currencyLarge,
            positiveColor: DSColors.success.main,
            negativeColor: DSColors.error.main,
            neutralColor: DSColors.neutral.text
        )
    }
    
    /// Standard financial amount
    static func amount(
        _ value: Double,
        currencyCode: String = "USD"
    ) -> AnimatedNumber {
        AnimatedNumber(
            value: value,
            format: .currency(code: currencyCode),
            font: DSTypography.financial.currency
        )
    }
    
    /// Percentage change with appropriate colors
    static func percentage(
        _ value: Double,
        decimals: Int = 1
    ) -> AnimatedNumber {
        AnimatedNumber(
            value: value,
            format: .percentage(decimals: decimals),
            font: DSTypography.financial.percentage,
            positiveColor: DSColors.success.main,
            negativeColor: DSColors.error.main,
            neutralColor: DSColors.neutral.textSecondary
        )
    }
    
    /// Integer count (e.g., transaction count)
    static func count(
        _ value: Double,
        font: Font = DSTypography.body.semibold
    ) -> AnimatedNumber {
        AnimatedNumber(
            value: value,
            format: .integer,
            font: font,
            positiveColor: DSColors.neutral.text,
            negativeColor: DSColors.neutral.text,
            neutralColor: DSColors.neutral.text
        )
    }
    
    /// Balance with automatic positive/negative handling
    static func balance(
        _ value: Double,
        currencyCode: String = "USD",
        showPlusSign: Bool = false
    ) -> AnimatedNumber {
        let displayValue = showPlusSign && value > 0 ? value : value
        
        return AnimatedNumber(
            value: displayValue,
            format: .currency(code: currencyCode),
            font: DSTypography.financial.currency,
            positiveColor: DSColors.success.main,
            negativeColor: DSColors.error.main,
            neutralColor: DSColors.neutral.text
        )
    }
}

// MARK: - Performance Optimized Animated Counter

/// High-performance animated counter for rapid value changes
struct AnimatedCounter: View {
    let targetValue: Int
    let duration: TimeInterval
    let font: Font
    let color: Color
    
    @State private var currentValue: Int = 0
    @State private var timer: Timer?
    
    init(
        value: Int,
        duration: TimeInterval = 0.5,
        font: Font = DSTypography.body.semibold,
        color: Color = DSColors.neutral.text
    ) {
        self.targetValue = value
        self.duration = duration
        self.font = font
        self.color = color
    }
    
    var body: some View {
        Text("\(currentValue)")
            .font(font)
            .foregroundColor(color)
            .contentTransition(.numericText(value: Double(currentValue)))
            .onAppear {
                animateCounter()
            }
            .onChange(of: targetValue) { _, newValue in
                animateCounter(to: newValue)
            }
    }
    
    private func animateCounter(to target: Int? = nil) {
        let target = target ?? targetValue
        let startValue = currentValue
        let valueRange = target - startValue
        
        // Skip if no change needed
        if valueRange == 0 { return }
        
        // Calculate optimal frame rate based on value range
        let steps = min(abs(valueRange), 60) // Cap at 60 steps for performance
        let stepDuration = duration / Double(steps)
        
        timer?.invalidate()
        
        var stepCount = 0
        timer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { timer in
            stepCount += 1
            
            if stepCount >= steps {
                currentValue = target
                timer.invalidate()
            } else {
                let progress = Double(stepCount) / Double(steps)
                // Use ease-out curve for natural deceleration
                let easedProgress = 1 - pow(1 - progress, 3)
                currentValue = startValue + Int(Double(valueRange) * easedProgress)
            }
        }
    }
}

// MARK: - Financial Number Utilities

extension Double {
    /// Format as animated currency
    func animatedCurrency(
        code: String = "USD",
        font: Font = DSTypography.financial.currency
    ) -> AnimatedNumber {
        AnimatedNumber.amount(self, currencyCode: code)
    }
    
    /// Format as animated percentage
    func animatedPercentage(
        decimals: Int = 1,
        font: Font = DSTypography.financial.percentage
    ) -> AnimatedNumber {
        AnimatedNumber.percentage(self, decimals: decimals)
    }
    
    /// Format as animated balance with color coding
    func animatedBalance(
        code: String = "USD",
        showPlusSign: Bool = false
    ) -> AnimatedNumber {
        AnimatedNumber.balance(self, currencyCode: code, showPlusSign: showPlusSign)
    }
}

extension Int {
    /// Create animated counter
    func animatedCount(
        duration: TimeInterval = 0.5,
        font: Font = DSTypography.body.semibold,
        color: Color = DSColors.neutral.text
    ) -> AnimatedCounter {
        AnimatedCounter(
            value: self,
            duration: duration,
            font: font,
            color: color
        )
    }
}

// MARK: - View Extensions

extension View {
    /// Apply animated number styling
    func animatedNumberStyle() -> some View {
        self
            .font(DSTypography.financial.currency)
            .foregroundColor(DSColors.neutral.text)
    }
    
    /// Apply large animated number styling
    func largeAnimatedNumberStyle() -> some View {
        self
            .font(DSTypography.financial.currencyLarge)
            .foregroundColor(DSColors.neutral.text)
    }
}

// MARK: - Preview

#Preview("Animated Numbers") {
    ScrollView {
        VStack(spacing: DSSpacing.xl) {
            // Large amounts
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                Text("Large Financial Amounts")
                    .font(DSTypography.title.title2)
                    .foregroundColor(DSColors.neutral.text)
                
                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    AnimatedNumber.largeAmount(25847.50)
                    AnimatedNumber.largeAmount(-1234.56)
                    AnimatedNumber.largeAmount(0)
                }
            }
            .cleanGlassCard()
            
            // Percentages
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                Text("Percentage Changes")
                    .font(DSTypography.title.title2)
                    .foregroundColor(DSColors.neutral.text)
                
                HStack(spacing: DSSpacing.xl) {
                    VStack {
                        AnimatedNumber.percentage(12.5)
                        Text("Gain")
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                    }
                    
                    VStack {
                        AnimatedNumber.percentage(-3.2)
                        Text("Loss")
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                    }
                    
                    VStack {
                        AnimatedNumber.percentage(0)
                        Text("Neutral")
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                    }
                }
            }
            .cleanGlassCard()
            
            // Counters
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                Text("Transaction Counts")
                    .font(DSTypography.title.title2)
                    .foregroundColor(DSColors.neutral.text)
                
                HStack(spacing: DSSpacing.xl) {
                    VStack {
                        142.animatedCount()
                        Text("This Month")
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                    }
                    
                    VStack {
                        1847.animatedCount()
                        Text("This Year")
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                    }
                    
                    VStack {
                        23.animatedCount(color: DSColors.warning.main)
                        Text("Uncategorized")
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
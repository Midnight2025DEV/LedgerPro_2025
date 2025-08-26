import SwiftUI

/// BudgetProgressRing - Advanced progress visualization component
///
/// Sophisticated progress ring with gradient fills, animated segments,
/// pulsing effects, and accessibility support for budget tracking.
struct BudgetProgressRing: View {
    let progress: Double // 0.0 to 1.0
    let color: Color
    let isOverBudget: Bool
    let size: CGFloat
    
    @State private var hasAppeared = false
    @State private var pulseAnimation = false
    @State private var rotationAnimation = false
    @State private var glowIntensity: Double = 0
    
    // Animation configuration
    private let animationDuration: Double = 1.5
    private let pulseInterval: Double = 2.0
    private let strokeWidth: CGFloat
    
    init(
        progress: Double,
        color: Color,
        isOverBudget: Bool = false,
        size: CGFloat = 120
    ) {
        self.progress = min(max(progress, 0), 2.0) // Allow up to 200% for over-budget
        self.color = color
        self.isOverBudget = isOverBudget
        self.size = size
        self.strokeWidth = size * 0.08 // Proportional stroke width
    }
    
    var body: some View {
        ZStack {
            // Background effects
            backgroundEffects
            
            // Progress rings
            progressRings
            
            // Over-budget effects
            if isOverBudget {
                overBudgetEffects
            }
            
            // Glow effect
            glowEffect
        }
        .frame(width: size, height: size)
        .onAppear {
            startAnimations()
        }
        .onChange(of: progress) { _, _ in
            updateAnimations()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
    }
    
    // MARK: - Background Effects
    
    @ViewBuilder
    private var backgroundEffects: some View {
        ZStack {
            // Subtle background ring
            Circle()
                .stroke(
                    Color.gray.opacity(0.1),
                    lineWidth: strokeWidth * 0.5
                )
            
            // Dynamic background based on progress
            if progress > 0.8 {
                Circle()
                    .stroke(
                        color.opacity(0.05),
                        lineWidth: strokeWidth * 2
                    )
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .opacity(pulseAnimation ? 0.3 : 0.1)
            }
        }
    }
    
    // MARK: - Progress Rings
    
    @ViewBuilder
    private var progressRings: some View {
        ZStack {
            // Main progress ring
            Circle()
                .trim(from: 0, to: hasAppeared ? CGFloat(min(progress, 1.0)) : 0)
                .stroke(
                    progressGradient,
                    style: StrokeStyle(
                        lineWidth: strokeWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(
                    .spring(response: animationDuration, dampingFraction: 0.8),
                    value: hasAppeared
                )
            
            // Over-budget ring (second lap)
            if progress > 1.0 {
                Circle()
                    .trim(from: 0, to: hasAppeared ? CGFloat(progress - 1.0) : 0)
                    .stroke(
                        overBudgetGradient,
                        style: StrokeStyle(
                            lineWidth: strokeWidth * 0.8,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(
                        .spring(response: animationDuration, dampingFraction: 0.8)
                        .delay(0.5),
                        value: hasAppeared
                    )
            }
            
            // Animated segments for categories (if applicable)
            if hasAppeared && progress > 0.1 {
                categorySegments
            }
        }
    }
    
    // MARK: - Category Segments
    
    @ViewBuilder
    private var categorySegments: some View {
        // This would show different segments for different categories
        // For now, we'll show decorative segments
        ForEach(0..<Int(progress * 8), id: \.self) { index in
            Circle()
                .trim(
                    from: CGFloat(index) * 0.125 * min(progress, 1.0),
                    to: CGFloat(index + 1) * 0.125 * min(progress, 1.0) - 0.01
                )
                .stroke(
                    color.opacity(0.3),
                    style: StrokeStyle(
                        lineWidth: strokeWidth * 0.3,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .scaleEffect(0.9)
                .opacity(hasAppeared ? 1.0 : 0.0)
                .animation(
                    .spring(response: 0.8, dampingFraction: 0.8)
                    .delay(Double(index) * 0.1),
                    value: hasAppeared
                )
        }
    }
    
    // MARK: - Over-Budget Effects
    
    @ViewBuilder
    private var overBudgetEffects: some View {
        ZStack {
            // Pulsing warning ring
            Circle()
                .stroke(
                    DSColors.error.main.opacity(0.3),
                    lineWidth: strokeWidth * 1.5
                )
                .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                .opacity(pulseAnimation ? 0.0 : 0.6)
                .animation(
                    .easeInOut(duration: pulseInterval)
                    .repeatForever(autoreverses: true),
                    value: pulseAnimation
                )
            
            // Warning indicators
            ForEach(0..<4) { index in
                Circle()
                    .fill(DSColors.error.main)
                    .frame(width: 8, height: 8)
                    .offset(y: -size/2 - 10)
                    .rotationEffect(.degrees(Double(index) * 90))
                    .opacity(pulseAnimation ? 1.0 : 0.5)
                    .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                    .animation(
                        .easeInOut(duration: pulseInterval * 0.5)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.1),
                        value: pulseAnimation
                    )
            }
        }
    }
    
    // MARK: - Glow Effect
    
    @ViewBuilder
    private var glowEffect: some View {
        if progress > 0.5 {
            Circle()
                .stroke(
                    color.opacity(glowIntensity),
                    lineWidth: strokeWidth * 0.5
                )
                .blur(radius: 4)
                .scaleEffect(1.1)
                .animation(
                    .easeInOut(duration: 3.0)
                    .repeatForever(autoreverses: true),
                    value: glowIntensity
                )
        }
    }
    
    // MARK: - Gradient Definitions
    
    private var progressGradient: AngularGradient {
        let colors: [Color] = {
            if progress >= 1.0 {
                return [DSColors.error.main, DSColors.warning.main, color]
            } else if progress >= 0.8 {
                return [DSColors.warning.main, color, color.opacity(0.7)]
            } else {
                return [color, color.opacity(0.7), color.opacity(0.5)]
            }
        }()
        
        return AngularGradient(
            colors: colors,
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(-90 + 360 * min(progress, 1.0))
        )
    }
    
    private var overBudgetGradient: AngularGradient {
        AngularGradient(
            colors: [
                DSColors.error.main,
                DSColors.error.e600,
                DSColors.error.main.opacity(0.8)
            ],
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(-90 + 360 * (progress - 1.0))
        )
    }
    
    // MARK: - Accessibility
    
    private var accessibilityLabel: String {
        if isOverBudget {
            return "Budget progress: Over budget"
        } else {
            return "Budget progress"
        }
    }
    
    private var accessibilityValue: String {
        let percentage = Int(progress * 100)
        if isOverBudget {
            return "\(percentage)% spent, over budget by \(percentage - 100)%"
        } else {
            return "\(percentage)% of budget used"
        }
    }
    
    // MARK: - Animation Control
    
    private func startAnimations() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
            hasAppeared = true
        }
        
        // Start pulse animation for over-budget
        if isOverBudget {
            withAnimation(.easeInOut(duration: pulseInterval).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
        
        // Start glow animation
        if progress > 0.5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                    glowIntensity = 0.3
                }
            }
        }
    }
    
    private func updateAnimations() {
        // Update animations when progress changes
        if isOverBudget && !pulseAnimation {
            withAnimation(.easeInOut(duration: pulseInterval).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        } else if !isOverBudget && pulseAnimation {
            pulseAnimation = false
        }
        
        // Update glow based on progress
        let shouldGlow = progress > 0.5
        if shouldGlow && glowIntensity == 0 {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                glowIntensity = 0.3
            }
        } else if !shouldGlow && glowIntensity > 0 {
            withAnimation(.easeOut(duration: 1.0)) {
                glowIntensity = 0
            }
        }
    }
}

// MARK: - Enhanced Progress Ring Variants

extension BudgetProgressRing {
    /// Minimal version without effects
    static func minimal(
        progress: Double,
        color: Color,
        size: CGFloat = 80
    ) -> some View {
        MinimalProgressRing(
            progress: progress,
            color: color,
            size: size
        )
    }
    
    /// Interactive version with tap gestures
    static func interactive(
        progress: Double,
        color: Color,
        size: CGFloat = 120,
        onTap: (() -> Void)? = nil
    ) -> some View {
        InteractiveProgressRing(
            progress: progress,
            color: color,
            size: size,
            onTap: onTap
        )
    }
    
    /// Multi-segment version for category breakdown
    static func multiSegment(
        segments: [ProgressSegment],
        size: CGFloat = 120
    ) -> some View {
        MultiSegmentProgressRing(
            segments: segments,
            size: size
        )
    }
}

// MARK: - Minimal Progress Ring

struct MinimalProgressRing: View {
    let progress: Double
    let color: Color
    let size: CGFloat
    
    @State private var hasAppeared = false
    
    private var strokeWidth: CGFloat {
        size * 0.06
    }
    
    var body: some View {
        ZStack {
            // Background
            Circle()
                .stroke(
                    color.opacity(0.1),
                    lineWidth: strokeWidth
                )
            
            // Progress
            Circle()
                .trim(from: 0, to: hasAppeared ? CGFloat(min(progress, 1.0)) : 0)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: strokeWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(
                    .spring(response: 1.0, dampingFraction: 0.8),
                    value: hasAppeared
                )
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1)) {
                hasAppeared = true
            }
        }
    }
}

// MARK: - Interactive Progress Ring

struct InteractiveProgressRing: View {
    let progress: Double
    let color: Color
    let size: CGFloat
    let onTap: (() -> Void)?
    
    @State private var isPressed = false
    @State private var hasAppeared = false
    
    var body: some View {
        Button(action: {
            onTap?()
            #if canImport(UIKit)
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            #endif
        }) {
            BudgetProgressRing(
                progress: progress,
                color: color,
                size: size
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: 50,
            pressing: { pressing in
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
    }
}

// MARK: - Multi-Segment Progress Ring

struct MultiSegmentProgressRing: View {
    let segments: [ProgressSegment]
    let size: CGFloat
    
    @State private var hasAppeared = false
    
    private var strokeWidth: CGFloat {
        size * 0.08
    }
    
    private var totalProgress: Double {
        segments.reduce(0) { $0 + $1.progress }
    }
    
    var body: some View {
        ZStack {
            // Background
            Circle()
                .stroke(
                    Color.gray.opacity(0.1),
                    lineWidth: strokeWidth
                )
            
            // Segments
            ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                let startAngle = calculateStartAngle(for: index)
                let endAngle = startAngle + (segment.progress * 360)
                
                Circle()
                    .trim(
                        from: hasAppeared ? CGFloat(startAngle / 360) : 0,
                        to: hasAppeared ? CGFloat(endAngle / 360) : 0
                    )
                    .stroke(
                        segment.color,
                        style: StrokeStyle(
                            lineWidth: strokeWidth,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(
                        .spring(response: 1.0, dampingFraction: 0.8)
                        .delay(Double(index) * 0.2),
                        value: hasAppeared
                    )
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                hasAppeared = true
            }
        }
    }
    
    private func calculateStartAngle(for index: Int) -> Double {
        segments.prefix(index).reduce(0) { $0 + $1.progress * 360 }
    }
}

// MARK: - Progress Segment Model

struct ProgressSegment: Identifiable {
    let id = UUID()
    let progress: Double // 0.0 to 1.0
    let color: Color
    let label: String
}

// MARK: - Preview

#Preview("Budget Progress Rings") {
    ScrollView {
        VStack(spacing: DSSpacing.xl) {
            // Regular progress ring
            VStack {
                Text("Regular Progress Ring")
                    .font(DSTypography.title.title3)
                
                BudgetProgressRing(
                    progress: 0.75,
                    color: DSColors.primary.main,
                    size: 120
                )
            }
            
            // Over-budget ring
            VStack {
                Text("Over Budget Ring")
                    .font(DSTypography.title.title3)
                
                BudgetProgressRing(
                    progress: 1.25,
                    color: DSColors.primary.main,
                    isOverBudget: true,
                    size: 120
                )
            }
            
            // Minimal ring
            VStack {
                Text("Minimal Ring")
                    .font(DSTypography.title.title3)
                
                BudgetProgressRing.minimal(
                    progress: 0.6,
                    color: DSColors.success.main,
                    size: 80
                )
            }
            
            // Multi-segment ring
            VStack {
                Text("Multi-Segment Ring")
                    .font(DSTypography.title.title3)
                
                BudgetProgressRing.multiSegment(
                    segments: [
                        ProgressSegment(progress: 0.3, color: DSColors.primary.main, label: "Food"),
                        ProgressSegment(progress: 0.2, color: DSColors.success.main, label: "Transport"),
                        ProgressSegment(progress: 0.15, color: DSColors.warning.main, label: "Entertainment")
                    ],
                    size: 120
                )
            }
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
import SwiftUI
import Foundation

/// Premium glass morphism card component for LedgerPro
///
/// A sophisticated card component with glass morphism effects, gradient borders,
/// and premium animations that rivals Monarch Money's visual quality.
struct GlassCard<Content: View>: View {
    let content: Content
    var gradient: LinearGradient?
    var padding: CGFloat = DSSpacing.component.cardPadding
    var cornerRadius: CGFloat = DSSpacing.radius.standard
    var borderGradient: LinearGradient = LinearGradient(
        colors: [
            DSColors.primary.p400.opacity(0.3),
            DSColors.primary.p600.opacity(0.1),
            DSColors.primary.p300.opacity(0.2)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    var enableHoverEffect: Bool = true
    var enableBorderAnimation: Bool = true
    
    @State private var isHovered = false
    @State private var borderAnimationOffset: CGFloat = 0
    @Environment(\.colorScheme) private var colorScheme
    
    // Performance optimization - lazy rendering for complex content
    @State private var hasAppeared = false
    
    init(
        gradient: LinearGradient? = nil,
        padding: CGFloat = DSSpacing.component.cardPadding,
        cornerRadius: CGFloat = DSSpacing.radius.standard,
        borderGradient: LinearGradient? = nil,
        enableHoverEffect: Bool = true,
        enableBorderAnimation: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.gradient = gradient
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.enableHoverEffect = enableHoverEffect
        self.enableBorderAnimation = enableBorderAnimation
        
        if let customBorder = borderGradient {
            self.borderGradient = customBorder
        } else {
            // Default premium border gradient
            self.borderGradient = LinearGradient(
                colors: [
                    DSColors.primary.p400.opacity(0.3),
                    DSColors.primary.p600.opacity(0.1),
                    DSColors.primary.p300.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var body: some View {
        ZStack {
            // Background - Glass morphism effect
            backgroundLayer
            
            // Content
            if hasAppeared {
                content
                    .padding(padding)
            } else {
                // Placeholder during lazy loading
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 100) // Minimum height placeholder
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(borderOverlay)
        .scaleEffect(hoveredScale)
        .shadow(color: hoveredShadowColor, radius: hoveredShadowRadius, x: 0, y: hoveredShadowY)
        .onHover { hovering in
            if enableHoverEffect {
                withAnimation(DSAnimations.common.gentleBounce) {
                    isHovered = hovering
                }
            }
        }
        .onAppear {
            // Lazy rendering activation
            withAnimation(.easeOut(duration: 0.3)) {
                hasAppeared = true
            }
            
            // Start border animation
            if enableBorderAnimation {
                startBorderAnimation()
            }
        }
    }
    
    // MARK: - Background Layer
    
    @ViewBuilder
    private var backgroundLayer: some View {
        ZStack {
            // Glass morphism background
            if colorScheme == .dark {
                // Dark mode glass effect
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .background(
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        DSColors.neutral.n900.opacity(0.8),
                                        DSColors.neutral.n800.opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            } else {
                // Light mode glass effect
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .background(
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        DSColors.neutral.n50.opacity(0.9),
                                        Color.white.opacity(0.7)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            }
            
            // Optional gradient overlay
            if let gradient = gradient {
                Rectangle()
                    .fill(gradient)
                    .opacity(0.1)
            }
            
            // Subtle noise texture for premium feel
            noiseTexture
        }
    }
    
    // MARK: - Border Overlay
    
    @ViewBuilder
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(
                animatedBorderGradient,
                lineWidth: isHovered ? 1.5 : 1.0
            )
            .animation(DSAnimations.common.quickFeedback, value: isHovered)
    }
    
    // MARK: - Computed Properties
    
    private var hoveredScale: CGFloat {
        isHovered ? 1.02 : 1.0
    }
    
    private var hoveredShadowColor: Color {
        if isHovered {
            return DSColors.primary.p500.opacity(0.15)
        } else {
            return Color.black.opacity(colorScheme == .dark ? 0.6 : 0.05)
        }
    }
    
    private var hoveredShadowRadius: CGFloat {
        isHovered ? 20 : 8
    }
    
    private var hoveredShadowY: CGFloat {
        isHovered ? 8 : 2
    }
    
    private var animatedBorderGradient: LinearGradient {
        if !enableBorderAnimation {
            return borderGradient
        }
        
        // Simplify the gradient animation calculation
        let animationFactor = 0.3
        let angleOffset = borderAnimationOffset
        
        // Calculate animated start and end points
        let startX = 0.5 + Foundation.cos(angleOffset) * animationFactor
        let startY = 0.5 + Foundation.sin(angleOffset) * animationFactor
        let endX = 0.5 - Foundation.cos(angleOffset) * animationFactor
        let endY = 0.5 - Foundation.sin(angleOffset) * animationFactor
        
        // Simple animated colors without complex opacity calculations
        let animatedColors = [
            DSColors.primary.p400.opacity(0.3 + Foundation.sin(angleOffset) * 0.1),
            DSColors.primary.p600.opacity(0.1 + Foundation.sin(angleOffset + 1) * 0.05),
            DSColors.primary.p300.opacity(0.2 + Foundation.sin(angleOffset + 2) * 0.1)
        ]
        
        return LinearGradient(
            colors: animatedColors,
            startPoint: UnitPoint(x: startX, y: startY),
            endPoint: UnitPoint(x: endX, y: endY)
        )
    }
    
    // MARK: - Noise Texture
    
    @ViewBuilder
    private var noiseTexture: some View {
        // Subtle noise pattern for premium texture
        Canvas { context, size in
            // Create a subtle noise pattern
            for x in stride(from: 0, to: size.width, by: 4) {
                for y in stride(from: 0, to: size.height, by: 4) {
                    let opacity = Double.random(in: 0.01...0.03)
                    let noiseColor = colorScheme == .dark ? 
                        Color.white.opacity(opacity) : 
                        Color.black.opacity(opacity)
                    
                    context.fill(
                        Path(CGRect(x: x, y: y, width: 1, height: 1)),
                        with: .color(noiseColor)
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Animation Functions
    
    private func startBorderAnimation() {
        withAnimation(
            .linear(duration: 8.0)
            .repeatForever(autoreverses: false)
        ) {
            borderAnimationOffset = .pi * 2
        }
    }
}

// MARK: - Convenience Initializers

extension GlassCard {
    /// Premium financial card with success gradient
    init(
        successStyle: Bool,
        padding: CGFloat = DSSpacing.component.cardPadding,
        @ViewBuilder content: () -> Content
    ) where Content: View {
        self.init(
            gradient: LinearGradient(
                colors: [DSColors.success.s400, DSColors.success.s600],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            padding: padding,
            borderGradient: LinearGradient(
                colors: [
                    DSColors.success.s400.opacity(0.4),
                    DSColors.success.s600.opacity(0.2),
                    DSColors.success.s300.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            content: content
        )
    }
    
    /// Premium financial card with primary gradient
    init(
        primaryStyle: Bool,
        padding: CGFloat = DSSpacing.component.cardPadding,
        @ViewBuilder content: () -> Content
    ) where Content: View {
        self.init(
            gradient: LinearGradient(
                colors: [DSColors.primary.p400, DSColors.primary.p600],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            padding: padding,
            content: content
        )
    }
    
    /// Clean glass card without gradient
    init(
        cleanStyle: Bool,
        padding: CGFloat = DSSpacing.component.cardPadding,
        enableBorderAnimation: Bool = false,
        @ViewBuilder content: () -> Content
    ) where Content: View {
        self.init(
            padding: padding,
            enableBorderAnimation: enableBorderAnimation,
            content: content
        )
    }
    
    /// Error state card with red accent
    init(
        errorStyle: Bool,
        padding: CGFloat = DSSpacing.component.cardPadding,
        @ViewBuilder content: () -> Content
    ) where Content: View {
        self.init(
            gradient: LinearGradient(
                colors: [DSColors.error.e400, DSColors.error.e600],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            padding: padding,
            borderGradient: LinearGradient(
                colors: [
                    DSColors.error.e400.opacity(0.4),
                    DSColors.error.e600.opacity(0.2),
                    DSColors.error.e300.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            content: content
        )
    }
}

// MARK: - View Extensions

extension View {
    /// Apply glass card container with default settings
    func glassCard(
        gradient: LinearGradient? = nil,
        padding: CGFloat = DSSpacing.component.cardPadding
    ) -> some View {
        GlassCard(
            gradient: gradient,
            padding: padding
        ) {
            self
        }
    }
    
    /// Apply premium glass card with success styling
    func successGlassCard(
        padding: CGFloat = DSSpacing.component.cardPadding
    ) -> some View {
        GlassCard(successStyle: true, padding: padding) {
            self
        }
    }
    
    /// Apply premium glass card with primary styling
    func primaryGlassCard(
        padding: CGFloat = DSSpacing.component.cardPadding
    ) -> some View {
        GlassCard(primaryStyle: true, padding: padding) {
            self
        }
    }
    
    /// Apply clean glass card styling
    func cleanGlassCard(
        padding: CGFloat = DSSpacing.component.cardPadding,
        enableBorderAnimation: Bool = false
    ) -> some View {
        GlassCard(
            cleanStyle: true,
            padding: padding,
            enableBorderAnimation: enableBorderAnimation
        ) {
            self
        }
    }
}

// MARK: - Preview

#Preview("Glass Card Variations") {
    VStack(spacing: DSSpacing.xl) {
        // Clean glass card
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text("Clean Glass Card")
                .font(DSTypography.title.title3)
                .foregroundColor(DSColors.neutral.text)
            
            Text("Ultra-thin material with subtle border animation")
                .font(DSTypography.body.regular)
                .foregroundColor(DSColors.neutral.textSecondary)
        }
        .cleanGlassCard()
        
        // Success gradient card
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            HStack {
                Image(systemName: "arrow.up.right.circle.fill")
                    .font(DSTypography.title.title2)
                    .foregroundColor(DSColors.success.main)
                
                Spacer()
                
                Text("+12.5%")
                    .font(DSTypography.financial.percentage)
                    .foregroundColor(DSColors.success.main)
            }
            
            Text("$25,847.50")
                .font(DSTypography.display.display3)
                .foregroundColor(DSColors.neutral.text)
            
            Text("Portfolio Value")
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.neutral.textSecondary)
        }
        .successGlassCard()
        
        // Primary gradient card
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .font(DSTypography.title.title2)
                    .foregroundColor(DSColors.primary.main)
                
                Spacer()
                
                Text("****1234")
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
            }
            
            Text("$5,423.89")
                .font(DSTypography.display.display3)
                .foregroundColor(DSColors.neutral.text)
            
            Text("Checking Account")
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.neutral.textSecondary)
        }
        .primaryGlassCard()
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
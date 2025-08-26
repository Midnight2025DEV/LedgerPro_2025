import SwiftUI

/// LedgerPro Design System - Animations
///
/// A comprehensive animation system providing consistent timing, easing,
/// and transitions throughout the financial application interface.
public struct DSAnimations {
    
    // MARK: - Timing Values
    
    /// Animation timing constants for consistent duration across the app
    public static let timing = Timing()
    
    public struct Timing {
        /// Ultra fast: 0.1s - Micro-interactions, hover states
        public let ultraFast: TimeInterval = 0.1
        
        /// Fast: 0.2s - Quick state changes, button presses
        public let fast: TimeInterval = 0.2
        
        /// Medium: 0.3s - Standard UI transitions, modal presentations
        public let medium: TimeInterval = 0.3
        
        /// Slow: 0.5s - Large state changes, significant transitions
        public let slow: TimeInterval = 0.5
        
        /// Extra slow: 0.8s - Hero animations, major layout changes
        public let extraSlow: TimeInterval = 0.8
        
        /// Toast duration: 3.0s - Time before auto-dismiss
        public let toastDuration: TimeInterval = 3.0
        
        /// Debounce duration: 0.25s - Search input debouncing
        public let debounce: TimeInterval = 0.25
    }
    
    // MARK: - Easing Curves
    
    /// Standard easing functions extracted from existing patterns
    public static let easing = Easing()
    
    public struct Easing {
        /// Ease in out: Smooth start and end (most common)
        public static func easeInOut(duration: TimeInterval = DSAnimations.timing.medium) -> Animation {
            .easeInOut(duration: duration)
        }
        
        /// Ease out: Quick start, smooth end (for appearing elements)
        public static func easeOut(duration: TimeInterval = DSAnimations.timing.medium) -> Animation {
            .easeOut(duration: duration)
        }
        
        /// Ease in: Smooth start, quick end (for disappearing elements)
        public static func easeIn(duration: TimeInterval = DSAnimations.timing.medium) -> Animation {
            .easeIn(duration: duration)
        }
        
        /// Linear: Constant speed (for continuous animations)
        public static func linear(duration: TimeInterval = DSAnimations.timing.medium) -> Animation {
            .linear(duration: duration)
        }
        
        /// Spring: Natural bounce effect (for interactive elements)
        public static func spring(
            response: Double = 0.3,
            dampingFraction: Double = 0.8,
            blendDuration: Double = 0
        ) -> Animation {
            .spring(response: response, dampingFraction: dampingFraction, blendDuration: blendDuration)
        }
        
        /// Smooth spring: Gentle bounce (for UI feedback)
        public static func smoothSpring(
            response: Double = 0.5,
            dampingFraction: Double = 0.7
        ) -> Animation {
            .spring(response: response, dampingFraction: dampingFraction)
        }
        
        /// Bouncy spring: More pronounced bounce (for success states)
        public static func bouncySpring(
            response: Double = 0.6,
            dampingFraction: Double = 0.6
        ) -> Animation {
            .spring(response: response, dampingFraction: dampingFraction)
        }
    }
    
    // MARK: - Common Animations
    
    /// Pre-defined animations for common use cases
    public static let common = CommonAnimations()
    
    public struct CommonAnimations {
        /// Quick UI feedback (0.2s ease in out)
        public let quickFeedback = Animation.easeInOut(duration: DSAnimations.timing.fast)
        
        /// Standard transition (0.3s ease in out)
        public let standardTransition = Animation.easeInOut(duration: DSAnimations.timing.medium)
        
        /// Smooth fade (0.3s ease in out)
        public let smoothFade = Animation.easeInOut(duration: DSAnimations.timing.medium)
        
        /// Button press response (spring with quick response)
        public let buttonPress = Animation.spring(response: 0.3, dampingFraction: 0.8)
        
        /// Scale up animation (for success states)
        public let scaleUp = Animation.spring(response: 0.6, dampingFraction: 0.8)
        
        /// Gentle bounce (for category selection)
        public let gentleBounce = Animation.spring(response: 0.3, dampingFraction: 0.7)
        
        /// Rotation animation (for loading indicators)
        public let rotation = Animation.linear(duration: 2.0).repeatForever(autoreverses: false)
        
        /// Pulse animation (for emphasis)
        public let pulse = Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
        
        /// Slide transition (for panel animations)
        public let slide = Animation.easeInOut(duration: DSAnimations.timing.medium)
    }
    
    // MARK: - Transition Effects
    
    /// Common transition combinations used throughout the app
    public static let transitions = Transitions()
    
    public struct Transitions {
        /// Fade transition (opacity change)
        public let fade = AnyTransition.opacity
        
        /// Scale transition (size change with fade)
        public let scale = AnyTransition.scale.combined(with: .opacity)
        
        /// Scale down transition (for modals)
        public let scaleDown = AnyTransition.scale(scale: 0.95).combined(with: .opacity)
        
        /// Slide from top (for toasts, notifications)
        public let slideFromTop = AnyTransition.move(edge: .top).combined(with: .opacity)
        
        /// Slide from bottom (for sheets, action panels)
        public let slideFromBottom = AnyTransition.move(edge: .bottom).combined(with: .opacity)
        
        /// Slide from trailing (for sidebars, details)
        public let slideFromTrailing = AnyTransition.move(edge: .trailing).combined(with: .opacity)
        
        /// Slide from leading (for navigation)
        public let slideFromLeading = AnyTransition.move(edge: .leading).combined(with: .opacity)
        
        /// Asymmetric slide (different in/out transitions)
        public let asymmetricSlide = AnyTransition.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        )
        
        /// Modal presentation (scale with fade)
        public let modalPresentation = AnyTransition.scale(scale: 0.95).combined(with: .opacity)
        
        /// Toast notification (slide from top)
        public let toastNotification = AnyTransition.move(edge: .top).combined(with: .opacity)
        
        /// Category picker (scale with fade)
        public let categoryPicker = AnyTransition.opacity.combined(with: .scale(scale: 0.95))
        
        /// Loading skeleton (fade)
        public let loadingSkeleton = AnyTransition.opacity
        
        /// Filter overlay (slide from top)
        public let filterOverlay = AnyTransition.move(edge: .top).combined(with: .opacity)
    }
    
    // MARK: - Financial-Specific Animations
    
    /// Animations tailored for financial interface patterns
    public static let financial = FinancialAnimations()
    
    public struct FinancialAnimations {
        /// Amount change animation (for balance updates)
        public let amountChange = Animation.spring(response: 0.6, dampingFraction: 0.8)
        
        /// Chart data update (smooth transition for charts)
        public let chartDataUpdate = Animation.easeInOut(duration: 0.8)
        
        /// Transaction categorization (success feedback)
        public let categorization = Animation.spring(response: 0.3, dampingFraction: 0.7)
        
        /// Progress bar animation (linear for consistency)
        public let progressBar = Animation.linear(duration: 0.3)
        
        /// Currency conversion (gentle bounce)
        public let currencyConversion = Animation.spring(response: 0.5, dampingFraction: 0.7)
        
        /// Account selection (quick response)
        public let accountSelection = Animation.easeInOut(duration: 0.2)
        
        /// Loading states (smooth fade)
        public let loadingState = Animation.easeInOut(duration: 0.3)
        
        /// Auto-categorization feedback (bouncy spring)
        public let autoCategorization = Animation.spring(response: 0.6, dampingFraction: 0.6)
        
        /// Filter application (quick transition)
        public let filterApplication = Animation.easeInOut(duration: 0.2)
    }
    
    // MARK: - Animation Modifiers
    
    /// Repeating animations for continuous effects
    public static let repeating = RepeatingAnimations()
    
    public struct RepeatingAnimations {
        /// Infinite rotation (for loading spinners)
        public let infiniteRotation = Animation.linear(duration: 2.0).repeatForever(autoreverses: false)
        
        /// Breathing effect (for emphasis)
        public let breathing = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
        
        /// Pulsing effect (for notifications)
        public let pulsing = Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
        
        /// Shimmer effect (for skeleton loading)
        public let shimmer = Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
        
        /// Gradient animation (for loading backgrounds)
        public let gradientShift = Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
    }
    
    // MARK: - Performance Optimizations
    
    /// Animation performance settings
    public static let performance = PerformanceSettings()
    
    public struct PerformanceSettings {
        /// Reduced motion setting (for accessibility)
        public static var respectsReducedMotion: Bool = true
        
        /// Animation quality levels
        public enum Quality {
            case high, medium, low
            
            var animationMultiplier: Double {
                switch self {
                case .high: return 1.0
                case .medium: return 0.75
                case .low: return 0.5
                }
            }
        }
        
        /// Current quality setting
        public static var currentQuality: Quality = .high
        
        /// Get adjusted duration based on quality setting
        public static func adjustedDuration(_ duration: TimeInterval) -> TimeInterval {
            return duration * currentQuality.animationMultiplier
        }
    }
}

// MARK: - SwiftUI Extensions for Easy Animation Application

extension View {
    
    // MARK: - Common Animation Shortcuts
    
    /// Apply quick feedback animation
    public func quickFeedback() -> some View {
        self.animation(DSAnimations.common.quickFeedback, value: true)
    }
    
    /// Apply standard transition animation
    public func standardTransition<V: Equatable>(_ value: V) -> some View {
        self.animation(DSAnimations.common.standardTransition, value: value)
    }
    
    /// Apply smooth fade animation
    public func smoothFade<V: Equatable>(_ value: V) -> some View {
        self.animation(DSAnimations.common.smoothFade, value: value)
    }
    
    /// Apply gentle bounce animation
    public func gentleBounce<V: Equatable>(_ value: V) -> some View {
        self.animation(DSAnimations.common.gentleBounce, value: value)
    }
    
    // MARK: - Financial Animation Shortcuts
    
    /// Apply amount change animation (for financial values)
    public func amountChange<V: Equatable>(_ value: V) -> some View {
        self.animation(DSAnimations.financial.amountChange, value: value)
    }
    
    /// Apply categorization animation (for category changes)
    public func categorizationFeedback<V: Equatable>(_ value: V) -> some View {
        self.animation(DSAnimations.financial.categorization, value: value)
    }
    
    /// Apply loading state animation
    public func loadingState<V: Equatable>(_ value: V) -> some View {
        self.animation(DSAnimations.financial.loadingState, value: value)
    }
    
    /// Apply filter animation (for search/filter changes)
    public func filterAnimation<V: Equatable>(_ value: V) -> some View {
        self.animation(DSAnimations.financial.filterApplication, value: value)
    }
    
    // MARK: - Transition Application
    
    /// Apply toast notification transition
    public func toastTransition() -> some View {
        self.transition(DSAnimations.transitions.toastNotification)
    }
    
    /// Apply modal presentation transition
    public func modalTransition() -> some View {
        self.transition(DSAnimations.transitions.modalPresentation)
    }
    
    /// Apply scale transition
    public func scaleTransition() -> some View {
        self.transition(DSAnimations.transitions.scale)
    }
    
    /// Apply slide from top transition
    public func slideFromTopTransition() -> some View {
        self.transition(DSAnimations.transitions.slideFromTop)
    }
    
    /// Apply category picker transition
    public func categoryPickerTransition() -> some View {
        self.transition(DSAnimations.transitions.categoryPicker)
    }
    
    // MARK: - Interactive Animation Helpers
    
    /// Apply hover scale effect with animation
    public func hoverScale(isHovered: Bool, scale: CGFloat = 1.05) -> some View {
        self
            .scaleEffect(isHovered ? scale : 1.0)
            .animation(DSAnimations.common.gentleBounce, value: isHovered)
    }
    
    /// Apply selection scale effect with animation
    public func selectionScale(isSelected: Bool, scale: CGFloat = 1.05) -> some View {
        self
            .scaleEffect(isSelected ? scale : 1.0)
            .animation(DSAnimations.common.gentleBounce, value: isSelected)
    }
    
    /// Apply rotation effect with animation
    public func rotationFeedback(angle: Double) -> some View {
        self
            .rotationEffect(.degrees(angle))
            .animation(DSAnimations.common.standardTransition, value: angle)
    }
    
    /// Apply opacity change with animation
    public func opacityFeedback(opacity: Double) -> some View {
        self
            .opacity(opacity)
            .animation(DSAnimations.common.smoothFade, value: opacity)
    }
    
    // MARK: - Conditional Animation
    
    /// Apply animation only if motion is not reduced
    public func conditionalAnimation<V: Equatable>(
        _ animation: Animation,
        value: V
    ) -> some View {
        Group {
            if DSAnimations.PerformanceSettings.respectsReducedMotion && isReduceMotionEnabled {
                self
            } else {
                self.animation(animation, value: value)
            }
        }
    }
    
    /// Check if reduce motion is enabled (simplified for example)
    private var isReduceMotionEnabled: Bool {
        // In a real implementation, this would check system accessibility settings
        false
    }
}

// MARK: - Custom Animation Functions

extension DSAnimations {
    
    /// Create a delayed animation
    public static func delayed(
        _ animation: Animation,
        delay: TimeInterval
    ) -> Animation {
        animation.delay(delay)
    }
    
    /// Create a staggered animation for multiple elements
    public static func staggered(
        _ baseAnimation: Animation,
        itemCount: Int,
        staggerDelay: TimeInterval = 0.1
    ) -> [Animation] {
        (0..<itemCount).map { index in
            baseAnimation.delay(TimeInterval(index) * staggerDelay)
        }
    }
    
    /// Create animation based on performance setting
    public static func adaptive(
        _ animation: Animation,
        quality: PerformanceSettings.Quality = .high
    ) -> Animation {
        // For now, return the original animation
        // Pattern matching on Animation is complex in Swift
        return animation
    }
}

// MARK: - Animation Presets for Common Scenarios

extension DSAnimations {
    
    /// Animation presets for specific UI scenarios
    public static let presets = AnimationPresets()
    
    public struct AnimationPresets {
        
        // MARK: - List Animations
        
        /// Transaction list filtering
        public let listFiltering = Animation.easeInOut(duration: 0.2)
        
        /// Transaction row selection
        public let rowSelection = Animation.spring(response: 0.3, dampingFraction: 0.7)
        
        /// List item insertion
        public let itemInsertion = Animation.spring(response: 0.5, dampingFraction: 0.8)
        
        /// List item removal
        public let itemRemoval = Animation.easeIn(duration: 0.3)
        
        // MARK: - Modal Animations
        
        /// Modal presentation
        public let modalPresent = Animation.easeOut(duration: 0.3)
        
        /// Modal dismissal
        public let modalDismiss = Animation.easeIn(duration: 0.2)
        
        /// Sheet presentation
        public let sheetPresent = Animation.easeOut(duration: 0.4)
        
        // MARK: - Toast Animations
        
        /// Toast appearance
        public let toastAppear = Animation.spring(response: 0.4, dampingFraction: 0.8)
        
        /// Toast dismissal
        public let toastDismiss = Animation.easeIn(duration: 0.3)
        
        // MARK: - Loading Animations
        
        /// Loading spinner
        public let spinner = Animation.linear(duration: 1.0).repeatForever(autoreverses: false)
        
        /// Progress bar
        public let progressBar = Animation.easeInOut(duration: 0.3)
        
        /// Skeleton loading
        public let skeleton = Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)
        
        // MARK: - Financial Animations
        
        /// Balance update
        public let balanceUpdate = Animation.spring(response: 0.6, dampingFraction: 0.8)
        
        /// Chart animation
        public let chartUpdate = Animation.easeInOut(duration: 0.8)
        
        /// Category assignment
        public let categoryAssignment = Animation.spring(response: 0.4, dampingFraction: 0.7)
    }
}

// MARK: - Legacy Animation Support

/// Legacy animation support for backward compatibility
extension DSAnimations {
    
    /// Legacy animation values for smooth migration
    public struct Legacy {
        /// Standard easeInOut duration from existing code
        public static let standardDuration: TimeInterval = 0.3
        
        /// Quick feedback duration from existing code
        public static let quickDuration: TimeInterval = 0.2
        
        /// Spring animation from existing code
        public static let springAnimation = Animation.spring(response: 0.3, dampingFraction: 0.8)
        
        /// Toast auto-dismiss duration from existing code
        public static let toastDuration: TimeInterval = 3.0
        
        /// Category icon rotation from existing code
        public static let iconRotation = Animation.spring(response: 0.5, dampingFraction: 0.6)
        
        /// File upload animation from existing code
        public static let uploadAnimation = Animation.spring(response: 0.6, dampingFraction: 0.8)
    }
}

// MARK: - macOS Animation Optimizations

#if os(macOS)
extension DSAnimations {
    
    /// macOS-specific animation adjustments
    public struct macOS {
        /// Reduced motion for desktop interaction patterns
        public static let reducedMotion = true
        
        /// Faster animations for desktop responsiveness
        public static let desktopMultiplier: Double = 0.8
        
        /// Window transition animations
        public static let windowTransition = Animation.easeInOut(duration: 0.25)
        
        /// Popover animations
        public static let popoverTransition = Animation.easeOut(duration: 0.2)
        
        /// Menu animations
        public static let menuTransition = Animation.easeOut(duration: 0.15)
    }
}
#endif
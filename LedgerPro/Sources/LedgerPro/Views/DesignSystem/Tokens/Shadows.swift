import SwiftUI

/// LedgerPro Design System - Shadows
///
/// A comprehensive shadow system providing depth, elevation, and visual hierarchy
/// throughout the financial application interface. Based on material design principles
/// and optimized for financial data presentation.
public struct DSShadows {
    
    // MARK: - Shadow Levels (Elevation)
    
    /// Subtle shadow: 1pt radius - Cards, list items, minimal elevation
    public static let subtle = ShadowStyle(
        color: Color.black.opacity(0.08),
        radius: 1,
        x: 0,
        y: 0
    )
    
    /// Small shadow: 2pt radius - Interactive elements, small cards
    public static let small = ShadowStyle(
        color: Color.black.opacity(0.1),
        radius: 2,
        x: 0,
        y: 1
    )
    
    /// Medium shadow: 4pt radius - Dropdowns, tooltips, floating elements
    public static let medium = ShadowStyle(
        color: Color.black.opacity(0.05),
        radius: 4,
        x: 0,
        y: 2
    )
    
    /// Large shadow: 8pt radius - Modals, popovers, elevated content
    public static let large = ShadowStyle(
        color: Color.black.opacity(0.05),
        radius: 8,
        x: 0,
        y: 2
    )
    
    /// Extra large shadow: 10pt radius - Toast notifications, floating panels
    public static let extraLarge = ShadowStyle(
        color: Color.black.opacity(0.1),
        radius: 10,
        x: 0,
        y: 5
    )
    
    /// Huge shadow: 20pt radius - Modal dialogs, major overlays
    public static let huge = ShadowStyle(
        color: Color.black.opacity(0.3),
        radius: 20,
        x: 0,
        y: 8
    )
    
    // MARK: - Component-Specific Shadows
    
    /// Shadows optimized for specific component types
    public static let component = ComponentShadows()
    
    public struct ComponentShadows {
        /// Card shadow (from StatCard, AccountCard patterns)
        public let card = ShadowStyle(
            color: Color.black.opacity(0.08),
            radius: 1,
            x: 0,
            y: 0
        )
        
        /// Transaction row shadow (subtle depth)
        public let transactionRow = ShadowStyle(
            color: Color.black.opacity(0.08),
            radius: 1,
            x: 0,
            y: 0
        )
        
        /// Modal shadow (strong depth for overlays)
        public let modal = ShadowStyle(
            color: Color.black.opacity(0.3),
            radius: 20,
            x: 0,
            y: 8
        )
        
        /// Popup shadow (medium depth for dropdowns)
        public let popup = ShadowStyle(
            color: Color.black.opacity(0.3),
            radius: 20,
            x: 0,
            y: 8
        )
        
        /// Toast shadow (floating notification)
        public let toast = ShadowStyle(
            color: Color.black.opacity(0.1),
            radius: 10,
            x: 0,
            y: 5
        )
        
        /// Button shadow (interactive element)
        public let button = ShadowStyle(
            color: Color.black.opacity(0.05),
            radius: 4,
            x: 0,
            y: 2
        )
        
        /// Chart shadow (data visualization)
        public let chart = ShadowStyle(
            color: Color.black.opacity(0.05),
            radius: 8,
            x: 0,
            y: 2
        )
        
        /// Insight card shadow (enhanced depth)
        public let insightCard = ShadowStyle(
            color: Color.black.opacity(0.06),
            radius: 2,
            x: 0,
            y: 1
        )
        
        /// Performance test shadow (minimal depth)
        public let performanceTest = ShadowStyle(
            color: Color.black.opacity(0.08),
            radius: 1,
            x: 0,
            y: 0
        )
        
        /// Filter overlay shadow (floating panel)
        public let filterOverlay = ShadowStyle(
            color: Color.black.opacity(0.15),
            radius: 5,
            x: 0,
            y: 3
        )
    }
    
    // MARK: - Financial-Specific Shadows
    
    /// Shadows tailored for financial interface elements
    public static let financial = FinancialShadows()
    
    public struct FinancialShadows {
        /// Account balance card (important financial data)
        public let balanceCard = ShadowStyle(
            color: Color.black.opacity(0.1),
            radius: 3,
            x: 0,
            y: 2
        )
        
        /// Transaction detail modal (critical information)
        public let transactionDetail = ShadowStyle(
            color: Color.black.opacity(0.3),
            radius: 20,
            x: 0,
            y: 8
        )
        
        /// Category picker (selection interface)
        public let categoryPicker = ShadowStyle(
            color: Color.black.opacity(0.3),
            radius: 20,
            x: 0,
            y: 8
        )
        
        /// Financial metric card (KPI display)
        public let metricCard = ShadowStyle(
            color: Color.black.opacity(0.08),
            radius: 1,
            x: 0,
            y: 0
        )
        
        /// Auto-categorization toast (success feedback)
        public let autoCategory = ShadowStyle(
            color: Color.black.opacity(0.1),
            radius: 10,
            x: 0,
            y: 5
        )
        
        /// Currency conversion indicator (forex data)
        public let currencyIndicator = ShadowStyle(
            color: Color.black.opacity(0.05),
            radius: 2,
            x: 0,
            y: 1
        )
        
        /// Account selection highlight
        public let accountSelection = ShadowStyle(
            color: Color.blue.opacity(0.2),
            radius: 4,
            x: 0,
            y: 2
        )
        
        /// Error state shadow (attention grabbing)
        public let errorState = ShadowStyle(
            color: Color.red.opacity(0.15),
            radius: 6,
            x: 0,
            y: 3
        )
        
        /// Success state shadow (positive feedback)
        public let successState = ShadowStyle(
            color: Color.green.opacity(0.15),
            radius: 6,
            x: 0,
            y: 3
        )
    }
    
    // MARK: - Colored Shadows
    
    /// Shadows with specific colors for semantic purposes
    public static let colored = ColoredShadows()
    
    public struct ColoredShadows {
        /// Primary brand shadow (electric blue tint)
        public let primary = ShadowStyle(
            color: DSColors.primary.p500.opacity(0.2),
            radius: 8,
            x: 0,
            y: 4
        )
        
        /// Success shadow (green tint for positive actions)
        public let success = ShadowStyle(
            color: DSColors.success.s500.opacity(0.15),
            radius: 6,
            x: 0,
            y: 3
        )
        
        /// Error shadow (red tint for error states)
        public let error = ShadowStyle(
            color: DSColors.error.e500.opacity(0.15),
            radius: 6,
            x: 0,
            y: 3
        )
        
        /// Warning shadow (amber tint for warnings)
        public let warning = ShadowStyle(
            color: DSColors.warning.w500.opacity(0.15),
            radius: 6,
            x: 0,
            y: 3
        )
        
        /// Category shadow with dynamic color
        public func category(color: Color) -> ShadowStyle {
            ShadowStyle(
                color: color.opacity(0.3),
                radius: 10,
                x: 0,
                y: 5
            )
        }
    }
    
    // MARK: - Interactive Shadows
    
    /// Shadows that change based on interaction states
    public static let interactive = InteractiveShadows()
    
    public struct InteractiveShadows {
        /// Default state shadow
        public let normal = ShadowStyle(
            color: Color.black.opacity(0.05),
            radius: 2,
            x: 0,
            y: 1
        )
        
        /// Hover state shadow (elevated)
        public let hover = ShadowStyle(
            color: Color.black.opacity(0.1),
            radius: 6,
            x: 0,
            y: 3
        )
        
        /// Pressed state shadow (depressed)
        public let pressed = ShadowStyle(
            color: Color.black.opacity(0.03),
            radius: 1,
            x: 0,
            y: 0
        )
        
        /// Selected state shadow (highlighted)
        public let selected = ShadowStyle(
            color: DSColors.primary.p500.opacity(0.2),
            radius: 8,
            x: 0,
            y: 4
        )
        
        /// Focus state shadow (accessibility)
        public let focus = ShadowStyle(
            color: DSColors.primary.p500.opacity(0.3),
            radius: 6,
            x: 0,
            y: 2
        )
        
        /// Active state shadow (currently interacting)
        public let active = ShadowStyle(
            color: Color.black.opacity(0.15),
            radius: 4,
            x: 0,
            y: 2
        )
    }
    
    // MARK: - Layered Shadows
    
    /// Multiple shadow layers for complex depth effects
    public static let layered = LayeredShadows()
    
    public struct LayeredShadows {
        /// Premium card with multiple shadow layers
        public static let premiumCard: [ShadowStyle] = [
            ShadowStyle(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 0),
            ShadowStyle(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1),
            ShadowStyle(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
        ]
        
        /// Modal with depth layers
        public static let modalDepth: [ShadowStyle] = [
            ShadowStyle(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4),
            ShadowStyle(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 8)
        ]
        
        /// Floating element with realistic depth
        public static let floatingElement: [ShadowStyle] = [
            ShadowStyle(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 1),
            ShadowStyle(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        ]
    }
    
    // MARK: - Platform-Specific Shadows
    
    /// macOS-specific shadow adjustments
    public static let platform = PlatformShadows()
    
    public struct PlatformShadows {
        #if os(macOS)
        /// macOS window shadow
        public let window = ShadowStyle(
            color: Color.black.opacity(0.3),
            radius: 20,
            x: 0,
            y: 8
        )
        
        /// macOS popover shadow
        public let popover = ShadowStyle(
            color: Color.black.opacity(0.15),
            radius: 10,
            x: 0,
            y: 5
        )
        
        /// macOS menu shadow
        public let menu = ShadowStyle(
            color: Color.black.opacity(0.2),
            radius: 8,
            x: 0,
            y: 4
        )
        #endif
    }
}

// MARK: - Shadow Style Structure

/// Represents a complete shadow definition
public struct ShadowStyle {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat
    
    public init(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

// MARK: - SwiftUI Extensions for Easy Shadow Application

extension View {
    
    // MARK: - Elevation Shadows
    
    /// Apply subtle shadow (elevation 1)
    public func shadowSubtle() -> some View {
        self.shadow(
            color: DSShadows.subtle.color,
            radius: DSShadows.subtle.radius,
            x: DSShadows.subtle.x,
            y: DSShadows.subtle.y
        )
    }
    
    /// Apply small shadow (elevation 2)
    public func shadowSmall() -> some View {
        self.shadow(
            color: DSShadows.small.color,
            radius: DSShadows.small.radius,
            x: DSShadows.small.x,
            y: DSShadows.small.y
        )
    }
    
    /// Apply medium shadow (elevation 3)
    public func shadowMedium() -> some View {
        self.shadow(
            color: DSShadows.medium.color,
            radius: DSShadows.medium.radius,
            x: DSShadows.medium.x,
            y: DSShadows.medium.y
        )
    }
    
    /// Apply large shadow (elevation 4)
    public func shadowLarge() -> some View {
        self.shadow(
            color: DSShadows.large.color,
            radius: DSShadows.large.radius,
            x: DSShadows.large.x,
            y: DSShadows.large.y
        )
    }
    
    /// Apply extra large shadow (elevation 5)
    public func shadowExtraLarge() -> some View {
        self.shadow(
            color: DSShadows.extraLarge.color,
            radius: DSShadows.extraLarge.radius,
            x: DSShadows.extraLarge.x,
            y: DSShadows.extraLarge.y
        )
    }
    
    /// Apply huge shadow (elevation 6)
    public func shadowHuge() -> some View {
        self.shadow(
            color: DSShadows.huge.color,
            radius: DSShadows.huge.radius,
            x: DSShadows.huge.x,
            y: DSShadows.huge.y
        )
    }
    
    // MARK: - Component Shadows
    
    /// Apply card shadow (standard card depth)
    public func shadowCard() -> some View {
        self.shadow(
            color: DSShadows.component.card.color,
            radius: DSShadows.component.card.radius,
            x: DSShadows.component.card.x,
            y: DSShadows.component.card.y
        )
    }
    
    /// Apply modal shadow (floating overlay depth)
    public func shadowModal() -> some View {
        self.shadow(
            color: DSShadows.component.modal.color,
            radius: DSShadows.component.modal.radius,
            x: DSShadows.component.modal.x,
            y: DSShadows.component.modal.y
        )
    }
    
    /// Apply popup shadow (dropdown/popover depth)
    public func shadowPopup() -> some View {
        self.shadow(
            color: DSShadows.component.popup.color,
            radius: DSShadows.component.popup.radius,
            x: DSShadows.component.popup.x,
            y: DSShadows.component.popup.y
        )
    }
    
    /// Apply toast shadow (notification depth)
    public func shadowToast() -> some View {
        self.shadow(
            color: DSShadows.component.toast.color,
            radius: DSShadows.component.toast.radius,
            x: DSShadows.component.toast.x,
            y: DSShadows.component.toast.y
        )
    }
    
    /// Apply button shadow (interactive element depth)
    public func shadowButton() -> some View {
        self.shadow(
            color: DSShadows.component.button.color,
            radius: DSShadows.component.button.radius,
            x: DSShadows.component.button.x,
            y: DSShadows.component.button.y
        )
    }
    
    /// Apply chart shadow (data visualization depth)
    public func shadowChart() -> some View {
        self.shadow(
            color: DSShadows.component.chart.color,
            radius: DSShadows.component.chart.radius,
            x: DSShadows.component.chart.x,
            y: DSShadows.component.chart.y
        )
    }
    
    // MARK: - Financial Shadows
    
    /// Apply balance card shadow (important financial data)
    public func shadowBalanceCard() -> some View {
        self.shadow(
            color: DSShadows.financial.balanceCard.color,
            radius: DSShadows.financial.balanceCard.radius,
            x: DSShadows.financial.balanceCard.x,
            y: DSShadows.financial.balanceCard.y
        )
    }
    
    /// Apply transaction detail shadow (critical information)
    public func shadowTransactionDetail() -> some View {
        self.shadow(
            color: DSShadows.financial.transactionDetail.color,
            radius: DSShadows.financial.transactionDetail.radius,
            x: DSShadows.financial.transactionDetail.x,
            y: DSShadows.financial.transactionDetail.y
        )
    }
    
    /// Apply category picker shadow (selection interface)
    public func shadowCategoryPicker() -> some View {
        self.shadow(
            color: DSShadows.financial.categoryPicker.color,
            radius: DSShadows.financial.categoryPicker.radius,
            x: DSShadows.financial.categoryPicker.x,
            y: DSShadows.financial.categoryPicker.y
        )
    }
    
    /// Apply metric card shadow (KPI display)
    public func shadowMetricCard() -> some View {
        self.shadow(
            color: DSShadows.financial.metricCard.color,
            radius: DSShadows.financial.metricCard.radius,
            x: DSShadows.financial.metricCard.x,
            y: DSShadows.financial.metricCard.y
        )
    }
    
    // MARK: - Colored Shadows
    
    /// Apply primary brand shadow
    public func shadowPrimary() -> some View {
        self.shadow(
            color: DSShadows.colored.primary.color,
            radius: DSShadows.colored.primary.radius,
            x: DSShadows.colored.primary.x,
            y: DSShadows.colored.primary.y
        )
    }
    
    /// Apply success shadow (green tint)
    public func shadowSuccess() -> some View {
        self.shadow(
            color: DSShadows.colored.success.color,
            radius: DSShadows.colored.success.radius,
            x: DSShadows.colored.success.x,
            y: DSShadows.colored.success.y
        )
    }
    
    /// Apply error shadow (red tint)
    public func shadowError() -> some View {
        self.shadow(
            color: DSShadows.colored.error.color,
            radius: DSShadows.colored.error.radius,
            x: DSShadows.colored.error.x,
            y: DSShadows.colored.error.y
        )
    }
    
    /// Apply warning shadow (amber tint)
    public func shadowWarning() -> some View {
        self.shadow(
            color: DSShadows.colored.warning.color,
            radius: DSShadows.colored.warning.radius,
            x: DSShadows.colored.warning.x,
            y: DSShadows.colored.warning.y
        )
    }
    
    /// Apply category shadow with custom color
    public func shadowCategory(color: Color) -> some View {
        let categoryShadow = DSShadows.colored.category(color: color)
        return self.shadow(
            color: categoryShadow.color,
            radius: categoryShadow.radius,
            x: categoryShadow.x,
            y: categoryShadow.y
        )
    }
    
    // MARK: - Interactive Shadows
    
    /// Apply interactive shadow that changes with hover state
    public func shadowInteractive(isHovered: Bool = false) -> some View {
        let shadowStyle = isHovered ? DSShadows.interactive.hover : DSShadows.interactive.normal
        return self.shadow(
            color: shadowStyle.color,
            radius: shadowStyle.radius,
            x: shadowStyle.x,
            y: shadowStyle.y
        )
    }
    
    /// Apply selection shadow (highlighted state)
    public func shadowSelected() -> some View {
        self.shadow(
            color: DSShadows.interactive.selected.color,
            radius: DSShadows.interactive.selected.radius,
            x: DSShadows.interactive.selected.x,
            y: DSShadows.interactive.selected.y
        )
    }
    
    /// Apply focus shadow (accessibility)
    public func shadowFocus() -> some View {
        self.shadow(
            color: DSShadows.interactive.focus.color,
            radius: DSShadows.interactive.focus.radius,
            x: DSShadows.interactive.focus.x,
            y: DSShadows.interactive.focus.y
        )
    }
    
    // MARK: - Custom Shadow Application
    
    /// Apply custom shadow style
    public func shadow(_ style: ShadowStyle) -> some View {
        self.shadow(
            color: style.color,
            radius: style.radius,
            x: style.x,
            y: style.y
        )
    }
    
    /// Apply multiple shadow layers
    public func shadows(_ styles: [ShadowStyle]) -> some View {
        styles.reduce(AnyView(self)) { view, style in
            AnyView(
                view.shadow(
                    color: style.color,
                    radius: style.radius,
                    x: style.x,
                    y: style.y
                )
            )
        }
    }
    
    // MARK: - Conditional Shadows
    
    /// Apply shadow only if condition is true
    public func shadowConditional(_ style: ShadowStyle, when condition: Bool) -> some View {
        Group {
            if condition {
                self.shadow(style)
            } else {
                self
            }
        }
    }
    
    /// Apply shadow with opacity adjustment for performance
    public func shadowPerformance(_ style: ShadowStyle, opacity: Double = 1.0) -> some View {
        self.shadow(
            color: style.color.opacity(opacity),
            radius: style.radius,
            x: style.x,
            y: style.y
        )
    }
}

// MARK: - Shadow Utilities

extension DSShadows {
    
    /// Create custom shadow style
    public static func custom(
        color: Color = Color.black,
        opacity: Double = 0.1,
        radius: CGFloat = 4,
        x: CGFloat = 0,
        y: CGFloat = 2
    ) -> ShadowStyle {
        ShadowStyle(
            color: color.opacity(opacity),
            radius: radius,
            x: x,
            y: y
        )
    }
    
    /// Create shadow with brand color tint
    public static func branded(
        brandColor: Color,
        opacity: Double = 0.2,
        radius: CGFloat = 6,
        x: CGFloat = 0,
        y: CGFloat = 3
    ) -> ShadowStyle {
        ShadowStyle(
            color: brandColor.opacity(opacity),
            radius: radius,
            x: x,
            y: y
        )
    }
    
    /// Adjust shadow for dark mode
    public static func adaptive(_ style: ShadowStyle, for colorScheme: ColorScheme) -> ShadowStyle {
        switch colorScheme {
        case .dark:
            return ShadowStyle(
                color: style.color.opacity(0.6),
                radius: style.radius * 1.2,
                x: style.x,
                y: style.y
            )
        case .light:
            return style
        @unknown default:
            return style
        }
    }
}

// MARK: - Legacy Shadow Support

/// Legacy shadow support for backward compatibility
extension DSShadows {
    
    /// Legacy shadow values for smooth migration
    public struct Legacy {
        /// Standard card shadow (from existing StatCard, AccountCard)
        public static let cardShadow = ShadowStyle(
            color: Color.black.opacity(0.08),
            radius: 1,
            x: 0,
            y: 0
        )
        
        /// Modal shadow (from existing TransactionDetailView, CategoryPickerPopup)
        public static let modalShadow = ShadowStyle(
            color: Color.black.opacity(0.3),
            radius: 20,
            x: 0,
            y: 8
        )
        
        /// Toast shadow (from existing AutoCategoryToast)
        public static let toastShadow = ShadowStyle(
            color: Color.black.opacity(0.1),
            radius: 10,
            x: 0,
            y: 5
        )
        
        /// Chart shadow (from existing InsightsChartComponents)
        public static let chartShadow = ShadowStyle(
            color: Color.black.opacity(0.05),
            radius: 8,
            x: 0,
            y: 2
        )
        
        /// Filter shadow (from existing patterns)
        public static let filterShadow = ShadowStyle(
            color: Color.black.opacity(0.15),
            radius: 5,
            x: 0,
            y: 3
        )
    }
}

// MARK: - macOS Shadow Optimizations

#if os(macOS)
extension DSShadows {
    
    /// macOS-specific shadow optimizations
    public struct macOS {
        /// Standard macOS window shadow
        public static let window = ShadowStyle(
            color: Color.black.opacity(0.3),
            radius: 20,
            x: 0,
            y: 8
        )
        
        /// macOS popover shadow
        public static let popover = ShadowStyle(
            color: Color.black.opacity(0.15),
            radius: 10,
            x: 0,
            y: 5
        )
        
        /// macOS menu shadow
        public static let menu = ShadowStyle(
            color: Color.black.opacity(0.2),
            radius: 8,
            x: 0,
            y: 4
        )
        
        /// macOS sidebar shadow
        public static let sidebar = ShadowStyle(
            color: Color.black.opacity(0.1),
            radius: 1,
            x: 1,
            y: 0
        )
    }
}
#endif
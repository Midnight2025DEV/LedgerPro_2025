import SwiftUI

/// LedgerPro Design System - Spacing
///
/// A systematic approach to spacing that ensures consistent visual rhythm
/// and hierarchy throughout the financial application interface.
public struct DSSpacing {
    
    // MARK: - Base Spacing Units
    
    /// Base unit (4pt) - Foundation for all spacing calculations
    public static let base: CGFloat = 4
    
    // MARK: - Core Spacing Scale
    
    /// Extra small spacing: 4pt
    /// Usage: Icon-to-text gaps, tight component spacing
    public static let xs: CGFloat = 4
    
    /// Small spacing: 8pt
    /// Usage: Element spacing within components, list item internal padding
    public static let sm: CGFloat = 8
    
    /// Medium spacing: 12pt
    /// Usage: Component internal padding, card content spacing
    public static let md: CGFloat = 12
    
    /// Large spacing: 16pt
    /// Usage: Section spacing, form field gaps, component margins
    public static let lg: CGFloat = 16
    
    /// Extra large spacing: 20pt
    /// Usage: View padding, major section separation
    public static let xl: CGFloat = 20
    
    /// Extra extra large spacing: 24pt
    /// Usage: Page margins, major layout separation
    public static let xxl: CGFloat = 24
    
    /// Huge spacing: 32pt
    /// Usage: Page header spacing, major content blocks
    public static let huge: CGFloat = 32
    
    /// Massive spacing: 40pt
    /// Usage: Hero sections, major page divisions
    public static let massive: CGFloat = 40
    
    // MARK: - Component-Specific Spacing
    
    /// Component spacing patterns extracted from existing code
    public static let component = ComponentSpacing()
    
    public struct ComponentSpacing {
        /// Card internal padding (from StatCard pattern)
        public let cardPadding: CGFloat = 16
        
        /// Toast notification padding (from AutoCategoryToast)
        public let toastPadding: CGFloat = 16
        
        /// List row vertical padding
        public let listRowVertical: CGFloat = 20
        
        /// List row horizontal padding
        public let listRowHorizontal: CGFloat = 32
        
        /// Form field spacing
        public let formFieldGap: CGFloat = 12
        
        /// Button internal padding horizontal
        public let buttonPaddingH: CGFloat = 16
        
        /// Button internal padding vertical
        public let buttonPaddingV: CGFloat = 8
        
        /// Icon spacing from text
        public let iconToText: CGFloat = 8
        
        /// Section header spacing
        public let sectionHeader: CGFloat = 16
        
        /// Modal/popup margins
        public let modalMargin: CGFloat = 20
        
        /// Sidebar width (from existing patterns)
        public let sidebarWidth: CGFloat = 300
        
        /// Detail view width (from TransactionDetailView)
        public let detailViewWidth: CGFloat = 520
    }
    
    // MARK: - Layout Spacing
    
    /// Layout-specific spacing for major interface elements
    public static let layout = LayoutSpacing()
    
    public struct LayoutSpacing {
        /// Navigation bar height
        public let navigationHeight: CGFloat = 44
        
        /// Toolbar height
        public let toolbarHeight: CGFloat = 36
        
        /// Status bar equivalent spacing
        public let statusBarHeight: CGFloat = 24
        
        /// Footer height
        public let footerHeight: CGFloat = 60
        
        /// Minimum touch target size (Apple HIG)
        public let minTouchTarget: CGFloat = 44
        
        /// Recommended touch target size
        public let touchTarget: CGFloat = 48
        
        /// Safe area top padding
        public let safeAreaTop: CGFloat = 20
        
        /// Safe area bottom padding
        public let safeAreaBottom: CGFloat = 20
        
        /// Window minimum width
        public let windowMinWidth: CGFloat = 800
        
        /// Window minimum height
        public let windowMinHeight: CGFloat = 600
    }
    
    // MARK: - Corner Radius Scale
    
    /// Corner radius values for consistent rounded corners
    public static let radius = RadiusScale()
    
    public struct RadiusScale {
        /// Extra small radius: 2pt
        /// Usage: Small badges, minimal rounding
        public let xs: CGFloat = 2
        
        /// Small radius: 4pt
        /// Usage: Buttons, small components
        public let sm: CGFloat = 4
        
        /// Medium radius: 6pt
        /// Usage: Form fields, interactive elements
        public let md: CGFloat = 6
        
        /// Large radius: 8pt
        /// Usage: Category badges, secondary cards
        public let lg: CGFloat = 8
        
        /// Extra large radius: 10pt
        /// Usage: Icon backgrounds, compact cards
        public let xl: CGFloat = 10
        
        /// Standard radius: 12pt (primary card radius from existing patterns)
        /// Usage: Main cards, modals, primary containers
        public let standard: CGFloat = 12
        
        /// Large container radius: 16pt
        /// Usage: Large cards, main content areas
        public let container: CGFloat = 16
        
        /// Extra large container radius: 20pt
        /// Usage: Modal dialogs, major containers
        public let xlContainer: CGFloat = 20
        
        /// Circular radius (50%)
        /// Usage: Avatars, circular buttons
        public let circular: CGFloat = 999
    }
    
    // MARK: - Grid System
    
    /// Grid system for layout consistency
    public static let grid = GridSystem()
    
    public struct GridSystem {
        /// Column count for main grid
        public let columns: Int = 12
        
        /// Gutter spacing between grid columns
        public let gutter: CGFloat = 16
        
        /// Container max width
        public let containerMaxWidth: CGFloat = 1200
        
        /// Column width calculation helper
        public func columnWidth(for columns: Int, totalWidth: CGFloat) -> CGFloat {
            let totalGutters = CGFloat(self.columns - 1) * gutter
            let availableWidth = totalWidth - totalGutters
            let singleColumnWidth = availableWidth / CGFloat(self.columns)
            let requestedGutters = CGFloat(columns - 1) * gutter
            return (singleColumnWidth * CGFloat(columns)) + requestedGutters
        }
    }
    
    // MARK: - Border Widths
    
    /// Border width scale for consistent borders
    public static let border = BorderScale()
    
    public struct BorderScale {
        /// Hairline border: 0.5pt
        /// Usage: Subtle dividers, light separations
        public let hairline: CGFloat = 0.5
        
        /// Thin border: 1pt
        /// Usage: Standard borders, form fields
        public let thin: CGFloat = 1
        
        /// Medium border: 2pt
        /// Usage: Focus states, emphasis borders
        public let medium: CGFloat = 2
        
        /// Thick border: 3pt
        /// Usage: Strong emphasis, error states
        public let thick: CGFloat = 3
        
        /// Extra thick border: 4pt
        /// Usage: Primary action focus, strong selection
        public let extraThick: CGFloat = 4
    }
    
    // MARK: - Icon Sizes
    
    /// Standard icon sizes for consistency
    public static let icon = IconSizes()
    
    public struct IconSizes {
        /// Extra small icon: 12pt
        public let xs: CGFloat = 12
        
        /// Small icon: 16pt
        public let sm: CGFloat = 16
        
        /// Medium icon: 20pt
        public let md: CGFloat = 20
        
        /// Large icon: 24pt
        public let lg: CGFloat = 24
        
        /// Extra large icon: 32pt
        public let xl: CGFloat = 32
        
        /// Huge icon: 40pt
        public let huge: CGFloat = 40
        
        /// Category icon size (from existing patterns): 44pt
        public let category: CGFloat = 44
        
        /// Large category icon: 48pt
        public let categoryLarge: CGFloat = 48
    }
}

// MARK: - SwiftUI Extensions for Easy Spacing Application

extension View {
    
    // MARK: - Padding Extensions
    
    /// Apply extra small padding (4pt)
    public func paddingXS() -> some View {
        self.padding(DSSpacing.xs)
    }
    
    /// Apply small padding (8pt)
    public func paddingSM() -> some View {
        self.padding(DSSpacing.sm)
    }
    
    /// Apply medium padding (12pt)
    public func paddingMD() -> some View {
        self.padding(DSSpacing.md)
    }
    
    /// Apply large padding (16pt)
    public func paddingLG() -> some View {
        self.padding(DSSpacing.lg)
    }
    
    /// Apply extra large padding (20pt)
    public func paddingXL() -> some View {
        self.padding(DSSpacing.xl)
    }
    
    /// Apply extra extra large padding (24pt)
    public func paddingXXL() -> some View {
        self.padding(DSSpacing.xxl)
    }
    
    // MARK: - Specific Padding Extensions
    
    /// Apply horizontal large padding and vertical medium padding (common pattern)
    public func paddingHLVS() -> some View {
        self.padding(.horizontal, DSSpacing.lg)
            .padding(.vertical, DSSpacing.sm)
    }
    
    /// Apply card-style padding (from StatCard pattern)
    public func paddingCard() -> some View {
        self.padding(DSSpacing.component.cardPadding)
    }
    
    /// Apply list row padding (from existing patterns)
    public func paddingListRow() -> some View {
        self
            .padding(.horizontal, DSSpacing.component.listRowHorizontal)
            .padding(.vertical, DSSpacing.component.listRowVertical)
    }
    
    /// Apply modal padding (consistent modal spacing)
    public func paddingModal() -> some View {
        self.padding(DSSpacing.component.modalMargin)
    }
    
    // MARK: - Corner Radius Extensions
    
    /// Apply small corner radius (4pt)
    public func cornerRadiusSM() -> some View {
        self.cornerRadius(DSSpacing.radius.sm)
    }
    
    /// Apply medium corner radius (8pt)
    public func cornerRadiusLG() -> some View {
        self.cornerRadius(DSSpacing.radius.lg)
    }
    
    /// Apply standard corner radius (12pt - primary card style)
    public func cornerRadiusStandard() -> some View {
        self.cornerRadius(DSSpacing.radius.standard)
    }
    
    /// Apply container corner radius (16pt)
    public func cornerRadiusContainer() -> some View {
        self.cornerRadius(DSSpacing.radius.container)
    }
    
    // MARK: - Frame Extensions
    
    /// Apply minimum touch target size
    public func minTouchTarget() -> some View {
        self.frame(minWidth: DSSpacing.layout.minTouchTarget, 
                  minHeight: DSSpacing.layout.minTouchTarget)
    }
    
    /// Apply recommended touch target size
    public func touchTarget() -> some View {
        self.frame(width: DSSpacing.layout.touchTarget, 
                  height: DSSpacing.layout.touchTarget)
    }
    
    /// Apply category icon size frame (44pt)
    public func categoryIconFrame() -> some View {
        self.frame(width: DSSpacing.icon.category, 
                  height: DSSpacing.icon.category)
    }
    
    // MARK: - Spacing Extensions
    
    /// Add small vertical spacing (8pt)
    public func spacingSM() -> some View {
        VStack(spacing: DSSpacing.sm) {
            self
        }
    }
    
    /// Add medium vertical spacing (12pt)
    public func spacingMD() -> some View {
        VStack(spacing: DSSpacing.md) {
            self
        }
    }
    
    /// Add large vertical spacing (16pt)
    public func spacingLG() -> some View {
        VStack(spacing: DSSpacing.lg) {
            self
        }
    }
}

// MARK: - HStack and VStack Extensions

// Note: HStack and VStack extensions with custom spacing removed to avoid conflicts
// Use spacing.value directly when creating stacks with design system spacing

// MARK: - Spacing Value Enum

/// Design system spacing values for type-safe spacing
public enum DSSpacingValue {
    case xs, sm, md, lg, xl, xxl, huge, massive
    case custom(CGFloat)
    
    public var value: CGFloat {
        switch self {
        case .xs: return DSSpacing.xs
        case .sm: return DSSpacing.sm
        case .md: return DSSpacing.md
        case .lg: return DSSpacing.lg
        case .xl: return DSSpacing.xl
        case .xxl: return DSSpacing.xxl
        case .huge: return DSSpacing.huge
        case .massive: return DSSpacing.massive
        case .custom(let value): return value
        }
    }
}

// MARK: - Legacy Spacing Compatibility

/// Legacy spacing support for backward compatibility with existing code
extension DSSpacing {
    
    /// Legacy padding values for smooth migration
    public struct Legacy {
        /// Standard list row vertical padding (from existing TransactionRowView)
        public static let listRowVertical: CGFloat = 20
        
        /// Standard list row horizontal padding (from existing TransactionRowView)  
        public static let listRowHorizontal: CGFloat = 32
        
        /// Standard card padding (from existing StatCard)
        public static let cardPadding: CGFloat = 16
        
        /// Standard section spacing (from existing patterns)
        public static let sectionSpacing: CGFloat = 16
        
        /// Standard modal margins (from existing TransactionDetailView)
        public static let modalMargin: CGFloat = 20
        
        /// Standard corner radius (from existing StatCard and AutoCategoryToast)
        public static let cornerRadius: CGFloat = 12
        
        /// Icon spacing from text (common pattern)
        public static let iconSpacing: CGFloat = 8
    }
}

// MARK: - macOS Spacing Optimizations

#if os(macOS)
extension DSSpacing {
    
    /// macOS-specific spacing adjustments for platform conventions
    public struct macOS {
        /// Reduced padding for denser macOS layouts
        public static let densePadding: CGFloat = 8
        
        /// macOS standard button padding
        public static let buttonPadding: CGFloat = 12
        
        /// macOS control spacing
        public static let controlSpacing: CGFloat = 8
        
        /// macOS table row height
        public static let tableRowHeight: CGFloat = 24
        
        /// macOS sidebar spacing
        public static let sidebarSpacing: CGFloat = 4
    }
}
#endif
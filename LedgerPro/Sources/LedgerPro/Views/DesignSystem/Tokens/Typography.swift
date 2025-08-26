import SwiftUI

/// LedgerPro Design System - Typography
///
/// A sophisticated typography system optimized for financial applications.
/// Uses SF Pro for UI elements and SF Mono for tabular numbers and data.
public struct DSTypography {
    
    // MARK: - Font Families
    
    /// System font family for UI elements
    public static let systemFont = "SF Pro"
    
    /// Monospace font family for numbers and data
    public static let monoFont = "SF Mono"
    
    // MARK: - Display Typography (Large Numbers & Headlines)
    
    /// Display typography for large financial numbers and hero content
    public static let display = Display()
    
    public struct Display {
        /// Display 1: 48pt bold - Hero numbers, main dashboard totals
        public let display1 = Font.system(size: 48, weight: .bold, design: .default)
        
        /// Display 2: 40pt bold - Section totals, key metrics
        public let display2 = Font.system(size: 40, weight: .bold, design: .default)
        
        /// Display 3: 34pt bold - Card headers, important figures
        public let display3 = Font.system(size: 34, weight: .bold, design: .default)
        
        /// Tabular Display 1: 48pt monospace - Large financial amounts
        public let tabularDisplay1 = Font.system(size: 48, weight: .bold, design: .monospaced)
        
        /// Tabular Display 2: 40pt monospace - Section financial amounts
        public let tabularDisplay2 = Font.system(size: 40, weight: .bold, design: .monospaced)
        
        /// Tabular Display 3: 34pt monospace - Card financial amounts
        public let tabularDisplay3 = Font.system(size: 34, weight: .bold, design: .monospaced)
    }
    
    // MARK: - Title Typography
    
    /// Title typography for headings and section headers
    public static let title = Title()
    
    public struct Title {
        /// Title 1: 34pt bold - Main page titles
        public let title1 = Font.system(size: 34, weight: .bold, design: .default)
        
        /// Title 2: 28pt semibold - Section headers (existing pattern)
        public let title2 = Font.system(size: 28, weight: .semibold, design: .default)
        
        /// Title 3: 22pt medium - Subsection headers
        public let title3 = Font.system(size: 22, weight: .medium, design: .default)
        
        /// Title 4: 18pt semibold - Component headers
        public let title4 = Font.system(size: 18, weight: .semibold, design: .default)
        
        /// Large Title: 42pt bold - Navigation titles (macOS style)
        public let largeTitle = Font.system(size: 42, weight: .bold, design: .default)
    }
    
    // MARK: - Body Typography
    
    /// Body typography for content and interface elements
    public static let body = Body()
    
    public struct Body {
        /// Body Large: 19pt regular - Primary body text
        public let large = Font.system(size: 19, weight: .regular, design: .default)
        
        /// Body: 17pt regular - Standard body text (iOS standard)
        public let regular = Font.system(size: 17, weight: .regular, design: .default)
        
        /// Body Medium: 17pt medium - Emphasized body text
        public let medium = Font.system(size: 17, weight: .medium, design: .default)
        
        /// Body Semibold: 17pt semibold - Strong body text
        public let semibold = Font.system(size: 17, weight: .semibold, design: .default)
        
        /// Body Small: 15pt regular - Secondary body text
        public let small = Font.system(size: 15, weight: .regular, design: .default)
    }
    
    // MARK: - Label Typography
    
    /// Label typography for form elements and small interface text
    public static let label = Label()
    
    public struct Label {
        /// Label Large: 15pt medium - Primary labels
        public let large = Font.system(size: 15, weight: .medium, design: .default)
        
        /// Label: 13pt medium - Standard labels
        public let regular = Font.system(size: 13, weight: .medium, design: .default)
        
        /// Label Small: 11pt medium - Small labels
        public let small = Font.system(size: 11, weight: .medium, design: .default)
    }
    
    // MARK: - Caption Typography
    
    /// Caption typography for metadata and helper text
    public static let caption = Caption()
    
    public struct Caption {
        /// Caption Large: 15pt regular - Large captions
        public let large = Font.system(size: 15, weight: .regular, design: .default)
        
        /// Caption: 13pt regular - Standard captions (existing pattern)
        public let regular = Font.system(size: 13, weight: .regular, design: .default)
        
        /// Caption Small: 11pt regular - Small captions
        public let small = Font.system(size: 11, weight: .regular, design: .default)
        
        /// Caption Tiny: 9pt regular - Tiny helper text
        public let tiny = Font.system(size: 9, weight: .regular, design: .default)
    }
    
    // MARK: - Financial Typography (Monospace for Alignment)
    
    /// Specialized typography for financial data with tabular figures
    public static let financial = Financial()
    
    public struct Financial {
        /// Currency Large: 28pt monospace bold - Large amounts
        public let currencyLarge = Font.system(size: 28, weight: .bold, design: .monospaced)
        
        /// Currency: 17pt monospace semibold - Standard amounts
        public let currency = Font.system(size: 17, weight: .semibold, design: .monospaced)
        
        /// Currency Small: 15pt monospace medium - Small amounts
        public let currencySmall = Font.system(size: 15, weight: .medium, design: .monospaced)
        
        /// Currency Caption: 13pt monospace regular - Caption amounts
        public let currencyCaption = Font.system(size: 13, weight: .regular, design: .monospaced)
        
        /// Percentage: 17pt monospace medium - Percentage changes
        public let percentage = Font.system(size: 17, weight: .medium, design: .monospaced)
        
        /// Percentage Small: 13pt monospace regular - Small percentages
        public let percentageSmall = Font.system(size: 13, weight: .regular, design: .monospaced)
        
        /// Numbers: 17pt monospace regular - Pure numbers
        public let numbers = Font.system(size: 17, weight: .regular, design: .monospaced)
        
        /// Numbers Small: 13pt monospace regular - Small numbers
        public let numbersSmall = Font.system(size: 13, weight: .regular, design: .monospaced)
    }
    
    // MARK: - Code Typography
    
    /// Code typography for technical content and debugging
    public static let code = Code()
    
    public struct Code {
        /// Code: 14pt monospace regular - Standard code
        public let regular = Font.system(size: 14, weight: .regular, design: .monospaced)
        
        /// Code Small: 12pt monospace regular - Small code
        public let small = Font.system(size: 12, weight: .regular, design: .monospaced)
        
        /// Code Inline: 15pt monospace medium - Inline code
        public let inline = Font.system(size: 15, weight: .medium, design: .monospaced)
    }
}

// MARK: - Typography Styles with Color

/// Typography styles that combine font and color for common use cases
public struct DSTypographyStyles {
    
    // MARK: - Text Styles
    
    /// Primary heading style
    public static func primaryHeading() -> some View {
        EmptyView().modifier(TypographyStyleModifier(
            font: DSTypography.title.title2,
            color: DSColors.neutral.text
        ))
    }
    
    /// Secondary heading style
    public static func secondaryHeading() -> some View {
        EmptyView().modifier(TypographyStyleModifier(
            font: DSTypography.title.title3,
            color: DSColors.neutral.textSecondary
        ))
    }
    
    /// Body text style
    public static func bodyText() -> some View {
        EmptyView().modifier(TypographyStyleModifier(
            font: DSTypography.body.regular,
            color: DSColors.neutral.text
        ))
    }
    
    /// Secondary body text style
    public static func secondaryBodyText() -> some View {
        EmptyView().modifier(TypographyStyleModifier(
            font: DSTypography.body.regular,
            color: DSColors.neutral.textSecondary
        ))
    }
    
    /// Caption style
    public static func caption() -> some View {
        EmptyView().modifier(TypographyStyleModifier(
            font: DSTypography.caption.regular,
            color: DSColors.neutral.textTertiary
        ))
    }
    
    // MARK: - Financial Text Styles
    
    /// Positive financial amount style (gains/income)
    public static func positiveAmount() -> some View {
        EmptyView().modifier(TypographyStyleModifier(
            font: DSTypography.financial.currency,
            color: DSColors.success.main
        ))
    }
    
    /// Negative financial amount style (losses/expenses)
    public static func negativeAmount() -> some View {
        EmptyView().modifier(TypographyStyleModifier(
            font: DSTypography.financial.currency,
            color: DSColors.error.main
        ))
    }
    
    /// Neutral financial amount style
    public static func neutralAmount() -> some View {
        EmptyView().modifier(TypographyStyleModifier(
            font: DSTypography.financial.currency,
            color: DSColors.neutral.text
        ))
    }
    
    /// Large hero amount style
    public static func heroAmount() -> some View {
        EmptyView().modifier(TypographyStyleModifier(
            font: DSTypography.display.tabularDisplay1,
            color: DSColors.neutral.text
        ))
    }
    
    /// Percentage change style (adapts color based on value)
    public static func percentageChange(value: Double) -> some View {
        EmptyView().modifier(TypographyStyleModifier(
            font: DSTypography.financial.percentage,
            color: value >= 0 ? DSColors.success.main : DSColors.error.main
        ))
    }
}

// MARK: - Typography Style Modifier

private struct TypographyStyleModifier: ViewModifier {
    let font: Font
    let color: Color
    
    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundColor(color)
    }
}

// MARK: - View Extensions for Easy Typography Application

extension View {
    
    // MARK: - Title Styles
    
    /// Apply display 1 typography (48pt bold)
    public func display1() -> some View {
        self.font(DSTypography.display.display1)
    }
    
    /// Apply display 2 typography (40pt bold)
    public func display2() -> some View {
        self.font(DSTypography.display.display2)
    }
    
    /// Apply display 3 typography (34pt bold)
    public func display3() -> some View {
        self.font(DSTypography.display.display3)
    }
    
    /// Apply title 1 typography (34pt bold)
    public func title1() -> some View {
        self.font(DSTypography.title.title1)
    }
    
    /// Apply title 2 typography (28pt semibold) - existing pattern
    public func title2() -> some View {
        self.font(DSTypography.title.title2)
    }
    
    /// Apply title 3 typography (22pt medium)
    public func title3() -> some View {
        self.font(DSTypography.title.title3)
    }
    
    // MARK: - Body Styles
    
    /// Apply body typography (17pt regular) - existing pattern
    public func bodyRegular() -> some View {
        self.font(DSTypography.body.regular)
    }
    
    /// Apply body medium typography (17pt medium)
    public func bodyMedium() -> some View {
        self.font(DSTypography.body.medium)
    }
    
    /// Apply body semibold typography (17pt semibold)
    public func bodySemibold() -> some View {
        self.font(DSTypography.body.semibold)
    }
    
    // MARK: - Caption Styles
    
    /// Apply caption typography (13pt regular) - existing pattern
    public func captionRegular() -> some View {
        self.font(DSTypography.caption.regular)
    }
    
    /// Apply small caption typography (11pt regular)
    public func captionSmall() -> some View {
        self.font(DSTypography.caption.small)
    }
    
    // MARK: - Financial Styles
    
    /// Apply currency typography (17pt monospace semibold)
    public func currency() -> some View {
        self.font(DSTypography.financial.currency)
    }
    
    /// Apply large currency typography (28pt monospace bold)
    public func currencyLarge() -> some View {
        self.font(DSTypography.financial.currencyLarge)
    }
    
    /// Apply percentage typography (17pt monospace medium)
    public func percentage() -> some View {
        self.font(DSTypography.financial.percentage)
    }
    
    /// Apply tabular numbers (maintains existing spacing)
    public func tabularNumbers() -> some View {
        self.font(DSTypography.financial.numbers)
    }
    
    // MARK: - Combined Styles
    
    /// Apply positive financial styling (green color + monospace)
    public func positiveFinancial() -> some View {
        self
            .font(DSTypography.financial.currency)
            .foregroundColor(DSColors.success.main)
    }
    
    /// Apply negative financial styling (red color + monospace)
    public func negativeFinancial() -> some View {
        self
            .font(DSTypography.financial.currency)
            .foregroundColor(DSColors.error.main)
    }
    
    /// Apply neutral financial styling (default color + monospace)
    public func neutralFinancial() -> some View {
        self
            .font(DSTypography.financial.currency)
            .foregroundColor(DSColors.neutral.text)
    }
    
    /// Apply primary text styling
    public func primaryText() -> some View {
        self
            .font(DSTypography.body.regular)
            .foregroundColor(DSColors.neutral.text)
    }
    
    /// Apply secondary text styling
    public func secondaryText() -> some View {
        self
            .font(DSTypography.body.regular)
            .foregroundColor(DSColors.neutral.textSecondary)
    }
    
    /// Apply tertiary text styling
    public func tertiaryText() -> some View {
        self
            .font(DSTypography.caption.regular)
            .foregroundColor(DSColors.neutral.textTertiary)
    }
}

// MARK: - Legacy Font Compatibility

/// Legacy font support for backward compatibility with existing code
extension DSTypography {
    
    /// Legacy large title (equivalent to title1)
    public static let largeTitle = title.largeTitle
    
    /// Legacy title (equivalent to title2) - maintains existing pattern
    public static let titleFont = title.title2
    
    /// Legacy headline (equivalent to title3)
    public static let headline = title.title3
    
    /// Legacy body (maintains existing 17pt standard)
    public static let bodyFont = body.regular
    
    /// Legacy caption (maintains existing 13pt standard)
    public static let captionFont = caption.regular
    
    /// Legacy subheadline (equivalent to body small)
    public static let subheadline = body.small
}

// MARK: - macOS Typography Optimizations

#if os(macOS)
extension DSTypography {
    
    /// macOS-optimized typography adjustments
    public struct macOS {
        /// Slightly smaller body text for macOS density
        public static let body = Font.system(size: 15, weight: .regular, design: .default)
        
        /// macOS-style caption
        public static let caption = Font.system(size: 11, weight: .regular, design: .default)
        
        /// macOS-style control labels
        public static let controlLabel = Font.system(size: 13, weight: .medium, design: .default)
    }
}
#endif
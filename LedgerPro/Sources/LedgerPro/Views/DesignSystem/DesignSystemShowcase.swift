import SwiftUI

/// LedgerPro Design System Showcase
///
/// A comprehensive preview of all design system tokens and components.
/// This view serves as both documentation and testing for the design system.
struct DesignSystemShowcase: View {
    @State private var selectedTab: ShowcaseTab = .colors
    @State private var isAnimationEnabled = true
    
    enum ShowcaseTab: String, CaseIterable {
        case colors = "Colors"
        case typography = "Typography"
        case spacing = "Spacing"
        case shadows = "Shadows"
        case animations = "Animations"
        case components = "Components"
        
        var icon: String {
            switch self {
            case .colors: return "paintpalette.fill"
            case .typography: return "textformat"
            case .spacing: return "square.grid.3x3"
            case .shadows: return "cube.transparent"
            case .animations: return "waveform.path"
            case .components: return "app.fill"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar Navigation
            ShowcaseSidebar(selectedTab: $selectedTab)
        } detail: {
            // Main Content Area
            ScrollView {
                VStack(alignment: .leading, spacing: DSSpacing.xl) {
                    // Header
                    ShowcaseHeader(selectedTab: selectedTab)
                    
                    // Content based on selected tab
                    Group {
                        switch selectedTab {
                        case .colors:
                            ColorsShowcase()
                        case .typography:
                            TypographyShowcase()
                        case .spacing:
                            SpacingShowcase()
                        case .shadows:
                            ShadowsShowcase()
                        case .animations:
                            AnimationsShowcase(isEnabled: $isAnimationEnabled)
                        case .components:
                            ComponentsShowcase()
                        }
                    }
                    .animation(DSAnimations.common.standardTransition, value: selectedTab)
                }
                .padding(DSSpacing.xl)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DSColors.neutral.backgroundSecondary)
        }
        .navigationTitle("Design System Showcase")
    }
}

// MARK: - Sidebar Navigation

struct ShowcaseSidebar: View {
    @Binding var selectedTab: DesignSystemShowcase.ShowcaseTab
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            Text("Design System")
                .font(DSTypography.title.title2)
                .foregroundColor(DSColors.neutral.text)
                .padding(.bottom, DSSpacing.lg)
            
            ForEach(DesignSystemShowcase.ShowcaseTab.allCases, id: \.self) { tab in
                ShowcaseTabRow(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    onSelect: { selectedTab = tab }
                )
            }
            
            Spacer()
            
            // Design System Info
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("LedgerPro")
                    .font(DSTypography.body.semibold)
                    .foregroundColor(DSColors.neutral.text)
                
                Text("Financial Design System")
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                
                Text("v1.0")
                    .font(DSTypography.caption.small)
                    .foregroundColor(DSColors.neutral.textTertiary)
            }
            .paddingCard()
            .background(DSColors.neutral.backgroundCard)
            .cornerRadiusStandard()
        }
        .padding(DSSpacing.lg)
        .frame(width: 250)
    }
}

struct ShowcaseTabRow: View {
    let tab: DesignSystemShowcase.ShowcaseTab
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: DSSpacing.md) {
                Image(systemName: tab.icon)
                    .font(DSTypography.body.medium)
                    .foregroundColor(isSelected ? .white : DSColors.primary.main)
                    .frame(width: DSSpacing.icon.md)
                
                Text(tab.rawValue)
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

// MARK: - Showcase Header

struct ShowcaseHeader: View {
    let selectedTab: DesignSystemShowcase.ShowcaseTab
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            HStack {
                Image(systemName: selectedTab.icon)
                    .font(DSTypography.display.display3)
                    .foregroundColor(DSColors.primary.main)
                
                Text(selectedTab.rawValue)
                    .font(DSTypography.display.display3)
                    .foregroundColor(DSColors.neutral.text)
                
                Spacer()
            }
            
            Text(descriptionForTab(selectedTab))
                .font(DSTypography.body.regular)
                .foregroundColor(DSColors.neutral.textSecondary)
        }
        .paddingCard()
        .background(DSColors.neutral.backgroundCard)
        .cornerRadiusStandard()
        .shadowCard()
    }
    
    private func descriptionForTab(_ tab: DesignSystemShowcase.ShowcaseTab) -> String {
        switch tab {
        case .colors:
            return "Financial color palette optimized for trust, clarity, and accessibility"
        case .typography:
            return "SF Pro and SF Mono typography scales for financial applications"
        case .spacing:
            return "Consistent spacing system ensuring visual rhythm and hierarchy"
        case .shadows:
            return "Elevation and depth system creating visual hierarchy and focus"
        case .animations:
            return "Smooth animations enhancing user experience and feedback"
        case .components:
            return "Reusable components built with design system foundations"
        }
    }
}

// MARK: - Colors Showcase

struct ColorsShowcase: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            // Primary Colors
            ColorPaletteSection(
                title: "Primary Brand Colors",
                subtitle: "Electric blue conveying trust and technology",
                colors: [
                    ("p50", DSColors.primary.p50),
                    ("p100", DSColors.primary.p100),
                    ("p200", DSColors.primary.p200),
                    ("p300", DSColors.primary.p300),
                    ("p400", DSColors.primary.p400),
                    ("p500", DSColors.primary.p500),
                    ("p600", DSColors.primary.p600),
                    ("p700", DSColors.primary.p700),
                    ("p800", DSColors.primary.p800),
                    ("p900", DSColors.primary.p900)
                ]
            )
            
            // Success Colors
            ColorPaletteSection(
                title: "Success Colors",
                subtitle: "Emerald green for profits and positive outcomes",
                colors: [
                    ("s50", DSColors.success.s50),
                    ("s100", DSColors.success.s100),
                    ("s200", DSColors.success.s200),
                    ("s300", DSColors.success.s300),
                    ("s400", DSColors.success.s400),
                    ("s500", DSColors.success.s500),
                    ("s600", DSColors.success.s600),
                    ("s700", DSColors.success.s700),
                    ("s800", DSColors.success.s800),
                    ("s900", DSColors.success.s900)
                ]
            )
            
            // Error Colors
            ColorPaletteSection(
                title: "Error Colors",
                subtitle: "Red for losses and negative outcomes",
                colors: [
                    ("e50", DSColors.error.e50),
                    ("e100", DSColors.error.e100),
                    ("e200", DSColors.error.e200),
                    ("e300", DSColors.error.e300),
                    ("e400", DSColors.error.e400),
                    ("e500", DSColors.error.e500),
                    ("e600", DSColors.error.e600),
                    ("e700", DSColors.error.e700),
                    ("e800", DSColors.error.e800),
                    ("e900", DSColors.error.e900)
                ]
            )
            
            // Category Colors
            CategoryColorsSection()
        }
    }
}

struct ColorPaletteSection: View {
    let title: String
    let subtitle: String
    let colors: [(String, Color)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(title)
                    .primaryHeadingStyle()
                
                Text(subtitle)
                    .captionTextStyle()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DSSpacing.sm), count: 5), spacing: DSSpacing.sm) {
                ForEach(colors, id: \.0) { name, color in
                    ColorSwatch(name: name, color: color)
                }
            }
        }
        .enhancedCardStyle()
    }
}

struct CategoryColorsSection: View {
    let categories = [
        ("Food & Dining", DSColors.category.foodDining),
        ("Transportation", DSColors.category.transportation),
        ("Shopping", DSColors.category.shopping),
        ("Entertainment", DSColors.category.entertainment),
        ("Bills & Utilities", DSColors.category.billsUtilities),
        ("Healthcare", DSColors.category.healthcare),
        ("Travel", DSColors.category.travel),
        ("Groceries", DSColors.category.groceries),
        ("Income", DSColors.category.income),
        ("Subscription", DSColors.category.subscription)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Category Colors")
                    .primaryHeadingStyle()
                
                Text("Distinct colors for financial transaction categories")
                    .captionTextStyle()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DSSpacing.md), count: 3), spacing: DSSpacing.md) {
                ForEach(categories, id: \.0) { name, color in
                    CategoryColorSwatch(name: name, color: color)
                }
            }
        }
        .enhancedCardStyle()
    }
}

struct ColorSwatch: View {
    let name: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DSSpacing.xs) {
            Rectangle()
                .fill(color)
                .frame(height: 60)
                .cornerRadius(DSSpacing.radius.md)
                .shadowSubtle()
            
            Text(name)
                .font(DSTypography.caption.small)
                .foregroundColor(DSColors.neutral.textSecondary)
        }
    }
}

struct CategoryColorSwatch: View {
    let name: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DSSpacing.md) {
            Circle()
                .fill(color)
                .frame(width: 24, height: 24)
                .shadowSubtle()
            
            Text(name)
                .font(DSTypography.body.medium)
                .foregroundColor(DSColors.neutral.text)
            
            Spacer()
        }
        .padding(DSSpacing.md)
        .background(DSColors.neutral.backgroundCard)
        .cornerRadius(DSSpacing.radius.lg)
        .shadowSubtle()
    }
}

// MARK: - Typography Showcase

struct TypographyShowcase: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            // Display Typography
            TypographySection(
                title: "Display Typography",
                subtitle: "Large financial numbers and hero content",
                samples: [
                    ("Display 1", "48pt Bold", DSTypography.display.display1),
                    ("Display 2", "40pt Bold", DSTypography.display.display2),
                    ("Display 3", "34pt Bold", DSTypography.display.display3)
                ]
            )
            
            // Title Typography
            TypographySection(
                title: "Title Typography",
                subtitle: "Headings and section headers",
                samples: [
                    ("Title 1", "34pt Bold", DSTypography.title.title1),
                    ("Title 2", "28pt Semibold", DSTypography.title.title2),
                    ("Title 3", "22pt Medium", DSTypography.title.title3),
                    ("Title 4", "18pt Semibold", DSTypography.title.title4)
                ]
            )
            
            // Body Typography
            TypographySection(
                title: "Body Typography",
                subtitle: "Content and interface elements",
                samples: [
                    ("Body Large", "19pt Regular", DSTypography.body.large),
                    ("Body Regular", "17pt Regular", DSTypography.body.regular),
                    ("Body Medium", "17pt Medium", DSTypography.body.medium),
                    ("Body Semibold", "17pt Semibold", DSTypography.body.semibold)
                ]
            )
            
            // Financial Typography
            FinancialTypographySection()
        }
    }
}

struct TypographySection: View {
    let title: String
    let subtitle: String
    let samples: [(String, String, Font)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(title)
                    .primaryHeadingStyle()
                
                Text(subtitle)
                    .captionTextStyle()
            }
            
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                ForEach(samples, id: \.0) { name, description, font in
                    TypographySample(name: name, description: description, font: font)
                }
            }
        }
        .enhancedCardStyle()
    }
}

struct FinancialTypographySection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Financial Typography")
                    .primaryHeadingStyle()
                
                Text("Monospace fonts for tabular financial data")
                    .captionTextStyle()
            }
            
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                HStack {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Text("$12,345.67")
                            .font(DSTypography.financial.currencyLarge)
                            .foregroundColor(DSColors.success.main)
                        
                        Text("Large Currency")
                            .font(DSTypography.caption.small)
                            .foregroundColor(DSColors.neutral.textSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: DSSpacing.sm) {
                        Text("-$1,234.56")
                            .font(DSTypography.financial.currency)
                            .foregroundColor(DSColors.error.main)
                        
                        Text("Standard Currency")
                            .font(DSTypography.caption.small)
                            .foregroundColor(DSColors.neutral.textSecondary)
                    }
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Text("+5.2%")
                            .font(DSTypography.financial.percentage)
                            .foregroundColor(DSColors.success.main)
                        
                        Text("Percentage")
                            .font(DSTypography.caption.small)
                            .foregroundColor(DSColors.neutral.textSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: DSSpacing.sm) {
                        Text("1,234")
                            .font(DSTypography.financial.numbers)
                            .foregroundColor(DSColors.neutral.text)
                        
                        Text("Numbers")
                            .font(DSTypography.caption.small)
                            .foregroundColor(DSColors.neutral.textSecondary)
                    }
                }
            }
        }
        .enhancedCardStyle()
    }
}

struct TypographySample: View {
    let name: String
    let description: String
    let font: Font
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            Text("The quick brown fox jumps over the lazy dog")
                .font(font)
                .foregroundColor(DSColors.neutral.text)
            
            HStack {
                Text(name)
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                
                Text("•")
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textTertiary)
                
                Text(description)
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textTertiary)
                
                Spacer()
            }
        }
        .padding(DSSpacing.md)
        .background(DSColors.neutral.backgroundCard)
        .cornerRadius(DSSpacing.radius.lg)
        .shadowSubtle()
    }
}

// MARK: - Spacing Showcase

struct SpacingShowcase: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            // Base Spacing Scale
            SpacingScaleSection()
            
            // Component Spacing
            ComponentSpacingSection()
            
            // Layout Examples
            LayoutSpacingSection()
        }
    }
}

struct SpacingScaleSection: View {
    let spacingValues = [
        ("XS", DSSpacing.xs, "4pt"),
        ("SM", DSSpacing.sm, "8pt"),
        ("MD", DSSpacing.md, "12pt"),
        ("LG", DSSpacing.lg, "16pt"),
        ("XL", DSSpacing.xl, "20pt"),
        ("XXL", DSSpacing.xxl, "24pt"),
        ("Huge", DSSpacing.huge, "32pt"),
        ("Massive", DSSpacing.massive, "40pt")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Spacing Scale")
                    .primaryHeadingStyle()
                
                Text("Base spacing units for consistent rhythm")
                    .captionTextStyle()
            }
            
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                ForEach(spacingValues, id: \.0) { name, value, description in
                    SpacingExample(name: name, value: value, description: description)
                }
            }
        }
        .enhancedCardStyle()
    }
}

struct ComponentSpacingSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Component Spacing")
                    .primaryHeadingStyle()
                
                Text("Spacing patterns for specific components")
                    .captionTextStyle()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DSSpacing.md), count: 2), spacing: DSSpacing.md) {
                ComponentSpacingCard(
                    title: "Card Padding",
                    value: "\(Int(DSSpacing.component.cardPadding))pt",
                    usage: "Internal card spacing"
                )
                
                ComponentSpacingCard(
                    title: "List Row",
                    value: "\(Int(DSSpacing.component.listRowVertical))pt × \(Int(DSSpacing.component.listRowHorizontal))pt",
                    usage: "Transaction row padding"
                )
                
                ComponentSpacingCard(
                    title: "Button Padding",
                    value: "\(Int(DSSpacing.component.buttonPaddingH))pt × \(Int(DSSpacing.component.buttonPaddingV))pt",
                    usage: "Button internal spacing"
                )
                
                ComponentSpacingCard(
                    title: "Icon Spacing",
                    value: "\(Int(DSSpacing.component.iconToText))pt",
                    usage: "Icon to text gap"
                )
            }
        }
        .enhancedCardStyle()
    }
}

struct LayoutSpacingSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Layout Spacing")
                    .primaryHeadingStyle()
                
                Text("Examples of spacing in practice")
                    .captionTextStyle()
            }
            
            // Example layout with proper spacing
            VStack(spacing: DSSpacing.lg) {
                HStack(spacing: DSSpacing.md) {
                    Circle()
                        .fill(DSColors.primary.main)
                        .categoryIconFrame()
                    
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text("Transaction Example")
                            .bodyTextStyle()
                        
                        Text("With proper spacing")
                            .captionTextStyle()
                    }
                    
                    Spacer()
                    
                    Text("$123.45")
                        .font(DSTypography.financial.currency)
                        .foregroundColor(DSColors.success.main)
                }
                .paddingListRow()
                .background(DSColors.neutral.backgroundCard)
                .cornerRadiusStandard()
                .shadowCard()
                
                HStack(spacing: DSSpacing.sm) {
                    ForEach(0..<3) { _ in
                        Rectangle()
                            .fill(DSColors.primary.main.opacity(0.3))
                            .frame(height: 60)
                            .cornerRadius(DSSpacing.radius.md)
                    }
                }
            }
        }
        .enhancedCardStyle()
    }
}

struct SpacingExample: View {
    let name: String
    let value: CGFloat
    let description: String
    
    var body: some View {
        HStack(spacing: DSSpacing.md) {
            // Visual representation
            Rectangle()
                .fill(DSColors.primary.main)
                .frame(width: value, height: 20)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(name)
                        .font(DSTypography.body.medium)
                        .foregroundColor(DSColors.neutral.text)
                    
                    Text(description)
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                }
            }
            
            Spacer()
        }
        .padding(DSSpacing.md)
        .background(DSColors.neutral.backgroundCard)
        .cornerRadius(DSSpacing.radius.lg)
        .shadowSubtle()
    }
}

struct ComponentSpacingCard: View {
    let title: String
    let value: String
    let usage: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text(title)
                .font(DSTypography.body.semibold)
                .foregroundColor(DSColors.neutral.text)
            
            Text(value)
                .font(DSTypography.title.title4)
                .foregroundColor(DSColors.primary.main)
            
            Text(usage)
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.neutral.textSecondary)
        }
        .padding(DSSpacing.md)
        .background(DSColors.neutral.backgroundCard)
        .cornerRadius(DSSpacing.radius.lg)
        .shadowSubtle()
    }
}

// MARK: - Shadows Showcase

struct ShadowsShowcase: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            // Elevation Scale
            ShadowElevationSection()
            
            // Component Shadows
            ComponentShadowsSection()
            
            // Interactive Shadows
            InteractiveShadowsSection()
        }
    }
}

struct ShadowElevationSection: View {
    let elevations = [
        ("Subtle", DSShadows.subtle, "Cards, list items"),
        ("Small", DSShadows.small, "Interactive elements"),
        ("Medium", DSShadows.medium, "Dropdowns, tooltips"),
        ("Large", DSShadows.large, "Modals, popovers"),
        ("Extra Large", DSShadows.extraLarge, "Toast notifications"),
        ("Huge", DSShadows.huge, "Modal dialogs")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Shadow Elevation Scale")
                    .primaryHeadingStyle()
                
                Text("Progressive depth for visual hierarchy")
                    .captionTextStyle()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DSSpacing.lg), count: 3), spacing: DSSpacing.lg) {
                ForEach(elevations, id: \.0) { name, shadow, usage in
                    ShadowExample(name: name, shadow: shadow, usage: usage)
                }
            }
        }
        .enhancedCardStyle()
    }
}

struct ComponentShadowsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Component Shadows")
                    .primaryHeadingStyle()
                
                Text("Shadows optimized for specific components")
                    .captionTextStyle()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DSSpacing.lg), count: 2), spacing: DSSpacing.lg) {
                ComponentShadowExample(
                    title: "Financial Card",
                    subtitle: "Balance display card",
                    shadow: DSShadows.financial.balanceCard
                )
                
                ComponentShadowExample(
                    title: "Transaction Detail",
                    subtitle: "Modal overlay",
                    shadow: DSShadows.financial.transactionDetail
                )
                
                ComponentShadowExample(
                    title: "Toast Notification",
                    subtitle: "Auto-categorization feedback",
                    shadow: DSShadows.financial.autoCategory
                )
                
                ComponentShadowExample(
                    title: "Chart Component",
                    subtitle: "Data visualization",
                    shadow: DSShadows.component.chart
                )
            }
        }
        .enhancedCardStyle()
    }
}

struct InteractiveShadowsSection: View {
    @State private var isHovered = false
    @State private var isPressed = false
    @State private var isSelected = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Interactive Shadows")
                    .primaryHeadingStyle()
                
                Text("Shadows that respond to user interaction")
                    .captionTextStyle()
            }
            
            HStack(spacing: DSSpacing.lg) {
                // Hover Example
                VStack(spacing: DSSpacing.sm) {
                    Rectangle()
                        .fill(DSColors.primary.main.opacity(0.1))
                        .frame(height: 80)
                        .cornerRadius(DSSpacing.radius.lg)
                        .shadow(DSShadows.interactive.hover)
                    
                    Text("Hover State")
                        .captionTextStyle()
                }
                
                // Selected Example
                VStack(spacing: DSSpacing.sm) {
                    Rectangle()
                        .fill(DSColors.primary.main.opacity(0.2))
                        .frame(height: 80)
                        .cornerRadius(DSSpacing.radius.lg)
                        .shadow(DSShadows.interactive.selected)
                    
                    Text("Selected State")
                        .captionTextStyle()
                }
                
                // Focus Example
                VStack(spacing: DSSpacing.sm) {
                    Rectangle()
                        .fill(DSColors.primary.main.opacity(0.15))
                        .frame(height: 80)
                        .cornerRadius(DSSpacing.radius.lg)
                        .shadow(DSShadows.interactive.focus)
                    
                    Text("Focus State")
                        .captionTextStyle()
                }
            }
        }
        .enhancedCardStyle()
    }
}

struct ShadowExample: View {
    let name: String
    let shadow: ShadowStyle
    let usage: String
    
    var body: some View {
        VStack(spacing: DSSpacing.md) {
            Rectangle()
                .fill(DSColors.neutral.backgroundCard)
                .frame(height: 80)
                .cornerRadius(DSSpacing.radius.lg)
                .shadow(shadow)
            
            VStack(spacing: DSSpacing.xs) {
                Text(name)
                    .font(DSTypography.body.medium)
                    .foregroundColor(DSColors.neutral.text)
                
                Text(usage)
                    .font(DSTypography.caption.small)
                    .foregroundColor(DSColors.neutral.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

struct ComponentShadowExample: View {
    let title: String
    let subtitle: String
    let shadow: ShadowStyle
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(title)
                    .font(DSTypography.body.semibold)
                    .foregroundColor(DSColors.neutral.text)
                
                Text(subtitle)
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
            }
            
            Rectangle()
                .fill(DSColors.neutral.backgroundCard)
                .frame(height: 60)
                .cornerRadius(DSSpacing.radius.lg)
                .shadow(shadow)
        }
        .padding(DSSpacing.md)
        .background(DSColors.neutral.backgroundCard)
        .cornerRadius(DSSpacing.radius.lg)
        .shadowSubtle()
    }
}

// MARK: - Animations Showcase

struct AnimationsShowcase: View {
    @Binding var isEnabled: Bool
    @State private var animationStates = AnimationStates()
    
    struct AnimationStates {
        var scaleAnimation = false
        var rotationAnimation = 0.0
        var slideAnimation = false
        var fadeAnimation = true
        var pulseAnimation = false
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            // Animation Controls
            AnimationControlsSection(isEnabled: $isEnabled, states: $animationStates)
            
            // Timing Examples
            AnimationTimingSection(isEnabled: isEnabled, states: $animationStates)
            
            // Transition Examples
            TransitionExamplesSection(isEnabled: isEnabled, states: $animationStates)
        }
    }
}

struct AnimationControlsSection: View {
    @Binding var isEnabled: Bool
    @Binding var states: AnimationsShowcase.AnimationStates
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Animation Controls")
                    .primaryHeadingStyle()
                
                Text("Interactive animation examples")
                    .captionTextStyle()
            }
            
            HStack(spacing: DSSpacing.lg) {
                Button("Scale") {
                    if isEnabled {
                        withAnimation(DSAnimations.common.gentleBounce) {
                            states.scaleAnimation.toggle()
                        }
                    }
                }
                .secondaryButtonStyle()
                
                Button("Rotate") {
                    if isEnabled {
                        withAnimation(DSAnimations.common.standardTransition) {
                            states.rotationAnimation += 90
                        }
                    }
                }
                .secondaryButtonStyle()
                
                Button("Slide") {
                    if isEnabled {
                        withAnimation(DSAnimations.common.slide) {
                            states.slideAnimation.toggle()
                        }
                    }
                }
                .secondaryButtonStyle()
                
                Button("Fade") {
                    if isEnabled {
                        withAnimation(DSAnimations.common.smoothFade) {
                            states.fadeAnimation.toggle()
                        }
                    }
                }
                .secondaryButtonStyle()
            }
        }
        .enhancedCardStyle()
    }
}

struct AnimationTimingSection: View {
    let isEnabled: Bool
    @Binding var states: AnimationsShowcase.AnimationStates
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Animation Examples")
                    .primaryHeadingStyle()
                
                Text("Different timing and easing functions")
                    .captionTextStyle()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DSSpacing.lg), count: 4), spacing: DSSpacing.lg) {
                AnimationExample(
                    title: "Scale",
                    isAnimated: states.scaleAnimation,
                    content: {
                        Rectangle()
                            .fill(DSColors.primary.main)
                            .frame(width: 40, height: 40)
                            .scaleEffect(states.scaleAnimation ? 1.2 : 1.0)
                            .cornerRadius(DSSpacing.radius.lg)
                    }
                )
                
                AnimationExample(
                    title: "Rotation",
                    isAnimated: states.rotationAnimation != 0,
                    content: {
                        Rectangle()
                            .fill(DSColors.success.main)
                            .frame(width: 40, height: 40)
                            .rotationEffect(.degrees(states.rotationAnimation))
                            .cornerRadius(DSSpacing.radius.lg)
                    }
                )
                
                AnimationExample(
                    title: "Slide",
                    isAnimated: states.slideAnimation,
                    content: {
                        Rectangle()
                            .fill(DSColors.warning.main)
                            .frame(width: 40, height: 40)
                            .offset(x: states.slideAnimation ? 20 : -20)
                            .cornerRadius(DSSpacing.radius.lg)
                    }
                )
                
                AnimationExample(
                    title: "Fade",
                    isAnimated: !states.fadeAnimation,
                    content: {
                        Rectangle()
                            .fill(DSColors.error.main)
                            .frame(width: 40, height: 40)
                            .opacity(states.fadeAnimation ? 1.0 : 0.3)
                            .cornerRadius(DSSpacing.radius.lg)
                    }
                )
            }
        }
        .enhancedCardStyle()
    }
}

struct TransitionExamplesSection: View {
    let isEnabled: Bool
    @Binding var states: AnimationsShowcase.AnimationStates
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Transition Examples")
                    .primaryHeadingStyle()
                
                Text("Common transition patterns")
                    .captionTextStyle()
            }
            
            HStack(spacing: DSSpacing.xl) {
                // Toast Transition
                VStack(spacing: DSSpacing.sm) {
                    ZStack {
                        Rectangle()
                            .fill(DSColors.neutral.backgroundSecondary)
                            .frame(height: 100)
                            .cornerRadius(DSSpacing.radius.lg)
                        
                        if states.slideAnimation {
                            Rectangle()
                                .fill(DSColors.primary.main)
                                .frame(width: 80, height: 30)
                                .cornerRadius(DSSpacing.radius.md)
                                .toastTransition()
                        }
                    }
                    
                    Text("Toast Transition")
                        .captionTextStyle()
                }
                
                // Modal Transition
                VStack(spacing: DSSpacing.sm) {
                    ZStack {
                        Rectangle()
                            .fill(DSColors.neutral.backgroundSecondary)
                            .frame(height: 100)
                            .cornerRadius(DSSpacing.radius.lg)
                        
                        if states.scaleAnimation {
                            Rectangle()
                                .fill(DSColors.success.main)
                                .frame(width: 60, height: 60)
                                .cornerRadius(DSSpacing.radius.lg)
                                .modalTransition()
                        }
                    }
                    
                    Text("Modal Transition")
                        .captionTextStyle()
                }
                
                // Scale Transition
                VStack(spacing: DSSpacing.sm) {
                    ZStack {
                        Rectangle()
                            .fill(DSColors.neutral.backgroundSecondary)
                            .frame(height: 100)
                            .cornerRadius(DSSpacing.radius.lg)
                        
                        if states.fadeAnimation {
                            Rectangle()
                                .fill(DSColors.warning.main)
                                .frame(width: 50, height: 50)
                                .cornerRadius(DSSpacing.radius.lg)
                                .scaleTransition()
                        }
                    }
                    
                    Text("Scale Transition")
                        .captionTextStyle()
                }
            }
        }
        .enhancedCardStyle()
    }
}

struct AnimationExample<Content: View>: View {
    let title: String
    let isAnimated: Bool
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(spacing: DSSpacing.sm) {
            ZStack {
                Rectangle()
                    .fill(DSColors.neutral.backgroundSecondary)
                    .frame(height: 80)
                    .cornerRadius(DSSpacing.radius.lg)
                
                content
            }
            
            Text(title)
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.neutral.textSecondary)
            
            Circle()
                .fill(isAnimated ? DSColors.success.main : DSColors.neutral.n300)
                .frame(width: 8, height: 8)
        }
    }
}

// MARK: - Components Showcase

struct ComponentsShowcase: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            // Button Components
            ButtonComponentsSection()
            
            // Card Components
            CardComponentsSection()
            
            // Financial Components
            FinancialComponentsSection()
        }
    }
}

struct ButtonComponentsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Button Components")
                    .primaryHeadingStyle()
                
                Text("Interactive button styles using design system")
                    .captionTextStyle()
            }
            
            HStack(spacing: DSSpacing.lg) {
                Button("Primary Button") {}
                    .interactiveButtonStyle()
                
                Button("Secondary Button") {}
                    .secondaryButtonStyle()
                
                Button("Outlined") {}
                    .padding(.horizontal, DSSpacing.component.buttonPaddingH)
                    .padding(.vertical, DSSpacing.component.buttonPaddingV)
                    .background(Color.clear)
                    .foregroundColor(DSColors.primary.main)
                    .overlay(
                        RoundedRectangle(cornerRadius: DSSpacing.radius.lg)
                            .stroke(DSColors.primary.main, lineWidth: 1)
                    )
            }
        }
        .enhancedCardStyle()
    }
}

struct CardComponentsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Card Components")
                    .primaryHeadingStyle()
                
                Text("Card layouts with consistent styling")
                    .captionTextStyle()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DSSpacing.lg), count: 2), spacing: DSSpacing.lg) {
                // Standard Card
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Standard Card")
                        .font(DSTypography.body.semibold)
                        .foregroundColor(DSColors.neutral.text)
                    
                    Text("Basic card with standard styling")
                        .captionTextStyle()
                }
                .cardStyle()
                
                // Enhanced Card
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Enhanced Card")
                        .font(DSTypography.body.semibold)
                        .foregroundColor(DSColors.neutral.text)
                    
                    Text("Card with enhanced shadow depth")
                        .captionTextStyle()
                }
                .enhancedCardStyle()
                
                // Financial Card
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Financial Card")
                        .font(DSTypography.body.semibold)
                        .foregroundColor(DSColors.neutral.text)
                    
                    Text("Optimized for financial data")
                        .captionTextStyle()
                }
                .financialCardStyle()
                
                // Metric Card
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(DSColors.success.main)
                        
                        Spacer()
                        
                        Text("+5.2%")
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.success.main)
                            .padding(.horizontal, DSSpacing.xs)
                            .padding(.vertical, 2)
                            .background(DSColors.success.s50)
                            .cornerRadius(4)
                    }
                    
                    Text("$12,345.67")
                        .font(DSTypography.title.title3)
                        .foregroundColor(DSColors.neutral.text)
                    
                    Text("Total Balance")
                        .captionTextStyle()
                }
                .shadowMetricCard()
                .paddingCard()
                .background(DSColors.neutral.backgroundCard)
                .cornerRadiusStandard()
            }
        }
        .enhancedCardStyle()
    }
}

struct FinancialComponentsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Financial Components")
                    .primaryHeadingStyle()
                
                Text("Components specific to financial applications")
                    .captionTextStyle()
            }
            
            VStack(spacing: DSSpacing.lg) {
                // Transaction Row Example
                HStack(spacing: DSSpacing.lg) {
                    Circle()
                        .fill(DSColors.category.foodDining)
                        .frame(width: DSSpacing.icon.category, height: DSSpacing.icon.category)
                        .overlay(
                            Image(systemName: "fork.knife")
                                .font(.title2)
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text("Restaurant ABC")
                            .bodyTextStyle()
                        
                        Text("Food & Dining")
                            .captionTextStyle()
                    }
                    
                    Spacer()
                    
                    Text("-$45.67")
                        .font(DSTypography.financial.currency)
                        .foregroundColor(DSColors.error.main)
                }
                .paddingListRow()
                .background(DSColors.neutral.backgroundCard)
                .cornerRadiusStandard()
                .shadowCard()
                
                // Account Balance Card
                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    HStack {
                        Text("Checking Account")
                            .font(DSTypography.body.semibold)
                            .foregroundColor(DSColors.neutral.text)
                        
                        Spacer()
                        
                        Text("****1234")
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                    }
                    
                    Text("$15,423.89")
                        .font(DSTypography.display.display3)
                        .foregroundColor(DSColors.success.main)
                    
                    HStack {
                        Text("Available Balance")
                            .captionTextStyle()
                        
                        Spacer()
                        
                        HStack(spacing: DSSpacing.xs) {
                            Text("+$1,234.56")
                                .font(DSTypography.caption.regular)
                                .foregroundColor(DSColors.success.main)
                            
                            Text("this month")
                                .captionTextStyle()
                        }
                    }
                }
                .financialCardStyle()
            }
        }
        .enhancedCardStyle()
    }
}

// MARK: - Preview

#Preview {
    DesignSystemShowcase()
        .frame(minWidth: 1200, minHeight: 800)
}
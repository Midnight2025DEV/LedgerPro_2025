import SwiftUI

/// LedgerPro Design System - Colors
/// 
/// A sophisticated financial color palette designed for clarity, trust, and premium feel.
/// Colors are optimized for financial data visualization and accessibility.
public struct DSColors {
    
    // MARK: - Primary Brand Colors
    
    /// Electric blue primary color - conveys trust and technology
    public static let primary = Primary()
    
    public struct Primary {
        /// Primary 50: #EEF2FF
        public let p50 = Color(hex: "#EEF2FF")!
        /// Primary 100: #E0E7FF
        public let p100 = Color(hex: "#E0E7FF")!
        /// Primary 200: #C7D2FE
        public let p200 = Color(hex: "#C7D2FE")!
        /// Primary 300: #A5B4FC
        public let p300 = Color(hex: "#A5B4FC")!
        /// Primary 400: #818CF8
        public let p400 = Color(hex: "#818CF8")!
        /// Primary 500: #5B6DFF - Main brand color
        public let p500 = Color(hex: "#5B6DFF")!
        /// Primary 600: #4054DB
        public let p600 = Color(hex: "#4054DB")!
        /// Primary 700: #3B4BC7
        public let p700 = Color(hex: "#3B4BC7")!
        /// Primary 800: #3343A3
        public let p800 = Color(hex: "#3343A3")!
        /// Primary 900: #1E2875
        public let p900 = Color(hex: "#1E2875")!
        
        /// Main primary color - adapts to light/dark mode
        public var main: Color {
            Color(light: p500, dark: p400)
        }
        
        /// Subtle primary color for backgrounds
        public var subtle: Color {
            Color(light: p50, dark: p900.opacity(0.3))
        }
    }
    
    // MARK: - Financial Success Colors (Profit/Positive)
    
    /// Emerald green for profits, gains, and positive financial outcomes
    public static let success = Success()
    
    public struct Success {
        /// Success 50: #ECFDF5
        public let s50 = Color(hex: "#ECFDF5")!
        /// Success 100: #D1FAE5
        public let s100 = Color(hex: "#D1FAE5")!
        /// Success 200: #A7F3D0
        public let s200 = Color(hex: "#A7F3D0")!
        /// Success 300: #6EE7B7
        public let s300 = Color(hex: "#6EE7B7")!
        /// Success 400: #34D399
        public let s400 = Color(hex: "#34D399")!
        /// Success 500: #10B981 - Main success color
        public let s500 = Color(hex: "#10B981")!
        /// Success 600: #059669
        public let s600 = Color(hex: "#059669")!
        /// Success 700: #047857
        public let s700 = Color(hex: "#047857")!
        /// Success 800: #065F46
        public let s800 = Color(hex: "#065F46")!
        /// Success 900: #064E3B
        public let s900 = Color(hex: "#064E3B")!
        
        /// Main success color - adapts to light/dark mode
        public var main: Color {
            Color(light: s500, dark: s400)
        }
        
        /// Subtle success color for backgrounds
        public var subtle: Color {
            Color(light: s50, dark: s900.opacity(0.3))
        }
    }
    
    // MARK: - Financial Error Colors (Loss/Negative)
    
    /// Red for losses, expenses, and negative financial outcomes
    public static let error = Error()
    
    public struct Error {
        /// Error 50: #FEF2F2
        public let e50 = Color(hex: "#FEF2F2")!
        /// Error 100: #FEE2E2
        public let e100 = Color(hex: "#FEE2E2")!
        /// Error 200: #FECACA
        public let e200 = Color(hex: "#FECACA")!
        /// Error 300: #FCA5A5
        public let e300 = Color(hex: "#FCA5A5")!
        /// Error 400: #F87171
        public let e400 = Color(hex: "#F87171")!
        /// Error 500: #EF4444 - Main error color
        public let e500 = Color(hex: "#EF4444")!
        /// Error 600: #DC2626
        public let e600 = Color(hex: "#DC2626")!
        /// Error 700: #B91C1C
        public let e700 = Color(hex: "#B91C1C")!
        /// Error 800: #991B1B
        public let e800 = Color(hex: "#991B1B")!
        /// Error 900: #7F1D1D
        public let e900 = Color(hex: "#7F1D1D")!
        
        /// Main error color - adapts to light/dark mode
        public var main: Color {
            Color(light: e500, dark: e400)
        }
        
        /// Subtle error color for backgrounds
        public var subtle: Color {
            Color(light: e50, dark: e900.opacity(0.3))
        }
    }
    
    // MARK: - Warning Colors (Caution/Neutral)
    
    /// Amber for warnings and neutral financial states
    public static let warning = Warning()
    
    // MARK: - Info Colors (Information/Neutral)
    
    /// Blue for informational states
    public static let info = Info()
    
    public struct Warning {
        /// Warning 50: #FFFBEB
        public let w50 = Color(hex: "#FFFBEB")!
        /// Warning 100: #FEF3C7
        public let w100 = Color(hex: "#FEF3C7")!
        /// Warning 200: #FDE68A
        public let w200 = Color(hex: "#FDE68A")!
        /// Warning 300: #FCD34D
        public let w300 = Color(hex: "#FCD34D")!
        /// Warning 400: #FBBF24
        public let w400 = Color(hex: "#FBBF24")!
        /// Warning 500: #F59E0B - Main warning color
        public let w500 = Color(hex: "#F59E0B")!
        /// Warning 600: #D97706
        public let w600 = Color(hex: "#D97706")!
        /// Warning 700: #B45309
        public let w700 = Color(hex: "#B45309")!
        /// Warning 800: #92400E
        public let w800 = Color(hex: "#92400E")!
        /// Warning 900: #78350F
        public let w900 = Color(hex: "#78350F")!
        
        /// Main warning color - adapts to light/dark mode
        public var main: Color {
            Color(light: w500, dark: w400)
        }
        
        /// Subtle warning color for backgrounds
        public var subtle: Color {
            Color(light: w50, dark: w900.opacity(0.3))
        }
    }
    
    public struct Info {
        /// Info 50: #EFF6FF
        public let i50 = Color(hex: "#EFF6FF")!
        /// Info 100: #DBEAFE
        public let i100 = Color(hex: "#DBEAFE")!
        /// Info 200: #BFDBFE
        public let i200 = Color(hex: "#BFDBFE")!
        /// Info 300: #93BBFD
        public let i300 = Color(hex: "#93BBFD")!
        /// Info 400: #60A5FA
        public let i400 = Color(hex: "#60A5FA")!
        /// Info 500: #3B82F6 - Main info color
        public let i500 = Color(hex: "#3B82F6")!
        /// Info 600: #2563EB
        public let i600 = Color(hex: "#2563EB")!
        /// Info 700: #1D4ED8
        public let i700 = Color(hex: "#1D4ED8")!
        /// Info 800: #1E40AF
        public let i800 = Color(hex: "#1E40AF")!
        /// Info 900: #1E3A8A
        public let i900 = Color(hex: "#1E3A8A")!
        
        /// Main info color - adapts to light/dark mode
        public var main: Color {
            Color(light: i500, dark: i400)
        }
        
        /// Subtle info color for backgrounds
        public var subtle: Color {
            Color(light: i50, dark: i900.opacity(0.3))
        }
    }
    
    // MARK: - Neutral Colors (Data Visualization & UI)
    
    /// Premium neutral colors for data visualization and interface elements
    public static let neutral = Neutral()
    
    public struct Neutral {
        /// Neutral 50: #FAFAFA - Lightest background
        public let n50 = Color(hex: "#FAFAFA")!
        /// Neutral 100: #F5F5F5 - Card backgrounds
        public let n100 = Color(hex: "#F5F5F5")!
        /// Neutral 200: #E5E5E5 - Borders
        public let n200 = Color(hex: "#E5E5E5")!
        /// Neutral 300: #D4D4D4 - Dividers
        public let n300 = Color(hex: "#D4D4D4")!
        /// Neutral 400: #A3A3A3 - Disabled elements
        public let n400 = Color(hex: "#A3A3A3")!
        /// Neutral 500: #737373 - Secondary text
        public let n500 = Color(hex: "#737373")!
        /// Neutral 600: #525252 - Body text
        public let n600 = Color(hex: "#525252")!
        /// Neutral 700: #404040 - Headings
        public let n700 = Color(hex: "#404040")!
        /// Neutral 800: #262626 - Dark headings
        public let n800 = Color(hex: "#262626")!
        /// Neutral 900: #171717 - Darkest text
        public let n900 = Color(hex: "#171717")!
        
        /// Primary text color - adapts to light/dark mode
        public var text: Color {
            Color(light: n900, dark: n100)
        }
        
        /// Secondary text color - adapts to light/dark mode
        public var textSecondary: Color {
            Color(light: n600, dark: n400)
        }
        
        /// Tertiary text color - adapts to light/dark mode
        public var textTertiary: Color {
            Color(light: n500, dark: n500)
        }
        
        /// Background color - adapts to light/dark mode
        public var background: Color {
            Color(light: .white, dark: Color(hex: "#0A0A0A")!)
        }
        
        /// Secondary background color - adapts to light/dark mode
        public var backgroundSecondary: Color {
            Color(light: n50, dark: Color(hex: "#1A1A1A")!)
        }
        
        /// Card background color - adapts to light/dark mode
        public var backgroundCard: Color {
            Color(light: .white, dark: Color(hex: "#1F1F1F")!)
        }
        
        /// Border color - adapts to light/dark mode
        public var border: Color {
            Color(light: n200, dark: Color(hex: "#333333")!)
        }
        
        /// Divider color - adapts to light/dark mode
        public var divider: Color {
            Color(light: n200, dark: Color(hex: "#2A2A2A")!)
        }
    }
    
    // MARK: - Category Colors (Enhanced from Extensions.swift)
    
    /// Financial category colors optimized for data visualization
    public static let category = Category()
    
    public struct Category {
        /// Food & Dining: Warm orange
        public let foodDining = Color(hex: "#FB923C")!
        /// Transportation: Electric blue
        public let transportation = Color(hex: "#3B82F6")!
        /// Shopping: Rich purple
        public let shopping = Color(hex: "#A855F7")!
        /// Entertainment: Pink
        public let entertainment = Color(hex: "#EC4899")!
        /// Bills & Utilities: Urgent red
        public let billsUtilities = Color(hex: "#EF4444")!
        /// Healthcare: Medical teal
        public let healthcare = Color(hex: "#06B6D4")!
        /// Travel: Adventure blue
        public let travel = Color(hex: "#0EA5E9")!
        /// Groceries: Fresh green
        public let groceries = Color(hex: "#22C55E")!
        /// Income: Success green
        public let income = Color(hex: "#10B981")!
        /// Subscription: Technology indigo
        public let subscription = Color(hex: "#6366F1")!
        /// Transfer: Neutral gray
        public let transfer = Color(hex: "#6B7280")!
        /// Uncategorized: Light gray
        public let uncategorized = Color(hex: "#9CA3AF")!
        
        /// Get color for category name
        public func color(for category: String) -> Color {
            switch category.lowercased() {
            case "food & dining", "dining", "food":
                return foodDining
            case "transportation", "gas", "fuel":
                return transportation
            case "shopping", "retail":
                return shopping
            case "entertainment":
                return entertainment
            case "bills & utilities", "utilities":
                return billsUtilities
            case "healthcare", "health":
                return healthcare
            case "travel":
                return travel
            case "groceries":
                return groceries
            case "income", "deposits", "salary":
                return income
            case "subscription", "subscriptions":
                return subscription
            case "transfer", "payment":
                return transfer
            default:
                return uncategorized
            }
        }
    }
    
    // MARK: - Gradients
    
    /// Premium gradient definitions for modern financial UI
    public static let gradient = Gradient()
    
    public struct Gradient {
        /// Primary brand gradient: Electric blue to deeper blue
        public let primary = LinearGradient(
            colors: [DSColors.primary.p500, DSColors.primary.p600],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        /// Success gradient: Emerald to deeper green
        public let success = LinearGradient(
            colors: [DSColors.success.s500, DSColors.success.s600],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        /// Error gradient: Red to deeper red
        public let error = LinearGradient(
            colors: [DSColors.error.e500, DSColors.error.e600],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        /// Warning gradient: Amber to deeper orange
        public let warning = LinearGradient(
            colors: [DSColors.warning.w500, DSColors.warning.w600],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        /// Neutral gradient: Light to medium gray
        public let neutral = LinearGradient(
            colors: [DSColors.neutral.n100, DSColors.neutral.n200],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        /// Subtle background gradient for cards
        public let subtleBackground = LinearGradient(
            colors: [
                Color.white,
                DSColors.neutral.n50
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        /// Dark mode subtle background gradient
        public let subtleBackgroundDark = LinearGradient(
            colors: [
                Color(hex: "#1F1F1F")!,
                Color(hex: "#171717")!
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        /// Financial positive gradient (for gains)
        public let financialPositive = LinearGradient(
            colors: [DSColors.success.s400, DSColors.success.s600],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        /// Financial negative gradient (for losses)
        public let financialNegative = LinearGradient(
            colors: [DSColors.error.e400, DSColors.error.e600],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Color Extensions
// Note: Color.init(hex:) extension is defined in Models/Category.swift to avoid duplication

#if canImport(UIKit)
import UIKit

extension Color {
    /// Create adaptive color for light/dark mode on iOS
    init(light: Color, dark: Color) {
        self = Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
}

#elseif canImport(AppKit)
import AppKit

extension Color {
    /// Create adaptive color for light/dark mode on macOS
    init(light: Color, dark: Color) {
        self = Color(NSColor(name: nil) { appearance in
            switch appearance.bestMatch(from: [.darkAqua, .aqua]) {
            case .darkAqua:
                return NSColor(dark)
            default:
                return NSColor(light)
            }
        })
    }
}
#endif

// MARK: - Legacy Category Color Migration

extension DSColors.Category {
    /// Legacy category color function for backward compatibility
    /// Migrated from Extensions.swift forCategory function
    static func forCategory(_ category: String) -> Color {
        return DSColors.category.color(for: category)
    }
}
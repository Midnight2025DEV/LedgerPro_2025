import Foundation
import SwiftUI

// Import design system tokens for consistent styling
// Note: These imports reference the design system tokens created in Views/DesignSystem/Tokens/

// MARK: - Date Extensions
extension Date {
    func formatted(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        return formatter.string(from: self)
    }
    
    func isInCurrentMonth() -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, equalTo: Date(), toGranularity: .month)
    }
    
    func isInCurrentWeek() -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
}

// MARK: - Double Extensions
extension Double {
    func formatAsCurrency(code: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }
    
    func formatAsPercentage(decimals: Int = 1) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals
        return formatter.string(from: NSNumber(value: self / 100)) ?? "0%"
    }
}

// MARK: - String Extensions
extension String {
    func truncated(to length: Int) -> String {
        if self.count <= length {
            return self
        }
        return String(self.prefix(length)) + "..."
    }
    
    /// Safe UTF-8 data conversion that throws instead of force unwrapping
    func safeUTF8Data() throws -> Data {
        guard let data = self.data(using: .utf8) else {
            throw EncodingError.invalidValue(self, EncodingError.Context(
                codingPath: [],
                debugDescription: "Failed to encode string as UTF-8: \(self)"
            ))
        }
        return data
    }
    
    func sanitizedForFilename() -> String {
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return self.components(separatedBy: invalidCharacters).joined(separator: "_")
    }
}

// MARK: - Color Extensions
extension Color {
    @MainActor static func forCategory(_ category: String) -> Color {
        // Use design system category colors as primary source
        let designSystemColor = DSColors.category.color(for: category)
        
        // Use CategoryService as fallback for dynamic categories
        let categoryService = CategoryService.shared
        
        // Find exact match first
        if let categoryObject = categoryService.categories.first(where: { $0.name.lowercased() == category.lowercased() }) {
            return Color(hex: categoryObject.color) ?? designSystemColor
        }
        
        // Try partial match (e.g., "Dining" matches "Food & Dining")
        if let categoryObject = categoryService.categories.first(where: { 
            $0.name.lowercased().contains(category.lowercased()) || 
            category.lowercased().contains($0.name.lowercased())
        }) {
            return Color(hex: categoryObject.color) ?? designSystemColor
        }
        
        // Return design system color for consistent mapping
        return designSystemColor
    }
    
    // System color adapters using design system tokens
    static var systemBackground: Color {
        DSColors.neutral.background
    }
    
    static var secondarySystemBackground: Color {
        DSColors.neutral.backgroundSecondary
    }
    
    static var label: Color {
        DSColors.neutral.text
    }
    
    static var secondaryLabel: Color {
        DSColors.neutral.textSecondary
    }
    
    static var tertiaryLabel: Color {
        DSColors.neutral.textTertiary
    }
    
    static var systemCard: Color {
        DSColors.neutral.backgroundCard
    }
    
    static var systemBorder: Color {
        DSColors.neutral.border
    }
    
    static var systemDivider: Color {
        DSColors.neutral.divider
    }
}

// MARK: - View Extensions
extension View {
    /// Apply standard card styling using design system tokens
    func cardStyle() -> some View {
        self
            .paddingCard()
            .background(DSColors.neutral.backgroundCard)
            .cornerRadiusStandard()
            .shadowCard()
    }
    
    /// Apply enhanced card styling with subtle elevation
    func enhancedCardStyle() -> some View {
        self
            .paddingCard()
            .background(DSColors.neutral.backgroundCard)
            .cornerRadiusStandard()
            .shadowMedium()
    }
    
    /// Apply financial card styling for important data
    func financialCardStyle() -> some View {
        self
            .paddingCard()
            .background(DSColors.neutral.backgroundCard)
            .cornerRadiusStandard()
            .shadowBalanceCard()
    }
    
    /// Apply navigation title styling using design system typography
    func navigationTitleStyle() -> some View {
        self
            .font(DSTypography.title.largeTitle)
            .foregroundColor(DSColors.neutral.text)
    }
    
    /// Apply primary heading style
    func primaryHeadingStyle() -> some View {
        self
            .font(DSTypography.title.title2)
            .foregroundColor(DSColors.neutral.text)
    }
    
    /// Apply secondary heading style
    func secondaryHeadingStyle() -> some View {
        self
            .font(DSTypography.title.title3)
            .foregroundColor(DSColors.neutral.textSecondary)
    }
    
    /// Apply body text style
    func bodyTextStyle() -> some View {
        self
            .font(DSTypography.body.regular)
            .foregroundColor(DSColors.neutral.text)
    }
    
    /// Apply caption text style
    func captionTextStyle() -> some View {
        self
            .font(DSTypography.caption.regular)
            .foregroundColor(DSColors.neutral.textTertiary)
    }
    
    /// Apply financial amount styling (positive/negative aware)
    func financialAmountStyle(isPositive: Bool) -> some View {
        self
            .font(DSTypography.financial.currency)
            .foregroundColor(isPositive ? DSColors.success.main : DSColors.error.main)
    }
    
    /// Apply large financial amount styling
    func largeFinancialAmountStyle(isPositive: Bool) -> some View {
        self
            .font(DSTypography.financial.currencyLarge)
            .foregroundColor(isPositive ? DSColors.success.main : DSColors.error.main)
    }
    
    /// Apply interactive button styling
    func interactiveButtonStyle() -> some View {
        self
            .padding(.horizontal, DSSpacing.component.buttonPaddingH)
            .padding(.vertical, DSSpacing.component.buttonPaddingV)
            .background(DSColors.primary.main)
            .foregroundColor(.white)
            .cornerRadius(DSSpacing.radius.lg)
            .shadowButton()
    }
    
    /// Apply secondary button styling
    func secondaryButtonStyle() -> some View {
        self
            .padding(.horizontal, DSSpacing.component.buttonPaddingH)
            .padding(.vertical, DSSpacing.component.buttonPaddingV)
            .background(DSColors.neutral.backgroundSecondary)
            .foregroundColor(DSColors.neutral.text)
            .cornerRadius(DSSpacing.radius.lg)
            .shadowSubtle()
    }
    
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Array Extensions
extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

extension Array where Element == Transaction {
    func grouped(by keyPath: KeyPath<Transaction, String>) -> [String: [Transaction]] {
        return Dictionary(grouping: self) { $0[keyPath: keyPath] }
    }
    
    func totalAmount() -> Double {
        return reduce(0) { $0 + $1.amount }
    }
    
    func totalExpenses() -> Double {
        return filter { $0.amount < 0 }.reduce(0) { $0 + abs($1.amount) }
    }
    
    func totalIncome() -> Double {
        return filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount }
    }
    
    func sortedByDate(ascending: Bool = false) -> [Transaction] {
        return sorted { transaction1, transaction2 in
            let date1 = transaction1.formattedDate
            let date2 = transaction2.formattedDate
            return ascending ? date1 < date2 : date1 > date2
        }
    }
    
    func filtered(by category: String) -> [Transaction] {
        return filter { $0.category == category }
    }
    
    func filtered(by dateRange: ClosedRange<Date>) -> [Transaction] {
        return filter { dateRange.contains($0.formattedDate) }
    }
}

// MARK: - UserDefaults Extensions
extension UserDefaults {
    func setEncodable<T: Codable>(_ object: T, forKey key: String) {
        do {
            let data = try JSONEncoder().encode(object)
            set(data, forKey: key)
        } catch {
            AppLogger.shared.error("Failed to encode object for key \(key): \(error)", category: "Utils")
        }
    }
    
    func getDecodable<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            AppLogger.shared.error("Failed to decode object for key \(key): \(error)", category: "Utils")
            return nil
        }
    }
}

// MARK: - NumberFormatter Extensions
extension NumberFormatter {
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }()
    
    static let percentage: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    static let decimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}

// MARK: - DateFormatter Extensions
extension DateFormatter {
    static let chartDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter
    }()
    
    static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()
    
    static let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

// MARK: - DispatchQueue Extensions
extension DispatchQueue {
    static func mainAsync(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }
}

// MARK: - Debugging Helpers
extension Transaction {
    var debugDescription: String {
        return """
        Transaction {
            id: \(id)
            date: \(date)
            description: \(description)
            amount: \(amount)
            category: \(category)
            accountId: \(accountId ?? "nil")
            jobId: \(jobId ?? "nil")
        }
        """
    }
}

extension BankAccount {
    var debugDescription: String {
        return """
        BankAccount {
            id: \(id)
            name: \(name)
            institution: \(institution)
            accountType: \(accountType.rawValue)
            isActive: \(isActive)
        }
        """
    }
}
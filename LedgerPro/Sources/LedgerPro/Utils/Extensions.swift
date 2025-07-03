import Foundation
import SwiftUI

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
    
    func sanitizedForFilename() -> String {
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return self.components(separatedBy: invalidCharacters).joined(separator: "_")
    }
}

// MARK: - Color Extensions
extension Color {
    @MainActor static func forCategory(_ category: String) -> Color {
        // Use CategoryService as single source of truth
        let categoryService = CategoryService.shared
        
        // Find exact match first
        if let categoryObject = categoryService.categories.first(where: { $0.name.lowercased() == category.lowercased() }) {
            return Color(hex: categoryObject.color) ?? .gray
        }
        
        // Try partial match (e.g., "Dining" matches "Food & Dining")
        if let categoryObject = categoryService.categories.first(where: { 
            $0.name.lowercased().contains(category.lowercased()) || 
            category.lowercased().contains($0.name.lowercased())
        }) {
            return Color(hex: categoryObject.color) ?? .gray
        }
        
        // Legacy fallback mappings for unmapped categories
        switch category.lowercased() {
        case "groceries", "food", "dining":
            return .green
        case "transportation", "gas", "fuel":
            return .blue
        case "shopping", "retail":
            return .purple
        default:
            return .gray
        }
    }
    
    // System color adapters for better cross-platform compatibility
    static var systemBackground: Color {
        Color(NSColor.controlBackgroundColor)
    }
    
    static var secondarySystemBackground: Color {
        Color(NSColor.windowBackgroundColor)
    }
    
    static var label: Color {
        Color(NSColor.labelColor)
    }
    
    static var secondaryLabel: Color {
        Color(NSColor.secondaryLabelColor)
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color.systemBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    func navigationTitleStyle() -> some View {
        self
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.label)
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
            print("Failed to encode object for key \(key): \(error)")
        }
    }
    
    func getDecodable<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("Failed to decode object for key \(key): \(error)")
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
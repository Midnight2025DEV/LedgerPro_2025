import SwiftUI

/// Transaction filter types shared between transaction views
public struct TransactionFilters {
    var dateRange: DateRange?
    var amountRange: ClosedRange<Double>?
    var categories: Set<String> = []
    var transactionTypes: Set<TransactionType> = []
    
    public enum TransactionType {
        case income, expense, transfer
    }
    
    public enum DateRange {
        case thisWeek, thisMonth, thisYear, custom(Date, Date)
        
        var title: String {
            switch self {
            case .thisWeek: return "This Week"
            case .thisMonth: return "This Month"
            case .thisYear: return "This Year"
            case .custom: return "Custom Range"
            }
        }
    }
    
    public var hasActiveFilters: Bool {
        dateRange != nil || amountRange != nil || !categories.isEmpty || !transactionTypes.isEmpty
    }
    
    public var activeChips: [FilterChip.ChipData] {
        var chips: [FilterChip.ChipData] = []
        
        if let dateRange = dateRange {
            chips.append(FilterChip.ChipData(
                id: "date",
                title: dateRange.title,
                color: DSColors.primary.main,
                type: .date
            ))
        }
        
        if let amountRange = amountRange {
            chips.append(FilterChip.ChipData(
                id: "amount",
                title: "\(amountRange.lowerBound.formatAsCurrency()) - \(amountRange.upperBound.formatAsCurrency())",
                color: DSColors.success.main,
                type: .amount
            ))
        }
        
        for category in categories {
            chips.append(FilterChip.ChipData(
                id: "category-\(category)",
                title: category,
                color: DSColors.warning.main,
                type: .category
            ))
        }
        
        return chips
    }
    
    public mutating func clear() {
        dateRange = nil
        amountRange = nil
        categories.removeAll()
        transactionTypes.removeAll()
    }
    
    public mutating func removeFilter(_ type: FilterChip.ChipData.FilterType) {
        switch type {
        case .date:
            dateRange = nil
        case .amount:
            amountRange = nil
        case .category:
            categories.removeAll()
        }
    }
    
    func apply(to transactions: [Transaction]) -> [Transaction] {
        var filtered = transactions
        
        // Apply date filter
        if let dateRange = dateRange {
            // Implementation would filter by date range
        }
        
        // Apply amount filter
        if let amountRange = amountRange {
            filtered = filtered.filter { amountRange.contains(abs($0.amount)) }
        }
        
        // Apply category filter
        if !categories.isEmpty {
            filtered = filtered.filter { categories.contains($0.category) }
        }
        
        return filtered
    }
}

/// Filter chip component for transaction filters
public struct FilterChip: View {
    let data: ChipData
    let onRemove: () -> Void
    
    public struct ChipData: Identifiable {
        public let id: String
        public let title: String
        public let color: Color
        public let type: FilterType
        
        public enum FilterType {
            case date, amount, category
        }
        
        public init(id: String, title: String, color: Color, type: FilterType) {
            self.id = id
            self.title = title
            self.color = color
            self.type = type
        }
    }
    
    public init(title: String, color: Color, onRemove: @escaping () -> Void) {
        self.data = ChipData(id: UUID().uuidString, title: title, color: color, type: .category)
        self.onRemove = onRemove
    }
    
    public init(data: ChipData, onRemove: @escaping () -> Void) {
        self.data = data
        self.onRemove = onRemove
    }
    
    public var body: some View {
        HStack(spacing: DSSpacing.xs) {
            Text(data.title)
                .font(DSTypography.caption.regular)
                .foregroundColor(data.color)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(DSTypography.caption.small)
                    .foregroundColor(data.color.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DSSpacing.sm)
        .padding(.vertical, DSSpacing.xs)
        .background(
            Capsule()
                .fill(data.color.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(data.color.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
}


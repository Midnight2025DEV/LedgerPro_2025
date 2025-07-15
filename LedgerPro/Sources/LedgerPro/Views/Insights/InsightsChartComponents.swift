//
//  InsightsChartComponents.swift
//  LedgerPro
//
//  Chart and visualization components for the Insights view including
//  spending cards, category charts, and enhanced visualizations
//

import SwiftUI
import Charts

// Extract lines 805-1325 from InsightsView.swift
// This includes:
// - TotalSpendingCard
// - CategorySpendingCharts
// - CategoryPieChart
// - CategoryLegend
// - EnhancedBarChart
// - TopCategoriesList
// - CategorySpendingRow

struct TotalSpendingCard: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    let period: SpendingInsightsView.SpendingPeriod
    
    private var totalSpending: Double {
        let expenses = dataManager.transactions.filter { $0.amount < 0 }
        return expenses.reduce(0) { $0 + abs($1.amount) }
    }
    
    private var transactionCount: Int {
        return dataManager.transactions.filter { $0.amount < 0 }.count
    }
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Total Spending")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(formattedSpending)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("\(transactionCount) transactions • \(period.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.red.opacity(0.2), .red.opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.red)
            }
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var formattedSpending: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: totalSpending)) ?? "$0.00"
    }
}

struct CategorySpendingCharts: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    @EnvironmentObject private var categoryService: CategoryService
    @Binding var selectedCategory: CategorySpendingAnalysis?
    @Binding var showingDetail: Bool
    
    private var categoryData: [EnhancedCategorySpending] {
        let expenses = dataManager.transactions.filter { $0.amount < 0 }
        let grouped = Dictionary(grouping: expenses) { $0.category }
        
        let enhancedData = grouped.map { categoryName, transactions in
            let total = transactions.reduce(0) { $0 + abs($1.amount) }
            // Try exact match first
            let categoryObject = categoryService.categories.first { $0.name == categoryName }
                ?? categoryService.categories.first { $0.name.lowercased().contains(categoryName.lowercased()) }
                ?? categoryService.categories.first { categoryName.lowercased().contains($0.name.lowercased()) }
            AppLogger.shared.debug("Category: '\(categoryName)'")
            print("   Found object: \(categoryObject?.name ?? "NOT FOUND")")
            print("   Available categories containing this word:")
            for cat in categoryService.categories where cat.name.lowercased().contains(categoryName.lowercased()) {
                print("   - '\(cat.name)' (color: \(cat.color))")
            }
            
            if categoryObject == nil {
                AppLogger.shared.warning("Creating missing category: \(categoryName)")
                // You might want to create the category here or use a default
            }
            
            let categorySpending = EnhancedCategorySpending(
                category: categoryName,
                amount: total,
                categoryObject: categoryObject
            )
            
            AppLogger.shared.debug("Category: \(categoryName), Color: \(categorySpending.color), Icon: \(categorySpending.icon)")
            
            return categorySpending
        }
        
        let sortedData = enhancedData.sorted { $0.amount > $1.amount }
        
        // Debug logging for chart data
        print("🎨 INSIGHTS CHART DATA:")
        let allCategories = grouped.map { categoryName, transactions in
            let total = transactions.reduce(0) { $0 + abs($1.amount) }
            return (categoryName, total)
        }.sorted { $0.1 > $1.1 }
        print("All categories before filtering:")
        for (cat, amount) in allCategories {
            print("  - \(cat): $\(String(format: "%.2f", amount)) (\(String(format: "%.1f%%", amount/allCategories.map{$0.1}.reduce(0,+)*100)))")
        }
        print("All categories shown: \(allCategories.map{$0.0})")
        
        return sortedData
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Pie Chart (macOS 14.0+)
            if #available(macOS 14.0, *) {
                CategoryPieChart(data: categoryData)
            }
            
            // Enhanced Bar Chart
            EnhancedBarChart(data: categoryData)
        }
        .onAppear {
            print("📊 CategoryService has \(categoryService.categories.count) categories loaded")
            for cat in categoryService.categories.prefix(5) {
                print("  - \(cat.name): \(cat.color)")
            }
            
            // Force reload categories to get updated colors
            Task {
                do {
                    try await categoryService.reloadCategories()
                    print("✅ Categories reloaded with updated colors")
                } catch {
                    print("❌ Failed to reload categories: \(error)")
                }
            }
        }
    }
}

// FIXED: Pie chart interaction now working with DragGesture for precise click detection
// - Direct clicks on pie slices select categories via DragGesture with minimumDistance: 0
// - Legend items are clickable buttons that toggle category selection
// - Hover effects work on legend items
// - Click outside the donut or click same category to deselect
@available(macOS 14.0, *)
struct CategoryPieChart: View {
    let data: [EnhancedCategorySpending]
    @State private var hoveredCategory: String?
    
    var totalAmount: Double {
        data.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Breakdown")
                .font(.title2)
                .fontWeight(.bold)
            
            if !data.isEmpty {
                Chart(data, id: \.category) { item in
                    let _ = print("🎨 Rendering segment: \(item.category), Color: \(item.color)")
                    SectorMark(
                        angle: .value("Amount", item.amount),
                        innerRadius: .ratio(0.4),
                        angularInset: 5
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [item.color, item.color.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(hoveredCategory == nil || hoveredCategory == item.category ? 1.0 : 0.3)
                }
                .frame(height: 250)
                .contentShape(Rectangle())
                .overlay(
                    GeometryReader { geometry in
                        Color.clear
                            .contentShape(Rectangle())
                            .allowsHitTesting(true)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onEnded { value in
                                        let location = value.location
                                        print("🎯 TAP ON CHART at location: \(location)")
                                        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                                        let distance = sqrt(pow(location.x - center.x, 2) + pow(location.y - center.y, 2))
                                        print("📍 Center: \(center), Distance: \(distance)")
                                        
                                        // Check if within donut ring
                                        let outerRadius = min(geometry.size.width, geometry.size.height) * 0.45
                                        let innerRadius = outerRadius * 0.4
                                        
                                        if distance >= innerRadius && distance <= outerRadius {
                                            let angle = atan2(location.y - center.y, location.x - center.x)
                                            let degrees = angle * 180 / .pi
                                            let normalizedDegrees = degrees < 0 ? degrees + 360 : degrees
                                            let chartAngle = (normalizedDegrees + 90).truncatingRemainder(dividingBy: 360)
                                            
                                            print("📐 Chart angle: \(chartAngle)°")
                                            let tappedCategory = categoryForAngle(chartAngle)
                                            print("🎯 Tapped category: \(tappedCategory ?? "nil")")
                                            
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                if hoveredCategory == tappedCategory {
                                                    hoveredCategory = nil
                                                } else {
                                                    hoveredCategory = tappedCategory
                                                }
                                            }
                                        } else {
                                            print("🎯 Click outside donut ring")
                                        }
                                    }
                            )
                    }
                )
                .chartBackground { chartProxy in
                    // Center text display only
                    VStack(spacing: 4) {
                        if let hoveredCategory = hoveredCategory,
                           let selectedData = data.first(where: { $0.category == hoveredCategory }) {
                            Text(selectedData.category)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                            Text(selectedData.formattedAmount)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        } else {
                            Text("Total")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                            Text(NumberFormatter.currency.string(from: NSNumber(value: totalAmount)) ?? "$0.00")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.2), value: hoveredCategory)
                }
                
                // Enhanced Legend with click support
                CategoryLegend(data: data, hoveredCategory: $hoveredCategory)
            } else {
                Text("No spending data available")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func categoryForAngle(_ angle: Double) -> String? {
        // Calculate cumulative angles to determine which category is at the given angle
        let total = totalAmount
        var cumulativeAngle: Double = 0
        
        print("🔍 Looking for angle: \(angle)° in categories:")
        for item in data {
            let itemAngle = (item.amount / total) * 360
            let endAngle = cumulativeAngle + itemAngle
            print("  📊 \(item.category): \(cumulativeAngle)° to \(endAngle)° (size: \(itemAngle)°)")
            
            if angle >= cumulativeAngle && angle < endAngle {
                print("  ✅ Found match: \(item.category)")
                return item.category
            }
            cumulativeAngle += itemAngle
        }
        print("  ❌ No category found for angle \(angle)°")
        
        return nil
    }
}

struct CategoryLegend: View {
    let data: [EnhancedCategorySpending]
    @Binding var hoveredCategory: String?
    
    init(data: [EnhancedCategorySpending], hoveredCategory: Binding<String?> = .constant(nil)) {
        self.data = data
        self._hoveredCategory = hoveredCategory
    }
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ForEach(data) { item in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if hoveredCategory == item.category {
                            hoveredCategory = nil
                        } else {
                            hoveredCategory = item.category
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        // Enhanced icon with category icon
                        ZStack {
                            Circle()
                                .fill(item.color.opacity(0.2))
                                .frame(width: 20, height: 20)
                            
                            Image(systemName: item.icon)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(item.color)
                        }
                        
                        Text(item.shortName)
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundColor(hoveredCategory == nil || hoveredCategory == item.category ? .primary : .secondary)
                        
                        Spacer()
                        
                        Text(item.formattedAmount)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(hoveredCategory == nil || hoveredCategory == item.category ? .primary : .secondary)
                    }
                }
                .buttonStyle(.plain)
                .scaleEffect(hoveredCategory == item.category ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: hoveredCategory)
                .onHover { isHovering in
                    if isHovering && hoveredCategory != item.category {
                        hoveredCategory = item.category
                    }
                }
            }
        }
    }
}

struct EnhancedBarChart: View {
    let data: [EnhancedCategorySpending]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category Comparison")
                .font(.title2)
                .fontWeight(.bold)
            
            if !data.isEmpty {
                Chart(data, id: \.category) { item in
                    BarMark(
                        x: .value("Amount", item.amount),
                        y: .value("Category", item.shortName)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [item.color, item.color.opacity(0.7)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(6)
                }
                .frame(height: 300)
                .chartXAxis {
                    AxisMarks(position: .bottom) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2]))
                            .foregroundStyle(Color.secondary.opacity(0.3))
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(formatAmount(amount))
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let category = value.as(String.self),
                               let categoryData = data.first(where: { $0.shortName == category }) {
                                HStack(spacing: 4) {
                                    Image(systemName: categoryData.icon)
                                        .font(.system(size: 8, weight: .medium))
                                        .foregroundColor(categoryData.color)
                                    
                                    Text(category)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func formatAmount(_ amount: Double) -> String {
        if amount >= 1000 {
            return String(format: "$%.1fK", amount / 1000)
        } else {
            return String(format: "$%.0f", amount)
        }
    }
}

struct TopCategoriesList: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    @EnvironmentObject private var categoryService: CategoryService
    @Binding var selectedCategory: CategorySpendingAnalysis?
    @Binding var showingDetail: Bool
    
    private var categoryAnalysis: [CategorySpendingAnalysis] {
        let expenses = dataManager.transactions.filter { $0.amount < 0 }
        let totalExpenses = expenses.reduce(0) { $0 + abs($1.amount) }
        let grouped = Dictionary(grouping: expenses) { $0.category }
        
        return grouped.map { categoryName, transactions in
            let amount = transactions.reduce(0) { $0 + abs($1.amount) }
            let percentage = totalExpenses > 0 ? (amount / totalExpenses) * 100 : 0
            let categoryObject = categoryService.categories.first { $0.name == categoryName }
            
            return CategorySpendingAnalysis(
                category: categoryName,
                amount: amount,
                percentage: percentage,
                categoryObject: categoryObject
            )
        }.sorted { $0.amount > $1.amount }.prefix(8).map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Spending Categories")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVStack(spacing: 12) {
                ForEach(categoryAnalysis) { category in
                    CategorySpendingRow(
                        category: category,
                        onTap: {
                            selectedCategory = category
                            showingDetail = true
                        }
                    )
                }
            }
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct CategorySpendingRow: View {
    let category: CategorySpendingAnalysis
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Category Icon
                ZStack {
                    Circle()
                        .fill(category.color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: category.icon)
                        .font(.title3)
                        .foregroundColor(category.color)
                }
                
                // Category Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.category)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("\(String(format: "%.1f", category.percentage))% of spending")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Amount and Arrow
                VStack(alignment: .trailing, spacing: 4) {
                    Text(category.formattedAmount)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .background(Color.clear)
    }
}



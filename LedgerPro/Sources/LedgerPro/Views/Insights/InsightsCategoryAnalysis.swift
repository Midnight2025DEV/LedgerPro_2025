//
//  InsightsCategoryAnalysis.swift
//  LedgerPro
//
//  Category-specific analysis components and data models for detailed
//  category insights and spending analysis
//

import SwiftUI
import Charts

// Extract lines 1326-1434 from InsightsView.swift
// This includes:
// - CategoryDetailInsightsView
// - EnhancedCategorySpending struct
// - Additional category analysis helpers

struct CategoryDetailInsightsView: View {
    let category: CategorySpendingAnalysis
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Category Header
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(category.color.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: category.icon)
                            .font(.title)
                            .foregroundColor(category.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.category)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(category.formattedAmount)
                            .font(.title3)
                            .foregroundColor(category.color)
                    }
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                Text("Detailed category insights coming soon...")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Category Details")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CategorySpendingAnalysis: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
    let percentage: Double
    let categoryObject: Category?
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    var icon: String {
        return categoryObject?.icon ?? "circle.fill"
    }
    
    var color: Color {
        if let categoryObject = categoryObject,
           let color = Color(hex: categoryObject.color) {
            return color
        }
        return .gray
    }
}

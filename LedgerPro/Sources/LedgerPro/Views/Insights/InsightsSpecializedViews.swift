//
//  InsightsSpecializedViews.swift
//  LedgerPro
//
//  Specialized insight views including AI insights, spending analysis,
//  and trend analysis components
//

import SwiftUI
import Charts

// Extract lines 596-804 from InsightsView.swift
// This includes:
// - SpendingInsightsView
// - TrendInsightsView
// - AIInsightsView
// - AIInsightCard
// Plus the AIInsight data model

struct SpendingInsightsView: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    @EnvironmentObject private var categoryService: CategoryService
    @State private var selectedPeriod: SpendingPeriod = .thisMonth
    @State private var selectedCategory: CategorySpendingAnalysis?
    @State private var showingCategoryDetail = false
    
    enum SpendingPeriod: String, CaseIterable {
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case last3Months = "Last 3 Months"
        case thisYear = "This Year"
    }
    
    var body: some View {
        LazyVStack(spacing: 24) {
            // Period Selector
            VStack(spacing: 16) {
                HStack {
                    Text("Spending Analysis")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(SpendingPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 150)
                }
                
                // Total spending card
                TotalSpendingCard(period: selectedPeriod)
            }
            
            // Enhanced Category Charts
            CategorySpendingCharts(
                selectedCategory: $selectedCategory,
                showingDetail: $showingCategoryDetail
            )
            
            // Top Categories List
            TopCategoriesList(
                selectedCategory: $selectedCategory,
                showingDetail: $showingCategoryDetail
            )
        }
        .padding()
        .sheet(item: $selectedCategory) { category in
            CategoryDetailInsightsView(category: category)
        }
    }
}

struct TrendInsightsView: View {
    var body: some View {
        VStack {
            Text("Trend Analysis")
                .font(.title)
            Text("Historical trend analysis coming soon...")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct AIInsightsView: View {
    let insights: [AIInsight]
    let isGenerating: Bool
    let onGenerateInsights: () -> Void
    
    var body: some View {
        LazyVStack(spacing: 16) {
            HStack {
                Text("AI-Powered Insights")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: onGenerateInsights) {
                    if isGenerating {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("Generate Insights")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isGenerating)
            }
            
            if insights.isEmpty && !isGenerating {
                VStack(spacing: 12) {
                    Image(systemName: "brain")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No AI insights generated yet")
                        .foregroundColor(.secondary)
                    Text("Click 'Generate Insights' to analyze your financial data")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            } else {
                ForEach(insights) { insight in
                    AIInsightCard(insight: insight)
                }
            }
        }
        .padding()
    }
}

struct AIInsightCard: View {
    let insight: AIInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: insight.type.systemImage)
                    .foregroundColor(insight.type.color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .font(.headline)
                    
                    Text(insight.category)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(insight.type.color.opacity(0.2))
                        .foregroundColor(insight.type.color)
                        .cornerRadius(4)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Confidence")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(Int(insight.confidence * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            
            Text(insight.description)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(insight.type.color.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(insight.type.color.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(8)
    }
}

// MARK: - Supporting Models
struct AIInsight: Identifiable, Codable {
    let id: UUID
    let type: InsightType
    let title: String
    let description: String
    let confidence: Double
    let category: String
    
    init(type: InsightType, title: String, description: String, confidence: Double, category: String) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.description = description
        self.confidence = confidence
        self.category = category
    }
    
    enum InsightType: String, Codable {
        case positive, warning, info
        
        var color: Color {
            switch self {
            case .positive: return .green
            case .warning: return .orange
            case .info: return .blue
            }
        }
        
        var systemImage: String {
            switch self {
            case .positive: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
}


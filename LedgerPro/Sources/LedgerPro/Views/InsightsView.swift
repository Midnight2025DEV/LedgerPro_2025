//
//  InsightsView.swift
//  LedgerPro
//
//  Main insights view container with tab navigation
//  Components are now modularized into separate files in Views/Insights/
//

import SwiftUI
import Charts

struct InsightsView: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    @EnvironmentObject private var apiService: APIService
    @EnvironmentObject private var categoryService: CategoryService
    @State private var selectedInsightTab: InsightTab = .overview
    @State private var isGeneratingInsights = false
    @State private var aiInsights: [AIInsight] = []
    
    enum InsightTab: String, CaseIterable {
        case overview = "Overview"
        case spending = "Spending"
        case trends = "Trends"
        case ai = "AI Analysis"
        
        var systemImage: String {
            switch self {
            case .overview: return "chart.bar.fill"
            case .spending: return "creditcard.fill"
            case .trends: return "chart.line.uptrend.xyaxis"
            case .ai: return "brain"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Enhanced Tab Picker
            VStack(spacing: 16) {
                HStack {
                    Text("Financial Insights")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: { 
                        generateAIInsights() 
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: isGeneratingInsights ? "arrow.clockwise" : "sparkles")
                                .font(.caption)
                            Text(isGeneratingInsights ? "Analyzing..." : "AI Insights")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(isGeneratingInsights)
                }
                
                // Custom Tab Picker
                HStack(spacing: 0) {
                    ForEach(InsightTab.allCases, id: \.self) { tab in
                        Button(action: { selectedInsightTab = tab }) {
                            VStack(spacing: 8) {
                                Image(systemName: tab.systemImage)
                                    .font(.title3)
                                    .foregroundColor(selectedInsightTab == tab ? .white : .secondary)
                                
                                Text(tab.rawValue)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(selectedInsightTab == tab ? .white : .secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedInsightTab == tab ? 
                                          LinearGradient(
                                            gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                          ) : 
                                          LinearGradient(
                                            gradient: Gradient(colors: [Color.clear]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                          )
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(NSColor.windowBackgroundColor))
            
            ScrollView {
                switch selectedInsightTab {
                case .overview:
                    InsightOverviewView()
                        .environmentObject(categoryService)
                case .spending:
                    SpendingInsightsView()
                        .environmentObject(categoryService)
                case .trends:
                    TrendInsightsView()
                        .environmentObject(categoryService)
                case .ai:
                    AIInsightsView(
                        insights: aiInsights,
                        isGenerating: isGeneratingInsights,
                        onGenerateInsights: generateAIInsights
                    )
                }
            }
        }
        .navigationTitle("")
        .onAppear {
            loadStoredInsights()
            Task {
                if categoryService.categories.isEmpty {
                    await categoryService.loadCategories()
                }
            }
        }
    }
    
    private func generateAIInsights() {
        isGeneratingInsights = true
        
        // Simulate AI analysis (in real app, this would call MCP servers)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            aiInsights = generateMockInsights()
            isGeneratingInsights = false
            saveInsights()
        }
    }
    
    private func generateMockInsights() -> [AIInsight] {
        let summary = dataManager.summary
        var insights: [AIInsight] = []
        
        // Spending Analysis
        if summary.totalExpenses > summary.totalIncome * 0.8 {
            insights.append(AIInsight(
                type: .warning,
                title: "High Spending Alert",
                description: "Your expenses are \(Int((summary.totalExpenses / summary.totalIncome) * 100))% of your income. Consider reviewing discretionary spending.",
                confidence: 0.9,
                category: "Spending"
            ))
        }
        
        // Savings Opportunity
        if summary.netSavings > 0 {
            insights.append(AIInsight(
                type: .positive,
                title: "Great Savings Performance",
                description: "You're saving \(summary.formattedSavings) this period. Consider investing in a high-yield savings account or index funds.",
                confidence: 0.85,
                category: "Savings"
            ))
        }
        
        // Category Analysis
        let categorySpending = analyzeCategorySpending()
        if let topCategory = categorySpending.first, topCategory.percentage > 30 {
            insights.append(AIInsight(
                type: .info,
                title: "Top Spending Category",
                description: "\(topCategory.category) accounts for \(Int(topCategory.percentage))% of your expenses (\(topCategory.formattedAmount)). This is your largest expense category.",
                confidence: 0.95,
                category: "Categories"
            ))
        }
        
        // Transaction Patterns
        let transactionCount = dataManager.transactions.count
        if transactionCount > 100 {
            insights.append(AIInsight(
                type: .info,
                title: "Transaction Volume Analysis",
                description: "You have \(transactionCount) transactions analyzed. Your average transaction is \(averageTransactionAmount()).",
                confidence: 0.8,
                category: "Patterns"
            ))
        }
        
        return insights
    }
    
    private func analyzeCategorySpending() -> [CategorySpendingAnalysis] {
        let expenses = dataManager.transactions.filter { $0.amount < 0 }
        let totalExpenses = expenses.reduce(0) { $0 + abs($1.amount) }
        
        let grouped = Dictionary(grouping: expenses) { $0.category }
        
        return grouped.map { categoryName, transactions in
            let amount = transactions.reduce(0) { $0 + abs($1.amount) }
            let percentage = totalExpenses > 0 ? (amount / totalExpenses) * 100 : 0
            
            // Try to find matching category from CategoryService for enhanced data
            let categoryObject = categoryService.categories.first { $0.name == categoryName }
            
            return CategorySpendingAnalysis(
                category: categoryName,
                amount: amount,
                percentage: percentage,
                categoryObject: categoryObject
            )
        }.sorted { $0.amount > $1.amount }
    }
    
    private func averageTransactionAmount() -> String {
        let total = dataManager.transactions.reduce(0) { $0 + abs($1.amount) }
        let average = total / Double(dataManager.transactions.count)
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: average)) ?? "$0.00"
    }
    
    private func loadStoredInsights() {
        if let data = UserDefaults.standard.data(forKey: "ai_insights") {
            do {
                aiInsights = try JSONDecoder().decode([AIInsight].self, from: data)
            } catch {
                AppLogger.shared.error("Failed to load insights: \(error)")
            }
        }
    }
    
    private func saveInsights() {
        do {
            let data = try JSONEncoder().encode(aiInsights)
            UserDefaults.standard.set(data, forKey: "ai_insights")
        } catch {
            AppLogger.shared.error("Failed to save insights: \(error)")
        }
    }
}

#Preview {
    NavigationView {
        InsightsView()
            .environmentObject(FinancialDataManager())
            .environmentObject(APIService())
    }
}
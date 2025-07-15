import SwiftUI
import Charts

struct LearningAnalyticsView: View {
    @StateObject private var learningService = PatternLearningService.shared
    @State private var stats: CorrectionStats?
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Analytics View", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Patterns").tag(1)
                    Text("Suggestions").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                TabView(selection: $selectedTab) {
                    // Overview Tab
                    overviewTab
                        .tag(0)
                    
                    // Patterns Tab
                    patternsTab
                        .tag(1)
                    
                    // Suggestions Tab
                    suggestionsTab
                        .tag(2)
                }
                .tabViewStyle(.automatic)
            }
            .navigationTitle("Smart Learning Analytics")
            .onAppear {
                stats = learningService.getCorrectionStats()
            }
            .refreshable {
                stats = learningService.getCorrectionStats()
            }
        }
    }
    
    // MARK: - Overview Tab
    
    private var overviewTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary Cards
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    LearningStatCard(
                        title: "Total Corrections",
                        value: "\(stats?.totalCorrections ?? 0)",
                        icon: "checkmark.circle.fill",
                        color: .blue
                    )
                    
                    LearningStatCard(
                        title: "Avg per Day",
                        value: String(format: "%.1f", stats?.averageCorrectionsPerDay ?? 0),
                        icon: "chart.line.uptrend.xyaxis",
                        color: .green
                    )
                    
                    LearningStatCard(
                        title: "Patterns Learned",
                        value: "\(learningService.patterns.count)",
                        icon: "brain",
                        color: .purple
                    )
                    
                    LearningStatCard(
                        title: "Success Rate",
                        value: String(format: "%.0f%%", (stats?.patternSuccessRate ?? 0) * 100),
                        icon: "target",
                        color: .orange
                    )
                }
                .padding(.horizontal)
                
                // Corrections Over Time Chart
                if let stats = stats, !stats.correctionsPerDay.isEmpty {
                    correctionsTrendChart(stats: stats)
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                
                // Learning Trends
                if let trends = stats?.learningTrends {
                    learningTrendsView(trends: trends)
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Patterns Tab
    
    private var patternsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Active Learning Patterns")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                
                if learningService.patterns.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "brain")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No Learning Patterns Yet")
                            .font(.headline)
                        
                        Text("As you correct transaction categories, LedgerPro will learn patterns to improve future suggestions.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(learningService.patterns.values.sorted(by: { $0.confidence > $1.confidence }), id: \.id) { pattern in
                            PatternRowView(pattern: pattern)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Suggestions Tab
    
    private var suggestionsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Rule Suggestions")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                
                if learningService.getRuleSuggestions().isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "lightbulb")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No Rule Suggestions")
                            .font(.headline)
                        
                        Text("Keep correcting transaction categories and LedgerPro will suggest rules to automate categorization.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(learningService.getRuleSuggestions(), id: \.id) { rule in
                            RuleSuggestionRowView(
                                rule: rule,
                                onAccept: { acceptRuleSuggestion(rule) },
                                onDismiss: { dismissRuleSuggestion(rule) }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Helper Views
    
    private func correctionsTrendChart(stats: CorrectionStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Corrections Over Time")
                .font(.headline)
            
            let sortedData = stats.correctionsPerDay.sorted { $0.key < $1.key }
            
            Chart(sortedData, id: \.key) { item in
                LineMark(
                    x: .value("Date", item.key),
                    y: .value("Corrections", item.value)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Date", item.key),
                    y: .value("Corrections", item.value)
                )
                .foregroundStyle(.blue.opacity(0.2))
                .interpolationMethod(.catmullRom)
            }
            .frame(height: 150)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7))
            }
        }
    }
    
    private func learningTrendsView(trends: LearningTrends) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Learning Trends")
                .font(.headline)
            
            HStack(spacing: 20) {
                TrendItem(
                    title: "Improving",
                    value: "\(trends.improvingPatterns)",
                    icon: "arrow.up.circle.fill",
                    color: .green
                )
                
                TrendItem(
                    title: "Declining",
                    value: "\(trends.decliningPatterns)",
                    icon: "arrow.down.circle.fill",
                    color: .red
                )
                
                TrendItem(
                    title: "New This Week",
                    value: "\(trends.newPatternsThisWeek)",
                    icon: "plus.circle.fill",
                    color: .blue
                )
            }
        }
    }
    
    // MARK: - Actions
    
    private func acceptRuleSuggestion(_ rule: CategoryRule) {
        if let pattern = learningService.patterns.values.first(where: { $0.pattern == rule.merchantContains }) {
            learningService.createRuleFromPattern(pattern)
            stats = learningService.getCorrectionStats() // Refresh stats
        }
    }
    
    private func dismissRuleSuggestion(_ rule: CategoryRule) {
        if let pattern = learningService.patterns.values.first(where: { $0.pattern == rule.merchantContains }) {
            learningService.dismissRuleSuggestion(pattern)
            stats = learningService.getCorrectionStats() // Refresh stats
        }
    }
}

// MARK: - Supporting Views

struct LearningStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
}

struct PatternRowView: View {
    let pattern: CorrectionPattern
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(pattern.pattern)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                
                Text(pattern.categoryName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Text("\(pattern.occurrenceCount)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "repeat")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text(String(format: "%.0f%%", pattern.confidence * 100))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(confidenceColor(pattern.confidence))
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.7 {
            return .green
        } else if confidence >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }
}

struct RuleSuggestionRowView: View {
    let rule: CategoryRule
    let onAccept: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(rule.merchantContains ?? "Unknown Pattern")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                
                Text("→ \(CategoryService.shared.categories.first(where: { $0.id == rule.categoryId })?.name ?? "Unknown")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button("Accept") {
                    onAccept()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Button("Dismiss") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct TrendItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    LearningAnalyticsView()
}
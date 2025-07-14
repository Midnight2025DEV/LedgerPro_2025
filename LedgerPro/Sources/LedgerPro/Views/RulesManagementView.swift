import SwiftUI

@available(macOS 13.0, *)
struct RulesManagementView: View {
    @StateObject private var viewModel = RuleViewModel()
    @State private var selectedRule: CategoryRule?
    @State private var showRuleBuilder = false
    @State private var showExportView = false
    @State private var showQuickStart = false
    
    var body: some View {
        NavigationSplitView {
            RulesListView(viewModel: viewModel, selectedRule: $selectedRule)
                .navigationTitle("Rules Management")
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button("Quick Start") {
                            showQuickStart = true
                        }
                        .help("Add rules from common templates")
                        
                        Button("New Rule") {
                            showRuleBuilder = true
                        }
                    }
                }
        } detail: {
            if let selectedRule {
                RuleDetailView(rule: selectedRule)
            } else {
                if #available(macOS 14.0, *) {
                    ContentUnavailableView("No Rule Selected", 
                                         systemImage: "doc.text")
                } else {
                    VStack {
                        Image(systemName: "doc.text")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No Rule Selected")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showRuleBuilder) {
            RuleBuilderView()
        }
        .sheet(isPresented: $showExportView) {
            RuleExportView(rules: viewModel.rules)
        }
        .sheet(isPresented: $showQuickStart) {
            QuickStartTemplatesView(viewModel: viewModel)
        }
    }
}

// MARK: - Rules List View
struct RulesListView: View {
    @ObservedObject var viewModel: RuleViewModel
    @Binding var selectedRule: CategoryRule?
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Bar
            Picker("View", selection: $selectedTab) {
                Text("Rules (\(viewModel.filteredRules.count))").tag(0)
                Text("Suggestions (\(viewModel.ruleSuggestions.count))").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.top)
            
            TabView(selection: $selectedTab) {
                // Rules Tab
                RulesTabView(viewModel: viewModel, selectedRule: $selectedRule)
                    .tag(0)
                
                // Suggestions Tab  
                SuggestionsTabView(viewModel: viewModel)
                    .tag(1)
            }
        }
    }
}

// MARK: - Rules Tab View
struct RulesTabView: View {
    @ObservedObject var viewModel: RuleViewModel
    @Binding var selectedRule: CategoryRule?
    
    var body: some View {
        VStack {
            // Search and Filter Bar
            HStack {
                TextField("Search rules...", text: $viewModel.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: viewModel.searchText) {
                        viewModel.applyFilters()
                    }
                
                Menu("Filter") {
                    Toggle("Active Only", isOn: $viewModel.filterActive)
                        .onChange(of: viewModel.filterActive) {
                            viewModel.applyFilters()
                        }
                    
                    Toggle("Custom Only", isOn: $viewModel.filterCustomOnly)
                        .onChange(of: viewModel.filterCustomOnly) {
                            viewModel.applyFilters()
                        }
                    
                    Picker("Sort By", selection: $viewModel.sortOrder) {
                        ForEach(RuleViewModel.SortOrder.allCases, id: \.self) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                    .onChange(of: viewModel.sortOrder) {
                        viewModel.applyFilters()
                    }
                }
            }
            .padding()
            
            // Rules List
            List(viewModel.filteredRules, id: \.id, selection: $selectedRule) { rule in
                RuleRowView(rule: rule)
                    .tag(rule)
            }
            .listStyle(PlainListStyle())
            .overlay {
                if viewModel.filteredRules.isEmpty {
                    if #available(macOS 14.0, *) {
                        ContentUnavailableView("No Rules Found", 
                                             systemImage: "magnifyingglass")
                    } else {
                        VStack {
                            Image(systemName: "magnifyingglass")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No Rules Found")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Suggestions Tab View
@available(macOS 13.0, *)
struct SuggestionsTabView: View {
    @ObservedObject var viewModel: RuleViewModel
    @EnvironmentObject private var categoryService: CategoryService
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Suggested Rules")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Based on transactions needing categorization")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Refresh") {
                    viewModel.refreshSuggestions()
                }
                .disabled(viewModel.isGeneratingSuggestions)
                
                Button("Clear Dismissed") {
                    viewModel.clearDismissedSuggestions()
                }
                .disabled(viewModel.isGeneratingSuggestions)
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Suggestions List
            if viewModel.isGeneratingSuggestions {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Analyzing transactions...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.ruleSuggestions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "lightbulb")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No Suggestions Available")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Import more transactions or adjust categorization")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.ruleSuggestions) { suggestion in
                            SuggestionCardView(
                                suggestion: suggestion,
                                categoryService: categoryService,
                                onCreateRule: { viewModel.createRuleFromSuggestion(suggestion) },
                                onDismiss: { viewModel.dismissSuggestion(suggestion) }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Rule Row View
struct RuleRowView: View {
    let rule: CategoryRule
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(rule.ruleName)
                    .font(.headline)
                    .foregroundColor(rule.isActive ? .primary : .secondary)
                
                Spacer()
                
                // Priority Badge
                Text("\(rule.priority)")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
            }
            
            Text(rule.ruleDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Text("Matches: \(rule.matchCount)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Confidence: \(Int(rule.confidence * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Rule Detail View
struct RuleDetailView: View {
    let rule: CategoryRule
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Rule Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(rule.ruleName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    HStack {
                        Label("Priority: \(rule.priority)", systemImage: "arrow.up")
                        Spacer()
                        Label("Confidence: \(Int(rule.confidence * 100))%", systemImage: "target")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Rule Conditions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Conditions")
                        .font(.headline)
                    
                    Text(rule.ruleDescription)
                        .font(.body)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Rule Statistics
                VStack(alignment: .leading, spacing: 12) {
                    Text("Statistics")
                        .font(.headline)
                    
                    HStack {
                        StatView(title: "Matches", value: "\(rule.matchCount)")
                        StatView(title: "Success Rate", value: "\(Int(rule.confidence * 100))%")
                        StatView(title: "Last Used", value: rule.lastMatched?.formatted(.dateTime.month().day()) ?? "Never")
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Rule Details")
        // .navigationBarTitleDisplayMode(.inline) // Not available on macOS
    }
}

// MARK: - Statistics View
struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Rule Builder View
struct RuleBuilderView: View {
    @StateObject private var builder = RuleBuilder()
    @StateObject private var ruleViewModel = RuleViewModel()
    @Environment(\.dismiss) var dismiss
    
    @State private var availableCategories: [Category] = []
    @State private var testTransactions: [Transaction] = []
    @State private var matchingTransactions: [Transaction] = []
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Information Section
                Section("Basic Information") {
                    // Rule Name
                    HStack {
                        Text("Rule Name")
                        Spacer()
                        TextField("Enter rule name", text: $builder.ruleName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 200)
                    }
                    
                    // Category Selection
                    HStack {
                        Text("Category")
                        Spacer()
                        Picker("Category", selection: $builder.categoryId) {
                            Text("Select Category").tag(nil as UUID?)
                            ForEach(availableCategories, id: \.id) { category in
                                HStack {
                                    Image(systemName: category.icon)
                                        .foregroundColor(category.swiftUIColor)
                                    Text(category.name)
                                }
                                .tag(category.id as UUID?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 200)
                    }
                    
                    // Priority Slider
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Priority")
                            Spacer()
                            Text("\(builder.priority)")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: Binding(
                            get: { Double(builder.priority) },
                            set: { builder.priority = Int($0) }
                        ), in: 0...100, step: 1)
                        .accentColor(.blue)
                        
                        HStack {
                            Text("Low")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("High")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Active Toggle
                    Toggle("Active", isOn: $builder.isActive)
                }
                
                // Merchant Rules Section
                Section("Merchant Rules") {
                    HStack {
                        Text("Contains")
                        Spacer()
                        TextField("e.g., STARBUCKS", text: $builder.merchantContains)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 200)
                    }
                    .help("Transaction description contains this text")
                    
                    HStack {
                        Text("Exact Match")
                        Spacer()
                        TextField("e.g., STARBUCKS #1234", text: $builder.merchantExact)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 200)
                    }
                    .help("Transaction description exactly matches this text")
                }
                
                // Description Rules Section
                Section("Description Rules") {
                    HStack {
                        Text("Contains")
                        Spacer()
                        TextField("e.g., SUBSCRIPTION", text: $builder.descriptionContains)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 200)
                    }
                    .help("Transaction description contains this additional text")
                }
                
                // Amount Rules Section
                Section("Amount Rules") {
                    HStack {
                        Text("Minimum Amount")
                        Spacer()
                        TextField("0.00", text: $builder.amountMin)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 100)
                        Text("$")
                    }
                    
                    HStack {
                        Text("Maximum Amount")
                        Spacer()
                        TextField("0.00", text: $builder.amountMax)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 100)
                        Text("$")
                    }
                    
                    Picker("Amount Type", selection: $builder.amountSign) {
                        ForEach(AmountSign.allCases, id: \.self) { sign in
                            Text(sign.displayName).tag(sign)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Validation Errors Section
                if !builder.validationErrors.isEmpty {
                    Section("Validation Issues") {
                        ForEach(builder.validationErrors, id: \.self) { error in
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                Text(error)
                                    .foregroundColor(.orange)
                                Spacer()
                            }
                        }
                    }
                }
                
                // Test Rule Section
                if builder.isValid && !testTransactions.isEmpty {
                    Section("Test Rule") {
                        HStack {
                            Text("Matching Transactions")
                            Spacer()
                            Text("\(matchingTransactions.count) of \(testTransactions.count)")
                                .foregroundColor(matchingTransactions.count > 0 ? .green : .secondary)
                                .fontWeight(.medium)
                        }
                        
                        if !matchingTransactions.isEmpty {
                            ForEach(matchingTransactions.prefix(3), id: \.id) { transaction in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(transaction.description)
                                        .font(.caption)
                                        .lineLimit(1)
                                    Text("$\(abs(transaction.amount), specifier: "%.2f")")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 2)
                            }
                            
                            if matchingTransactions.count > 3 {
                                Text("... and \(matchingTransactions.count - 3) more")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Create Rule")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let rule = builder.buildRule() {
                            ruleViewModel.saveRule(rule)
                            dismiss()
                        }
                    }
                    .disabled(!builder.isValid)
                }
            }
            .onAppear {
                availableCategories = ruleViewModel.getAvailableCategories()
                testTransactions = ruleViewModel.getSampleTransactions()
                updateMatchingTransactions()
            }
            .onChange(of: builder.ruleName) { updateMatchingTransactions() }
            .onChange(of: builder.merchantContains) { updateMatchingTransactions() }
            .onChange(of: builder.merchantExact) { updateMatchingTransactions() }
            .onChange(of: builder.descriptionContains) { updateMatchingTransactions() }
            .onChange(of: builder.amountMin) { updateMatchingTransactions() }
            .onChange(of: builder.amountMax) { updateMatchingTransactions() }
            .onChange(of: builder.amountSign) { updateMatchingTransactions() }
        }
    }
    
    private func updateMatchingTransactions() {
        guard builder.isValid else {
            matchingTransactions = []
            return
        }
        
        matchingTransactions = builder.testRule(against: testTransactions)
    }
}

// MARK: - Rule Export View (Placeholder)
struct RuleExportView: View {
    let rules: [CategoryRule]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Export Rules")
                    .font(.largeTitle)
                    .padding()
                
                Text("Export \(rules.count) rules")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Export Rules")
            // .navigationBarTitleDisplayMode(.inline) // Not available on macOS
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Export") {
                        // TODO: Export rules
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Quick Start Templates View
@available(macOS 13.0, *)
struct QuickStartTemplatesView: View {
    @ObservedObject var viewModel: RuleViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var categoryService: CategoryService
    
    @State private var selectedTemplates: Set<UUID> = []
    @State private var isAdding = false
    
    private var availableTemplates: [CategoryRule] {
        // Filter out templates that already exist as custom rules
        let existingRuleNames = Set(viewModel.rules.map { $0.ruleName.lowercased() })
        return CategoryRule.commonRuleTemplates.filter { template in
            !existingRuleNames.contains(template.ruleName.lowercased())
        }
    }
    
    private var groupedTemplates: [String: [CategoryRule]] {
        Dictionary(grouping: availableTemplates) { template in
            if let category = categoryService.categories.first(where: { $0.id == template.categoryId }) {
                return category.name
            }
            return "Other"
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Start Templates")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Select common merchant rules to add to your categorization system. These templates cover popular brands and services.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                
                // Templates List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(groupedTemplates.keys.sorted(), id: \.self) { categoryName in
                            TemplateGroupView(
                                categoryName: categoryName,
                                templates: groupedTemplates[categoryName] ?? [],
                                selectedTemplates: $selectedTemplates
                            )
                        }
                    }
                    .padding()
                }
                
                Divider()
                
                // Bottom Actions
                HStack {
                    Button("Select All") {
                        selectedTemplates = Set(availableTemplates.map { $0.id })
                    }
                    .disabled(availableTemplates.isEmpty)
                    
                    Button("Deselect All") {
                        selectedTemplates.removeAll()
                    }
                    .disabled(selectedTemplates.isEmpty)
                    
                    Spacer()
                    
                    Text("\(selectedTemplates.count) selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    
                    Button("Add Rules") {
                        addSelectedTemplates()
                    }
                    .disabled(selectedTemplates.isEmpty || isAdding)
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .frame(width: 700, height: 600)
            .navigationTitle("")
        }
    }
    
    private func addSelectedTemplates() {
        isAdding = true
        
        let templatesToAdd = availableTemplates.filter { selectedTemplates.contains($0.id) }
        
        for template in templatesToAdd {
            viewModel.saveRule(template)
        }
        
        isAdding = false
        dismiss()
    }
}

// MARK: - Template Group View
@available(macOS 13.0, *)
struct TemplateGroupView: View {
    let categoryName: String
    let templates: [CategoryRule]
    @Binding var selectedTemplates: Set<UUID>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(categoryName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(allSelected ? "Deselect All" : "Select All") {
                    if allSelected {
                        templates.forEach { selectedTemplates.remove($0.id) }
                    } else {
                        templates.forEach { selectedTemplates.insert($0.id) }
                    }
                }
                .font(.caption)
            }
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 250, maximum: 300), spacing: 12)
            ], spacing: 12) {
                ForEach(templates, id: \.id) { template in
                    TemplateCardView(
                        template: template,
                        isSelected: selectedTemplates.contains(template.id)
                    ) {
                        if selectedTemplates.contains(template.id) {
                            selectedTemplates.remove(template.id)
                        } else {
                            selectedTemplates.insert(template.id)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var allSelected: Bool {
        templates.allSatisfy { selectedTemplates.contains($0.id) }
    }
}

// MARK: - Template Card View
@available(macOS 13.0, *)
struct TemplateCardView: View {
    let template: CategoryRule
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Selection indicator
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(template.ruleName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                
                if let merchantContains = template.merchantContains {
                    Text("Matches: *\(merchantContains)*")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let regexPattern = template.regexPattern {
                    Text("Matches: \(regexPattern)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("Priority: \(template.priority)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
}

// MARK: - Suggestion Card View
@available(macOS 13.0, *)
struct SuggestionCardView: View {
    let suggestion: RuleSuggestion
    let categoryService: CategoryService
    let onCreateRule: () -> Void
    let onDismiss: () -> Void
    
    @MainActor
    private var suggestedCategory: Category? {
        categoryService.categories.first { $0.id == suggestion.suggestedCategory }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.merchantPattern)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(suggestion.transactionCount) transactions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Confidence Badge
                Text("\(Int(suggestion.confidence * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(confidenceColor.opacity(0.2))
                    .foregroundColor(confidenceColor)
                    .cornerRadius(6)
            }
            
            // Suggested Category
            HStack(spacing: 8) {
                Text("Suggested Category:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let category = suggestedCategory {
                    Text(category.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                } else {
                    Text("Unknown")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }
            
            // Transaction Details
            HStack {
                Text("Average Amount:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(NumberFormatter.currencyFormatter.string(from: suggestion.averageAmount as NSDecimalNumber) ?? "$0.00")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("Examples:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(min(suggestion.exampleTransactions.count, 3))")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            // Example Transactions (first 2)
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(suggestion.exampleTransactions.prefix(2)), id: \.id) { transaction in
                    HStack {
                        Text(transaction.description.prefix(35))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(transaction.formattedAmount)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(transaction.amount < 0 ? .red : .green)
                    }
                }
            }
            .padding(.top, 4)
            
            // Action Buttons
            HStack(spacing: 12) {
                Button("Dismiss") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Create Rule") {
                    onCreateRule()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var confidenceColor: Color {
        if suggestion.confidence >= 0.8 {
            return .green
        } else if suggestion.confidence >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
}


#Preview {
    RulesManagementView()
}

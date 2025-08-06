import SwiftUI

struct CreateBudgetView: View {
    @Environment(\.dismiss) private var dismiss
    let budgetManager: BudgetManager
    
    @State private var name = ""
    @State private var selectedCategory = ""
    @State private var amount = ""
    @State private var period: BudgetPeriod = .monthly
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var alertThreshold: Double = 0.8
    @State private var selectedColor = "#007AFF"
    @State private var description = ""
    @State private var useCustomPeriod = false
    
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let availableColors = [
        "#007AFF", "#34C759", "#FF9500", "#FF3B30", 
        "#5856D6", "#AF52DE", "#FF2D92", "#A2845E"
    ]
    
    private var availableCategories: [String] {
        // Get unique categories from transactions, plus some common ones
        // Note: This should ideally come from dataManager.transactions but for now use static list
        let transactionCategories: Set<String> = []
        
        let commonCategories = [
            "All Categories",
            "Food & Dining",
            "Groceries", 
            "Transportation",
            "Shopping",
            "Bills & Utilities",
            "Entertainment",
            "Healthcare",
            "Travel",
            "Education",
            "Personal Care",
            "Home & Garden",
            "Other Expenses"
        ]
        
        return Array(Set(commonCategories + Array(transactionCategories))).sorted()
    }
    
    private var formattedAmount: Double? {
        let cleanAmount = amount.replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
        return Double(cleanAmount)
    }
    
    private var isValidForm: Bool {
        !name.isEmpty && 
        !selectedCategory.isEmpty && 
        formattedAmount != nil && 
        formattedAmount! > 0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            Divider()
            
            // Form
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    basicInfoSection
                    amountSection
                    periodSection
                    customizationSection
                    alertSection
                }
                .padding()
            }
            
            Divider()
            
            // Actions
            actionButtons
        }
        .frame(width: 600, height: 700)
        .onAppear {
            if selectedCategory.isEmpty {
                selectedCategory = availableCategories.first ?? "All Categories"
            }
            updateEndDate()
        }
        .onChange(of: period) {
            updateEndDate()
        }
        .onChange(of: startDate) {
            updateEndDate()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Create Budget")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
            
            Text("Set spending limits and track your financial goals")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Information")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Budget Name", systemImage: "textformat")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("e.g., Monthly Food Budget", text: $name)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("Category", systemImage: "folder")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(availableCategories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
    }
    
    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Budget Amount")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Amount", systemImage: "dollarsign.circle")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    TextField("0.00", text: $amount)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 150)
                    
                    Text("USD")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
        }
    }
    
    private var periodSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Budget Period")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                Picker("Period", selection: $period) {
                    ForEach(BudgetPeriod.allCases.filter { $0 != .custom }, id: \.self) { period in
                        Label(period.rawValue, systemImage: period.systemImage)
                            .tag(period)
                    }
                }
                .pickerStyle(.segmented)
                
                Toggle("Custom Date Range", isOn: $useCustomPeriod)
                    .onChange(of: useCustomPeriod) {
                        if useCustomPeriod {
                            period = .custom
                        } else {
                            period = .monthly
                        }
                        updateEndDate()
                    }
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start Date")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .datePickerStyle(.field)
                            .labelsHidden()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("End Date")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if useCustomPeriod {
                            DatePicker("", selection: $endDate, displayedComponents: .date)
                                .datePickerStyle(.field)
                                .labelsHidden()
                        } else {
                            Text(endDate.formatted(.dateTime.month().day().year()))
                                .foregroundColor(.secondary)
                                .frame(height: 22)
                        }
                    }
                }
            }
        }
    }
    
    private var customizationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Customization")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Color", systemImage: "paintpalette")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                        ForEach(availableColors, id: \.self) { colorHex in
                            Circle()
                                .fill(Color(hex: colorHex) ?? .blue)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColor == colorHex ? 2 : 0)
                                )
                                .onTapGesture {
                                    selectedColor = colorHex
                                }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("Description (Optional)", systemImage: "note.text")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextEditor(text: $description)
                        .font(.system(.body))
                        .frame(height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                        )
                }
            }
        }
    }
    
    private var alertSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Alert Settings")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Alert Threshold", systemImage: "bell")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(Int(alertThreshold * 100))%")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $alertThreshold, in: 0.5...1.0, step: 0.05)
                    
                    Text("Get notified when you've spent \(Int(alertThreshold * 100))% of your budget")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var actionButtons: some View {
        HStack {
            if showError {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Spacer()
            
            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.escape, modifiers: [])
            
            Button("Create Budget") {
                createBudget()
            }
            .keyboardShortcut(.return, modifiers: [])
            .buttonStyle(.borderedProminent)
            .disabled(!isValidForm)
        }
        .padding()
    }
    
    private func updateEndDate() {
        if !useCustomPeriod {
            endDate = period.calculateEndDate(from: startDate)
        }
    }
    
    @MainActor
    private func createBudget() {
        guard let amount = formattedAmount else {
            showError = true
            errorMessage = "Please enter a valid amount"
            return
        }
        
        let budget = Budget(
            name: name,
            category: selectedCategory,
            amount: amount,
            period: period,
            startDate: startDate,
            alertThreshold: alertThreshold,
            color: selectedColor,
            description: description.isEmpty ? nil : description
        )
        
        budgetManager.createBudget(budget)
        dismiss()
    }
}

#Preview {
    CreateBudgetView(budgetManager: BudgetManager(dataManager: FinancialDataManager()))
}
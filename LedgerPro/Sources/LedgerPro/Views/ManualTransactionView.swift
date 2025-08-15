import SwiftUI

struct ManualTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: FinancialDataManager
    @EnvironmentObject var categoryService: CategoryService
    
    @State private var date = Date()
    @State private var description = ""
    @State private var amount = ""
    @State private var isDebit = true
    @State private var selectedCategory = ""
    @State private var merchant = ""
    @State private var notes = ""
    @State private var accountName = "Manual Entry"
    
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var categories: [String] {
        let allCategories = categoryService.categories.map { $0.name }
        return allCategories.sorted()
    }
    
    private var formattedAmount: Double? {
        let cleanAmount = amount.replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
        return Double(cleanAmount)
    }
    
    private var isValidForm: Bool {
        !description.isEmpty && formattedAmount != nil && formattedAmount! > 0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Add Transaction")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .keyboardShortcut(.escape, modifiers: [])
                }
                
                Text("Manually add a transaction to your records")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Form
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Date
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Date", systemImage: "calendar")
                            .font(.headline)
                        
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.field)
                            .labelsHidden()
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Description", systemImage: "text.alignleft")
                            .font(.headline)
                        
                        TextField("e.g., Grocery shopping, Electric bill", text: $description)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Amount
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Amount", systemImage: "dollarsign.circle")
                            .font(.headline)
                        
                        HStack {
                            TextField("0.00", text: $amount)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)
                                .onChange(of: amount) {
                                    // Format as currency while typing
                                    if let value = formattedAmount {
                                        amount = String(format: "%.2f", value)
                                    }
                                }
                            
                            Picker("", selection: $isDebit) {
                                Text("Expense").tag(true)
                                Text("Income").tag(false)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 200)
                        }
                    }
                    
                    // Category
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Category", systemImage: "tag")
                            .font(.headline)
                        
                        Picker("Select a category", selection: $selectedCategory) {
                            Text("None").tag("")
                            Divider()
                            ForEach(categories, id: \.self) { category in
                                Text(category).tag(category)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 300)
                    }
                    
                    // Merchant (optional)
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Merchant (Optional)", systemImage: "building.2")
                            .font(.headline)
                        
                        TextField("e.g., Walmart, Amazon", text: $merchant)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Account
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Account", systemImage: "creditcard")
                            .font(.headline)
                        
                        TextField("e.g., Checking, Credit Card", text: $accountName)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Notes (optional)
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Notes (Optional)", systemImage: "note.text")
                            .font(.headline)
                        
                        TextEditor(text: $notes)
                            .font(.system(.body))
                            .frame(height: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                            )
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Actions
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
                
                Button("Add Transaction") {
                    addTransaction()
                }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
                .disabled(!isValidForm)
            }
            .padding()
        }
        .frame(width: 600, height: 700)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func addTransaction() {
        guard let amount = formattedAmount else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        let transaction = Transaction(
            id: nil,
            date: dateString,
            description: description.isEmpty ? "Manual Entry" : description,
            amount: isDebit ? -abs(amount) : abs(amount),
            category: selectedCategory.isEmpty ? (isDebit ? "Other Expenses" : "Income") : selectedCategory,
            confidence: 1.0
        )
        
        dataManager.transactions.append(transaction)
        // Data is automatically saved by the @Published property
        
        // Note: Category learning would go here if available
        
        dismiss()
    }
}

struct ManualTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        ManualTransactionView()
            .environmentObject(FinancialDataManager())
            .environmentObject(CategoryService.shared)
    }
}
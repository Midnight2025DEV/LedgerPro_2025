import SwiftUI

/// View for adding new categories to the system
struct AddCategoryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var categoryService: CategoryService
    
    // Form fields
    @State private var name = ""
    @State private var selectedIcon = "📁"
    @State private var customColor = Color.blue
    @State private var selectedParentId: UUID?
    @State private var budgetAmount = ""
    @State private var isCustomIcon = false
    @State private var customIconText = ""
    
    // UI state
    @State private var isCreating = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingIconPicker = false
    
    // Predefined icons for common categories
    private let commonIcons = [
        "📁", "💰", "🏠", "🚗", "🍔", "🛒", "🎬", "✈️", "🏥", "📚",
        "💡", "🎮", "👕", "☕", "🏃", "💳", "📱", "🎵", "🍕", "🛠️",
        "🏦", "📊", "🎯", "🎨", "📖", "🏖️", "🚀", "💎", "🌟", "🔧"
    ]
    
    var availableParentCategories: [Category] {
        // Only show categories that can have children (typically root categories)
        return categoryService.rootCategories.filter { $0.isActive }
    }
    
    var selectedParentCategory: Category? {
        guard let parentId = selectedParentId else { return nil }
        return categoryService.category(by: parentId)
    }
    
    var isFormValid: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !finalIcon.isEmpty
    }
    
    var finalIcon: String {
        return isCustomIcon ? customIconText.trimmingCharacters(in: .whitespacesAndNewlines) : selectedIcon
    }
    
    var finalColor: String {
        return customColor.hexString
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Information Section
                Section("Basic Information") {
                    TextField("Category Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                    
                    // Icon Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Icon")
                            .font(.headline)
                        
                        HStack {
                            Toggle("Custom Icon", isOn: $isCustomIcon)
                            
                            Spacer()
                            
                            Text(finalIcon)
                                .font(.title2)
                                .frame(width: 40, height: 40)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        if isCustomIcon {
                            TextField("Enter emoji or symbol", text: $customIconText)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            Button("Choose Icon") {
                                showingIconPicker = true
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    // Color Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(.headline)
                        
                        HStack {
                            ColorPicker("Category Color", selection: $customColor, supportsOpacity: false)
                                .labelsHidden()
                                .frame(width: 40, height: 40)
                            
                            Text(finalColor)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            // Color preview
                            Circle()
                                .fill(customColor)
                                .frame(width: 24, height: 24)
                        }
                    }
                }
                
                // Hierarchy Section
                Section("Category Hierarchy") {
                    Picker("Parent Category", selection: $selectedParentId) {
                        Text("None (Top Level Category)")
                            .tag(nil as UUID?)
                        
                        ForEach(availableParentCategories) { category in
                            HStack {
                                Text(category.icon)
                                Text(category.name)
                            }
                            .tag(category.id as UUID?)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    if let parent = selectedParentCategory {
                        HStack {
                            Text("Will be created under:")
                            Spacer()
                            HStack(spacing: 4) {
                                Text(parent.icon)
                                Text(parent.name)
                            }
                            .foregroundColor(.blue)
                        }
                        .font(.caption)
                    }
                }
                
                // Budget Section
                Section("Budget (Optional)") {
                    TextField("Monthly Budget Amount", text: $budgetAmount)
                        .textFieldStyle(.roundedBorder)
                    
                    Text("Leave empty if no budget tracking needed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Preview Section
                Section("Preview") {
                    CategoryPreviewRow(
                        name: name.isEmpty ? "Category Name" : name,
                        icon: finalIcon,
                        color: customColor,
                        parentName: selectedParentCategory?.name
                    )
                }
            }
            .navigationTitle("Add Category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createCategory()
                    }
                    .disabled(!isFormValid || isCreating)
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                IconPickerView(selectedIcon: $selectedIcon)
            }
            .alert("Error Creating Category", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
        .frame(width: 600, height: 750)
    }
    
    // MARK: - Actions
    
    private func createCategory() {
        guard isFormValid else { return }
        
        isCreating = true
        
        Task {
            do {
                // Parse budget amount if provided
                var budget: Decimal?
                if !budgetAmount.isEmpty,
                   let budgetValue = Double(budgetAmount) {
                    budget = Decimal(budgetValue)
                }
                
                // Create new category
                let newCategory = Category(
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    icon: finalIcon,
                    color: finalColor,
                    parentId: selectedParentId,
                    isSystem: false,
                    budgetAmount: budget
                )
                
                try await categoryService.createCategory(newCategory)
                
                await MainActor.run {
                    isCreating = false
                    dismiss()
                }
                
            } catch {
                await MainActor.run {
                    isCreating = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Category Preview Row

struct CategoryPreviewRow: View {
    let name: String
    let icon: String
    let color: Color
    let parentName: String?
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Text(icon)
                .font(.title3)
            
            // Color indicator
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body)
                    .fontWeight(.medium)
                
                if let parentName = parentName {
                    Text("Under: \(parentName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text("CUSTOM")
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.green.opacity(0.2))
                .foregroundColor(.green)
                .cornerRadius(4)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Icon Picker View

struct IconPickerView: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) var dismiss
    
    private let commonIcons = [
        "📁", "💰", "🏠", "🚗", "🍔", "🛒", "🎬", "✈️", "🏥", "📚",
        "💡", "🎮", "👕", "☕", "🏃", "💳", "📱", "🎵", "🍕", "🛠️",
        "🏦", "📊", "🎯", "🎨", "📖", "🏖️", "🚀", "💎", "🌟", "🔧",
        "🎪", "🎭", "🎨", "🎯", "🎲", "🎹", "🎸", "🎤", "🎧", "🎬"
    ]
    
    private let sfSymbols = [
        "folder.fill", "dollarsign.circle.fill", "house.fill", "car.fill",
        "cart.fill", "bag.fill", "tv.fill", "airplane", "cross.fill",
        "book.fill", "lightbulb.fill", "gamecontroller.fill", "tshirt.fill",
        "cup.and.saucer.fill", "figure.run", "creditcard.fill", "iphone",
        "music.note", "fork.knife", "wrench.fill"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 16) {
                    // Emoji icons
                    ForEach(commonIcons, id: \.self) { icon in
                        Button(action: {
                            selectedIcon = icon
                            dismiss()
                        }) {
                            Text(icon)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(selectedIcon == icon ? Color.blue.opacity(0.2) : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedIcon == icon ? Color.blue : Color.clear, lineWidth: 2)
                                )
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // SF Symbols
                    ForEach(sfSymbols, id: \.self) { symbol in
                        Button(action: {
                            selectedIcon = symbol
                            dismiss()
                        }) {
                            Image(systemName: symbol)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(selectedIcon == symbol ? Color.blue.opacity(0.2) : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedIcon == symbol ? Color.blue : Color.clear, lineWidth: 2)
                                )
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Icon")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 400, height: 500)
    }
}

// Color extension is defined in Category.swift

#Preview {
    AddCategoryView()
}
import SwiftUI

// MARK: - Category Filter Picker Popup
struct CategoryFilterPickerPopup: View {
    @Binding var selectedCategory: Category?
    @Binding var isPresented: Bool
    
    @EnvironmentObject private var categoryService: CategoryService
    @State private var searchText = ""
    
    var body: some View {
        ZStack {
            // Background overlay - tap to dismiss
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // The actual popup
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    HStack {
                        Text("Filter by Category")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button(action: { isPresented = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .imageScale(.large)
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut(.escape)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Search bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .imageScale(.medium)
                        
                        TextField("Search categories...", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.body)
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .imageScale(.small)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
                }
                .background(Color(NSColor.windowBackgroundColor))
                
                Divider()
                
                // Category list
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        // All Categories option
                        CategoryFilterItem(
                            category: nil,
                            isSelected: selectedCategory == nil,
                            onSelect: {
                                selectedCategory = nil
                                isPresented = false
                            }
                        )
                        
                        // Root categories
                        ForEach(filteredCategories) { category in
                            CategoryFilterItem(
                                category: category,
                                isSelected: selectedCategory?.id == category.id,
                                onSelect: {
                                    selectedCategory = category
                                    isPresented = false
                                }
                            )
                        }
                    }
                    .padding(20)
                }
            }
            .frame(width: 400, height: 500)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 8)
            .onTapGesture {} // Prevent taps on popup from closing
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var filteredCategories: [Category] {
        if searchText.isEmpty {
            return categoryService.rootCategories
        } else {
            return categoryService.categories.filter { category in
                category.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// MARK: - Category Filter Item
struct CategoryFilterItem: View {
    let category: Category?
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: category?.icon ?? "folder.fill")
                    .font(.title3)
                    .foregroundColor(category.flatMap { Color(hex: $0.color) } ?? .secondary)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category?.name ?? "All Categories")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if let category = category {
                        Text(category.isSystem ? "System Category" : "Custom Category")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Show all transactions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
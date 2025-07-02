import SwiftUI

/// Test view for the category system - displays hierarchical categories with management features
struct CategoryTestView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var categoryService = CategoryService.shared
    @State private var showAddCategory = false
    @State private var selectedCategory: Category?
    @State private var showCategoryDetails = false
    @State private var searchText = ""
    
    var filteredCategories: [Category] {
        if searchText.isEmpty {
            return categoryService.rootCategories
        } else {
            return categoryService.categories.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with stats
            CategoryStatsView(categoryService: categoryService)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 40)
            
            Divider()
            
            // Search bar
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    TextField("Search categories...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 15))
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
            
            Divider()
            
            // Category list
            if categoryService.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    Text("Loading categories...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if categoryService.categories.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No categories found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Categories will be initialized automatically")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Reload Categories") {
                        Task {
                            await categoryService.loadCategories()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 280, maximum: .infinity), spacing: 16),
                        GridItem(.adaptive(minimum: 280, maximum: .infinity), spacing: 16),
                        GridItem(.adaptive(minimum: 280, maximum: .infinity), spacing: 16)
                    ], spacing: 16) {
                        ForEach(categoryService.rootCategories) { rootCategory in
                            VStack(spacing: 0) {
                                // Root category card
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        ZStack {
                                            Circle()
                                                .fill(Color(hex: rootCategory.color)?.opacity(0.2) ?? Color.gray.opacity(0.2))
                                                .frame(width: 56, height: 56)
                                            
                                            Text(rootCategory.icon)
                                                .font(.system(size: 28))
                                        }
                                        
                                        Spacer()
                                        
                                        if rootCategory.isSystem {
                                            Label("System", systemImage: "lock.fill")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.secondary.opacity(0.1))
                                                .cornerRadius(6)
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(rootCategory.name)
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                        
                                        Text("\(rootCategory.children?.count ?? 0) subcategories")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                .onTapGesture {
                                    selectedCategory = rootCategory
                                    showCategoryDetails = true
                                }
                                
                                // Subcategories if available
                                if let children = rootCategory.children, !children.isEmpty {
                                    VStack(spacing: 8) {
                                        ForEach(children) { child in
                                            HStack {
                                                Text(child.icon)
                                                    .font(.system(size: 16))
                                                
                                                Text(child.name)
                                                    .font(.subheadline)
                                                    .foregroundColor(.primary)
                                                
                                                Spacer()
                                                
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                                            .cornerRadius(8)
                                            .onTapGesture {
                                                selectedCategory = child
                                                showCategoryDetails = true
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 20)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        .navigationTitle("Category System Test")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                // Refresh button
                Button(action: {
                    Task { await categoryService.loadCategories() }
                }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(categoryService.isLoading)
                
                // Add category button
                Button(action: { showAddCategory = true }) {
                    Label("Add Category", systemImage: "plus.circle.fill")
                }
                
                // Reset button (for testing)
                Button(action: {
                    Task { await categoryService.resetCategories() }
                }) {
                    Label("Reset", systemImage: "trash.circle")
                }
                .foregroundColor(.red)
            }
        }
        .sheet(isPresented: $showAddCategory) {
            AddCategoryView()
        }
        .sheet(isPresented: $showCategoryDetails) {
            if let category = selectedCategory {
                CategoryDetailView(category: category)
            }
        }
        .frame(minWidth: 1200, minHeight: 700)
        .onAppear {
            Task {
                await categoryService.loadCategories()
            }
        }
    }
    
    // MARK: - Category Stats View
    
    struct CategoryStatsView: View {
        @ObservedObject var categoryService: CategoryService
        
        var systemCategoriesCount: Int {
            categoryService.categories.filter { $0.isSystem }.count
        }
        
        var customCategoriesCount: Int {
            categoryService.categories.filter { !$0.isSystem }.count
        }
        
        var body: some View {
            HStack(spacing: 20) {
                StatCard(
                    title: "Total Categories",
                    value: "\(categoryService.categories.count)",
                    icon: "folder.fill",
                    gradient: [Color.blue, Color.blue.opacity(0.7)]
                )
                
                StatCard(
                    title: "Root Categories", 
                    value: "\(categoryService.rootCategories.count)",
                    icon: "folder.fill.badge.plus",
                    gradient: [Color.green, Color.green.opacity(0.7)]
                )
                
                StatCard(
                    title: "System Categories",
                    value: "\(systemCategoriesCount)",
                    icon: "gearshape.fill",
                    gradient: [Color.orange, Color.orange.opacity(0.7)]
                )
                
                StatCard(
                    title: "Custom Categories",
                    value: "\(customCategoriesCount)",
                    icon: "person.crop.circle.fill.badge.plus",
                    gradient: [Color.purple, Color.purple.opacity(0.7)]
                )
            }
            .padding(.vertical, 24)
        }
    }
    
    struct StatCard: View {
        let title: String
        let value: String
        let icon: String
        let gradient: [Color]
        
        var body: some View {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: gradient),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(height: 120)
                    
                    VStack(spacing: 8) {
                        Image(systemName: icon)
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                        
                        Text(value)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(title)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .shadow(color: gradient[0].opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }
    
    // MARK: - Category Row View
    
    struct CategoryRowView: View {
        let category: Category
        let level: Int
        let categoryService: CategoryService
        let onCategoryTapped: (Category) -> Void
        var showHierarchyPath: Bool = false
        
        @State private var isExpanded = true
        
        private var children: [Category] {
            category.children ?? []
        }
        
        private var hasChildren: Bool {
            !children.isEmpty
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                // Main category row
                HStack(spacing: 12) {
                    // Color indicator
                    Circle()
                        .fill(Color(hex: category.color) ?? .gray)
                        .frame(width: 24, height: 24)
                    
                    // Icon
                    Text(category.icon)
                        .font(.title3)
                        .frame(width: 28)
                    
                    // Name and info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.name)
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(1)
                        
                        HStack(spacing: 6) {
                            if let childCount = category.children?.count, childCount > 0 {
                                Text("\(childCount) subcategories")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            if category.isSystem {
                                Text("SYSTEM")
                                    .font(.caption2)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .cornerRadius(3)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Debug ID
                    Text(String(category.id.uuidString.prefix(6)))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.clear, lineWidth: 2)
                )
                .onTapGesture {
                    onCategoryTapped(category)
                }
                
                // Child categories
                if isExpanded && hasChildren && !showHierarchyPath {
                    VStack(spacing: 2) {
                        ForEach(children) { child in
                            CategoryRowView(
                                category: child,
                                level: level + 1,
                                categoryService: categoryService,
                                onCategoryTapped: onCategoryTapped
                            )
                            .padding(.leading, 20)
                        }
                    }
                }
            }
            .padding(.horizontal, level > 0 ? 8 : 4)
        }
    }
    
    // MARK: - Category Detail View
    
    struct CategoryDetailView: View {
        let category: Category
        @Environment(\.dismiss) var dismiss
        @StateObject private var categoryService = CategoryService.shared
        
        var body: some View {
            NavigationStack {
                VStack {
                    Form {
                        Section {
                            VStack(alignment: .leading, spacing: 16) {
                                // Name with icon
                                HStack(spacing: 12) {
                                    Image(systemName: category.icon)
                                        .font(.system(size: 36))
                                        .foregroundColor(Color(hex: category.color) ?? .blue)
                                        .frame(width: 50, height: 50)
                                        .background(Color(hex: category.color)?.opacity(0.15) ?? Color.blue.opacity(0.15))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(category.name)
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                        Text(category.isSystem ? "System Category" : "Custom Category")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                
                                Divider()
                                
                                // Icon and Color Info
                                HStack(spacing: 40) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("ICON")
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                        HStack(spacing: 8) {
                                            Image(systemName: category.icon)
                                                .font(.title3)
                                                .foregroundColor(Color(hex: category.color) ?? .blue)
                                            Text(category.icon)
                                                .font(.callout)
                                                .foregroundColor(.primary)
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("COLOR")
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                        HStack(spacing: 8) {
                                            Circle()
                                                .fill(Color(hex: category.color) ?? .gray)
                                                .frame(width: 20, height: 20)
                                            Text(category.color.uppercased())
                                                .font(.system(.callout, design: .monospaced))
                                                .foregroundColor(.primary)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        } header: {
                            Text("Overview")
                                .font(.headline)
                        }
                        
                        Section {
                            VStack(spacing: 12) {
                                InfoRow(label: "Category ID", value: category.id.uuidString, isMonospaced: true)
                                
                                if let parentId = category.parentId {
                                    InfoRow(label: "Parent ID", value: parentId.uuidString, isMonospaced: true)
                                    InfoRow(label: "Full Path", value: categoryService.hierarchyPath(for: category.id))
                                } else {
                                    InfoRow(label: "Level", value: "Root Category", valueColor: .blue)
                                }
                                
                                if let children = category.children, !children.isEmpty {
                                    InfoRow(label: "Subcategories", value: "\(children.count)", valueColor: .orange)
                                }
                            }
                        } header: {
                            Text("Hierarchy")
                                .font(.headline)
                        }
                        
                        Section {
                            VStack(spacing: 12) {
                                InfoRow(label: "Sort Order", value: "\(category.sortOrder)")
                                InfoRow(label: "Status", value: category.isActive ? "Active" : "Inactive", valueColor: category.isActive ? .green : .red)
                                if let budget = category.budgetAmount {
                                    InfoRow(label: "Budget", value: "$\(budget)", valueColor: .blue)
                                }
                            }
                        } header: {
                            Text("Settings")
                                .font(.headline)
                        }
                        
                        Section {
                            VStack(spacing: 12) {
                                InfoRow(label: "Created", value: formatDate(category.createdAt))
                                InfoRow(label: "Last Updated", value: formatDate(category.updatedAt))
                            }
                        } header: {
                            Text("Activity")
                                .font(.headline)
                        }
                    }
                    .formStyle(.grouped)
                    .frame(maxWidth: 600)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("Category Details")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
            .frame(minWidth: 900, idealWidth: 1000, minHeight: 400, idealHeight: 600)
        }
        
        // Helper function for date formatting
        private func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
    
    // Helper view for info rows
    struct InfoRow: View {
        let label: String
        let value: String
        var valueColor: Color = .primary
        var isMonospaced: Bool = false
        
        var body: some View {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 120, alignment: .leading)
                
                Text(value)
                    .font(isMonospaced ? .system(.caption, design: .monospaced) : .subheadline)
                    .foregroundColor(valueColor)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    // #Preview("Category Test View") {
    //     CategoryTestView()
    //         .frame(width: 1200, height: 800)
    // }
}

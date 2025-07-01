import SwiftUI

/// Test view for the category system - displays hierarchical categories with management features
struct CategoryTestView: View {
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
        NavigationView {
            VStack(spacing: 0) {
                // Header with stats
                CategoryStatsView(categoryService: categoryService)
                
                Divider()
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search categories...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(NSColor.controlBackgroundColor))
                
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
                    List {
                        if searchText.isEmpty {
                            // Hierarchical view
                            ForEach(filteredCategories) { category in
                                CategoryRowView(
                                    category: category, 
                                    level: 0,
                                    categoryService: categoryService,
                                    onCategoryTapped: { selectedCategory = $0; showCategoryDetails = true }
                                )
                            }
                        } else {
                            // Flat search results
                            ForEach(filteredCategories) { category in
                                CategoryRowView(
                                    category: category, 
                                    level: 0,
                                    categoryService: categoryService,
                                    onCategoryTapped: { selectedCategory = $0; showCategoryDetails = true },
                                    showHierarchyPath: true
                                )
                            }
                        }
                    }
                    .listStyle(.sidebar)
                }
            }
            .navigationTitle("Category System Test")
            .toolbar {
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
        }
        .frame(minWidth: 900, minHeight: 600)
        .onAppear {
            Task {
                await categoryService.loadCategories()
            }
        }
    }
}

// MARK: - Category Stats View

struct CategoryStatsView: View {
    let categoryService: CategoryService
    
    var systemCategoriesCount: Int {
        categoryService.categories.filter { $0.isSystem }.count
    }
    
    var customCategoriesCount: Int {
        categoryService.categories.filter { !$0.isSystem }.count
    }
    
    var body: some View {
        HStack(spacing: 24) {
            CategoryStatCard(
                title: "Total Categories",
                value: "\(categoryService.categories.count)",
                icon: "folder",
                color: .blue
            )
            
            CategoryStatCard(
                title: "Root Categories",
                value: "\(categoryService.rootCategories.count)",
                icon: "folder.fill",
                color: .green
            )
            
            CategoryStatCard(
                title: "System Categories",
                value: "\(systemCategoriesCount)",
                icon: "gear",
                color: .orange
            )
            
            CategoryStatCard(
                title: "Custom Categories",
                value: "\(customCategoriesCount)",
                icon: "person.crop.circle",
                color: .purple
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct CategoryStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
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
                // Indentation for hierarchy
                if level > 0 && !showHierarchyPath {
                    ForEach(0..<level, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 20)
                    }
                }
                
                // Expand/collapse button
                if hasChildren && !showHierarchyPath {
                    Button(action: { isExpanded.toggle() }) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.plain)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 16, height: 16)
                }
                
                // Category content
                HStack(spacing: 12) {
                    // Icon and color
                    HStack(spacing: 8) {
                        Text(category.icon)
                            .font(.title3)
                        
                        Circle()
                            .fill(category.swiftUIColor)
                            .frame(width: 12, height: 12)
                    }
                    
                    // Category info
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text(category.name)
                                .font(.body)
                                .fontWeight(category.isSystem ? .medium : .regular)
                            
                            if category.isSystem {
                                Text("SYSTEM")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }
                        }
                        
                        if showHierarchyPath {
                            Text(categoryService.hierarchyPath(for: category.id))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if hasChildren {
                            Text("\(children.count) subcategories")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Category ID (for debugging)
                    Text(String(category.id.uuidString.prefix(8)))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(NSColor.controlBackgroundColor).opacity(level > 0 ? 0.5 : 1.0))
            .cornerRadius(8)
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
        NavigationView {
            Form {
                Section("Basic Information") {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(category.name)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Icon")
                        Spacer()
                        Text(category.icon)
                            .font(.title2)
                    }
                    
                    HStack {
                        Text("Color")
                        Spacer()
                        Circle()
                            .fill(category.swiftUIColor)
                            .frame(width: 24, height: 24)
                        Text(category.color)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Hierarchy") {
                    HStack {
                        Text("ID")
                        Spacer()
                        Text(category.id.uuidString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let parentId = category.parentId {
                        HStack {
                            Text("Parent ID")
                            Spacer()
                            Text(parentId.uuidString)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Full Path")
                            Spacer()
                            Text(categoryService.hierarchyPath(for: category.id))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack {
                            Text("Level")
                            Spacer()
                            Text("Root Category")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if let children = category.children, !children.isEmpty {
                        HStack {
                            Text("Children")
                            Spacer()
                            Text("\(children.count) subcategories")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Metadata") {
                    HStack {
                        Text("Type")
                        Spacer()
                        Text(category.isSystem ? "System Category" : "Custom Category")
                            .foregroundColor(category.isSystem ? .blue : .green)
                    }
                    
                    HStack {
                        Text("Sort Order")
                        Spacer()
                        Text("\(category.sortOrder)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Active")
                        Spacer()
                        Text(category.isActive ? "Yes" : "No")
                            .foregroundColor(category.isActive ? .green : .red)
                    }
                    
                    if let budget = category.budgetAmount {
                        HStack {
                            Text("Budget")
                            Spacer()
                            Text("$\(budget)")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Section("Timestamps") {
                    HStack {
                        Text("Created")
                        Spacer()
                        Text(category.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Updated")
                        Spacer()
                        Text(category.updatedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
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
        .frame(width: 500, height: 600)
    }
}

#Preview {
    CategoryTestView()
}
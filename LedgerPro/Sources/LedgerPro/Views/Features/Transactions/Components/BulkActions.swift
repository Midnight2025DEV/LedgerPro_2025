import SwiftUI

/// Bulk Actions Bar
///
/// Floating action bar that appears when transactions are selected,
/// with smooth animations and contextual bulk operations.
struct BulkActions: View {
    let selectedCount: Int
    let onCategorize: () -> Void
    let onDelete: () -> Void
    let onExport: () -> Void
    let onCancel: () -> Void
    
    @State private var hasAppeared = false
    @State private var isExpanded = false
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    var body: some View {
        VStack {
            Spacer()
            
            // Floating action bar
            HStack(spacing: 0) {
                // Selection indicator
                selectionIndicator
                
                // Action buttons
                if isExpanded {
                    actionButtons
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                } else {
                    expandButton
                        .transition(.opacity)
                }
                
                // Cancel button
                cancelButton
            }
            .padding(.horizontal, DSSpacing.lg)
            .padding(.vertical, DSSpacing.md)
            .background(actionBarBackground)
            .cornerRadius(DSSpacing.radius.xl)
            .shadow(
                color: .black.opacity(0.15),
                radius: 20,
                x: 0,
                y: 8
            )
            .scaleEffect(hasAppeared ? 1.0 : 0.8)
            .opacity(hasAppeared ? 1.0 : 0.0)
            .offset(y: dragOffset)
            .gesture(dragGesture)
            .padding(.horizontal, DSSpacing.xl)
            .padding(.bottom, DSSpacing.xl)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                hasAppeared = true
            }
            
            // Auto-expand after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isExpanded = true
                }
            }
        }
    }
    
    // MARK: - Action Bar Background
    
    @ViewBuilder
    private var actionBarBackground: some View {
        RoundedRectangle(cornerRadius: DSSpacing.radius.xl)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: DSSpacing.radius.xl)
                    .fill(
                        LinearGradient(
                            colors: [
                                DSColors.primary.p900.opacity(0.8),
                                DSColors.primary.p800.opacity(0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DSSpacing.radius.xl)
                    .stroke(
                        LinearGradient(
                            colors: [
                                DSColors.primary.main.opacity(0.6),
                                DSColors.primary.main.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
    
    // MARK: - Selection Indicator
    
    @ViewBuilder
    private var selectionIndicator: some View {
        HStack(spacing: DSSpacing.sm) {
            // Selection count badge
            ZStack {
                Circle()
                    .fill(DSColors.primary.main)
                    .frame(width: 32, height: 32)
                
                Text("\(selectedCount)")
                    .font(DSTypography.body.semibold)
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.7)
            }
            .scaleEffect(hasAppeared ? 1.0 : 0.5)
            .animation(
                .spring(response: 0.4, dampingFraction: 0.6).delay(0.1),
                value: hasAppeared
            )
            
            // Selection text
            VStack(alignment: .leading, spacing: 2) {
                Text("\(selectedCount) selected")
                    .font(DSTypography.body.medium)
                    .foregroundColor(.white)
                
                Text("Tap to expand actions")
                    .font(DSTypography.caption.small)
                    .foregroundColor(.white.opacity(0.7))
                    .opacity(isExpanded ? 0.0 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isExpanded)
            }
        }
        .onTapGesture {
            toggleExpansion()
        }
    }
    
    // MARK: - Action Buttons
    
    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: DSSpacing.lg) {
            Spacer()
            
            // Categorize action
            BulkActionButton(
                icon: "tag.fill",
                title: "Categorize",
                color: DSColors.warning.main,
                onTap: onCategorize
            )
            
            // Export action
            BulkActionButton(
                icon: "square.and.arrow.up",
                title: "Export",
                color: DSColors.success.main,
                onTap: onExport
            )
            
            // Delete action
            BulkActionButton(
                icon: "trash.fill",
                title: "Delete",
                color: DSColors.error.main,
                onTap: {
                    showDeleteConfirmation()
                }
            )
        }
    }
    
    // MARK: - Expand Button
    
    @ViewBuilder
    private var expandButton: some View {
        HStack {
            Spacer()
            
            Button(action: toggleExpansion) {
                HStack(spacing: DSSpacing.sm) {
                    Image(systemName: "ellipsis")
                        .font(DSTypography.body.medium)
                        .foregroundColor(.white)
                    
                    Text("Actions")
                        .font(DSTypography.body.medium)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, DSSpacing.md)
                .padding(.vertical, DSSpacing.sm)
                .background(
                    Capsule()
                        .fill(.white.opacity(0.1))
                        .overlay(
                            Capsule()
                                .stroke(.white.opacity(0.2), lineWidth: 0.5)
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Cancel Button
    
    @ViewBuilder
    private var cancelButton: some View {
        Button(action: onCancel) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.2), lineWidth: 0.5)
                    )
                
                Image(systemName: "xmark")
                    .font(DSTypography.body.medium)
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(hasAppeared ? 1.0 : 0.5)
        .animation(
            .spring(response: 0.4, dampingFraction: 0.6).delay(0.2),
            value: hasAppeared
        )
    }
    
    // MARK: - Drag Gesture
    
    private var dragGesture: some Gesture {
        DragGesture(coordinateSpace: .local)
            .onChanged { value in
                withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
                    dragOffset = max(0, value.translation.height)
                    isDragging = true
                }
            }
            .onEnded { value in
                let velocity = value.velocity.height
                let threshold: CGFloat = 100
                
                if value.translation.height > threshold || velocity > 500 {
                    // Dismiss if dragged down significantly
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        dragOffset = 300 // Animate off screen
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onCancel()
                    }
                } else {
                    // Snap back
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        dragOffset = 0
                        isDragging = false
                    }
                }
            }
    }
    
    // MARK: - Actions
    
    private func toggleExpansion() {
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        #endif
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            isExpanded.toggle()
        }
    }
    
    private func showDeleteConfirmation() {
        // Show confirmation alert
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        #endif
        
        // In a real app, this would show an alert
        onDelete()
    }
}

// MARK: - Bulk Action Button

struct BulkActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            #if canImport(UIKit)
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            #endif
            onTap()
        }) {
            VStack(spacing: DSSpacing.xs) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(color.opacity(0.4), lineWidth: 1)
                        )
                    
                    Image(systemName: icon)
                        .font(DSTypography.body.medium)
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(DSTypography.caption.small)
                    .foregroundColor(.white.opacity(0.9))
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: 50,
            pressing: { pressing in
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
    }
}

// MARK: - Enhanced Bulk Actions with Progress

struct ProgressiveBulkActions: View {
    let selectedCount: Int
    let totalCount: Int
    let onCategorize: () -> Void
    let onDelete: () -> Void
    let onExport: () -> Void
    let onCancel: () -> Void
    
    @State private var isProcessing = false
    @State private var progress: Double = 0.0
    @State private var currentAction: String = ""
    
    var body: some View {
        ZStack {
            // Normal bulk actions
            if !isProcessing {
                BulkActions(
                    selectedCount: selectedCount,
                    onCategorize: {
                        startProcessing("Categorizing", action: onCategorize)
                    },
                    onDelete: {
                        startProcessing("Deleting", action: onDelete)
                    },
                    onExport: {
                        startProcessing("Exporting", action: onExport)
                    },
                    onCancel: onCancel
                )
            } else {
                // Progress indicator
                progressIndicator
            }
        }
    }
    
    @ViewBuilder
    private var progressIndicator: some View {
        VStack {
            Spacer()
            
            HStack(spacing: DSSpacing.lg) {
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(
                            .white.opacity(0.2),
                            lineWidth: 4
                        )
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            DSColors.primary.main,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
                
                // Progress text
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(currentAction) \(selectedCount) transactions...")
                        .font(DSTypography.body.medium)
                        .foregroundColor(.white)
                    
                    Text("\(Int(progress * 100))% complete")
                        .font(DSTypography.caption.regular)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            .padding(.horizontal, DSSpacing.lg)
            .padding(.vertical, DSSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: DSSpacing.radius.xl)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: DSSpacing.radius.xl)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        DSColors.primary.p900.opacity(0.8),
                                        DSColors.primary.p800.opacity(0.9)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            )
            .cornerRadius(DSSpacing.radius.xl)
            .shadow(
                color: .black.opacity(0.15),
                radius: 20,
                x: 0,
                y: 8
            )
            .padding(.horizontal, DSSpacing.xl)
            .padding(.bottom, DSSpacing.xl)
        }
    }
    
    private func startProcessing(_ actionName: String, action: @escaping () -> Void) {
        currentAction = actionName
        isProcessing = true
        progress = 0.0
        
        // Simulate processing with progress updates
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            progress += 0.1
            
            if progress >= 1.0 {
                timer.invalidate()
                
                // Complete the action
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    action()
                    isProcessing = false
                    progress = 0.0
                }
            }
        }
    }
}

// MARK: - Contextual Bulk Actions

struct ContextualBulkActions: View {
    let selectedTransactions: [Transaction]
    let onCategorize: ([Transaction]) -> Void
    let onDelete: ([Transaction]) -> Void
    let onExport: ([Transaction]) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        BulkActions(
            selectedCount: selectedTransactions.count,
            onCategorize: {
                onCategorize(selectedTransactions)
            },
            onDelete: {
                showSmartDeleteOptions()
            },
            onExport: {
                showExportOptions()
            },
            onCancel: onCancel
        )
        .overlay(
            smartSuggestions,
            alignment: .top
        )
    }
    
    @ViewBuilder
    private var smartSuggestions: some View {
        if hasSmartSuggestions {
            VStack(spacing: DSSpacing.sm) {
                ForEach(generateSmartSuggestions(), id: \.title) { suggestion in
                    SmartSuggestionChip(suggestion: suggestion) {
                        applySuggestion(suggestion)
                    }
                }
            }
            .padding(.horizontal, DSSpacing.xl)
            .padding(.bottom, DSSpacing.md)
        }
    }
    
    private var hasSmartSuggestions: Bool {
        // Check if selected transactions have patterns
        let categories = Set(selectedTransactions.map(\.category))
        let merchants = Set(selectedTransactions.map(\.description))
        
        return categories.count == 1 || merchants.count == 1
    }
    
    private func generateSmartSuggestions() -> [SmartSuggestion] {
        var suggestions: [SmartSuggestion] = []
        
        // Same category suggestion
        let categories = Set(selectedTransactions.map(\.category))
        if categories.count == 1, let category = categories.first {
            suggestions.append(SmartSuggestion(
                title: "All \(category)",
                action: "Change category for all \(category) transactions",
                icon: "tag.fill",
                color: DSColors.warning.main
            ))
        }
        
        // Recurring transaction suggestion
        let merchants = Set(selectedTransactions.map(\.description))
        if merchants.count == 1, let merchant = merchants.first {
            suggestions.append(SmartSuggestion(
                title: "Recurring \(merchant)",
                action: "Set up auto-categorization",
                icon: "repeat.circle.fill",
                color: DSColors.primary.main
            ))
        }
        
        return suggestions
    }
    
    private func showSmartDeleteOptions() {
        // Show context-aware delete options
        onDelete(selectedTransactions)
    }
    
    private func showExportOptions() {
        // Show export format options
        onExport(selectedTransactions)
    }
    
    private func applySuggestion(_ suggestion: SmartSuggestion) {
        // Apply smart suggestion
        print("Apply suggestion: \(suggestion.title)")
    }
}

struct SmartSuggestion {
    let title: String
    let action: String
    let icon: String
    let color: Color
}

struct SmartSuggestionChip: View {
    let suggestion: SmartSuggestion
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DSSpacing.sm) {
                Image(systemName: suggestion.icon)
                    .font(DSTypography.caption.regular)
                    .foregroundColor(suggestion.color)
                
                Text(suggestion.title)
                    .font(DSTypography.caption.regular)
                    .foregroundColor(.white)
                
                Text(suggestion.action)
                    .font(DSTypography.caption.small)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, DSSpacing.md)
            .padding(.vertical, DSSpacing.sm)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(suggestion.color.opacity(0.3), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Bulk Actions") {
    ZStack {
        LinearGradient(
            colors: [DSColors.neutral.background, DSColors.neutral.backgroundSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VStack(spacing: DSSpacing.xl) {
            // Normal bulk actions
            BulkActions(
                selectedCount: 5,
                onCategorize: {},
                onDelete: {},
                onExport: {},
                onCancel: {}
            )
            
            Spacer()
            
            // Progressive bulk actions
            ProgressiveBulkActions(
                selectedCount: 12,
                totalCount: 50,
                onCategorize: {},
                onDelete: {},
                onExport: {},
                onCancel: {}
            )
        }
    }
}
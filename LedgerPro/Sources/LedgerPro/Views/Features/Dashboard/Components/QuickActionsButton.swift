import SwiftUI

/// Quick Actions Button
///
/// A floating action button with expandable menu for quick dashboard actions
/// featuring glass morphism, smooth animations, and contextual financial operations.
struct QuickActionsButton: View {
    @Binding var isExpanded: Bool
    @State private var hasAppeared = false
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    
    // Action definitions
    private let actions: [QuickAction] = [
        QuickAction(
            id: "add-transaction",
            title: "Add Transaction",
            icon: "plus.circle.fill",
            color: DSColors.primary.main,
            shortcut: "⌘T"
        ),
        QuickAction(
            id: "upload-statement",
            title: "Upload Statement",
            icon: "doc.badge.plus",
            color: DSColors.success.main,
            shortcut: "⌘U"
        ),
        QuickAction(
            id: "export-data",
            title: "Export Data",
            icon: "square.and.arrow.up",
            color: DSColors.warning.main,
            shortcut: "⌘E"
        ),
        QuickAction(
            id: "settings",
            title: "Settings",
            icon: "gearshape.fill",
            color: DSColors.neutral.n600,
            shortcut: "⌘,"
        )
    ]
    
    var body: some View {
        ZStack {
            // Background blur when expanded
            if isExpanded {
                backgroundBlur
            }
            
            // Action items
            ForEach(actions.indices, id: \.self) { index in
                actionButton(for: actions[index], at: index)
            }
            
            // Main floating action button
            mainActionButton
        }
        .offset(dragOffset)
        .animation(DSAnimations.common.standardTransition, value: isExpanded)
        .animation(DSAnimations.common.quickFeedback, value: isDragging)
        .onAppear {
            withAnimation(DSAnimations.common.standardTransition.delay(1.0)) {
                hasAppeared = true
            }
        }
    }
    
    // MARK: - Background Blur
    
    @ViewBuilder
    private var backgroundBlur: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .opacity(0.8)
            .ignoresSafeArea()
            .onTapGesture {
                withAnimation(DSAnimations.common.quickFeedback) {
                    isExpanded = false
                }
            }
            .transition(.opacity)
    }
    
    // MARK: - Main Action Button
    
    @ViewBuilder
    private var mainActionButton: some View {
        Button(action: toggleExpanded) {
            ZStack {
                // Glass morphism background
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        DSColors.primary.main.opacity(0.6),
                                        DSColors.primary.main.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(
                        color: DSColors.primary.main.opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                
                // Icon with rotation animation
                Image(systemName: isExpanded ? "xmark" : "plus")
                    .font(DSTypography.title.title2)
                    .foregroundColor(DSColors.primary.main)
                    .rotationEffect(.degrees(isExpanded ? 135 : 0))
                    .scaleEffect(isDragging ? 1.1 : 1.0)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(hasAppeared ? 1.0 : 0.0)
        .opacity(hasAppeared ? 1.0 : 0.0)
        .simultaneousGesture(
            DragGesture(coordinateSpace: .global)
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                    }
                    dragOffset = value.translation
                }
                .onEnded { value in
                    isDragging = false
                    
                    // Snap back to original position
                    withAnimation(DSAnimations.common.gentleBounce) {
                        dragOffset = .zero
                    }
                    
                    // Collapse if dragged significantly
                    if abs(value.translation.width) > 100 || abs(value.translation.height) > 100 {
                        withAnimation(DSAnimations.common.quickFeedback) {
                            isExpanded = false
                        }
                    }
                }
        )
    }
    
    // MARK: - Action Buttons
    
    @ViewBuilder
    private func actionButton(for action: QuickAction, at index: Int) -> some View {
        if isExpanded {
            Button(action: { executeAction(action) }) {
                HStack(spacing: DSSpacing.md) {
                    // Action content
                    actionContent(for: action)
                    
                    // Keyboard shortcut hint
                    if !action.shortcut.isEmpty {
                        Text(action.shortcut)
                            .font(DSTypography.caption.small)
                            .foregroundColor(DSColors.neutral.textTertiary)
                            .padding(.horizontal, DSSpacing.xs)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(DSColors.neutral.n200.opacity(0.5))
                            )
                    }
                }
                .padding(.horizontal, DSSpacing.lg)
                .padding(.vertical, DSSpacing.md)
                .background(.ultraThinMaterial)
                .cornerRadius(DSSpacing.radius.lg)
            }
            .buttonStyle(.plain)
            .offset(y: actionOffset(for: index))
            .scaleEffect(actionScale(for: index))
            .opacity(actionOpacity(for: index))
            .transition(.asymmetric(
                insertion: .scale.combined(with: .opacity),
                removal: .scale.combined(with: .opacity)
            ))
        }
    }
    
    @ViewBuilder
    private func actionContent(for action: QuickAction) -> some View {
        HStack(spacing: DSSpacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(action.color.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: action.icon)
                    .font(DSTypography.body.medium)
                    .foregroundColor(action.color)
            }
            
            // Title
            Text(action.title)
                .font(DSTypography.body.medium)
                .foregroundColor(DSColors.neutral.text)
            
            Spacer()
        }
    }
    
    // MARK: - Animation Calculations
    
    private func actionOffset(for index: Int) -> CGFloat {
        let baseOffset: CGFloat = -80
        let spacing: CGFloat = 70
        return baseOffset - (CGFloat(index) * spacing)
    }
    
    private func actionScale(for index: Int) -> CGFloat {
        return isExpanded ? 1.0 : 0.8
    }
    
    private func actionOpacity(for index: Int) -> Double {
        isExpanded ? 1.0 : 0.0
    }
    
    // MARK: - Actions
    
    private func toggleExpanded() {
        withAnimation(DSAnimations.common.gentleBounce) {
            isExpanded.toggle()
        }
        
        // Haptic feedback
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        #endif
    }
    
    private func executeAction(_ action: QuickAction) {
        // Close menu first
        withAnimation(DSAnimations.common.quickFeedback) {
            isExpanded = false
        }
        
        // Execute action after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            handleQuickAction(action)
        }
        
        // Haptic feedback
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        #endif
    }
    
    private func handleQuickAction(_ action: QuickAction) {
        switch action.id {
        case "add-transaction":
            // Navigate to add transaction view
            print("Add Transaction action triggered")
            
        case "upload-statement":
            // Show file picker for statement upload
            print("Upload Statement action triggered")
            
        case "export-data":
            // Show export options
            print("Export Data action triggered")
            
        case "settings":
            // Navigate to settings
            print("Settings action triggered")
            
        default:
            break
        }
    }
}

// MARK: - Quick Action Model

struct QuickAction: Identifiable {
    let id: String
    let title: String
    let icon: String
    let color: Color
    let shortcut: String
}

// MARK: - Compact Variant

extension QuickActionsButton {
    /// Compact version with fewer actions for smaller screens
    static func compact(isExpanded: Binding<Bool>) -> some View {
        CompactQuickActionsButton(isExpanded: isExpanded)
    }
}

struct CompactQuickActionsButton: View {
    @Binding var isExpanded: Bool
    @State private var hasAppeared = false
    
    private let compactActions: [QuickAction] = [
        QuickAction(
            id: "add-transaction",
            title: "Add",
            icon: "plus.circle.fill",
            color: DSColors.primary.main,
            shortcut: ""
        ),
        QuickAction(
            id: "upload-statement",
            title: "Upload",
            icon: "doc.badge.plus",
            color: DSColors.success.main,
            shortcut: ""
        )
    ]
    
    var body: some View {
        HStack(spacing: DSSpacing.sm) {
            if isExpanded {
                ForEach(compactActions) { action in
                    compactActionButton(for: action)
                }
            }
            
            // Main button
            Button(action: toggleExpanded) {
                Image(systemName: isExpanded ? "xmark" : "ellipsis")
                    .font(DSTypography.body.medium)
                    .foregroundColor(DSColors.primary.main)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .cornerRadius(22)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .buttonStyle(.plain)
        }
        .padding(DSSpacing.md)
        .background(.ultraThinMaterial)
        .cornerRadius(DSSpacing.radius.xl)
        .scaleEffect(hasAppeared ? 1.0 : 0.0)
        .onAppear {
            withAnimation(DSAnimations.common.standardTransition.delay(1.0)) {
                hasAppeared = true
            }
        }
    }
    
    @ViewBuilder
    private func compactActionButton(for action: QuickAction) -> some View {
        Button(action: { executeCompactAction(action) }) {
            Image(systemName: action.icon)
                .font(DSTypography.body.medium)
                .foregroundColor(action.color)
                .frame(width: 36, height: 36)
                .background(action.color.opacity(0.15))
                .cornerRadius(18)
        }
        .buttonStyle(.plain)
        .transition(.scale.combined(with: .opacity))
    }
    
    private func toggleExpanded() {
        withAnimation(DSAnimations.common.quickFeedback) {
            isExpanded.toggle()
        }
    }
    
    private func executeCompactAction(_ action: QuickAction) {
        withAnimation(DSAnimations.common.quickFeedback) {
            isExpanded = false
        }
        
        // Handle action (same logic as main button)
        print("\(action.title) action triggered")
    }
}

// MARK: - Preview

#Preview("Quick Actions Button") {
    ZStack {
        // Mock dashboard background
        LinearGradient(
            colors: [DSColors.neutral.n100, DSColors.neutral.n200],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        // Mock content
        VStack {
            Text("Dashboard Content")
                .font(DSTypography.title.title1)
                .foregroundColor(DSColors.neutral.text)
            
            Spacer()
        }
        .padding(DSSpacing.xl)
        
        // Quick actions button
        QuickActionsButton(isExpanded: .constant(false))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(DSSpacing.xl)
    }
}

#Preview("Expanded Quick Actions") {
    ZStack {
        LinearGradient(
            colors: [DSColors.neutral.n100, DSColors.neutral.n200],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        QuickActionsButton(isExpanded: .constant(true))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(DSSpacing.xl)
    }
}

#Preview("Compact Quick Actions") {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            HStack {
                Spacer()
                QuickActionsButton.compact(isExpanded: .constant(false))
            }
        }
        .padding(DSSpacing.lg)
    }
}
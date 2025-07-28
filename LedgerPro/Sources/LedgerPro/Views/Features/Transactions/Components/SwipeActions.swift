import SwiftUI

/// Swipe Actions System
///
/// Sophisticated swipe interactions with spring physics, haptic feedback,
/// and contextual action reveals for transaction management.
struct SwipeActions: View {
    let transaction: Transaction
    let onAction: (SwipeActionType) -> Void
    
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var currentAction: SwipeActionType?
    @State private var hasTriggeredHaptic = false
    
    // Configuration
    private let quickActionThreshold: CGFloat = 80
    private let destructiveActionThreshold: CGFloat = 150
    private let maxSwipeDistance: CGFloat = 220
    
    var body: some View {
        ZStack {
            // Background action indicators
            actionBackgrounds
            
            // Transaction content (passed as content)
            Color.clear
                .frame(height: 80)
                .offset(x: dragOffset.width)
                .gesture(swipeGesture)
        }
        .clipShape(RoundedRectangle(cornerRadius: DSSpacing.radius.lg))
    }
    
    // MARK: - Action Backgrounds
    
    @ViewBuilder
    private var actionBackgrounds: some View {
        HStack(spacing: 0) {
            // Left swipe actions (positive swipe)
            if dragOffset.width > 0 {
                leftActionBackground
            }
            
            Spacer()
            
            // Right swipe actions (negative swipe)
            if dragOffset.width < 0 {
                rightActionBackground
            }
        }
    }
    
    @ViewBuilder
    private var leftActionBackground: some View {
        HStack(spacing: DSSpacing.lg) {
            // Primary action: Categorize
            ActionIndicator(
                action: .categorize,
                isActive: dragOffset.width > quickActionThreshold,
                isTriggered: dragOffset.width > destructiveActionThreshold,
                progress: min(1.0, dragOffset.width / quickActionThreshold)
            )
            
            // Secondary action: Flag (appears on deeper swipe)
            if dragOffset.width > quickActionThreshold {
                ActionIndicator(
                    action: .flag,
                    isActive: dragOffset.width > destructiveActionThreshold,
                    isTriggered: false,
                    progress: min(1.0, max(0, (dragOffset.width - quickActionThreshold) / quickActionThreshold))
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.leading, DSSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    SwipeActionType.categorize.color.opacity(0.1),
                    SwipeActionType.categorize.color.opacity(0.05)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
    
    @ViewBuilder
    private var rightActionBackground: some View {
        HStack(spacing: DSSpacing.lg) {
            // Secondary action: Split (appears on deeper swipe)
            if abs(dragOffset.width) > quickActionThreshold {
                ActionIndicator(
                    action: .split,
                    isActive: abs(dragOffset.width) > destructiveActionThreshold,
                    isTriggered: false,
                    progress: min(1.0, max(0, (abs(dragOffset.width) - quickActionThreshold) / quickActionThreshold))
                )
                .transition(.scale.combined(with: .opacity))
            }
            
            // Primary action: Delete
            ActionIndicator(
                action: .delete,
                isActive: abs(dragOffset.width) > quickActionThreshold,
                isTriggered: abs(dragOffset.width) > destructiveActionThreshold,
                progress: min(1.0, abs(dragOffset.width) / quickActionThreshold)
            )
        }
        .padding(.trailing, DSSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(
            LinearGradient(
                colors: [
                    SwipeActionType.delete.color.opacity(0.05),
                    SwipeActionType.delete.color.opacity(0.1)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
    
    // MARK: - Gesture Handling
    
    private var swipeGesture: some Gesture {
        DragGesture(coordinateSpace: .local)
            .onChanged { value in
                handleDragChange(value)
            }
            .onEnded { value in
                handleDragEnd(value)
            }
    }
    
    private func handleDragChange(_ value: DragGesture.Value) {
        // Clamp the swipe distance
        let clampedWidth = min(maxSwipeDistance, max(-maxSwipeDistance, value.translation.width))
        
        withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.8)) {
            dragOffset = CGSize(width: clampedWidth, height: 0)
            isDragging = true
        }
        
        // Determine current action based on swipe distance and direction
        let absWidth = abs(clampedWidth)
        let newAction: SwipeActionType?
        
        if clampedWidth > destructiveActionThreshold {
            newAction = .flag
        } else if clampedWidth > quickActionThreshold {
            newAction = .categorize
        } else if clampedWidth < -destructiveActionThreshold {
            newAction = .delete
        } else if clampedWidth < -quickActionThreshold {
            newAction = .split
        } else {
            newAction = nil
        }
        
        // Trigger haptic feedback when crossing thresholds
        if newAction != currentAction {
            if newAction != nil && !hasTriggeredHaptic {
                triggerHapticFeedback(for: newAction!)
                hasTriggeredHaptic = true
            } else if newAction == nil {
                hasTriggeredHaptic = false
            }
            currentAction = newAction
        }
        
        // Enhanced haptic for destructive actions
        if absWidth > destructiveActionThreshold && !hasTriggeredHaptic {
            triggerDestructiveHaptic()
            hasTriggeredHaptic = true
        }
    }
    
    private func handleDragEnd(_ value: DragGesture.Value) {
        let absWidth = abs(value.translation.width)
        let velocity = abs(value.velocity.width)
        
        // Determine if action should be triggered based on distance and velocity
        let shouldTriggerAction = absWidth > destructiveActionThreshold || 
                                 (absWidth > quickActionThreshold && velocity > 500)
        
        if shouldTriggerAction, let action = currentAction {
            // Trigger the action
            triggerAction(action)
        } else {
            // Snap back to center
            snapBack()
        }
    }
    
    // MARK: - Action Execution
    
    private func triggerAction(_ action: SwipeActionType) {
        // Dramatic haptic feedback
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        #endif
        
        // Animate the action trigger
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            // Slight overshoot before snapping back
            dragOffset.width *= 1.2
        }
        
        // Execute the action after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onAction(action)
            snapBack()
        }
    }
    
    private func snapBack() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            dragOffset = .zero
            isDragging = false
            currentAction = nil
            hasTriggeredHaptic = false
        }
    }
    
    // MARK: - Haptic Feedback
    
    private func triggerHapticFeedback(for action: SwipeActionType) {
        switch action {
        case .categorize, .flag:
            #if canImport(UIKit)
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            #endif
        case .split:
            #if canImport(UIKit)
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            #endif
        case .delete:
            #if canImport(UIKit)
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
            #endif
        }
    }
    
    private func triggerDestructiveHaptic() {
        #if canImport(UIKit)
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
        #endif
    }
}

// MARK: - Action Indicator

struct ActionIndicator: View {
    let action: SwipeActionType
    let isActive: Bool
    let isTriggered: Bool
    let progress: CGFloat
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(action.color.opacity(isActive ? 0.8 : 0.4))
                .frame(width: circleSize, height: circleSize)
                .scaleEffect(isTriggered ? 1.3 : 1.0)
                .overlay(
                    Circle()
                        .stroke(action.color.opacity(0.3), lineWidth: isActive ? 2 : 1)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .opacity(isAnimating ? 0 : 1)
                )
            
            // Action icon
            Image(systemName: action.icon)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundColor(.white)
                .scaleEffect(isTriggered ? 1.2 : 1.0)
                .rotationEffect(.degrees(isTriggered ? 10 : 0))
            
            // Progress ring for threshold feedback
            if isActive && !isTriggered {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        action.color.opacity(0.8),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: circleSize + 8, height: circleSize + 8)
                    .rotationEffect(.degrees(-90))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isTriggered)
        .onAppear {
            startPulseAnimation()
        }
    }
    
    private var circleSize: CGFloat {
        let baseSize: CGFloat = 50
        let activeBonus: CGFloat = isActive ? 8 : 0
        let progressBonus: CGFloat = progress * 6
        return baseSize + activeBonus + progressBonus
    }
    
    private var iconSize: CGFloat {
        let baseSize: CGFloat = 20
        let activeBonus: CGFloat = isActive ? 4 : 0
        return baseSize + activeBonus
    }
    
    private func startPulseAnimation() {
        guard isActive else { return }
        
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            isAnimating = true
        }
    }
}

// MARK: - Swipe Action Types

enum SwipeActionType {
    case categorize
    case delete
    case split
    case flag
    
    var icon: String {
        switch self {
        case .categorize: return "tag.fill"
        case .delete: return "trash.fill"
        case .split: return "scissors"
        case .flag: return "flag.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .categorize: return DSColors.primary.main
        case .delete: return DSColors.error.main
        case .split: return DSColors.neutral.n600
        case .flag: return DSColors.warning.main
        }
    }
    
    var title: String {
        switch self {
        case .categorize: return "Categorize"
        case .delete: return "Delete"
        case .split: return "Split"
        case .flag: return "Flag"
        }
    }
    
    var description: String {
        switch self {
        case .categorize: return "Change transaction category"
        case .delete: return "Remove this transaction"
        case .split: return "Split into multiple transactions"
        case .flag: return "Flag for review"
        }
    }
}

// MARK: - Quick Action Menu

struct QuickActionMenu: View {
    let transaction: Transaction
    let onAction: (SwipeActionType) -> Void
    let onDismiss: () -> Void
    
    @State private var hasAppeared = false
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // Action menu
            VStack(spacing: DSSpacing.lg) {
                // Header
                menuHeader
                
                // Action buttons
                actionButtons
                
                // Cancel button
                cancelButton
            }
            .padding(DSSpacing.xl)
            .background(.ultraThinMaterial)
            .cornerRadius(DSSpacing.radius.xl)
            .shadow(
                color: .black.opacity(0.2),
                radius: 20,
                x: 0,
                y: 10
            )
            .scaleEffect(hasAppeared ? 1.0 : 0.8)
            .opacity(hasAppeared ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                hasAppeared = true
            }
        }
    }
    
    @ViewBuilder
    private var menuHeader: some View {
        VStack(spacing: DSSpacing.sm) {
            Text("Quick Actions")
                .font(DSTypography.title.title3)
                .foregroundColor(DSColors.neutral.text)
            
            Text(transaction.description)
                .font(DSTypography.body.regular)
                .foregroundColor(DSColors.neutral.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DSSpacing.lg), count: 2), spacing: DSSpacing.lg) {
            ForEach([SwipeActionType.categorize, .split, .flag, .delete], id: \.title) { action in
                QuickActionButton(action: action) {
                    onAction(action)
                    onDismiss()
                }
            }
        }
    }
    
    @ViewBuilder
    private var cancelButton: some View {
        Button("Cancel") {
            onDismiss()
        }
        .font(DSTypography.body.medium)
        .foregroundColor(DSColors.neutral.textSecondary)
        .padding(.vertical, DSSpacing.md)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .cornerRadius(DSSpacing.radius.lg)
    }
}

struct QuickActionButton: View {
    let action: SwipeActionType
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: DSSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(action.color.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: action.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(action.color)
                }
                
                Text(action.title)
                    .font(DSTypography.body.medium)
                    .foregroundColor(DSColors.neutral.text)
            }
            .padding(DSSpacing.md)
            .background(.ultraThinMaterial)
            .cornerRadius(DSSpacing.radius.lg)
            .scaleEffect(isPressed ? 0.95 : 1.0)
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

// MARK: - Preview

#Preview("Swipe Actions") {
    let sampleTransaction = Transaction(
        date: "2024-01-15",
        description: "Starbucks Coffee #1234",
        amount: -45.67,
        category: "Food & Dining",
        accountId: "account1"
    )
    
    VStack(spacing: DSSpacing.xl) {
        // Action indicators
        HStack(spacing: DSSpacing.xl) {
            ActionIndicator(
                action: .categorize,
                isActive: true,
                isTriggered: false,
                progress: 0.7
            )
            
            ActionIndicator(
                action: .delete,
                isActive: true,
                isTriggered: true,
                progress: 1.0
            )
            
            ActionIndicator(
                action: .split,
                isActive: false,
                isTriggered: false,
                progress: 0.3
            )
        }
        
        // Quick action menu
        QuickActionMenu(
            transaction: sampleTransaction,
            onAction: { action in
                print("Action: \(action.title)")
            },
            onDismiss: {}
        )
    }
    .padding(DSSpacing.xl)
    .background(
        LinearGradient(
            colors: [DSColors.neutral.n100, DSColors.neutral.n200],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
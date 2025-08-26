import SwiftUI

/// FeatureTour - Comprehensive feature introduction system
///
/// Interactive tour system with tooltips, coach marks, and guided experiences
/// to help users discover and learn LedgerPro's powerful features.
struct FeatureTour: View {
    @StateObject private var tourManager = FeatureTourManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep: TourStep = .dashboard
    @State private var progress: Double = 0.0
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Semi-transparent overlay
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture {
                    skipTour()
                }
            
            // Tour content
            VStack {
                Spacer()
                
                // Tour card
                tourCard
                    .padding(.horizontal, DSSpacing.lg)
                    .padding(.bottom, DSSpacing.xl)
            }
        }
        .onAppear {
            startTour()
        }
    }
    
    @ViewBuilder
    private var tourCard: some View {
        VStack(spacing: DSSpacing.xl) {
            // Progress indicator
            tourProgress
            
            // Step content
            stepContent
            
            // Navigation buttons
            navigationButtons
        }
        .padding(DSSpacing.xl)
        .background(.ultraThinMaterial)
        .cornerRadius(DSSpacing.radius.xl)
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        .scaleEffect(isAnimating ? 1.0 : 0.8)
        .opacity(isAnimating ? 1.0 : 0.0)
        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: isAnimating)
    }
    
    @ViewBuilder
    private var tourProgress: some View {
        VStack(spacing: DSSpacing.md) {
            // Step indicator dots
            HStack(spacing: DSSpacing.sm) {
                ForEach(TourStep.allCases.indices, id: \.self) { index in
                    let step = TourStep.allCases[index]
                    let isActive = step.rawValue <= currentStep.rawValue
                    let isCurrent = step == currentStep
                    
                    Circle()
                        .fill(isActive ? DSColors.primary.main : DSColors.neutral.n300)
                        .frame(width: isCurrent ? 10 : 6, height: isCurrent ? 10 : 6)
                        .scaleEffect(isCurrent ? 1.2 : 1.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentStep)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DSColors.neutral.n200.opacity(0.3))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [DSColors.primary.main, DSColors.primary.p600],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 4)
        }
    }
    
    @ViewBuilder
    private var stepContent: some View {
        VStack(spacing: DSSpacing.lg) {
            // Step illustration
            stepIllustration
            
            // Step text content
            VStack(spacing: DSSpacing.md) {
                Text(currentStep.title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(DSColors.neutral.text)
                    .multilineTextAlignment(.center)
                
                Text(currentStep.description)
                    .font(DSTypography.body.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            // Interactive elements
            if let interaction = currentStep.interaction {
                interactionElement(interaction)
            }
        }
    }
    
    @ViewBuilder
    private var stepIllustration: some View {
        ZStack {
            // Background glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            currentStep.color.opacity(0.2),
                            currentStep.color.opacity(0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .scaleEffect(isAnimating ? 1.0 : 0.5)
                .animation(.spring(response: 1.0, dampingFraction: 0.6).delay(0.2), value: isAnimating)
            
            // Main icon
            Image(systemName: currentStep.icon)
                .font(.system(size: 50, weight: .semibold))
                .foregroundColor(currentStep.color)
                .scaleEffect(isAnimating ? 1.0 : 0.3)
                .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.4), value: isAnimating)
        }
    }
    
    @ViewBuilder
    private func interactionElement(_ interaction: TourInteraction) -> some View {
        switch interaction {
        case .gesture(let gesture):
            GestureDemo(gesture: gesture)
        case .tooltip(let text, let position):
            TooltipDemo(text: text, position: position)
        case .highlight(let area):
            HighlightDemo(area: area)
        }
    }
    
    @ViewBuilder
    private var navigationButtons: some View {
        HStack(spacing: DSSpacing.lg) {
            // Skip button
            if currentStep != TourStep.allCases.last {
                Button("Skip Tour") {
                    skipTour()
                }
                .font(DSTypography.body.medium)
                .foregroundColor(DSColors.neutral.textSecondary)
            } else {
                Spacer()
            }
            
            Spacer()
            
            // Navigation buttons
            HStack(spacing: DSSpacing.md) {
                // Previous button
                if currentStep != TourStep.allCases.first {
                    Button(action: previousStep) {
                        HStack(spacing: DSSpacing.xs) {
                            Image(systemName: "chevron.left")
                                .font(DSTypography.caption.regular)
                            Text("Back")
                                .font(DSTypography.body.medium)
                        }
                        .foregroundColor(DSColors.neutral.text)
                        .padding(.horizontal, DSSpacing.lg)
                        .padding(.vertical, DSSpacing.sm)
                        .background(.ultraThinMaterial)
                        .cornerRadius(DSSpacing.radius.lg)
                    }
                    .buttonStyle(.plain)
                }
                
                // Next/Done button
                Button(action: nextStep) {
                    HStack(spacing: DSSpacing.xs) {
                        Text(nextButtonText)
                            .font(DSTypography.body.semibold)
                        
                        if currentStep != TourStep.allCases.last {
                            Image(systemName: "chevron.right")
                                .font(DSTypography.caption.regular)
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, DSSpacing.xl)
                    .padding(.vertical, DSSpacing.sm)
                    .background(
                        LinearGradient(
                            colors: [DSColors.primary.main, DSColors.primary.p600],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(DSSpacing.radius.lg)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var nextButtonText: String {
        if currentStep == TourStep.allCases.last {
            return "Get Started"
        } else {
            return "Next"
        }
    }
    
    // MARK: - Actions
    
    private func startTour() {
        progress = Double(currentStep.rawValue + 1) / Double(TourStep.allCases.count)
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3)) {
            isAnimating = true
        }
    }
    
    private func nextStep() {
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        #endif
        
        if currentStep == TourStep.allCases.last {
            completeTour()
        } else {
            advanceToNextStep()
        }
    }
    
    private func previousStep() {
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        #endif
        
        guard let currentIndex = TourStep.allCases.firstIndex(of: currentStep),
              currentIndex > 0 else { return }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            currentStep = TourStep.allCases[currentIndex - 1]
            progress = Double(currentStep.rawValue + 1) / Double(TourStep.allCases.count)
        }
    }
    
    private func advanceToNextStep() {
        guard let currentIndex = TourStep.allCases.firstIndex(of: currentStep),
              currentIndex < TourStep.allCases.count - 1 else { return }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            currentStep = TourStep.allCases[currentIndex + 1]
            progress = Double(currentStep.rawValue + 1) / Double(TourStep.allCases.count)
        }
    }
    
    private func skipTour() {
        tourManager.skipTour()
        dismiss()
    }
    
    private func completeTour() {
        tourManager.completeTour()
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
            isAnimating = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
}

// MARK: - Interactive Elements

struct GestureDemo: View {
    let gesture: TourGesture
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: DSSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(DSColors.neutral.n100.opacity(0.3))
                    .frame(width: 120, height: 80)
                
                gestureAnimation
            }
            
            Text("Try \(gesture.instruction)")
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.primary.main)
        }
        .onAppear {
            startGestureAnimation()
        }
    }
    
    @ViewBuilder
    private var gestureAnimation: some View {
        switch gesture {
        case .swipe(let direction):
            SwipeGestureAnimation(direction: direction, isAnimating: isAnimating)
        case .pinch:
            PinchGestureAnimation(isAnimating: isAnimating)
        case .longPress:
            LongPressGestureAnimation(isAnimating: isAnimating)
        case .doubleTap:
            DoubleTapGestureAnimation(isAnimating: isAnimating)
        }
    }
    
    private func startGestureAnimation() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.5)) {
            isAnimating = true
        }
    }
}

struct SwipeGestureAnimation: View {
    let direction: SwipeDirection
    let isAnimating: Bool
    
    var body: some View {
        HStack(spacing: DSSpacing.sm) {
            Circle()
                .fill(DSColors.primary.main)
                .frame(width: 12, height: 12)
                .offset(x: isAnimating ? offsetValue : 0)
            
            Image(systemName: "arrow.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(DSColors.primary.main)
                .opacity(isAnimating ? 1.0 : 0.3)
        }
    }
    
    private var offsetValue: CGFloat {
        switch direction {
        case .left: return -30
        case .right: return 30
        case .up: return 0 // Would need different layout for vertical
        case .down: return 0
        }
    }
}

struct PinchGestureAnimation: View {
    let isAnimating: Bool
    
    var body: some View {
        HStack(spacing: isAnimating ? 40 : 20) {
            Circle()
                .fill(DSColors.primary.main)
                .frame(width: 8, height: 8)
            
            Circle()
                .fill(DSColors.primary.main)
                .frame(width: 8, height: 8)
        }
    }
}

struct LongPressGestureAnimation: View {
    let isAnimating: Bool
    
    var body: some View {
        Circle()
            .fill(DSColors.primary.main)
            .frame(width: 20, height: 20)
            .scaleEffect(isAnimating ? 1.5 : 1.0)
            .overlay(
                Circle()
                    .stroke(DSColors.primary.main.opacity(0.3), lineWidth: 2)
                    .scaleEffect(isAnimating ? 2.0 : 1.0)
                    .opacity(isAnimating ? 0.0 : 1.0)
            )
    }
}

struct DoubleTapGestureAnimation: View {
    let isAnimating: Bool
    @State private var tapCount = 0
    
    var body: some View {
        Circle()
            .fill(DSColors.primary.main)
            .frame(width: 20, height: 20)
            .scaleEffect(tapCount > 0 ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: tapCount)
            .onAppear {
                if isAnimating {
                    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                        doubleTapAnimation()
                    }
                }
            }
    }
    
    private func doubleTapAnimation() {
        tapCount = 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            tapCount = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                tapCount = 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    tapCount = 0
                }
            }
        }
    }
}

struct TooltipDemo: View {
    let text: String
    let position: TooltipPosition
    
    var body: some View {
        VStack(spacing: DSSpacing.md) {
            // Mock UI element
            RoundedRectangle(cornerRadius: 8)
                .fill(DSColors.neutral.n200.opacity(0.3))
                .frame(width: 100, height: 40)
                .overlay(tooltipView)
            
            Text("Tooltips provide helpful context")
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.primary.main)
        }
    }
    
    @ViewBuilder
    private var tooltipView: some View {
        VStack {
            if position == .top {
                tooltipBubble
                Spacer()
            } else {
                Spacer()
                tooltipBubble
            }
        }
    }
    
    @ViewBuilder
    private var tooltipBubble: some View {
        Text(text)
            .font(DSTypography.caption.regular)
            .foregroundColor(.white)
            .padding(.horizontal, DSSpacing.sm)
            .padding(.vertical, DSSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.black.opacity(0.8))
            )
            .offset(y: position == .top ? -30 : 30)
    }
}

struct HighlightDemo: View {
    let area: HighlightArea
    @State private var isGlowing = false
    
    var body: some View {
        VStack(spacing: DSSpacing.md) {
            // Mock interface with highlight
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(DSColors.neutral.n100.opacity(0.3))
                    .frame(width: 200, height: 120)
                
                // Highlighted element
                highlightedElement
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(DSColors.primary.main, lineWidth: 2)
                            .shadow(color: DSColors.primary.main.opacity(0.5), radius: isGlowing ? 8 : 4)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isGlowing)
                    )
            }
            
            Text("Important areas are highlighted")
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.primary.main)
        }
        .onAppear {
            isGlowing = true
        }
    }
    
    @ViewBuilder
    private var highlightedElement: some View {
        switch area {
        case .button:
            RoundedRectangle(cornerRadius: 8)
                .fill(DSColors.primary.main.opacity(0.1))
                .frame(width: 80, height: 32)
                .overlay(
                    Text("Button")
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.primary.main)
                )
        case .menu:
            VStack(spacing: 4) {
                ForEach(0..<3) { _ in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DSColors.primary.main.opacity(0.3))
                        .frame(width: 60, height: 8)
                }
            }
        case .fab:
            Circle()
                .fill(DSColors.primary.main)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                )
        }
    }
}

// MARK: - Tooltip System

struct TooltipOverlay: View {
    let tooltip: ActiveTooltip
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    
    var body: some View {
        ZStack {
            // Invisible background to catch taps
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    onDismiss()
                }
            
            // Tooltip content
            VStack {
                if tooltip.position == .bottom {
                    Spacer()
                }
                
                HStack {
                    if tooltip.alignment == .trailing {
                        Spacer()
                    }
                    
                    tooltipBubble
                        .scaleEffect(isVisible ? 1.0 : 0.8)
                        .opacity(isVisible ? 1.0 : 0.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isVisible)
                    
                    if tooltip.alignment == .leading {
                        Spacer()
                    }
                }
                .padding(.horizontal, DSSpacing.lg)
                
                if tooltip.position == .top {
                    Spacer()
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                isVisible = true
            }
            
            // Auto-dismiss after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + tooltip.duration) {
                onDismiss()
            }
        }
    }
    
    @ViewBuilder
    private var tooltipBubble: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            if let title = tooltip.title {
                Text(title)
                    .font(DSTypography.body.semibold)
                    .foregroundColor(.white)
            }
            
            Text(tooltip.message)
                .font(DSTypography.caption.regular)
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(nil)
            
            if let actionText = tooltip.actionText {
                Button(actionText) {
                    tooltip.action?()
                    onDismiss()
                }
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.primary.main)
                .padding(.top, DSSpacing.xs)
            }
        }
        .padding(DSSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: DSSpacing.radius.lg)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: DSSpacing.radius.lg)
                        .fill(Color.black.opacity(0.8))
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Data Models

enum TourStep: Int, CaseIterable {
    case dashboard = 0
    case transactions = 1
    case budgets = 2
    case insights = 3
    case gestures = 4
    case completion = 5
    
    var title: String {
        switch self {
        case .dashboard: return "Welcome to LedgerPro"
        case .transactions: return "Smart Transactions"
        case .budgets: return "Budget Management"
        case .insights: return "AI Insights"
        case .gestures: return "Powerful Gestures"
        case .completion: return "You're All Set!"
        }
    }
    
    var description: String {
        switch self {
        case .dashboard:
            return "Your financial command center. See your balance, recent transactions, and spending insights at a glance."
        case .transactions:
            return "AI-powered categorization automatically organizes your spending. Swipe to edit, search to find, and filter to focus."
        case .budgets:
            return "Set spending goals and track progress with beautiful visualizations. Get smart recommendations to stay on track."
        case .insights:
            return "Discover patterns in your spending with AI-powered insights and personalized recommendations."
        case .gestures:
            return "Master these gestures to work faster: swipe for actions, pinch to change views, long-press for options."
        case .completion:
            return "You're ready to take control of your finances. Start by importing your first statement or creating a budget."
        }
    }
    
    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .transactions: return "list.bullet.rectangle"
        case .budgets: return "target"
        case .insights: return "brain.head.profile"
        case .gestures: return "hand.tap.fill"
        case .completion: return "checkmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .dashboard: return DSColors.primary.main
        case .transactions: return DSColors.success.main
        case .budgets: return DSColors.warning.main
        case .insights: return DSColors.info.main
        case .gestures: return DSColors.error.main
        case .completion: return DSColors.success.main
        }
    }
    
    var interaction: TourInteraction? {
        switch self {
        case .gestures:
            return .gesture(.swipe(.right))
        case .insights:
            return .tooltip("Tap for details", .top)
        case .budgets:
            return .highlight(.button)
        default:
            return nil
        }
    }
}

enum TourInteraction {
    case gesture(TourGesture)
    case tooltip(String, TooltipPosition)
    case highlight(HighlightArea)
}

enum TourGesture {
    case swipe(SwipeDirection)
    case pinch
    case longPress
    case doubleTap
    
    var instruction: String {
        switch self {
        case .swipe(let direction): return "swiping \(direction.rawValue)"
        case .pinch: return "pinching to zoom"
        case .longPress: return "long pressing"
        case .doubleTap: return "double tapping"
        }
    }
}

enum SwipeDirection: String {
    case left, right, up, down
}

enum TooltipPosition {
    case top, bottom
}

enum HighlightArea {
    case button, menu, fab
}

struct ActiveTooltip: Identifiable {
    let id = UUID()
    let title: String?
    let message: String
    let position: TooltipPosition
    let alignment: HorizontalAlignment
    let duration: TimeInterval
    let actionText: String?
    let action: (() -> Void)?
    
    init(
        title: String? = nil,
        message: String,
        position: TooltipPosition = .top,
        alignment: HorizontalAlignment = .center,
        duration: TimeInterval = 4.0,
        actionText: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.position = position
        self.alignment = alignment
        self.duration = duration
        self.actionText = actionText
        self.action = action
    }
}

// MARK: - Feature Tour Manager

class FeatureTourManager: ObservableObject {
    static let shared = FeatureTourManager()
    
    @Published var showingTour = false
    @Published var hasCompletedTour = false
    @Published var currentTooltip: ActiveTooltip?
    
    private init() {
        loadTourStatus()
    }
    
    func startTour() {
        guard !hasCompletedTour else { return }
        showingTour = true
    }
    
    func completeTour() {
        hasCompletedTour = true
        showingTour = false
        saveTourStatus()
    }
    
    func skipTour() {
        hasCompletedTour = true
        showingTour = false
        saveTourStatus()
    }
    
    func showTooltip(_ tooltip: ActiveTooltip) {
        currentTooltip = tooltip
    }
    
    func dismissTooltip() {
        currentTooltip = nil
    }
    
    func resetTour() {
        hasCompletedTour = false
        showingTour = false
        currentTooltip = nil
        saveTourStatus()
    }
    
    private func loadTourStatus() {
        hasCompletedTour = UserDefaults.standard.bool(forKey: "hasCompletedFeatureTour")
    }
    
    private func saveTourStatus() {
        UserDefaults.standard.set(hasCompletedTour, forKey: "hasCompletedFeatureTour")
    }
}

// MARK: - Preview

#Preview("Feature Tour") {
    ZStack {
        // Background content
        VStack {
            Text("Background App Content")
                .font(DSTypography.title.title1)
                .foregroundColor(DSColors.neutral.text)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DSColors.neutral.background)
        
        // Tour overlay
        FeatureTour()
    }
}

#Preview("Tooltip Overlay") {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()
        
        TooltipOverlay(
            tooltip: ActiveTooltip(
                title: "New Feature",
                message: "This is a helpful tooltip explaining how to use this feature effectively.",
                actionText: "Got it"
            )
        ) {
            // Dismiss action
        }
    }
}
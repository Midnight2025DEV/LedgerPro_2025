import SwiftUI

/// LoadingStates - Consistent loading experiences
///
/// Comprehensive loading state system with skeleton screens, shimmer effects,
/// progress indicators, error states, and empty states for all major views.
struct LoadingStates {
    // MARK: - Skeleton Screens
    
    /// Transaction list skeleton with shimmer effect
    struct TransactionListSkeleton: View {
        @State private var isAnimating = false
        
        var body: some View {
            LazyVStack(spacing: DSSpacing.md) {
                ForEach(0..<8, id: \.self) { _ in
                    TransactionRowSkeleton()
                }
            }
            .padding(.horizontal, DSSpacing.lg)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
        }
    }
    
    /// Individual transaction row skeleton
    struct TransactionRowSkeleton: View {
        @State private var shimmerOffset: CGFloat = -200
        
        var body: some View {
            HStack(spacing: DSSpacing.md) {
                // Merchant icon placeholder
                Circle()
                    .fill(DSColors.neutral.n200.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .overlay(shimmerOverlay)
                
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    // Description placeholder
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DSColors.neutral.n200.opacity(0.3))
                        .frame(width: CGFloat.random(in: 120...200), height: 16)
                        .overlay(shimmerOverlay)
                    
                    // Category and date placeholder
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DSColors.neutral.n200.opacity(0.2))
                        .frame(width: CGFloat.random(in: 80...140), height: 12)
                        .overlay(shimmerOverlay)
                }
                
                Spacer()
                
                // Amount placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(DSColors.neutral.n200.opacity(0.3))
                    .frame(width: CGFloat.random(in: 60...90), height: 16)
                    .overlay(shimmerOverlay)
            }
            .padding(.horizontal, DSSpacing.md)
            .padding(.vertical, DSSpacing.sm)
            .background(.ultraThinMaterial)
            .cornerRadius(DSSpacing.radius.lg)
            .onAppear {
                startShimmerAnimation()
            }
        }
        
        private var shimmerOverlay: some View {
            LinearGradient(
                colors: [
                    Color.clear,
                    DSColors.neutral.n100.opacity(0.5),
                    Color.clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 100)
            .offset(x: shimmerOffset)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: shimmerOffset)
        }
        
        private func startShimmerAnimation() {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false).delay(Double.random(in: 0...0.5))) {
                shimmerOffset = 300
            }
        }
    }
    
    /// Dashboard overview skeleton
    struct DashboardSkeleton: View {
        var body: some View {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: DSSpacing.xl) {
                    // Balance hero card skeleton
                    BalanceHeroSkeleton()
                    
                    // Quick stats skeleton
                    QuickStatsSkeleton()
                    
                    // Chart skeleton
                    ChartSkeleton()
                    
                    // Recent transactions skeleton
                    VStack(alignment: .leading, spacing: DSSpacing.lg) {
                        HeaderSkeleton(width: 150)
                        
                        LazyVStack(spacing: DSSpacing.sm) {
                            ForEach(0..<5, id: \.self) { _ in
                                TransactionRowSkeleton()
                            }
                        }
                    }
                }
                .padding(.horizontal, DSSpacing.lg)
            }
        }
    }
    
    /// Balance hero card skeleton
    struct BalanceHeroSkeleton: View {
        @State private var pulseAnimation = false
        
        var body: some View {
            VStack(spacing: DSSpacing.xl) {
                // Balance amount placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(DSColors.neutral.n200.opacity(0.3))
                    .frame(width: 200, height: 48)
                    .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)
                
                // Trend indicator placeholder
                HStack(spacing: DSSpacing.sm) {
                    Circle()
                        .fill(DSColors.neutral.n200.opacity(0.2))
                        .frame(width: 16, height: 16)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DSColors.neutral.n200.opacity(0.2))
                        .frame(width: 120, height: 14)
                }
                .scaleEffect(pulseAnimation ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.3), value: pulseAnimation)
            }
            .padding(DSSpacing.xl)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .cornerRadius(DSSpacing.radius.xl)
            .onAppear {
                pulseAnimation = true
            }
        }
    }
    
    /// Quick stats grid skeleton
    struct QuickStatsSkeleton: View {
        var body: some View {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DSSpacing.lg), count: 2), spacing: DSSpacing.lg) {
                ForEach(0..<4, id: \.self) { index in
                    StatCardSkeleton()
                        .opacity(0.8)
                        .scaleEffect(0.95)
                        .animation(.easeInOut(duration: 1.0).delay(Double(index) * 0.1), value: true)
                }
            }
        }
    }
    
    /// Individual stat card skeleton
    struct StatCardSkeleton: View {
        @State private var isAnimating = false
        
        var body: some View {
            VStack(spacing: DSSpacing.md) {
                HStack {
                    Circle()
                        .fill(DSColors.neutral.n200.opacity(0.3))
                        .frame(width: 32, height: 32)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DSColors.neutral.n200.opacity(0.3))
                        .frame(width: CGFloat.random(in: 80...120), height: 20)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DSColors.neutral.n200.opacity(0.2))
                        .frame(width: CGFloat.random(in: 60...100), height: 14)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DSColors.neutral.n200.opacity(0.2))
                        .frame(width: CGFloat.random(in: 40...80), height: 12)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(DSSpacing.lg)
            .background(.ultraThinMaterial)
            .cornerRadius(DSSpacing.radius.lg)
            .scaleEffect(isAnimating ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(Double.random(in: 0...1))) {
                    isAnimating = true
                }
            }
        }
    }
    
    /// Chart placeholder skeleton
    struct ChartSkeleton: View {
        @State private var waveAnimation = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                HeaderSkeleton(width: 180)
                
                VStack(spacing: DSSpacing.md) {
                    // Chart bars simulation
                    HStack(alignment: .bottom, spacing: DSSpacing.sm) {
                        ForEach(0..<12, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            DSColors.primary.main.opacity(0.3),
                                            DSColors.primary.main.opacity(0.1)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 20, height: CGFloat.random(in: 30...120))
                                .scaleEffect(y: waveAnimation ? CGFloat.random(in: 0.8...1.2) : 1.0)
                                .animation(
                                    .easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.1),
                                    value: waveAnimation
                                )
                        }
                    }
                    .frame(height: 120)
                    
                    // X-axis labels
                    HStack {
                        ForEach(0..<6, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(DSColors.neutral.n200.opacity(0.2))
                                .frame(width: 30, height: 10)
                            
                            if index < 5 { Spacer() }
                        }
                    }
                }
                .padding(DSSpacing.lg)
                .background(.ultraThinMaterial)
                .cornerRadius(DSSpacing.radius.lg)
            }
            .onAppear {
                waveAnimation = true
            }
        }
    }
    
    /// Budget card skeleton
    struct BudgetCardSkeleton: View {
        @State private var progressAnimation: CGFloat = 0
        
        var body: some View {
            HStack(spacing: DSSpacing.lg) {
                // Progress ring skeleton
                ZStack {
                    Circle()
                        .stroke(DSColors.neutral.n200.opacity(0.2), lineWidth: 6)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: progressAnimation)
                        .stroke(DSColors.primary.main.opacity(0.3), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: progressAnimation)
                }
                
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DSColors.neutral.n200.opacity(0.3))
                        .frame(width: 120, height: 16)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DSColors.neutral.n200.opacity(0.2))
                        .frame(width: 90, height: 14)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DSColors.neutral.n200.opacity(0.2))
                        .frame(width: 70, height: 12)
                }
                
                Spacer()
            }
            .padding(DSSpacing.lg)
            .background(.ultraThinMaterial)
            .cornerRadius(DSSpacing.radius.lg)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.5)) {
                    progressAnimation = 0.7
                }
            }
        }
    }
    
    /// Generic header skeleton
    struct HeaderSkeleton: View {
        let width: CGFloat
        
        var body: some View {
            RoundedRectangle(cornerRadius: 6)
                .fill(DSColors.neutral.n200.opacity(0.3))
                .frame(width: width, height: 24)
        }
    }
}

// MARK: - Progress Indicators

extension LoadingStates {
    /// File import progress indicator
    struct ImportProgress: View {
        let progress: Double
        let stage: ImportStage
        let fileName: String?
        
        @State private var pulseAnimation = false
        
        var body: some View {
            VStack(spacing: DSSpacing.xl) {
                // Progress animation
                ZStack {
                    Circle()
                        .stroke(DSColors.neutral.n200.opacity(0.3), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(
                            LinearGradient(
                                colors: [DSColors.primary.main, DSColors.primary.p600],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: progress)
                    
                    VStack(spacing: DSSpacing.xs) {
                        Image(systemName: stage.icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(DSColors.primary.main)
                            .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseAnimation)
                        
                        Text("\(Int(progress * 100))%")
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.neutral.text)
                    }
                }
                
                VStack(spacing: DSSpacing.md) {
                    Text(stage.displayName)
                        .font(DSTypography.title.title3)
                        .foregroundColor(DSColors.neutral.text)
                    
                    if let fileName = fileName {
                        Text("Processing \(fileName)")
                            .font(DSTypography.body.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Text(stage.description)
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textTertiary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(DSSpacing.xl)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .cornerRadius(DSSpacing.radius.xl)
            .onAppear {
                pulseAnimation = true
            }
        }
    }
    
    enum ImportStage {
        case uploading, parsing, categorizing, analyzing, completed
        
        var icon: String {
            switch self {
            case .uploading: return "arrow.up.doc"
            case .parsing: return "doc.text.magnifyingglass"
            case .categorizing: return "brain.head.profile"
            case .analyzing: return "chart.xyaxis.line"
            case .completed: return "checkmark.circle.fill"
            }
        }
        
        var displayName: String {
            switch self {
            case .uploading: return "Uploading..."
            case .parsing: return "Reading Document"
            case .categorizing: return "AI Categorization"
            case .analyzing: return "Generating Insights"
            case .completed: return "Import Complete"
            }
        }
        
        var description: String {
            switch self {
            case .uploading: return "Securely uploading your file"
            case .parsing: return "Extracting transaction data"
            case .categorizing: return "Intelligently categorizing transactions"
            case .analyzing: return "Creating spending insights"
            case .completed: return "Ready to explore your data"
            }
        }
    }
}

// MARK: - Error States

extension LoadingStates {
    /// Generic error state with retry action
    struct ErrorState: View {
        let title: String
        let message: String
        let retryAction: (() -> Void)?
        let icon: String
        
        @State private var hasAppeared = false
        
        init(
            title: String = "Something went wrong",
            message: String = "Please try again",
            icon: String = "exclamationmark.triangle.fill",
            retryAction: (() -> Void)? = nil
        ) {
            self.title = title
            self.message = message
            self.icon = icon
            self.retryAction = retryAction
        }
        
        var body: some View {
            VStack(spacing: DSSpacing.xl) {
                // Error icon
                ZStack {
                    Circle()
                        .fill(DSColors.error.main.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .scaleEffect(hasAppeared ? 1.0 : 0.5)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1), value: hasAppeared)
                    
                    Image(systemName: icon)
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundColor(DSColors.error.main)
                        .scaleEffect(hasAppeared ? 1.0 : 0.3)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.3), value: hasAppeared)
                }
                
                VStack(spacing: DSSpacing.md) {
                    Text(title)
                        .font(DSTypography.title.title2)
                        .foregroundColor(DSColors.neutral.text)
                        .multilineTextAlignment(.center)
                        .opacity(hasAppeared ? 1.0 : 0.0)
                        .offset(y: hasAppeared ? 0 : 20)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.5), value: hasAppeared)
                    
                    Text(message)
                        .font(DSTypography.body.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .opacity(hasAppeared ? 1.0 : 0.0)
                        .offset(y: hasAppeared ? 0 : 20)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.7), value: hasAppeared)
                }
                
                if let retryAction = retryAction {
                    Button(action: retryAction) {
                        HStack(spacing: DSSpacing.sm) {
                            Image(systemName: "arrow.clockwise")
                                .font(DSTypography.body.medium)
                            
                            Text("Try Again")
                                .font(DSTypography.body.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, DSSpacing.xl)
                        .padding(.vertical, DSSpacing.md)
                        .background(
                            Capsule()
                                .fill(DSColors.primary.main)
                        )
                    }
                    .buttonStyle(.plain)
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .scaleEffect(hasAppeared ? 1.0 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.9), value: hasAppeared)
                }
            }
            .padding(DSSpacing.xl)
            .onAppear {
                hasAppeared = true
            }
        }
    }
    
    /// Network error state
    struct NetworkErrorState: View {
        let retryAction: () -> Void
        
        var body: some View {
            ErrorState(
                title: "Network Error",
                message: "Please check your internet connection and try again.",
                icon: "wifi.slash",
                retryAction: retryAction
            )
        }
    }
    
    /// Import error state
    struct ImportErrorState: View {
        let fileName: String
        let error: ImportError
        let retryAction: () -> Void
        
        var body: some View {
            ErrorState(
                title: "Import Failed",
                message: "Could not process \(fileName). \(error.localizedDescription)",
                icon: "doc.badge.exclamationmark",
                retryAction: retryAction
            )
        }
    }
    
    enum ImportError: Error, LocalizedError {
        case unsupported, corrupted, tooLarge, parsing
        
        var errorDescription: String? {
            switch self {
            case .unsupported:
                return "File format not supported"
            case .corrupted:
                return "File appears to be corrupted"
            case .tooLarge:
                return "File is too large to process"
            case .parsing:
                return "Unable to extract transaction data"
            }
        }
    }
}

// MARK: - Empty States

extension LoadingStates {
    /// Generic empty state
    struct EmptyState: View {
        let title: String
        let message: String
        let icon: String
        let actionTitle: String?
        let action: (() -> Void)?
        
        @State private var hasAppeared = false
        
        init(
            title: String,
            message: String,
            icon: String,
            actionTitle: String? = nil,
            action: (() -> Void)? = nil
        ) {
            self.title = title
            self.message = message
            self.icon = icon
            self.actionTitle = actionTitle
            self.action = action
        }
        
        var body: some View {
            VStack(spacing: DSSpacing.xl) {
                // Empty state illustration
                ZStack {
                    Circle()
                        .fill(DSColors.neutral.n200.opacity(0.3))
                        .frame(width: 140, height: 140)
                        .scaleEffect(hasAppeared ? 1.0 : 0.5)
                        .animation(.spring(response: 1.0, dampingFraction: 0.6).delay(0.1), value: hasAppeared)
                    
                    Image(systemName: icon)
                        .font(.system(size: 44, weight: .light))
                        .foregroundColor(DSColors.neutral.textTertiary)
                        .scaleEffect(hasAppeared ? 1.0 : 0.3)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3), value: hasAppeared)
                }
                
                VStack(spacing: DSSpacing.md) {
                    Text(title)
                        .font(DSTypography.title.title2)
                        .foregroundColor(DSColors.neutral.text)
                        .multilineTextAlignment(.center)
                        .opacity(hasAppeared ? 1.0 : 0.0)
                        .offset(y: hasAppeared ? 0 : 20)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.5), value: hasAppeared)
                    
                    Text(message)
                        .font(DSTypography.body.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .opacity(hasAppeared ? 1.0 : 0.0)
                        .offset(y: hasAppeared ? 0 : 20)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.7), value: hasAppeared)
                }
                
                if let actionTitle = actionTitle, let action = action {
                    Button(action: action) {
                        Text(actionTitle)
                            .font(DSTypography.body.semibold)
                            .foregroundColor(DSColors.primary.main)
                            .padding(.horizontal, DSSpacing.lg)
                            .padding(.vertical, DSSpacing.sm)
                            .background(.ultraThinMaterial)
                            .cornerRadius(DSSpacing.radius.lg)
                    }
                    .buttonStyle(.plain)
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .scaleEffect(hasAppeared ? 1.0 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.9), value: hasAppeared)
                }
            }
            .padding(DSSpacing.xl)
            .onAppear {
                hasAppeared = true
            }
        }
    }
    
    /// No transactions empty state
    struct NoTransactionsState: View {
        let onImport: () -> Void
        
        var body: some View {
            EmptyState(
                title: "No Transactions Yet",
                message: "Import your first statement to start analyzing your spending patterns and creating budgets.",
                icon: "tray",
                actionTitle: "Import Statement",
                action: onImport
            )
        }
    }
    
    /// No budgets empty state
    struct NoBudgetsState: View {
        let onCreate: () -> Void
        
        var body: some View {
            EmptyState(
                title: "No Budgets Created",
                message: "Create your first budget to start tracking spending goals and get personalized insights.",
                icon: "target",
                actionTitle: "Create Budget",
                action: onCreate
            )
        }
    }
    
    /// Search results empty state
    struct NoSearchResultsState: View {
        let searchTerm: String
        
        var body: some View {
            EmptyState(
                title: "No Results Found",
                message: "We couldn't find any transactions matching \"\(searchTerm)\". Try adjusting your search or filters.",
                icon: "magnifyingglass"
            )
        }
    }
}

// MARK: - Loading Overlay

extension LoadingStates {
    /// Full-screen loading overlay
    struct LoadingOverlay: View {
        let message: String
        let showBackground: Bool
        
        @State private var rotationAngle: Double = 0
        
        init(message: String = "Loading...", showBackground: Bool = true) {
            self.message = message
            self.showBackground = showBackground
        }
        
        var body: some View {
            ZStack {
                if showBackground {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                }
                
                VStack(spacing: DSSpacing.lg) {
                    // Spinning indicator
                    Circle()
                        .trim(from: 0, to: 0.8)
                        .stroke(
                            LinearGradient(
                                colors: [DSColors.primary.main, DSColors.primary.main.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(rotationAngle))
                        .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: rotationAngle)
                    
                    Text(message)
                        .font(DSTypography.body.medium)
                        .foregroundColor(DSColors.neutral.text)
                }
                .padding(DSSpacing.xl)
                .background(.ultraThinMaterial)
                .cornerRadius(DSSpacing.radius.xl)
            }
            .onAppear {
                rotationAngle = 360
            }
        }
    }
}

// MARK: - Preview

#Preview("Loading States") {
    TabView {
        ScrollView {
            VStack(spacing: DSSpacing.xl) {
                Text("Transaction List Skeleton")
                    .font(DSTypography.title.title3)
                
                LoadingStates.TransactionListSkeleton()
            }
            .padding()
        }
        .tabItem {
            Label("Skeleton", systemImage: "rectangle.3.group")
        }
        
        ScrollView {
            VStack(spacing: DSSpacing.xl) {
                LoadingStates.ImportProgress(
                    progress: 0.65,
                    stage: .categorizing,
                    fileName: "bank_statement.pdf"
                )
                
                LoadingStates.ErrorState(
                    title: "Upload Failed",
                    message: "The file could not be processed. Please try again.",
                    retryAction: {}
                )
            }
            .padding()
        }
        .tabItem {
            Label("Progress", systemImage: "progress.indicator")
        }
        
        ScrollView {
            VStack(spacing: DSSpacing.xl) {
                LoadingStates.NoTransactionsState(onImport: {})
                
                LoadingStates.NoBudgetsState(onCreate: {})
            }
            .padding()
        }
        .tabItem {
            Label("Empty", systemImage: "tray")
        }
    }
}
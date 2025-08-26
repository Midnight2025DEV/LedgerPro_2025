import SwiftUI

/// OnboardingFlow - First-time user experience
///
/// Beautiful, engaging onboarding that introduces users to LedgerPro's
/// privacy-first approach and guides them through initial setup.
struct OnboardingFlow: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var onboardingManager = OnboardingManager()
    
    @State private var currentStep: OnboardingStep = .welcome
    @State private var progress: Double = 0.0
    @State private var showingImportSheet = false
    @State private var hasCompletedOnboarding = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dynamic background
                onboardingBackground
                
                // Content
                VStack(spacing: 0) {
                    // Progress indicator
                    progressIndicator
                    
                    // Step content
                    stepContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Navigation controls
                    navigationControls
                }
                .padding(.horizontal, DSSpacing.xl)
                .padding(.bottom, DSSpacing.xl)
            }
        }
        #if !os(macOS)
        .navigationBarHidden(true)
        #endif
        .interactiveDismissDisabled()
        .onAppear {
            startOnboarding()
        }
        .sheet(isPresented: $showingImportSheet) {
            // FileUploadView() - Your existing import view
            Text("Import Statement")
                .padding()
        }
    }
    
    // MARK: - Background
    
    @ViewBuilder
    private var onboardingBackground: some View {
        AnimatedGradientBackground(step: currentStep)
            .ignoresSafeArea()
    }
    
    // MARK: - Progress Indicator
    
    @ViewBuilder
    private var progressIndicator: some View {
        VStack(spacing: DSSpacing.md) {
            // Step dots
            HStack(spacing: DSSpacing.sm) {
                ForEach(OnboardingStep.allCases.indices, id: \.self) { index in
                    let step = OnboardingStep.allCases[index]
                    let isActive = step.rawValue <= currentStep.rawValue
                    let isCurrent = step == currentStep
                    
                    Circle()
                        .fill(isActive ? DSColors.primary.main : DSColors.neutral.n300)
                        .frame(width: isCurrent ? 12 : 8, height: isCurrent ? 12 : 8)
                        .scaleEffect(isCurrent ? 1.2 : 1.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentStep)
                }
            }
            .padding(.top, DSSpacing.xl)
            
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
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContent: some View {
        TabView(selection: $currentStep) {
            ForEach(OnboardingStep.allCases, id: \.self) { step in
                stepView(for: step)
                    .tag(step)
            }
        }
        #if !os(macOS)
        .tabViewStyle(.page(indexDisplayMode: .never))
        #endif
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentStep)
    }
    
    @ViewBuilder
    private func stepView(for step: OnboardingStep) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: DSSpacing.xl) {
                Spacer()
                    .frame(height: DSSpacing.xl)
                
                switch step {
                case .welcome:
                    WelcomeStep()
                case .privacy:
                    PrivacyStep()
                case .features:
                    FeaturesStep()
                case .importGuide:
                    ImportGuideStep(onImport: {
                        showingImportSheet = true
                    })
                case .budgetSetup:
                    BudgetSetupStep()
                case .completion:
                    CompletionStep()
                }
                
                Spacer()
                    .frame(height: DSSpacing.xl)
            }
            .padding(.horizontal, DSSpacing.lg)
        }
    }
    
    // MARK: - Navigation Controls
    
    @ViewBuilder
    private var navigationControls: some View {
        HStack(spacing: DSSpacing.lg) {
            // Skip button
            if currentStep != .completion {
                Button("Skip") {
                    completeOnboarding()
                }
                .font(DSTypography.body.medium)
                .foregroundColor(DSColors.neutral.textSecondary)
                .padding(.horizontal, DSSpacing.lg)
                .padding(.vertical, DSSpacing.md)
            } else {
                Spacer()
            }
            
            Spacer()
            
            // Primary action button
            Button(action: primaryAction) {
                HStack(spacing: DSSpacing.sm) {
                    Text(primaryActionText)
                        .font(DSTypography.body.semibold)
                    
                    if currentStep != .completion {
                        Image(systemName: "arrow.right")
                            .font(DSTypography.body.medium)
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, DSSpacing.xl)
                .padding(.vertical, DSSpacing.md)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [DSColors.primary.main, DSColors.primary.p600],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .buttonStyle(.plain)
            .scaleEffect(onboardingManager.isPrimaryButtonPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: onboardingManager.isPrimaryButtonPressed)
        }
        .padding(.top, DSSpacing.xl)
    }
    
    // MARK: - Computed Properties
    
    private var primaryActionText: String {
        switch currentStep {
        case .welcome: return "Get Started"
        case .privacy: return "I Understand"
        case .features: return "Explore Features"
        case .importGuide: return "Import Statement"
        case .budgetSetup: return "Create Budget"
        case .completion: return "Start Using LedgerPro"
        }
    }
    
    // MARK: - Actions
    
    private func startOnboarding() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3)) {
            progress = 0.2
        }
    }
    
    private func primaryAction() {
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        #endif
        
        onboardingManager.isPrimaryButtonPressed = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onboardingManager.isPrimaryButtonPressed = false
            
            switch currentStep {
            case .welcome:
                advanceToStep(.privacy)
            case .privacy:
                advanceToStep(.features)
            case .features:
                advanceToStep(.importGuide)
            case .importGuide:
                showingImportSheet = true
                // Don't advance automatically - wait for import completion
            case .budgetSetup:
                advanceToStep(.completion)
            case .completion:
                completeOnboarding()
            }
        }
    }
    
    private func advanceToStep(_ step: OnboardingStep) {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            currentStep = step
            progress = Double(step.rawValue + 1) / Double(OnboardingStep.allCases.count)
        }
    }
    
    private func completeOnboarding() {
        onboardingManager.completeOnboarding()
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
            hasCompletedOnboarding = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
}

// MARK: - Onboarding Steps

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case privacy = 1
    case features = 2
    case importGuide = 3
    case budgetSetup = 4
    case completion = 5
}

// MARK: - Step Views

struct WelcomeStep: View {
    @State private var hasAppeared = false
    
    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            // App icon with glow effect
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                DSColors.primary.main.opacity(0.3),
                                DSColors.primary.main.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(hasAppeared ? 1.0 : 0.5)
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .animation(.spring(response: 1.0, dampingFraction: 0.6).delay(0.2), value: hasAppeared)
                
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 60, weight: .semibold))
                    .foregroundColor(DSColors.primary.main)
                    .scaleEffect(hasAppeared ? 1.0 : 0.3)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.4), value: hasAppeared)
            }
            
            // Welcome text
            VStack(spacing: DSSpacing.lg) {
                Text("Welcome to LedgerPro")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(DSColors.neutral.text)
                    .multilineTextAlignment(.center)
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .offset(y: hasAppeared ? 0 : 20)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.6), value: hasAppeared)
                
                Text("Transform your financial statements into actionable insights with our privacy-first approach.")
                    .font(DSTypography.body.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .offset(y: hasAppeared ? 0 : 20)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.8), value: hasAppeared)
            }
            
            // Key benefits
            VStack(spacing: DSSpacing.md) {
                ForEach(Array(welcomeBenefits.enumerated()), id: \.offset) { index, benefit in
                    BenefitRow(
                        icon: benefit.icon,
                        title: benefit.title,
                        description: benefit.description
                    )
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .offset(x: hasAppeared ? 0 : -30)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.0 + Double(index) * 0.1), value: hasAppeared)
                }
            }
        }
        .onAppear {
            hasAppeared = true
        }
    }
    
    private var welcomeBenefits: [OnboardingBenefit] {
        [
            OnboardingBenefit(
                icon: "shield.fill",
                title: "Privacy First",
                description: "Your data never leaves your device"
            ),
            OnboardingBenefit(
                icon: "wand.and.stars",
                title: "AI-Powered",
                description: "Smart categorization and insights"
            ),
            OnboardingBenefit(
                icon: "chart.bar.fill",
                title: "Beautiful Reports",
                description: "Understand your finances at a glance"
            )
        ]
    }
}

struct PrivacyStep: View {
    @State private var hasAppeared = false
    
    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            // Privacy icon animation
            ZStack {
                Circle()
                    .fill(DSColors.success.main.opacity(0.1))
                    .frame(width: 160, height: 160)
                    .scaleEffect(hasAppeared ? 1.0 : 0.5)
                    .animation(.spring(response: 1.0, dampingFraction: 0.6).delay(0.2), value: hasAppeared)
                
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 50, weight: .semibold))
                    .foregroundColor(DSColors.success.main)
                    .scaleEffect(hasAppeared ? 1.0 : 0.3)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.4), value: hasAppeared)
            }
            
            VStack(spacing: DSSpacing.lg) {
                Text("Your Privacy Matters")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(DSColors.neutral.text)
                    .multilineTextAlignment(.center)
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .offset(y: hasAppeared ? 0 : 20)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.6), value: hasAppeared)
                
                Text("LedgerPro processes everything locally on your device. No cloud uploads, no data sharing, no tracking.")
                    .font(DSTypography.body.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .offset(y: hasAppeared ? 0 : 20)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.8), value: hasAppeared)
            }
            
            // Privacy features
            VStack(spacing: DSSpacing.lg) {
                ForEach(Array(privacyFeatures.enumerated()), id: \.offset) { index, feature in
                    PrivacyFeatureCard(feature: feature)
                        .opacity(hasAppeared ? 1.0 : 0.0)
                        .offset(y: hasAppeared ? 0 : 30)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.0 + Double(index) * 0.15), value: hasAppeared)
                }
            }
        }
        .onAppear {
            hasAppeared = true
        }
    }
    
    private var privacyFeatures: [PrivacyFeature] {
        [
            PrivacyFeature(
                icon: "iphone",
                title: "Local Processing",
                description: "All analysis happens on your device",
                color: DSColors.primary.main
            ),
            PrivacyFeature(
                icon: "nosign",
                title: "No Cloud Storage",
                description: "Your financial data stays with you",
                color: DSColors.error.main
            ),
            PrivacyFeature(
                icon: "eye.slash.fill",
                title: "Zero Tracking",
                description: "We don't collect usage analytics",
                color: DSColors.warning.main
            )
        ]
    }
}

struct FeaturesStep: View {
    @State private var hasAppeared = false
    @State private var selectedFeature = 0
    
    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            Text("Powerful Features")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(DSColors.neutral.text)
                .opacity(hasAppeared ? 1.0 : 0.0)
                .offset(y: hasAppeared ? 0 : 20)
                .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2), value: hasAppeared)
            
            // Feature carousel
            TabView(selection: $selectedFeature) {
                ForEach(Array(keyFeatures.enumerated()), id: \.offset) { index, feature in
                    FeatureCard(feature: feature)
                        .tag(index)
                }
            }
            #if !os(macOS)
        .tabViewStyle(.page(indexDisplayMode: .never))
        #endif
            .frame(height: 400)
            .opacity(hasAppeared ? 1.0 : 0.0)
            .scaleEffect(hasAppeared ? 1.0 : 0.9)
            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.4), value: hasAppeared)
            
            // Feature indicators
            HStack(spacing: DSSpacing.sm) {
                ForEach(keyFeatures.indices, id: \.self) { index in
                    Circle()
                        .fill(index == selectedFeature ? DSColors.primary.main : DSColors.neutral.n300)
                        .frame(width: 8, height: 8)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedFeature)
                }
            }
            .opacity(hasAppeared ? 1.0 : 0.0)
            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.6), value: hasAppeared)
        }
        .onAppear {
            hasAppeared = true
            startFeatureRotation()
        }
    }
    
    private func startFeatureRotation() {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                selectedFeature = (selectedFeature + 1) % keyFeatures.count
            }
        }
    }
    
    private var keyFeatures: [KeyFeature] {
        [
            KeyFeature(
                icon: "doc.text.magnifyingglass",
                title: "Smart Import",
                description: "Upload PDFs and CSVs for instant analysis",
                color: DSColors.primary.main
            ),
            KeyFeature(
                icon: "brain.head.profile",
                title: "AI Categorization",
                description: "Automatic transaction categorization with learning",
                color: DSColors.success.main
            ),
            KeyFeature(
                icon: "chart.pie.fill",
                title: "Beautiful Insights",
                description: "Interactive visualizations of your spending patterns",
                color: DSColors.warning.main
            ),
            KeyFeature(
                icon: "target",
                title: "Budget Management",
                description: "Set goals and track progress with smart recommendations",
                color: DSColors.info.main
            )
        ]
    }
}

struct ImportGuideStep: View {
    let onImport: () -> Void
    @State private var hasAppeared = false
    
    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            // Import illustration
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                DSColors.primary.main.opacity(0.1),
                                DSColors.primary.main.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 120)
                    .scaleEffect(hasAppeared ? 1.0 : 0.8)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: hasAppeared)
                
                VStack {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundColor(DSColors.primary.main)
                    
                    Text("PDF / CSV")
                        .font(DSTypography.body.semibold)
                        .foregroundColor(DSColors.primary.main)
                }
                .scaleEffect(hasAppeared ? 1.0 : 0.5)
                .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.4), value: hasAppeared)
            }
            
            VStack(spacing: DSSpacing.lg) {
                Text("Import Your First Statement")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(DSColors.neutral.text)
                    .multilineTextAlignment(.center)
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .offset(y: hasAppeared ? 0 : 20)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.6), value: hasAppeared)
                
                Text("Upload a bank statement or CSV file to see LedgerPro's AI categorization in action.")
                    .font(DSTypography.body.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .offset(y: hasAppeared ? 0 : 20)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.8), value: hasAppeared)
            }
            
            // Supported formats
            VStack(spacing: DSSpacing.md) {
                Text("Supported Formats")
                    .font(DSTypography.body.semibold)
                    .foregroundColor(DSColors.neutral.text)
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(1.0), value: hasAppeared)
                
                HStack(spacing: DSSpacing.lg) {
                    ForEach(supportedFormats, id: \.fileExtension) { format in
                        FormatCard(format: format)
                            .opacity(hasAppeared ? 1.0 : 0.0)
                            .offset(y: hasAppeared ? 0 : 20)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.2), value: hasAppeared)
                    }
                }
            }
        }
        .onAppear {
            hasAppeared = true
        }
    }
    
    private var supportedFormats: [SupportedFormat] {
        [
            SupportedFormat(fileExtension: "PDF", description: "Bank statements", icon: "doc.fill"),
            SupportedFormat(fileExtension: "CSV", description: "Exported data", icon: "tablecells.fill")
        ]
    }
}

struct BudgetSetupStep: View {
    @State private var hasAppeared = false
    
    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            // Budget icon
            ZStack {
                Circle()
                    .fill(DSColors.success.main.opacity(0.1))
                    .frame(width: 140, height: 140)
                    .scaleEffect(hasAppeared ? 1.0 : 0.5)
                    .animation(.spring(response: 1.0, dampingFraction: 0.6).delay(0.2), value: hasAppeared)
                
                Image(systemName: "target")
                    .font(.system(size: 45, weight: .semibold))
                    .foregroundColor(DSColors.success.main)
                    .scaleEffect(hasAppeared ? 1.0 : 0.3)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.4), value: hasAppeared)
            }
            
            VStack(spacing: DSSpacing.lg) {
                Text("Create Your First Budget")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(DSColors.neutral.text)
                    .multilineTextAlignment(.center)
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .offset(y: hasAppeared ? 0 : 20)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.6), value: hasAppeared)
                
                Text("Set spending goals and let LedgerPro help you stay on track with smart insights and recommendations.")
                    .font(DSTypography.body.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .offset(y: hasAppeared ? 0 : 20)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.8), value: hasAppeared)
            }
            
            // Budget preview
            BudgetPreviewCard()
                .opacity(hasAppeared ? 1.0 : 0.0)
                .scaleEffect(hasAppeared ? 1.0 : 0.9)
                .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(1.0), value: hasAppeared)
        }
        .onAppear {
            hasAppeared = true
        }
    }
}

struct CompletionStep: View {
    @State private var hasAppeared = false
    @State private var showingCelebration = false
    
    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            // Success animation
            ZStack {
                if showingCelebration {
                    ConfettiView()
                        .transition(.opacity)
                }
                
                Circle()
                    .fill(DSColors.success.main.opacity(0.1))
                    .frame(width: 180, height: 180)
                    .scaleEffect(hasAppeared ? 1.0 : 0.3)
                    .animation(.spring(response: 1.2, dampingFraction: 0.6).delay(0.2), value: hasAppeared)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60, weight: .semibold))
                    .foregroundColor(DSColors.success.main)
                    .scaleEffect(hasAppeared ? 1.0 : 0.1)
                    .animation(.spring(response: 0.8, dampingFraction: 0.5).delay(0.6), value: hasAppeared)
            }
            
            VStack(spacing: DSSpacing.lg) {
                Text("You're All Set!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(DSColors.neutral.text)
                    .multilineTextAlignment(.center)
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .offset(y: hasAppeared ? 0 : 30)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(1.0), value: hasAppeared)
                
                Text("Welcome to your new financial command center. Start exploring your data and discover insights you never knew existed.")
                    .font(DSTypography.body.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .offset(y: hasAppeared ? 0 : 30)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(1.2), value: hasAppeared)
            }
            
            // Final features highlight
            VStack(spacing: DSSpacing.md) {
                ForEach(Array(finalFeatures.enumerated()), id: \.offset) { index, feature in
                    CompletionFeatureRow(feature: feature)
                        .opacity(hasAppeared ? 1.0 : 0.0)
                        .offset(x: hasAppeared ? 0 : -50)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.4 + Double(index) * 0.1), value: hasAppeared)
                }
            }
        }
        .onAppear {
            hasAppeared = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                    showingCelebration = true
                }
            }
        }
    }
    
    private var finalFeatures: [CompletionFeature] {
        [
            CompletionFeature(icon: "sparkles", title: "Smart insights ready"),
            CompletionFeature(icon: "shield.checkered", title: "Privacy protected"),
            CompletionFeature(icon: "heart.fill", title: "Made with care")
        ]
    }
}

// MARK: - Supporting Views

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: DSSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(DSColors.primary.main)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(DSColors.primary.main.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(title)
                    .font(DSTypography.body.semibold)
                    .foregroundColor(DSColors.neutral.text)
                
                Text(description)
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, DSSpacing.md)
    }
}

struct PrivacyFeatureCard: View {
    let feature: PrivacyFeature
    
    var body: some View {
        HStack(spacing: DSSpacing.md) {
            Image(systemName: feature.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(feature.color)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(feature.color.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(feature.title)
                    .font(DSTypography.body.semibold)
                    .foregroundColor(DSColors.neutral.text)
                
                Text(feature.description)
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(DSSpacing.md)
        .background(.ultraThinMaterial)
        .cornerRadius(DSSpacing.radius.lg)
    }
}

struct FeatureCard: View {
    let feature: KeyFeature
    
    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            ZStack {
                Circle()
                    .fill(feature.color.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: feature.icon)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(feature.color)
            }
            
            VStack(spacing: DSSpacing.md) {
                Text(feature.title)
                    .font(DSTypography.title.title2)
                    .foregroundColor(DSColors.neutral.text)
                    .multilineTextAlignment(.center)
                
                Text(feature.description)
                    .font(DSTypography.body.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
        }
        .padding(DSSpacing.xl)
    }
}

struct FormatCard: View {
    let format: SupportedFormat
    
    var body: some View {
        VStack(spacing: DSSpacing.sm) {
            Image(systemName: format.icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(DSColors.primary.main)
            
            Text(format.fileExtension)
                .font(DSTypography.body.semibold)
                .foregroundColor(DSColors.neutral.text)
            
            Text(format.description)
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.neutral.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(DSSpacing.md)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .cornerRadius(DSSpacing.radius.lg)
    }
}

struct BudgetPreviewCard: View {
    var body: some View {
        HStack(spacing: DSSpacing.md) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(DSColors.success.main.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(DSColors.success.main, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                
                Text("70%")
                    .font(DSTypography.body.semibold)
                    .foregroundColor(DSColors.success.main)
            }
            
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Dining Out Budget")
                    .font(DSTypography.body.semibold)
                    .foregroundColor(DSColors.neutral.text)
                
                Text("$350 of $500 spent")
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                
                Text("5 days remaining")
                    .font(DSTypography.caption.small)
                    .foregroundColor(DSColors.neutral.textTertiary)
            }
            
            Spacer()
        }
        .padding(DSSpacing.lg)
        .background(.ultraThinMaterial)
        .cornerRadius(DSSpacing.radius.xl)
    }
}

struct CompletionFeatureRow: View {
    let feature: CompletionFeature
    
    var body: some View {
        HStack(spacing: DSSpacing.md) {
            Image(systemName: feature.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(DSColors.success.main)
            
            Text(feature.title)
                .font(DSTypography.body.medium)
                .foregroundColor(DSColors.neutral.text)
            
            Spacer()
        }
    }
}

// MARK: - Animated Background

struct AnimatedGradientBackground: View {
    let step: OnboardingStep
    @State private var animateGradient = false
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: animateGradient ? .topLeading : .bottomLeading,
                    endPoint: animateGradient ? .bottomTrailing : .topTrailing
                )
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                    animateGradient = true
                }
            }
            .onChange(of: step) { _, _ in
                withAnimation(.easeInOut(duration: 1.0)) {
                    // Gradient will update based on step
                }
            }
    }
    
    private var gradientColors: [Color] {
        switch step {
        case .welcome:
            return [DSColors.primary.main.opacity(0.1), DSColors.neutral.background]
        case .privacy:
            return [DSColors.success.main.opacity(0.1), DSColors.neutral.background]
        case .features:
            return [DSColors.warning.main.opacity(0.1), DSColors.neutral.background]
        case .importGuide:
            return [DSColors.info.main.opacity(0.1), DSColors.neutral.background]
        case .budgetSetup:
            return [DSColors.success.main.opacity(0.1), DSColors.neutral.background]
        case .completion:
            return [DSColors.primary.main.opacity(0.15), DSColors.success.main.opacity(0.1), DSColors.neutral.background]
        }
    }
}

struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<50, id: \.self) { index in
                Circle()
                    .fill(confettiColors.randomElement() ?? DSColors.primary.main)
                    .frame(width: CGFloat.random(in: 4...8), height: CGFloat.random(in: 4...8))
                    .position(
                        x: CGFloat.random(in: 0...300),
                        y: animate ? CGFloat.random(in: 300...600) : CGFloat.random(in: -100...0)
                    )
                    .animation(
                        .easeOut(duration: Double.random(in: 2...4))
                        .delay(Double.random(in: 0...2)),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
    
    private var confettiColors: [Color] {
        [
            DSColors.primary.main,
            DSColors.success.main,
            DSColors.warning.main,
            DSColors.error.main,
            DSColors.info.main
        ]
    }
}

// MARK: - Data Models

struct OnboardingBenefit {
    let icon: String
    let title: String
    let description: String
}

struct PrivacyFeature {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct KeyFeature {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct SupportedFormat {
    let fileExtension: String
    let description: String
    let icon: String
}

struct CompletionFeature {
    let icon: String
    let title: String
}

// MARK: - Onboarding Manager

class OnboardingManager: ObservableObject {
    @Published var isPrimaryButtonPressed = false
    @Published var hasCompletedOnboarding = false
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

// MARK: - Preview

#Preview("Onboarding Flow") {
    OnboardingFlow()
}
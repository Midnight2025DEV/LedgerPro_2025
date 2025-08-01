import SwiftUI

/// BudgetAmountPicker - Smart amount selection with haptic feedback
///
/// Intelligent budget amount picker with slider controls, quick select options,
/// historical spending suggestions, and delightful haptic feedback.
struct BudgetAmountPicker: View {
    @Binding var amount: Double
    let suggestions: [BudgetSuggestion]
    
    @State private var hasAppeared = false
    @State private var isEditing = false
    @State private var textAmount = ""
    @State private var sliderValue: Double = 0
    @State private var showingSuggestions = true
    @State private var lastHapticValue: Double = 0
    
    // Amount range
    private let minAmount: Double = 50
    private let maxAmount: Double = 5000
    private let hapticStep: Double = 50 // Trigger haptic every $50
    
    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            // Amount display
            amountDisplaySection
            
            // Smart suggestions
            if showingSuggestions && !suggestions.isEmpty {
                smartSuggestionsSection
            }
            
            // Slider with haptic feedback
            sliderSection
            
            // Quick amount buttons
            quickAmountButtons
            
            // Custom input toggle
            customInputSection
        }
        .onAppear {
            setupInitialState()
        }
        .onChange(of: sliderValue) { _, newValue in
            updateAmountFromSlider(newValue)
            triggerHapticFeedback(for: newValue)
        }
    }
    
    // MARK: - Amount Display Section
    
    @ViewBuilder
    private var amountDisplaySection: some View {
        VStack(spacing: DSSpacing.md) {
            Text("Budget Amount")
                .font(DSTypography.body.semibold)
                .foregroundColor(DSColors.neutral.text)
            
            // Large amount display
            VStack(spacing: DSSpacing.xs) {
                AnimatedNumber(value: amount, format: .currency())
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(DSColors.primary.main)
                    .contentTransition(.numericText())
                
                // Daily breakdown
                Text("≈ \((amount / 30).formatAsCurrency()) per day")
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.3).delay(0.5), value: hasAppeared)
            }
            .padding(.vertical, DSSpacing.lg)
            .frame(maxWidth: .infinity)
            .background(amountDisplayBackground)
            .cornerRadius(DSSpacing.radius.xl)
        }
    }
    
    @ViewBuilder
    private var amountDisplayBackground: some View {
        RoundedRectangle(cornerRadius: DSSpacing.radius.xl)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: DSSpacing.radius.xl)
                    .fill(
                        RadialGradient(
                            colors: [
                                DSColors.primary.main.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DSSpacing.radius.xl)
                    .stroke(DSColors.primary.main.opacity(0.2), lineWidth: 1)
            )
    }
    
    // MARK: - Smart Suggestions Section
    
    @ViewBuilder
    private var smartSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            HStack {
                Text("Smart Suggestions")
                    .font(DSTypography.body.semibold)
                    .foregroundColor(DSColors.neutral.text)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        showingSuggestions.toggle()
                    }
                }) {
                    Image(systemName: showingSuggestions ? "chevron.up" : "chevron.down")
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                }
                .buttonStyle(.plain)
            }
            
            if showingSuggestions {
                LazyVStack(spacing: DSSpacing.sm) {
                    ForEach(Array(suggestions.enumerated()), id: \.element.amount) { index, suggestion in
                        SuggestionCard(
                            suggestion: suggestion,
                            isSelected: abs(amount - suggestion.amount) < 1,
                            onSelect: {
                                selectSuggestion(suggestion)
                            }
                        )
                        .scaleEffect(hasAppeared ? 1.0 : 0.8)
                        .opacity(hasAppeared ? 1.0 : 0.0)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.8)
                            .delay(Double(index) * 0.1),
                            value: hasAppeared
                        )
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }
    
    // MARK: - Slider Section
    
    @ViewBuilder
    private var sliderSection: some View {
        VStack(spacing: DSSpacing.lg) {
            Text("Adjust Amount")
                .font(DSTypography.body.semibold)
                .foregroundColor(DSColors.neutral.text)
            
            // Custom slider with haptic feedback
            VStack(spacing: DSSpacing.md) {
                ZStack {
                    // Background track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(DSColors.neutral.n200.opacity(0.3))
                        .frame(height: 12)
                    
                    // Progress track
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        DSColors.primary.main,
                                        DSColors.primary.p600
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geometry.size.width * CGFloat((sliderValue - minAmount) / (maxAmount - minAmount)),
                                height: 12
                            )
                    }
                    .frame(height: 12)
                    
                    // Slider thumb
                    HStack {
                        Spacer()
                            .frame(width: sliderThumbPosition)
                        
                        ZStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 28, height: 28)
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            
                            Circle()
                                .fill(DSColors.primary.main)
                                .frame(width: 20, height: 20)
                        }
                        .scaleEffect(isEditing ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isEditing)
                        
                        Spacer()
                    }
                }
                .frame(height: 28)
                .gesture(sliderDragGesture)
                
                // Range labels
                HStack {
                    Text(minAmount.formatAsCurrency())
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                    
                    Spacer()
                    
                    Text(maxAmount.formatAsCurrency())
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                }
            }
        }
    }
    
    // MARK: - Quick Amount Buttons
    
    @ViewBuilder
    private var quickAmountButtons: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            Text("Quick Select")
                .font(DSTypography.body.semibold)
                .foregroundColor(DSColors.neutral.text)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DSSpacing.md), count: 4), spacing: DSSpacing.md) {
                ForEach(quickAmounts, id: \.self) { quickAmount in
                    QuickAmountButton(
                        amount: quickAmount,
                        isSelected: abs(amount - quickAmount) < 1,
                        onSelect: {
                            selectAmount(quickAmount)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Custom Input Section
    
    @ViewBuilder
    private var customInputSection: some View {
        VStack(spacing: DSSpacing.md) {
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    isEditing.toggle()
                    if isEditing {
                        textAmount = String(format: "%.0f", amount)
                    }
                }
            }) {
                HStack {
                    Image(systemName: "textformat.123")
                        .font(DSTypography.body.medium)
                    
                    Text(isEditing ? "Done" : "Enter Custom Amount")
                        .font(DSTypography.body.medium)
                }
                .foregroundColor(DSColors.primary.main)
                .padding(.horizontal, DSSpacing.lg)
                .padding(.vertical, DSSpacing.sm)
                .background(.ultraThinMaterial)
                .cornerRadius(DSSpacing.radius.lg)
            }
            .buttonStyle(.plain)
            
            if isEditing {
                HStack {
                    Text("$")
                        .font(DSTypography.body.semibold)
                        .foregroundColor(DSColors.neutral.text)
                    
                    TextField("0", text: $textAmount)
                        .font(DSTypography.body.regular)
                        #if !os(macOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: textAmount) { _, newValue in
                            if let value = Double(newValue), value >= minAmount && value <= maxAmount {
                                amount = value
                                updateSliderFromAmount()
                            }
                        }
                }
                .padding(.horizontal, DSSpacing.md)
                .padding(.vertical, DSSpacing.sm)
                .background(.ultraThinMaterial)
                .cornerRadius(DSSpacing.radius.lg)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var sliderThumbPosition: CGFloat {
        let progress = CGFloat((sliderValue - minAmount) / (maxAmount - minAmount))
        #if canImport(UIKit)
        return progress * (UIScreen.main.bounds.width - 80) // Approximate slider width
        #else
        return progress * 400 // Default width for macOS
        #endif
    }
    
    private var sliderDragGesture: some Gesture {
        DragGesture(coordinateSpace: .local)
            .onChanged { value in
                isEditing = true
                #if os(iOS)
                let screenWidth = UIScreen.main.bounds.width
                #else
                let screenWidth = 400 // Default width for macOS
                #endif
                let progress = max(0, min(1, value.location.x / CGFloat(screenWidth - 80)))
                let newValue = minAmount + (maxAmount - minAmount) * Double(progress)
                sliderValue = newValue
            }
            .onEnded { _ in
                isEditing = false
            }
    }
    
    private var quickAmounts: [Double] {
        [100, 250, 500, 750, 1000, 1500, 2000, 3000]
    }
    
    // MARK: - Actions
    
    private func setupInitialState() {
        sliderValue = amount
        textAmount = String(format: "%.0f", amount)
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
            hasAppeared = true
        }
    }
    
    private func updateAmountFromSlider(_ value: Double) {
        // Snap to nearest $25 increment
        let snappedValue = round(value / 25) * 25
        amount = max(minAmount, min(maxAmount, snappedValue))
        textAmount = String(format: "%.0f", amount)
    }
    
    private func updateSliderFromAmount() {
        sliderValue = amount
    }
    
    private func selectAmount(_ newAmount: Double) {
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        #endif
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            amount = newAmount
            sliderValue = newAmount
            textAmount = String(format: "%.0f", newAmount)
        }
    }
    
    private func selectSuggestion(_ suggestion: BudgetSuggestion) {
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        #endif
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            amount = suggestion.amount
            sliderValue = suggestion.amount
            textAmount = String(format: "%.0f", suggestion.amount)
        }
    }
    
    private func triggerHapticFeedback(for value: Double) {
        let threshold = hapticStep
        let currentStep = Int(value / threshold)
        let lastStep = Int(lastHapticValue / threshold)
        
        if currentStep != lastStep {
            #if os(iOS)
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            #endif
            lastHapticValue = value
        }
    }
}

// MARK: - Suggestion Card

struct SuggestionCard: View {
    let suggestion: BudgetSuggestion
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: DSSpacing.md) {
                // Amount
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    AnimatedNumber.amount(suggestion.amount)
                        .font(DSTypography.body.semibold)
                        .foregroundColor(DSColors.neutral.text)
                    
                    Text(suggestion.reason)
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Confidence indicator
                VStack(alignment: .trailing, spacing: DSSpacing.xs) {
                    Text("\(Int(suggestion.confidence * 100))%")
                        .font(DSTypography.caption.regular).fontWeight(.semibold)
                        .foregroundColor(confidenceColor)
                    
                    Text("confidence")
                        .font(DSTypography.caption.small)
                        .foregroundColor(DSColors.neutral.textTertiary)
                }
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(DSTypography.body.medium)
                        .foregroundColor(DSColors.primary.main)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(DSSpacing.md)
            .background(suggestionBackground)
            .cornerRadius(DSSpacing.radius.lg)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
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
    
    @ViewBuilder
    private var suggestionBackground: some View {
        RoundedRectangle(cornerRadius: DSSpacing.radius.lg)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: DSSpacing.radius.lg)
                    .stroke(
                        isSelected ? DSColors.primary.main.opacity(0.5) : DSColors.neutral.border.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
    }
    
    private var confidenceColor: Color {
        if suggestion.confidence >= 0.8 {
            return DSColors.success.main
        } else if suggestion.confidence >= 0.6 {
            return DSColors.warning.main
        } else {
            return DSColors.neutral.textSecondary
        }
    }
}

// MARK: - Quick Amount Button

struct QuickAmountButton: View {
    let amount: Double
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: DSSpacing.xs) {
                Text(formatQuickAmount(amount))
                    .font(DSTypography.body.semibold)
                    .foregroundColor(isSelected ? .white : DSColors.neutral.text)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DSSpacing.md)
            .background(quickAmountBackground)
            .cornerRadius(DSSpacing.radius.lg)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
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
    
    @ViewBuilder
    private var quickAmountBackground: some View {
        RoundedRectangle(cornerRadius: DSSpacing.radius.lg)
            .fill(isSelected ? DSColors.primary.main : Color.gray.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: DSSpacing.radius.lg)
                    .stroke(
                        isSelected ? DSColors.primary.main.opacity(0.3) : DSColors.neutral.border.opacity(0.3),
                        lineWidth: 1
                    )
            )
    }
    
    private func formatQuickAmount(_ amount: Double) -> String {
        if amount >= 1000 {
            return "$\(Int(amount / 1000))K"
        } else {
            return amount.formatAsCurrency()
        }
    }
}

// MARK: - Preview

#Preview("Budget Amount Picker") {
    VStack {
        BudgetAmountPicker(
            amount: .constant(500),
            suggestions: [
                BudgetSuggestion(amount: 400, reason: "Based on your dining history", confidence: 0.85, basedOn: .historicalAverage),
                BudgetSuggestion(amount: 600, reason: "Recommended for your income", confidence: 0.92, basedOn: .expertRecommendation),
                BudgetSuggestion(amount: 350, reason: "Similar to other users", confidence: 0.75, basedOn: .similarUsers)
            ]
        )
    }
    .padding()
    .background(
        LinearGradient(
            colors: [DSColors.neutral.background, DSColors.neutral.backgroundSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
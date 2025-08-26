import SwiftUI

/// AppearanceSettings - User customization preferences
///
/// Comprehensive appearance settings allowing users to customize their
/// LedgerPro experience with themes, colors, animations, and accessibility options.
struct AppearanceSettings: View {
    @StateObject private var appearanceManager = AppearanceManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var hasAppeared = false
    @State private var showingColorPicker = false
    @State private var selectedAccentColor = DSColors.primary.main
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: DSSpacing.xl) {
                    // Theme Selection
                    themeSelectionSection
                    
                    // Accent Color Picker
                    accentColorSection
                    
                    // Animation Preferences
                    animationPreferencesSection
                    
                    // Accessibility Options
                    accessibilitySection
                    
                    // Display Options
                    displayOptionsSection
                    
                    // Reset Section
                    resetSection
                }
                .padding(.horizontal, DSSpacing.lg)
                .padding(.top, DSSpacing.lg)
            }
            .navigationTitle("Appearance")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(DSColors.primary.main)
                }
            }
        }
        .onAppear {
            setupInitialState()
        }
        .sheet(isPresented: $showingColorPicker) {
            ColorPickerView(selectedColor: $selectedAccentColor) {
                appearanceManager.setAccentColor(selectedAccentColor)
            }
        }
    }
    
    // MARK: - Theme Selection Section
    
    @ViewBuilder
    private var themeSelectionSection: some View {
        SettingsSection(
            title: "Theme",
            description: "Choose your preferred app appearance"
        ) {
            VStack(spacing: DSSpacing.lg) {
                // Theme preview cards
                HStack(spacing: DSSpacing.md) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        ThemePreviewCard(
                            theme: theme,
                            isSelected: appearanceManager.currentTheme == theme,
                            onSelect: {
                                selectTheme(theme)
                            }
                        )
                    }
                }
                
                // Auto theme description
                if appearanceManager.currentTheme == .auto {
                    Text("Automatically switches between light and dark based on your system settings.")
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                        .multilineTextAlignment(.center)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
        }
        .scaleEffect(hasAppeared ? 1.0 : 0.95)
        .opacity(hasAppeared ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: hasAppeared)
    }
    
    // MARK: - Accent Color Section
    
    @ViewBuilder
    private var accentColorSection: some View {
        SettingsSection(
            title: "Accent Color",
            description: "Personalize your app with your favorite color"
        ) {
            VStack(spacing: DSSpacing.lg) {
                // Current color preview
                AccentColorPreview(color: appearanceManager.accentColor)
                
                // Predefined color palette
                ColorPalette(
                    selectedColor: appearanceManager.accentColor,
                    onColorSelect: { color in
                        appearanceManager.setAccentColor(color)
                        triggerHapticFeedback(0)
                    }
                )
                
                // Custom color picker button
                Button(action: {
                    selectedAccentColor = appearanceManager.accentColor
                    showingColorPicker = true
                }) {
                    HStack {
                        Image(systemName: "eyedropper")
                            .font(DSTypography.body.medium)
                        
                        Text("Custom Color")
                            .font(DSTypography.body.medium)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                    }
                    .foregroundColor(DSColors.primary.main)
                    .padding(.horizontal, DSSpacing.md)
                    .padding(.vertical, DSSpacing.sm)
                    .background(.ultraThinMaterial)
                    .cornerRadius(DSSpacing.radius.lg)
                }
                .buttonStyle(.plain)
            }
        }
        .scaleEffect(hasAppeared ? 1.0 : 0.95)
        .opacity(hasAppeared ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: hasAppeared)
    }
    
    // MARK: - Animation Preferences Section
    
    @ViewBuilder
    private var animationPreferencesSection: some View {
        SettingsSection(
            title: "Animations",
            description: "Control motion and visual effects"
        ) {
            VStack(spacing: DSSpacing.md) {
                // Reduce motion toggle
                SettingsToggle(
                    title: "Reduce Motion",
                    description: "Minimize animations and transitions",
                    icon: "figure.walk.motion",
                    isOn: $appearanceManager.reduceMotion,
                    color: DSColors.info.main
                ) {
                    triggerHapticFeedback(1)
                }
                
                // Animation speed slider
                SettingsSlider(
                    title: "Animation Speed",
                    description: "Adjust the speed of transitions",
                    icon: "speedometer",
                    value: $appearanceManager.animationSpeed,
                    range: 0.5...2.0,
                    step: 0.1,
                    color: DSColors.primary.main,
                    isDisabled: appearanceManager.reduceMotion
                )
                
                // Haptic feedback toggle
                SettingsToggle(
                    title: "Haptic Feedback",
                    description: "Feel subtle vibrations for interactions",
                    icon: "iphone.radiowaves.left.and.right",
                    isOn: $appearanceManager.hapticFeedback,
                    color: DSColors.success.main
                ) {
                    if appearanceManager.hapticFeedback {
                        triggerHapticFeedback(1)
                    }
                }
                
                // Sound effects toggle
                SettingsToggle(
                    title: "Sound Effects",
                    description: "Play audio for important actions",
                    icon: "speaker.wave.2",
                    isOn: $appearanceManager.soundEffects,
                    color: DSColors.warning.main
                ) {
                    triggerHapticFeedback(0)
                }
            }
        }
        .scaleEffect(hasAppeared ? 1.0 : 0.95)
        .opacity(hasAppeared ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: hasAppeared)
    }
    
    // MARK: - Accessibility Section
    
    @ViewBuilder
    private var accessibilitySection: some View {
        SettingsSection(
            title: "Accessibility",
            description: "Improve readability and usability"
        ) {
            VStack(spacing: DSSpacing.md) {
                // Font size slider
                SettingsSlider(
                    title: "Font Size",
                    description: "Adjust text size for better readability",
                    icon: "textformat.size",
                    value: $appearanceManager.fontSize,
                    range: 0.8...1.4,
                    step: 0.1,
                    color: DSColors.info.main,
                    formatter: { value in
                        switch value {
                        case 0.8: return "Small"
                        case 0.9: return "Default"
                        case 1.0...1.1: return "Medium"
                        case 1.2...1.3: return "Large"
                        default: return "Extra Large"
                        }
                    }
                )
                
                // High contrast toggle
                SettingsToggle(
                    title: "High Contrast",
                    description: "Increase contrast for better visibility",
                    icon: "circle.lefthalf.filled",
                    isOn: $appearanceManager.highContrast,
                    color: DSColors.neutral.text
                ) {
                    triggerHapticFeedback(1)
                }
                
                // Bold text toggle
                SettingsToggle(
                    title: "Bold Text",
                    description: "Make text easier to read",
                    icon: "bold",
                    isOn: $appearanceManager.boldText,
                    color: DSColors.error.main
                ) {
                    triggerHapticFeedback(0)
                }
                
                // Smart invert toggle
                SettingsToggle(
                    title: "Smart Invert",
                    description: "Invert colors while preserving images",
                    icon: "circle.righthalf.filled",
                    isOn: $appearanceManager.smartInvert,
                    color: DSColors.warning.main
                ) {
                    triggerHapticFeedback(1)
                }
            }
        }
        .scaleEffect(hasAppeared ? 1.0 : 0.95)
        .opacity(hasAppeared ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: hasAppeared)
    }
    
    // MARK: - Display Options Section
    
    @ViewBuilder
    private var displayOptionsSection: some View {
        SettingsSection(
            title: "Display",
            description: "Customize how information is presented"
        ) {
            VStack(spacing: DSSpacing.md) {
                // Show decimal places toggle
                SettingsToggle(
                    title: "Show Decimal Places",
                    description: "Display cents in currency amounts",
                    icon: "dollarsign.circle",
                    isOn: $appearanceManager.showDecimalPlaces,
                    color: DSColors.success.main
                ) {
                    triggerHapticFeedback(0)
                }
                
                // Compact mode toggle
                SettingsToggle(
                    title: "Compact Mode",
                    description: "Show more information in less space",
                    icon: "rectangle.compress.vertical",
                    isOn: $appearanceManager.compactMode,
                    color: DSColors.primary.main
                ) {
                    triggerHapticFeedback(1)
                }
                
                // Show account numbers toggle
                SettingsToggle(
                    title: "Show Account Numbers",
                    description: "Display partial account numbers for identification",
                    icon: "number.circle",
                    isOn: $appearanceManager.showAccountNumbers,
                    color: DSColors.info.main
                ) {
                    triggerHapticFeedback(0)
                }
                
                // Group transactions by date toggle
                SettingsToggle(
                    title: "Group by Date",
                    description: "Organize transactions by day",
                    icon: "calendar.badge.clock",
                    isOn: $appearanceManager.groupTransactionsByDate,
                    color: DSColors.warning.main
                ) {
                    triggerHapticFeedback(0)
                }
            }
        }
        .scaleEffect(hasAppeared ? 1.0 : 0.95)
        .opacity(hasAppeared ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: hasAppeared)
    }
    
    // MARK: - Reset Section
    
    @ViewBuilder
    private var resetSection: some View {
        VStack(spacing: DSSpacing.lg) {
            Button(action: resetToDefaults) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                        .font(DSTypography.body.medium)
                    
                    Text("Reset to Defaults")
                        .font(DSTypography.body.semibold)
                }
                .foregroundColor(DSColors.error.main)
                .padding(.horizontal, DSSpacing.lg)
                .padding(.vertical, DSSpacing.md)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
                .cornerRadius(DSSpacing.radius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: DSSpacing.radius.lg)
                        .stroke(DSColors.error.main.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            
            Text("This will reset all appearance settings to their original values.")
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.neutral.textSecondary)
                .multilineTextAlignment(.center)
        }
        .scaleEffect(hasAppeared ? 1.0 : 0.95)
        .opacity(hasAppeared ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: hasAppeared)
    }
    
    // MARK: - Actions
    
    private func setupInitialState() {
        selectedAccentColor = appearanceManager.accentColor
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
            hasAppeared = true
        }
    }
    
    private func selectTheme(_ theme: AppTheme) {
        triggerHapticFeedback(1)
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            appearanceManager.setTheme(theme)
        }
    }
    
    private func resetToDefaults() {
        triggerHapticFeedback(2)
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
            appearanceManager.resetToDefaults()
        }
    }
    
    #if canImport(UIKit)
    private func triggerHapticFeedback(_ styleInt: Int) {
        guard appearanceManager.hapticFeedback else { return }
        
        let style: UIImpactFeedbackGenerator.FeedbackStyle = {
            switch styleInt {
            case 0: return .light
            case 1: return .medium
            case 2: return .heavy
            default: return .light
            }
        }()
        
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
    #else
    private func triggerHapticFeedback(_ style: Int) {
        // No haptic feedback on macOS
    }
    #endif
}

// MARK: - Supporting Views

struct SettingsSection<Content: View>: View {
    let title: String
    let description: String?
    let content: Content
    
    init(
        title: String,
        description: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.description = description
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(title)
                    .font(DSTypography.title.title3)
                    .foregroundColor(DSColors.neutral.text)
                
                if let description = description {
                    Text(description)
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                }
            }
            
            content
        }
        .padding(DSSpacing.lg)
        .background(.ultraThinMaterial)
        .cornerRadius(DSSpacing.radius.xl)
    }
}

struct ThemePreviewCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: DSSpacing.md) {
                // Theme preview
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.previewBackground)
                        .frame(width: 80, height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(theme.previewBorder, lineWidth: 1)
                        )
                    
                    // Mock content
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(theme.previewContent)
                            .frame(width: 50, height: 6)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(theme.previewContent.opacity(0.6))
                            .frame(width: 35, height: 4)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(theme.previewContent.opacity(0.4))
                            .frame(width: 40, height: 4)
                    }
                }
                
                Text(theme.displayName)
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.text)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DSSpacing.md)
            .background(selectionBackground)
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
    private var selectionBackground: some View {
        RoundedRectangle(cornerRadius: DSSpacing.radius.lg)
            .fill(isSelected ? DSColors.primary.main.opacity(0.1) : DSColors.neutral.backgroundCard)
            .overlay(
                RoundedRectangle(cornerRadius: DSSpacing.radius.lg)
                    .stroke(
                        isSelected ? DSColors.primary.main.opacity(0.5) : DSColors.neutral.border.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
    }
}

struct AccentColorPreview: View {
    let color: Color
    
    var body: some View {
        HStack(spacing: DSSpacing.lg) {
            // Color swatch
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(.white, lineWidth: 2)
                )
                .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
            
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Current Accent Color")
                    .font(DSTypography.body.semibold)
                    .foregroundColor(DSColors.neutral.text)
                
                Text("This color appears throughout the app")
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
            }
            
            Spacer()
        }
        .padding(DSSpacing.md)
        .background(.ultraThinMaterial)
        .cornerRadius(DSSpacing.radius.lg)
    }
}

struct ColorPalette: View {
    let selectedColor: Color
    let onColorSelect: (Color) -> Void
    
    private let colors: [Color] = [
        DSColors.primary.main,
        DSColors.success.main,
        DSColors.warning.main,
        DSColors.error.main,
        DSColors.info.main,
        Color.purple,
        Color.pink,
        Color.orange,
        Color.indigo,
        Color.mint,
        Color.cyan,
        Color.brown
    ]
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: DSSpacing.md) {
            ForEach(colors.indices, id: \.self) { index in
                let color = colors[index]
                
                Button(action: {
                    onColorSelect(color)
                }) {
                    Circle()
                        .fill(color)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(.white, lineWidth: 2)
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected(color) ? DSColors.neutral.text : Color.clear,
                                    lineWidth: 3
                                )
                                .scaleEffect(1.2)
                        )
                        .scaleEffect(isSelected(color) ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected(color))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func isSelected(_ color: Color) -> Bool {
        // Simple color comparison - in production you'd want a more robust comparison
        color == selectedColor
    }
}

struct SettingsToggle: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isOn: Bool
    let color: Color
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: DSSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(title)
                    .font(DSTypography.body.semibold)
                    .foregroundColor(DSColors.neutral.text)
                
                Text(description)
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .onChange(of: isOn) { _, _ in
                    onToggle()
                }
        }
        .padding(.horizontal, DSSpacing.md)
        .padding(.vertical, DSSpacing.sm)
        .background(.ultraThinMaterial)
        .cornerRadius(DSSpacing.radius.lg)
    }
}

struct SettingsSlider: View {
    let title: String
    let description: String
    let icon: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let color: Color
    let isDisabled: Bool
    let formatter: ((Double) -> String)?
    
    init(
        title: String,
        description: String,
        icon: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        color: Color,
        isDisabled: Bool = false,
        formatter: ((Double) -> String)? = nil
    ) {
        self.title = title
        self.description = description
        self.icon = icon
        self._value = value
        self.range = range
        self.step = step
        self.color = color
        self.isDisabled = isDisabled
        self.formatter = formatter
    }
    
    var body: some View {
        VStack(spacing: DSSpacing.md) {
            HStack(spacing: DSSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isDisabled ? DSColors.neutral.textTertiary : color)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill((isDisabled ? DSColors.neutral.textTertiary : color).opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text(title)
                        .font(DSTypography.body.semibold)
                        .foregroundColor(isDisabled ? DSColors.neutral.textTertiary : DSColors.neutral.text)
                    
                    Text(description)
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Text(formattedValue)
                    .font(DSTypography.caption.regular)
                    .foregroundColor(isDisabled ? DSColors.neutral.textTertiary : color)
                    .frame(minWidth: 60, alignment: .trailing)
            }
            
            Slider(value: $value, in: range, step: step)
                .tint(isDisabled ? DSColors.neutral.textTertiary : color)
                .disabled(isDisabled)
                .opacity(isDisabled ? 0.5 : 1.0)
        }
        .padding(.horizontal, DSSpacing.md)
        .padding(.vertical, DSSpacing.sm)
        .background(.ultraThinMaterial)
        .cornerRadius(DSSpacing.radius.lg)
    }
    
    private var formattedValue: String {
        if let formatter = formatter {
            return formatter(value)
        } else {
            return String(format: "%.1f", value)
        }
    }
}

// MARK: - Custom Color Picker

struct ColorPickerView: View {
    @Binding var selectedColor: Color
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: DSSpacing.xl) {
                // Color preview
                Circle()
                    .fill(selectedColor)
                    .frame(width: 120, height: 120)
                    .shadow(color: selectedColor.opacity(0.4), radius: 8, x: 0, y: 4)
                
                // Color picker
                ColorPicker("Select Color", selection: $selectedColor, supportsOpacity: false)
                    .labelsHidden()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Custom Color")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .foregroundColor(DSColors.primary.main)
                }
            }
        }
    }
}

// MARK: - Appearance Manager

class AppearanceManager: ObservableObject {
    static let shared = AppearanceManager()
    
    @Published var currentTheme: AppTheme = .auto
    @Published var accentColor: Color = DSColors.primary.main
    @Published var reduceMotion: Bool = false
    @Published var animationSpeed: Double = 1.0
    @Published var hapticFeedback: Bool = true
    @Published var soundEffects: Bool = true
    @Published var fontSize: Double = 1.0
    @Published var highContrast: Bool = false
    @Published var boldText: Bool = false
    @Published var smartInvert: Bool = false
    @Published var showDecimalPlaces: Bool = true
    @Published var compactMode: Bool = false
    @Published var showAccountNumbers: Bool = false
    @Published var groupTransactionsByDate: Bool = true
    
    private init() {
        loadSettings()
    }
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        saveSettings()
    }
    
    func setAccentColor(_ color: Color) {
        accentColor = color
        saveSettings()
    }
    
    func resetToDefaults() {
        currentTheme = .auto
        accentColor = DSColors.primary.main
        reduceMotion = false
        animationSpeed = 1.0
        hapticFeedback = true
        soundEffects = true
        fontSize = 1.0
        highContrast = false
        boldText = false
        smartInvert = false
        showDecimalPlaces = true
        compactMode = false
        showAccountNumbers = false
        groupTransactionsByDate = true
        
        saveSettings()
    }
    
    private func loadSettings() {
        // In a real app, load from UserDefaults
    }
    
    private func saveSettings() {
        // In a real app, save to UserDefaults
    }
}

// MARK: - App Theme

enum AppTheme: String, CaseIterable {
    case auto, light, dark
    
    var displayName: String {
        switch self {
        case .auto: return "Auto"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    var previewBackground: Color {
        switch self {
        case .auto: return Color.gray.opacity(0.1)
        case .light: return Color.white
        case .dark: return Color.black
        }
    }
    
    var previewBorder: Color {
        switch self {
        case .auto: return Color.gray.opacity(0.3)
        case .light: return Color.gray.opacity(0.3)
        case .dark: return Color.white.opacity(0.3)
        }
    }
    
    var previewContent: Color {
        switch self {
        case .auto: return Color.primary
        case .light: return Color.black
        case .dark: return Color.white
        }
    }
}

// MARK: - Preview

#Preview("Appearance Settings") {
    AppearanceSettings()
}
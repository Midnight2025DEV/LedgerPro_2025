import SwiftUI

/// DesignSystemDebugMenu - Developer tools and debugging utilities
///
/// Comprehensive debug menu for developers to test components, inspect design tokens,
/// toggle feature flags, monitor performance, and validate the design system.
struct DesignSystemDebugMenu: View {
    @StateObject private var debugManager = DebugManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab: DebugTab = .overview
    @State private var hasAppeared = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                tabSelector
                
                // Content
                TabView(selection: $selectedTab) {
                    OverviewTab()
                        .tag(DebugTab.overview)
                    
                    ComponentsTab()
                        .tag(DebugTab.components)
                    
                    DesignTokensTab()
                        .tag(DebugTab.tokens)
                    
                    PerformanceTab()
                        .tag(DebugTab.performance)
                    
                    FeatureFlagsTab()
                        .tag(DebugTab.flags)
                    
                    UtilitiesTab()
                        .tag(DebugTab.utilities)
                }
                #if !os(macOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif
            }
            .navigationTitle("Debug Menu")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(DSColors.error.main)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Reset All Settings") {
                            debugManager.resetAllSettings()
                        }
                        
                        Button("Export Debug Report") {
                            debugManager.exportDebugReport()
                        }
                        
                        Button("Clear Performance Data") {
                            debugManager.clearPerformanceData()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(DSColors.primary.main)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1)) {
                hasAppeared = true
            }
        }
    }
    
    @ViewBuilder
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DSSpacing.sm) {
                ForEach(DebugTab.allCases, id: \.self) { tab in
                    TabButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        onSelect: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                selectedTab = tab
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, DSSpacing.lg)
        }
        .padding(.vertical, DSSpacing.md)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let tab: DebugTab
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: DSSpacing.xs) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14, weight: .semibold))
                
                Text(tab.title)
                    .font(DSTypography.caption.regular).fontWeight(.semibold)
            }
            .foregroundColor(isSelected ? .white : DSColors.neutral.text)
            .padding(.horizontal, DSSpacing.md)
            .padding(.vertical, DSSpacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? DSColors.primary.main : Color.gray.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Overview Tab

struct OverviewTab: View {
    @StateObject private var debugManager = DebugManager.shared
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: DSSpacing.lg) {
                // System info
                systemInfoSection
                
                // Quick toggles
                quickTogglesSection
                
                // Performance overview
                performanceOverviewSection
                
                // Recent activities
                recentActivitiesSection
            }
            .padding(DSSpacing.lg)
        }
    }
    
    @ViewBuilder
    private var systemInfoSection: some View {
        DebugSection(title: "System Information") {
            VStack(spacing: DSSpacing.sm) {
                InfoRow(label: "App Version", value: "1.0.0 (Build 1)")
                InfoRow(label: "OS Version", value: ProcessInfo.processInfo.operatingSystemVersionString)
                InfoRow(label: "Device Model", value: debugManager.deviceModel)
                InfoRow(label: "Memory Usage", value: debugManager.memoryUsage)
                InfoRow(label: "Storage Used", value: debugManager.storageUsed)
                InfoRow(label: "Launch Time", value: "\(debugManager.launchTime)ms")
            }
        }
    }
    
    @ViewBuilder
    private var quickTogglesSection: some View {
        DebugSection(title: "Quick Toggles") {
            VStack(spacing: DSSpacing.md) {
                DebugToggle(
                    title: "Performance Overlay",
                    description: "Show FPS and memory usage",
                    isOn: $debugManager.showPerformanceOverlay
                )
                
                DebugToggle(
                    title: "Debug Borders",
                    description: "Outline all UI components",
                    isOn: $debugManager.showDebugBorders
                )
                
                DebugToggle(
                    title: "Slow Animations",
                    description: "Reduce animation speed for debugging",
                    isOn: $debugManager.slowAnimations
                )
                
                DebugToggle(
                    title: "Mock Data",
                    description: "Use generated test data",
                    isOn: $debugManager.useMockData
                )
            }
        }
    }
    
    @ViewBuilder
    private var performanceOverviewSection: some View {
        DebugSection(title: "Performance") {
            VStack(spacing: DSSpacing.md) {
                HStack {
                    PerformanceMetric(title: "FPS", value: "\(debugManager.currentFPS)", color: debugManager.fpsColor)
                    PerformanceMetric(title: "CPU", value: "\(debugManager.cpuUsage)%", color: debugManager.cpuColor)
                    PerformanceMetric(title: "Memory", value: debugManager.memoryUsage, color: debugManager.memoryColor)
                }
                
                if debugManager.hasPerformanceWarnings {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(DSColors.warning.main)
                        
                        Text("Performance issues detected")
                            .font(DSTypography.caption.regular).fontWeight(.medium)
                            .foregroundColor(DSColors.warning.main)
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var recentActivitiesSection: some View {
        DebugSection(title: "Recent Activities") {
            VStack(spacing: DSSpacing.sm) {
                ForEach(debugManager.recentActivities, id: \.id) { activity in
                    ActivityRow(activity: activity)
                }
                
                if debugManager.recentActivities.isEmpty {
                    Text("No recent activities")
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                        .padding(.vertical, DSSpacing.lg)
                }
            }
        }
    }
}

// MARK: - Components Tab

struct ComponentsTab: View {
    @State private var selectedComponent: ComponentType?
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: DSSpacing.lg) {
                    ForEach(ComponentType.allCases, id: \.self) { component in
                        ComponentTestCard(
                            component: component,
                            onTest: {
                                selectedComponent = component
                            }
                        )
                    }
                }
                .padding(DSSpacing.lg)
            }
            .navigationTitle("Components")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        .sheet(item: $selectedComponent) { component in
            ComponentTestView(component: component)
        }
    }
}

struct ComponentTestCard: View {
    let component: ComponentType
    let onTest: () -> Void
    
    var body: some View {
        HStack(spacing: DSSpacing.md) {
            Image(systemName: component.icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(component.color)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(component.color.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(component.name)
                    .font(DSTypography.body.semibold)
                    .foregroundColor(DSColors.neutral.text)
                
                Text(component.description)
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button("Test") {
                onTest()
            }
            .font(DSTypography.caption.regular).fontWeight(.semibold)
            .foregroundColor(DSColors.primary.main)
            .padding(.horizontal, DSSpacing.md)
            .padding(.vertical, DSSpacing.sm)
            .background(.ultraThinMaterial)
            .cornerRadius(DSSpacing.radius.sm)
        }
        .padding(DSSpacing.md)
        .background(.ultraThinMaterial)
        .cornerRadius(DSSpacing.radius.lg)
    }
}

// MARK: - Design Tokens Tab

struct DesignTokensTab: View {
    @State private var selectedTokenType: TokenType = .colors
    
    var body: some View {
        VStack(spacing: 0) {
            // Token type picker
            Picker("Token Type", selection: $selectedTokenType) {
                ForEach(TokenType.allCases, id: \.self) { type in
                    Text(type.title).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, DSSpacing.lg)
            .padding(.vertical, DSSpacing.md)
            
            // Token content
            ScrollView(.vertical, showsIndicators: false) {
                tokenContent
                    .padding(DSSpacing.lg)
            }
        }
    }
    
    @ViewBuilder
    private var tokenContent: some View {
        switch selectedTokenType {
        case .colors:
            colorTokens
        case .typography:
            typographyTokens
        case .spacing:
            spacingTokens
        case .elevation:
            elevationTokens
        }
    }
    
    @ViewBuilder
    private var colorTokens: some View {
        LazyVStack(spacing: DSSpacing.lg) {
            ColorTokenGroup(title: "Primary", colors: [
                ("primary.main", DSColors.primary.main),
                ("primary.p600", DSColors.primary.p600),
                ("primary.p300", DSColors.primary.p300)
            ])
            
            ColorTokenGroup(title: "Success", colors: [
                ("success.main", DSColors.success.main),
                ("success.s600", DSColors.success.s600),
                ("success.s300", DSColors.success.s300)
            ])
            
            ColorTokenGroup(title: "Warning", colors: [
                ("warning.main", DSColors.warning.main),
                ("warning.w600", DSColors.warning.w600),
                ("warning.w300", DSColors.warning.w300)
            ])
            
            ColorTokenGroup(title: "Error", colors: [
                ("error.main", DSColors.error.main),
                ("error.e600", DSColors.error.e600),
                ("error.e300", DSColors.error.e300)
            ])
            
            ColorTokenGroup(title: "Neutral", colors: [
                ("neutral.text", DSColors.neutral.text),
                ("neutral.textSecondary", DSColors.neutral.textSecondary),
                ("neutral.background", DSColors.neutral.background)
            ])
        }
    }
    
    @ViewBuilder
    private var typographyTokens: some View {
        LazyVStack(spacing: DSSpacing.lg) {
            TypographyTokenGroup(title: "Titles", tokens: [
                ("title.title1", DSTypography.title.title1),
                ("title.title2", DSTypography.title.title2),
                ("title.title3", DSTypography.title.title3)
            ])
            
            TypographyTokenGroup(title: "Body", tokens: [
                ("body.regular", DSTypography.body.regular),
                ("body.medium", DSTypography.body.medium),
                ("body.semibold", DSTypography.body.semibold),
                ("body.bold", DSTypography.body.semibold)
            ])
            
            TypographyTokenGroup(title: "Caption", tokens: [
                ("caption.regular", DSTypography.caption.regular),
                // ("caption.medium", DSTypography.caption.medium), // Not available
                // ("caption.semibold", DSTypography.caption.semibold), // Not available
                ("caption.small", DSTypography.caption.small)
            ])
        }
    }
    
    @ViewBuilder
    private var spacingTokens: some View {
        LazyVStack(spacing: DSSpacing.lg) {
            SpacingTokenGroup(title: "Spacing", tokens: [
                ("xs", DSSpacing.xs),
                ("sm", DSSpacing.sm),
                ("md", DSSpacing.md),
                ("lg", DSSpacing.lg),
                ("xl", DSSpacing.xl),
                ("xxl", DSSpacing.xxl)
            ])
            
            SpacingTokenGroup(title: "Radius", tokens: [
                ("radius.sm", DSSpacing.radius.sm),
                ("radius.md", DSSpacing.radius.md),
                ("radius.lg", DSSpacing.radius.lg),
                ("radius.xl", DSSpacing.radius.xl)
            ])
        }
    }
    
    @ViewBuilder
    private var elevationTokens: some View {
        LazyVStack(spacing: DSSpacing.lg) {
            ForEach(0..<5, id: \.self) { level in
                ElevationDemo(level: level)
            }
        }
    }
}

// MARK: - Performance Tab

struct PerformanceTab: View {
    @StateObject private var debugManager = DebugManager.shared
    @State private var isMonitoring = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: DSSpacing.lg) {
                // Performance controls
                performanceControls
                
                // Real-time metrics
                realTimeMetrics
                
                // Performance history
                performanceHistory
                
                // Memory analysis
                memoryAnalysis
                
                // Recommendations
                performanceRecommendations
            }
            .padding(DSSpacing.lg)
        }
    }
    
    @ViewBuilder
    private var performanceControls: some View {
        DebugSection(title: "Performance Monitoring") {
            VStack(spacing: DSSpacing.md) {
                HStack {
                    Button(isMonitoring ? "Stop Monitoring" : "Start Monitoring") {
                        isMonitoring.toggle()
                        if isMonitoring {
                            debugManager.startPerformanceMonitoring()
                        } else {
                            debugManager.stopPerformanceMonitoring()
                        }
                    }
                    .font(DSTypography.body.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, DSSpacing.lg)
                    .padding(.vertical, DSSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: DSSpacing.radius.lg)
                            .fill(isMonitoring ? DSColors.error.main : DSColors.success.main)
                    )
                    
                    Spacer()
                    
                    Button("Export Data") {
                        debugManager.exportPerformanceData()
                    }
                    .font(DSTypography.body.medium)
                    .foregroundColor(DSColors.primary.main)
                }
                
                HStack {
                    DebugToggle(
                        title: "Show Overlay",
                        description: "Display performance metrics on screen",
                        isOn: $debugManager.showPerformanceOverlay
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private var realTimeMetrics: some View {
        DebugSection(title: "Real-time Metrics") {
            HStack(spacing: DSSpacing.lg) {
                DebugMetricCard(
                    title: "FPS",
                    value: "\(debugManager.currentFPS)",
                    subtitle: "Frames/sec",
                    color: debugManager.fpsColor
                )
                
                DebugMetricCard(
                    title: "CPU",
                    value: "\(debugManager.cpuUsage)%",
                    subtitle: "Usage",
                    color: debugManager.cpuColor
                )
                
                DebugMetricCard(
                    title: "Memory",
                    value: debugManager.memoryUsage,
                    subtitle: "Usage",
                    color: debugManager.memoryColor
                )
            }
        }
    }
    
    @ViewBuilder
    private var performanceHistory: some View {
        DebugSection(title: "Performance History") {
            VStack(spacing: DSSpacing.md) {
                // Simple performance chart would go here
                RoundedRectangle(cornerRadius: 8)
                    .fill(DSColors.neutral.n100.opacity(0.3))
                    .frame(height: 120)
                    .overlay(
                        Text("Performance Chart\n(Would show real metrics)")
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                            .multilineTextAlignment(.center)
                    )
                
                HStack {
                    Text("Last 60 seconds")
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                    
                    Spacer()
                    
                    Button("Clear History") {
                        debugManager.clearPerformanceHistory()
                    }
                    .font(DSTypography.caption.regular).fontWeight(.medium)
                    .foregroundColor(DSColors.error.main)
                }
            }
        }
    }
    
    @ViewBuilder
    private var memoryAnalysis: some View {
        DebugSection(title: "Memory Analysis") {
            VStack(spacing: DSSpacing.sm) {
                ForEach(debugManager.memoryBreakdown, id: \.component) { item in
                    HStack {
                        Text(item.component)
                            .font(DSTypography.caption.regular).fontWeight(.medium)
                            .foregroundColor(DSColors.neutral.text)
                        
                        Spacer()
                        
                        Text(item.usage)
                            .font(DSTypography.caption.regular).fontWeight(.semibold)
                            .foregroundColor(item.color)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var performanceRecommendations: some View {
        if !debugManager.performanceRecommendations.isEmpty {
            DebugSection(title: "Recommendations") {
                VStack(spacing: DSSpacing.sm) {
                    ForEach(debugManager.performanceRecommendations, id: \.id) { recommendation in
                        RecommendationRow(recommendation: recommendation)
                    }
                }
            }
        }
    }
}

// MARK: - Feature Flags Tab

struct FeatureFlagsTab: View {
    @StateObject private var featureFlagManager = FeatureFlagManager.shared
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: DSSpacing.lg) {
                ForEach(FeatureFlag.allCases, id: \.self) { flag in
                    FeatureFlagCard(flag: flag)
                }
            }
            .padding(DSSpacing.lg)
        }
    }
}

struct FeatureFlagCard: View {
    let flag: FeatureFlag
    @StateObject private var featureFlagManager = FeatureFlagManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text(flag.name)
                        .font(DSTypography.body.semibold)
                        .foregroundColor(DSColors.neutral.text)
                    
                    Text(flag.description)
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                        .lineLimit(nil)
                }
                
                Spacer()
                
                Toggle("", isOn: binding(for: flag))
            }
            
            if let rolloutPercentage = flag.rolloutPercentage {
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text("Rollout: \(Int(rolloutPercentage * 100))%")
                        .font(DSTypography.caption.regular).fontWeight(.medium)
                        .foregroundColor(DSColors.primary.main)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(DSColors.neutral.n200.opacity(0.3))
                                .frame(height: 4)
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(DSColors.primary.main)
                                .frame(width: geometry.size.width * CGFloat(rolloutPercentage), height: 4)
                        }
                    }
                    .frame(height: 4)
                }
            }
        }
        .padding(DSSpacing.md)
        .background(.ultraThinMaterial)
        .cornerRadius(DSSpacing.radius.lg)
    }
    
    private func binding(for flag: FeatureFlag) -> Binding<Bool> {
        Binding(
            get: { featureFlagManager.isEnabled(flag) },
            set: { featureFlagManager.setEnabled(flag, $0) }
        )
    }
}

// MARK: - Utilities Tab

struct UtilitiesTab: View {
    @StateObject private var debugManager = DebugManager.shared
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: DSSpacing.lg) {
                // Layout utilities
                layoutUtilities
                
                // Data utilities
                dataUtilities
                
                // Export utilities
                exportUtilities
                
                // Reset utilities
                resetUtilities
            }
            .padding(DSSpacing.lg)
        }
    }
    
    @ViewBuilder
    private var layoutUtilities: some View {
        DebugSection(title: "Layout Utilities") {
            VStack(spacing: DSSpacing.md) {
                UtilityButton(
                    title: "Show Layout Guides",
                    description: "Display grid and alignment guides",
                    icon: "grid",
                    action: {
                        debugManager.toggleLayoutGuides()
                    }
                )
                
                UtilityButton(
                    title: "Highlight Interactions",
                    description: "Show all tappable areas",
                    icon: "hand.tap",
                    action: {
                        debugManager.highlightInteractions()
                    }
                )
                
                UtilityButton(
                    title: "Screenshot All Views",
                    description: "Capture screenshots of every screen",
                    icon: "camera",
                    action: {
                        debugManager.screenshotAllViews()
                    }
                )
            }
        }
    }
    
    @ViewBuilder
    private var dataUtilities: some View {
        DebugSection(title: "Data Utilities") {
            VStack(spacing: DSSpacing.md) {
                UtilityButton(
                    title: "Load Sample Data",
                    description: "Populate with realistic test data",
                    icon: "doc.text.fill",
                    action: {
                        debugManager.loadSampleData()
                    }
                )
                
                UtilityButton(
                    title: "Clear All Data",
                    description: "Remove all stored data",
                    icon: "trash",
                    action: {
                        debugManager.clearAllData()
                    }
                )
                
                UtilityButton(
                    title: "Simulate Network Delay",
                    description: "Add artificial network latency",
                    icon: "wifi.slash",
                    action: {
                        debugManager.simulateNetworkDelay()
                    }
                )
            }
        }
    }
    
    @ViewBuilder
    private var exportUtilities: some View {
        DebugSection(title: "Export Utilities") {
            VStack(spacing: DSSpacing.md) {
                UtilityButton(
                    title: "Export Debug Log",
                    description: "Save detailed debug information",
                    icon: "doc.text.magnifyingglass",
                    action: {
                        debugManager.exportDebugLog()
                    }
                )
                
                UtilityButton(
                    title: "Export User Preferences",
                    description: "Save all user settings",
                    icon: "gear",
                    action: {
                        debugManager.exportUserPreferences()
                    }
                )
                
                UtilityButton(
                    title: "Generate Test Report",
                    description: "Create comprehensive test report",
                    icon: "chart.bar.doc.horizontal",
                    action: {
                        debugManager.generateTestReport()
                    }
                )
            }
        }
    }
    
    @ViewBuilder
    private var resetUtilities: some View {
        DebugSection(title: "Reset Utilities") {
            VStack(spacing: DSSpacing.md) {
                UtilityButton(
                    title: "Reset Onboarding",
                    description: "Show onboarding flow again",
                    icon: "arrow.counterclockwise",
                    action: {
                        debugManager.resetOnboarding()
                    }
                )
                
                UtilityButton(
                    title: "Reset Feature Tour",
                    description: "Enable feature tour tooltips",
                    icon: "questionmark.circle",
                    action: {
                        debugManager.resetFeatureTour()
                    }
                )
                
                UtilityButton(
                    title: "Factory Reset",
                    description: "Reset everything to defaults",
                    icon: "exclamationmark.triangle",
                    isDestructive: true,
                    action: {
                        debugManager.factoryReset()
                    }
                )
            }
        }
    }
}

// MARK: - Supporting Views

struct DebugSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            Text(title)
                .font(DSTypography.title.title3)
                .foregroundColor(DSColors.neutral.text)
            
            content
        }
        .padding(DSSpacing.lg)
        .background(.ultraThinMaterial)
        .cornerRadius(DSSpacing.radius.xl)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(DSTypography.caption.regular).fontWeight(.medium)
                .foregroundColor(DSColors.neutral.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(DSTypography.caption.regular).fontWeight(.semibold)
                .foregroundColor(DSColors.neutral.text)
        }
    }
}

struct DebugToggle: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(title)
                    .font(DSTypography.body.medium)
                    .foregroundColor(DSColors.neutral.text)
                
                Text(description)
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
        }
    }
}

struct PerformanceMetric: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DSSpacing.xs) {
            Text(value)
                .font(DSTypography.body.semibold)
                .foregroundColor(color)
            
            Text(title)
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.neutral.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DSSpacing.sm)
        .background(.ultraThinMaterial)
        .cornerRadius(DSSpacing.radius.sm)
    }
}

struct DebugMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DSSpacing.sm) {
            Text(value)
                .font(DSTypography.title.title3)
                .foregroundColor(color)
            
            VStack(spacing: DSSpacing.xs) {
                Text(title)
                    .font(DSTypography.caption.regular).fontWeight(.semibold)
                    .foregroundColor(DSColors.neutral.text)
                
                Text(subtitle)
                    .font(DSTypography.caption.small)
                    .foregroundColor(DSColors.neutral.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DSSpacing.md)
        .background(.ultraThinMaterial)
        .cornerRadius(DSSpacing.radius.lg)
    }
}

struct UtilityButton: View {
    let title: String
    let description: String
    let icon: String
    let isDestructive: Bool
    let action: () -> Void
    
    init(
        title: String,
        description: String,
        icon: String,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.description = description
        self.icon = icon
        self.isDestructive = isDestructive
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DSSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isDestructive ? DSColors.error.main : DSColors.primary.main)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text(title)
                        .font(DSTypography.body.medium)
                        .foregroundColor(isDestructive ? DSColors.error.main : DSColors.neutral.text)
                    
                    Text(description)
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
            }
            .padding(DSSpacing.md)
            .background(.ultraThinMaterial)
            .cornerRadius(DSSpacing.radius.lg)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Token Display Components

struct ColorTokenGroup: View {
    let title: String
    let colors: [(String, Color)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            Text(title)
                .font(DSTypography.body.semibold)
                .foregroundColor(DSColors.neutral.text)
            
            VStack(spacing: DSSpacing.sm) {
                ForEach(colors.indices, id: \.self) { index in
                    let (name, color) = colors[index]
                    
                    HStack {
                        Circle()
                            .fill(color)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(.white, lineWidth: 1)
                            )
                        
                        Text(name)
                            .font(DSTypography.caption.regular).fontWeight(.medium)
                            .foregroundColor(DSColors.neutral.text)
                        
                        Spacer()
                        
                        Text(color.hexString)
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                            .monospaced()
                    }
                }
            }
        }
        .padding(DSSpacing.md)
        .background(.ultraThinMaterial)
        .cornerRadius(DSSpacing.radius.lg)
    }
}

struct TypographyTokenGroup: View {
    let title: String
    let tokens: [(String, Font)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            Text(title)
                .font(DSTypography.body.semibold)
                .foregroundColor(DSColors.neutral.text)
            
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                ForEach(tokens.indices, id: \.self) { index in
                    let (name, font) = tokens[index]
                    
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text("The quick brown fox")
                            .font(font)
                            .foregroundColor(DSColors.neutral.text)
                        
                        Text(name)
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                            .monospaced()
                    }
                }
            }
        }
        .padding(DSSpacing.md)
        .background(.ultraThinMaterial)
        .cornerRadius(DSSpacing.radius.lg)
    }
}

struct SpacingTokenGroup: View {
    let title: String
    let tokens: [(String, CGFloat)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            Text(title)
                .font(DSTypography.body.semibold)
                .foregroundColor(DSColors.neutral.text)
            
            VStack(spacing: DSSpacing.sm) {
                ForEach(tokens.indices, id: \.self) { index in
                    let (name, value) = tokens[index]
                    
                    HStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(DSColors.primary.main)
                            .frame(width: value, height: 16)
                        
                        Text(name)
                            .font(DSTypography.caption.regular).fontWeight(.medium)
                            .foregroundColor(DSColors.neutral.text)
                        
                        Spacer()
                        
                        Text("\(Int(value))pt")
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                            .monospaced()
                    }
                }
            }
        }
        .padding(DSSpacing.md)
        .background(.ultraThinMaterial)
        .cornerRadius(DSSpacing.radius.lg)
    }
}

struct ElevationDemo: View {
    let level: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            Text("Elevation Level \(level)")
                .font(DSTypography.body.semibold)
                .foregroundColor(DSColors.neutral.text)
            
            RoundedRectangle(cornerRadius: DSSpacing.radius.lg)
                .fill(.ultraThinMaterial)
                .frame(height: 60)
                .shadow(
                    color: .black.opacity(Double(level) * 0.05),
                    radius: CGFloat(level * 2),
                    x: 0,
                    y: CGFloat(level)
                )
                .overlay(
                    Text("Shadow: radius \(level * 2)pt, y-offset \(level)pt")
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                )
        }
    }
}

// MARK: - Data Models and Enums

enum DebugTab: CaseIterable {
    case overview, components, tokens, performance, flags, utilities
    
    var title: String {
        switch self {
        case .overview: return "Overview"
        case .components: return "Components"
        case .tokens: return "Tokens"
        case .performance: return "Performance"
        case .flags: return "Flags"
        case .utilities: return "Utilities"
        }
    }
    
    var icon: String {
        switch self {
        case .overview: return "info.circle"
        case .components: return "square.stack.3d.up"
        case .tokens: return "paintbrush"
        case .performance: return "speedometer"
        case .flags: return "flag"
        case .utilities: return "wrench.and.screwdriver"
        }
    }
}

enum ComponentType: String, CaseIterable, Identifiable {
    case buttons, cards, forms, navigation, overlays, feedback
    
    var id: String { self.rawValue }
    
    var name: String {
        switch self {
        case .buttons: return "Buttons"
        case .cards: return "Cards"
        case .forms: return "Forms"
        case .navigation: return "Navigation"
        case .overlays: return "Overlays"
        case .feedback: return "Feedback"
        }
    }
    
    var description: String {
        switch self {
        case .buttons: return "Test all button variants and states"
        case .cards: return "Preview card layouts and interactions"
        case .forms: return "Validate form inputs and validation"
        case .navigation: return "Test navigation patterns"
        case .overlays: return "Modal and overlay behaviors"
        case .feedback: return "Loading states and animations"
        }
    }
    
    var icon: String {
        switch self {
        case .buttons: return "button.programmable"
        case .cards: return "rectangle.stack"
        case .forms: return "textformat"
        case .navigation: return "arrow.left.arrow.right"
        case .overlays: return "square.stack"
        case .feedback: return "checkmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .buttons: return DSColors.primary.main
        case .cards: return DSColors.success.main
        case .forms: return DSColors.warning.main
        case .navigation: return DSColors.info.main
        case .overlays: return DSColors.error.main
        case .feedback: return DSColors.primary.main
        }
    }
}

enum TokenType: CaseIterable {
    case colors, typography, spacing, elevation
    
    var title: String {
        switch self {
        case .colors: return "Colors"
        case .typography: return "Typography"
        case .spacing: return "Spacing"
        case .elevation: return "Elevation"
        }
    }
}

// MARK: - Extensions
// Color.hexString extension is provided by Category.swift

// MARK: - Component Test View

struct ComponentTestView: View {
    let component: ComponentType
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DSSpacing.xl) {
                    Text("Test view for \(component.name)")
                        .font(DSTypography.title.title2)
                        .foregroundColor(DSColors.neutral.text)
                        .padding()
                    
                    // Component-specific test content would go here
                    Text("Component tests and previews would be displayed here")
                        .font(DSTypography.body.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
            .navigationTitle(component.name)
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Debug Manager

class DebugManager: ObservableObject {
    static let shared = DebugManager()
    
    @Published var showPerformanceOverlay = false
    @Published var showDebugBorders = false
    @Published var slowAnimations = false
    @Published var useMockData = false
    
    @Published var currentFPS: Int = 60
    @Published var cpuUsage: Int = 15
    @Published var memoryUsage: String = "45.2 MB"
    
    @Published var recentActivities: [DebugActivity] = []
    @Published var memoryBreakdown: [MemoryItem] = []
    @Published var performanceRecommendations: [PerformanceRecommendation] = []
    
    var fpsColor: Color {
        currentFPS >= 55 ? DSColors.success.main : currentFPS >= 30 ? DSColors.warning.main : DSColors.error.main
    }
    
    var cpuColor: Color {
        cpuUsage <= 30 ? DSColors.success.main : cpuUsage <= 60 ? DSColors.warning.main : DSColors.error.main
    }
    
    var memoryColor: Color {
        DSColors.info.main // Simplified
    }
    
    var hasPerformanceWarnings: Bool {
        currentFPS < 55 || cpuUsage > 60
    }
    
    var launchTime: Int = 850
    var storageUsed: String = "12.4 MB"
    
    var deviceModel: String {
        #if os(macOS)
        return "Mac"
        #else
        return UIDevice.current.model
        #endif
    }
    
    private init() {
        setupMockData()
    }
    
    private func setupMockData() {
        recentActivities = [
            DebugActivity(id: UUID(), timestamp: Date(), action: "View loaded: TransactionList", category: .navigation),
            DebugActivity(id: UUID(), timestamp: Date().addingTimeInterval(-30), action: "API call: /transactions", category: .network),
            DebugActivity(id: UUID(), timestamp: Date().addingTimeInterval(-60), action: "User action: Budget created", category: .user)
        ]
        
        memoryBreakdown = [
            MemoryItem(component: "Transactions", usage: "15.2 MB", color: DSColors.primary.main),
            MemoryItem(component: "Images", usage: "8.7 MB", color: DSColors.success.main),
            MemoryItem(component: "Cache", usage: "12.1 MB", color: DSColors.warning.main),
            MemoryItem(component: "Other", usage: "9.2 MB", color: DSColors.info.main)
        ]
        
        if hasPerformanceWarnings {
            performanceRecommendations = [
                PerformanceRecommendation(
                    id: UUID(),
                    title: "High CPU Usage",
                    description: "Consider optimizing heavy computations",
                    severity: .medium
                )
            ]
        }
    }
    
    // MARK: - Actions
    
    func resetAllSettings() {
        showPerformanceOverlay = false
        showDebugBorders = false
        slowAnimations = false
        useMockData = false
    }
    
    func exportDebugReport() {
        print("Exporting debug report...")
    }
    
    func clearPerformanceData() {
        recentActivities.removeAll()
        memoryBreakdown.removeAll()
        performanceRecommendations.removeAll()
    }
    
    func startPerformanceMonitoring() {
        print("Starting performance monitoring...")
    }
    
    func stopPerformanceMonitoring() {
        print("Stopping performance monitoring...")
    }
    
    func exportPerformanceData() {
        print("Exporting performance data...")
    }
    
    func clearPerformanceHistory() {
        print("Clearing performance history...")
    }
    
    func toggleLayoutGuides() {
        print("Toggling layout guides...")
    }
    
    func highlightInteractions() {
        print("Highlighting interactions...")
    }
    
    func screenshotAllViews() {
        print("Taking screenshots...")
    }
    
    func loadSampleData() {
        print("Loading sample data...")
    }
    
    func clearAllData() {
        print("Clearing all data...")
    }
    
    func simulateNetworkDelay() {
        print("Simulating network delay...")
    }
    
    func exportDebugLog() {
        print("Exporting debug log...")
    }
    
    func exportUserPreferences() {
        print("Exporting user preferences...")
    }
    
    func generateTestReport() {
        print("Generating test report...")
    }
    
    func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
    }
    
    func resetFeatureTour() {
        UserDefaults.standard.set(false, forKey: "hasCompletedFeatureTour")
    }
    
    func factoryReset() {
        // Reset all user defaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
    }
}

struct DebugActivity {
    let id: UUID
    let timestamp: Date
    let action: String
    let category: ActivityCategory
    
    enum ActivityCategory {
        case navigation, network, user, system
    }
}

struct MemoryItem {
    let component: String
    let usage: String
    let color: Color
}

struct PerformanceRecommendation {
    let id: UUID
    let title: String
    let description: String
    let severity: Severity
    
    enum Severity {
        case low, medium, high
    }
}

struct ActivityRow: View {
    let activity: DebugActivity
    
    var body: some View {
        HStack {
            Text(activity.action)
                .font(DSTypography.caption.regular).fontWeight(.medium)
                .foregroundColor(DSColors.neutral.text)
            
            Spacer()
            
            Text(activity.timestamp.formatted(date: .omitted, time: .shortened))
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.neutral.textSecondary)
        }
    }
}

struct RecommendationRow: View {
    let recommendation: PerformanceRecommendation
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(severityColor)
            
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(recommendation.title)
                    .font(DSTypography.caption.regular).fontWeight(.semibold)
                    .foregroundColor(DSColors.neutral.text)
                
                Text(recommendation.description)
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
    }
    
    private var severityColor: Color {
        switch recommendation.severity {
        case .low: return DSColors.success.main
        case .medium: return DSColors.warning.main
        case .high: return DSColors.error.main
        }
    }
}

// MARK: - Preview

#Preview("Debug Menu") {
    DesignSystemDebugMenu()
}
import SwiftUI
import Combine

/// Performance baseline testing view for LedgerPro UI modernization
/// Tests scroll performance, animation smoothness, and provides FPS monitoring
struct PerformanceBaseline: View {
    @StateObject private var testDataManager = PerformanceTestDataManager()
    @StateObject private var fpsMonitor = FPSMonitor()
    @State private var selectedTest: PerformanceTest = .scrollPerformance
    @State private var isRunningTest = false
    @State private var testResults: [PerformanceTestResult] = []
    
    enum PerformanceTest: String, CaseIterable {
        case scrollPerformance = "Scroll Performance"
        case animationSmoothness = "Animation Smoothness" 
        case filteringSpeed = "Filtering Speed"
        case renderingBenchmark = "Rendering Benchmark"
        
        var description: String {
            switch self {
            case .scrollPerformance:
                return "Tests scroll performance with 10,000 transactions"
            case .animationSmoothness:
                return "Measures animation frame drops and timing"
            case .filteringSpeed:
                return "Times search and filter operations"
            case .renderingBenchmark:
                return "Stress tests view rendering with complex layouts"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            // Test Selection Sidebar
            TestSelectionSidebar(
                selectedTest: $selectedTest,
                isRunningTest: isRunningTest,
                onRunTest: runSelectedTest
            )
        } detail: {
            // Main Test Area
            VStack(spacing: 0) {
                // Performance HUD
                PerformanceHUD(
                    fpsMonitor: fpsMonitor,
                    currentTest: selectedTest,
                    isRunning: isRunningTest
                )
                
                // Test Content Area
                Group {
                    switch selectedTest {
                    case .scrollPerformance:
                        ScrollPerformanceTest(
                            testDataManager: testDataManager,
                            fpsMonitor: fpsMonitor,
                            isRunning: isRunningTest
                        )
                    case .animationSmoothness:
                        AnimationSmoothnessTest(
                            fpsMonitor: fpsMonitor,
                            isRunning: isRunningTest
                        )
                    case .filteringSpeed:
                        FilteringSpeedTest(
                            testDataManager: testDataManager,
                            isRunning: isRunningTest
                        )
                    case .renderingBenchmark:
                        RenderingBenchmarkTest(
                            testDataManager: testDataManager,
                            fpsMonitor: fpsMonitor,
                            isRunning: isRunningTest
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Results Panel
                if !testResults.isEmpty {
                    PerformanceResultsPanel(results: testResults)
                        .frame(height: 200)
                }
            }
        }
        .navigationTitle("Performance Baseline Testing")
        .onAppear {
            fpsMonitor.startMonitoring()
            testDataManager.generateTestData()
        }
        .onDisappear {
            fpsMonitor.stopMonitoring()
        }
    }
    
    private func runSelectedTest() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isRunningTest = true
        }
        
        // Run test with proper timing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            performTest(selectedTest) { result in
                testResults.append(result)
                withAnimation(.easeInOut(duration: 0.3)) {
                    isRunningTest = false
                }
            }
        }
    }
    
    private func performTest(_ test: PerformanceTest, completion: @escaping (PerformanceTestResult) -> Void) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        switch test {
        case .scrollPerformance:
            testScrollPerformance(completion: completion)
        case .animationSmoothness:
            testAnimationSmoothness(completion: completion)
        case .filteringSpeed:
            testFilteringSpeed(completion: completion)
        case .renderingBenchmark:
            testRenderingBenchmark(completion: completion)
        }
    }
    
    // MARK: - Individual Test Implementations
    
    private func testScrollPerformance(completion: @escaping (PerformanceTestResult) -> Void) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let initialFPS = fpsMonitor.averageFPS
        
        // Simulate scroll test completion after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            let endTime = CFAbsoluteTimeGetCurrent()
            let finalFPS = fpsMonitor.averageFPS
            let minFPS = fpsMonitor.minFPS
            
            let result = PerformanceTestResult(
                testName: "Scroll Performance",
                duration: endTime - startTime,
                fps: finalFPS,
                minFPS: minFPS,
                itemCount: testDataManager.testTransactions.count,
                passed: minFPS >= 45.0, // 45 FPS minimum for smooth scrolling
                details: "Items: \(testDataManager.testTransactions.count), Min FPS: \(minFPS)"
            )
            completion(result)
        }
    }
    
    private func testAnimationSmoothness(completion: @escaping (PerformanceTestResult) -> Void) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let initialFPS = fpsMonitor.averageFPS
        
        // Test animation smoothness
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let endTime = CFAbsoluteTimeGetCurrent()
            let avgFPS = fpsMonitor.averageFPS
            let minFPS = fpsMonitor.minFPS
            
            let result = PerformanceTestResult(
                testName: "Animation Smoothness",
                duration: endTime - startTime,
                fps: avgFPS,
                minFPS: minFPS,
                itemCount: 1,
                passed: minFPS >= 55.0, // Higher standard for animations
                details: "Animation FPS: \(avgFPS), Min: \(minFPS)"
            )
            completion(result)
        }
    }
    
    private func testFilteringSpeed(completion: @escaping (PerformanceTestResult) -> Void) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Perform filtering operation
        let _ = testDataManager.testTransactions.filter { transaction in
            transaction.description.lowercased().contains("test") ||
            transaction.category.lowercased().contains("food")
        }
        
        let filterTime = CFAbsoluteTimeGetCurrent() - startTime
        
        let result = PerformanceTestResult(
            testName: "Filtering Speed",
            duration: filterTime,
            fps: fpsMonitor.averageFPS,
            minFPS: fpsMonitor.minFPS,
            itemCount: testDataManager.testTransactions.count,
            passed: filterTime < 0.100, // 100ms target for filtering
            details: "Filter time: \(String(format: "%.3f", filterTime))s"
        )
        completion(result)
    }
    
    private func testRenderingBenchmark(completion: @escaping (PerformanceTestResult) -> Void) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let initialFPS = fpsMonitor.averageFPS
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            let endTime = CFAbsoluteTimeGetCurrent()
            let avgFPS = fpsMonitor.averageFPS
            let minFPS = fpsMonitor.minFPS
            
            let result = PerformanceTestResult(
                testName: "Rendering Benchmark",
                duration: endTime - startTime,
                fps: avgFPS,
                minFPS: minFPS,
                itemCount: testDataManager.testTransactions.count,
                passed: avgFPS >= 50.0 && minFPS >= 40.0,
                details: "Complex rendering with \(testDataManager.testTransactions.count) items"
            )
            completion(result)
        }
    }
}

// MARK: - Test Selection Sidebar

struct TestSelectionSidebar: View {
    @Binding var selectedTest: PerformanceBaseline.PerformanceTest
    let isRunningTest: Bool
    let onRunTest: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Performance Tests")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 10)
            
            // Test Selection
            ForEach(PerformanceBaseline.PerformanceTest.allCases, id: \.self) { test in
                TestSelectionRow(
                    test: test,
                    isSelected: selectedTest == test,
                    onSelect: { selectedTest = test }
                )
            }
            
            Spacer()
            
            // Run Test Button
            Button(action: onRunTest) {
                HStack {
                    Image(systemName: isRunningTest ? "stop.circle.fill" : "play.circle.fill")
                    Text(isRunningTest ? "Running..." : "Run Test")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRunningTest)
            
            // Test Info
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Test:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(selectedTest.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
        .padding()
        .frame(width: 300)
    }
}

struct TestSelectionRow: View {
    let test: PerformanceBaseline.PerformanceTest
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: iconForTest(test))
                    .foregroundColor(isSelected ? .white : .primary)
                Text(test.rawValue)
                    .foregroundColor(isSelected ? .white : .primary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
    
    private func iconForTest(_ test: PerformanceBaseline.PerformanceTest) -> String {
        switch test {
        case .scrollPerformance: return "scroll.fill"
        case .animationSmoothness: return "waveform.path"
        case .filteringSpeed: return "magnifyingglass"
        case .renderingBenchmark: return "speedometer"
        }
    }
}

// MARK: - Performance HUD

struct PerformanceHUD: View {
    @ObservedObject var fpsMonitor: FPSMonitor
    let currentTest: PerformanceBaseline.PerformanceTest
    let isRunning: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            // FPS Display
            VStack(alignment: .leading, spacing: 4) {
                Text("FPS")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(Int(fpsMonitor.currentFPS))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(fpsColor)
            }
            
            // Average FPS
            VStack(alignment: .leading, spacing: 4) {
                Text("Avg FPS")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(Int(fpsMonitor.averageFPS))")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            // Min FPS
            VStack(alignment: .leading, spacing: 4) {
                Text("Min FPS")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(Int(fpsMonitor.minFPS))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(minFpsColor)
            }
            
            Spacer()
            
            // Test Status
            HStack {
                Circle()
                    .fill(isRunning ? .green : .secondary)
                    .frame(width: 8, height: 8)
                Text(isRunning ? "Testing" : "Ready")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            Rectangle()
                .fill(Color(NSColor.separatorColor))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    private var fpsColor: Color {
        if fpsMonitor.currentFPS >= 55 { return .green }
        if fpsMonitor.currentFPS >= 45 { return .yellow }
        return .red
    }
    
    private var minFpsColor: Color {
        if fpsMonitor.minFPS >= 45 { return .green }
        if fpsMonitor.minFPS >= 30 { return .yellow }
        return .red
    }
}

// MARK: - Individual Test Views

struct ScrollPerformanceTest: View {
    @ObservedObject var testDataManager: PerformanceTestDataManager
    @ObservedObject var fpsMonitor: FPSMonitor
    let isRunning: Bool
    
    var body: some View {
        VStack {
            if isRunning {
                Text("Scroll through the list to test performance")
                    .font(.headline)
                    .padding()
            }
            
            ScrollViewReader { proxy in
                List(testDataManager.testTransactions, id: \.id) { transaction in
                    PerformanceTestTransactionRow(transaction: transaction)
                }
                .onChange(of: isRunning) { _, newValue in
                    if newValue {
                        // Auto-scroll to test performance
                        performAutoScroll(proxy: proxy)
                    }
                }
            }
        }
    }
    
    private func performAutoScroll(proxy: ScrollViewProxy) {
        let itemCount = testDataManager.testTransactions.count
        guard itemCount > 0 else { return }
        
        // Scroll to different positions to test performance
        let scrollPositions = [0, itemCount/4, itemCount/2, itemCount*3/4, itemCount-1]
        
        for (index, position) in scrollPositions.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.6) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    proxy.scrollTo(testDataManager.testTransactions[position].id, anchor: .center)
                }
            }
        }
    }
}

struct AnimationSmoothnessTest: View {
    @ObservedObject var fpsMonitor: FPSMonitor
    let isRunning: Bool
    @State private var animationOffset: CGFloat = 0
    @State private var animationScale: CGFloat = 1.0
    @State private var animationRotation: Double = 0
    
    var body: some View {
        VStack(spacing: 40) {
            Text("Animation Smoothness Test")
                .font(.title2)
                .fontWeight(.bold)
            
            // Multiple animated elements
            HStack(spacing: 40) {
                // Moving circle
                Circle()
                    .fill(.blue)
                    .frame(width: 50, height: 50)
                    .offset(x: animationOffset)
                
                // Scaling square
                Rectangle()
                    .fill(.green)
                    .frame(width: 50, height: 50)
                    .scaleEffect(animationScale)
                
                // Rotating triangle
                Image(systemName: "triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                    .rotationEffect(.degrees(animationRotation))
            }
            
            // Performance metrics during animation
            VStack(spacing: 8) {
                Text("Current FPS: \(Int(fpsMonitor.currentFPS))")
                Text("Frame Drops: \(fpsMonitor.frameDrops)")
                    .foregroundColor(fpsMonitor.frameDrops > 5 ? .red : .green)
            }
            .font(.caption)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: isRunning) { _, newValue in
            if newValue {
                startAnimations()
            } else {
                stopAnimations()
            }
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever()) {
            animationOffset = 100
        }
        
        withAnimation(.easeInOut(duration: 1.5).repeatForever()) {
            animationScale = 1.5
        }
        
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            animationRotation = 360
        }
    }
    
    private func stopAnimations() {
        withAnimation(.easeInOut(duration: 0.5)) {
            animationOffset = 0
            animationScale = 1.0
            animationRotation = 0
        }
    }
}

struct FilteringSpeedTest: View {
    @ObservedObject var testDataManager: PerformanceTestDataManager
    let isRunning: Bool
    @State private var searchText = ""
    @State private var filteredTransactions: [Transaction] = []
    @State private var filterTime: TimeInterval = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Filtering Speed Test")
                .font(.title2)
                .fontWeight(.bold)
            
            // Search field
            TextField("Search transactions...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 400)
                .onChange(of: searchText) { _, newValue in
                    if isRunning {
                        measureFilteringPerformance(searchTerm: newValue)
                    }
                }
            
            // Results
            VStack(spacing: 12) {
                Text("Dataset: \(testDataManager.testTransactions.count) transactions")
                Text("Filtered: \(filteredTransactions.count) results")
                Text("Filter Time: \(String(format: "%.3f", filterTime))s")
                    .foregroundColor(filterTime < 0.100 ? .green : .red)
            }
            .font(.caption)
            
            // Sample results
            List(filteredTransactions.prefix(20), id: \.id) { transaction in
                PerformanceTestTransactionRow(transaction: transaction)
            }
        }
        .onAppear {
            filteredTransactions = testDataManager.testTransactions
        }
    }
    
    private func measureFilteringPerformance(searchTerm: String) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        if searchTerm.isEmpty {
            filteredTransactions = testDataManager.testTransactions
        } else {
            filteredTransactions = testDataManager.testTransactions.filter { transaction in
                transaction.description.lowercased().contains(searchTerm.lowercased()) ||
                transaction.category.lowercased().contains(searchTerm.lowercased())
            }
        }
        
        filterTime = CFAbsoluteTimeGetCurrent() - startTime
    }
}

struct RenderingBenchmarkTest: View {
    @ObservedObject var testDataManager: PerformanceTestDataManager
    @ObservedObject var fpsMonitor: FPSMonitor
    let isRunning: Bool
    
    var body: some View {
        VStack {
            Text("Rendering Benchmark")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            
            // Complex layout with many views
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(testDataManager.testTransactions.prefix(isRunning ? 200 : 50), id: \.id) { transaction in
                        ComplexTransactionRow(transaction: transaction)
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Performance Test Data Manager

class PerformanceTestDataManager: ObservableObject {
    @Published var testTransactions: [Transaction] = []
    
    func generateTestData() {
        // Generate 10,000 test transactions for performance testing
        let categories = ["Food & Dining", "Transportation", "Shopping", "Entertainment", "Bills & Utilities", "Travel", "Healthcare", "Education", "Personal Care", "Gifts & Donations"]
        let merchants = ["Starbucks", "Uber", "Amazon", "Netflix", "Spotify", "Apple", "Google", "Microsoft", "Target", "Walmart", "CVS", "Chevron", "McDonald's", "Chipotle", "Best Buy"]
        
        testTransactions = (0..<10000).map { index in
            Transaction(
                id: "test-\(index)",
                date: "\(2024 - (index / 365))-\(String(format: "%02d", (index % 12) + 1))-\(String(format: "%02d", (index % 28) + 1))",
                description: "\(merchants.randomElement()!) Store #\(Int.random(in: 1000...9999))",
                amount: Double.random(in: -500...500),
                category: categories.randomElement()!,
                jobId: "test-job",
                accountId: "test-account-\(index % 5)"
            )
        }
    }
}

// MARK: - FPS Monitor

class FPSMonitor: ObservableObject {
    @Published var currentFPS: Double = 60.0
    @Published var averageFPS: Double = 60.0
    @Published var minFPS: Double = 60.0
    @Published var frameDrops: Int = 0
    
    private var timer: Timer?
    private var lastTimestamp: CFTimeInterval = 0
    private var fpsHistory: [Double] = []
    private let maxHistoryCount = 60 // 1 second of history at 60fps
    
    func startMonitoring() {
        // Use Timer for macOS compatibility instead of CADisplayLink
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            self?.timerTick()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func timerTick() {
        let currentTime = CFAbsoluteTimeGetCurrent()
        
        if lastTimestamp == 0 {
            lastTimestamp = currentTime
            return
        }
        
        let deltaTime = currentTime - lastTimestamp
        lastTimestamp = currentTime
        
        let fps = 1.0 / deltaTime
        
        DispatchQueue.main.async { [weak self] in
            self?.updateFPS(fps)
        }
    }
    
    private func updateFPS(_ fps: Double) {
        currentFPS = fps
        
        // Track frame drops (below 55 FPS)
        if fps < 55 {
            frameDrops += 1
        }
        
        // Update history
        fpsHistory.append(fps)
        if fpsHistory.count > maxHistoryCount {
            fpsHistory.removeFirst()
        }
        
        // Calculate average and min
        if !fpsHistory.isEmpty {
            averageFPS = fpsHistory.reduce(0, +) / Double(fpsHistory.count)
            minFPS = fpsHistory.min() ?? 60.0
        }
    }
}

// MARK: - Performance Test Result

struct PerformanceTestResult: Identifiable {
    let id = UUID()
    let testName: String
    let duration: TimeInterval
    let fps: Double
    let minFPS: Double
    let itemCount: Int
    let passed: Bool
    let details: String
    let timestamp = Date()
}

// MARK: - Results Panel

struct PerformanceResultsPanel: View {
    let results: [PerformanceTestResult]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Test Results")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(results) { result in
                        PerformanceResultRow(result: result)
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            Rectangle()
                .fill(Color(NSColor.separatorColor))
                .frame(height: 1),
            alignment: .top
        )
    }
}

struct PerformanceResultRow: View {
    let result: PerformanceTestResult
    
    var body: some View {
        HStack {
            Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(result.passed ? .green : .red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(result.testName)
                    .font(.headline)
                Text(result.details)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(String(format: "%.3f", result.duration))s")
                    .font(.caption)
                Text("\(Int(result.fps)) FPS")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Helper Views

struct PerformanceTestTransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            Circle()
                .fill(.blue)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading) {
                Text(transaction.description)
                    .font(.body)
                    .lineLimit(1)
                Text(transaction.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(transaction.amount.formatAsCurrency())
                .font(.body)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

struct ComplexTransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 16) {
            // Complex icon with gradient
            Image(systemName: "creditcard.fill")
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    Text(transaction.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.1))
                        .clipShape(Capsule())
                    
                    Text(transaction.date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(transaction.amount.formatAsCurrency())
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(transaction.amount >= 0 ? .green : .red)
                
                Text("Balance: $1,234.56")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 1)
    }
}

#Preview {
    PerformanceBaseline()
}
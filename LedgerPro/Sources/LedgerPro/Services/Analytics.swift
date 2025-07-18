import Foundation
import SwiftUI

// MARK: - Analytics Event Types

/// Represents an analytics event with properties
public struct AnalyticsEvent {
    let name: String
    let properties: [String: Any]
    let timestamp: Date
    let sessionId: String
    
    init(name: String, properties: [String: Any] = [:]) {
        self.name = name
        self.properties = properties
        self.timestamp = Date()
        self.sessionId = Analytics.shared.sessionId
    }
}

/// Performance timing measurement
public struct TimingEvent {
    let operation: String
    let startTime: CFAbsoluteTime
    let duration: TimeInterval
    let properties: [String: Any]
    
    init(operation: String, startTime: CFAbsoluteTime, properties: [String: Any] = [:]) {
        self.operation = operation
        self.startTime = startTime
        self.duration = CFAbsoluteTimeGetCurrent() - startTime
        self.properties = properties
    }
}

// MARK: - Analytics Protocol

/// Protocol for analytics providers (future extensibility)
public protocol AnalyticsProvider {
    func track(event: AnalyticsEvent)
    func track(timing: TimingEvent)
    func identify(userId: String?, properties: [String: Any])
    func flush()
}

// MARK: - Debug Analytics Provider

/// Debug-only analytics provider that logs to console
private class DebugAnalyticsProvider: AnalyticsProvider {
    private let logger = AppLogger.shared
    
    func track(event: AnalyticsEvent) {
        let propertiesString = event.properties.isEmpty ? "" : 
            " | Properties: \(event.properties.map { "\($0.key): \($0.value)" }.joined(separator: ", "))"
        
        logger.info("📊 Analytics Event: \(event.name)\(propertiesString)", category: "Analytics")
    }
    
    func track(timing: TimingEvent) {
        let propertiesString = timing.properties.isEmpty ? "" :
            " | Properties: \(timing.properties.map { "\($0.key): \($0.value)" }.joined(separator: ", "))"
        
        logger.info("⏱️ Performance: \(timing.operation) took \(String(format: "%.3f", timing.duration))s\(propertiesString)", category: "Analytics")
    }
    
    func identify(userId: String?, properties: [String: Any]) {
        let userIdString = userId ?? "anonymous"
        let propertiesString = properties.isEmpty ? "" :
            " | Properties: \(properties.map { "\($0.key): \($0.value)" }.joined(separator: ", "))"
        
        logger.info("👤 User Identified: \(userIdString)\(propertiesString)", category: "Analytics")
    }
    
    func flush() {
        logger.debug("🔄 Analytics flush requested", category: "Analytics")
    }
}

// MARK: - No-Op Analytics Provider

/// Production analytics provider for future integration
private class ProductionAnalyticsProvider: AnalyticsProvider {
    // TODO: Integrate with Mixpanel, Amplitude, or other analytics service
    
    func track(event: AnalyticsEvent) {
        // Store locally for now, future: send to analytics service
        storeEventLocally(event)
    }
    
    func track(timing: TimingEvent) {
        // Store locally for now, future: send to analytics service
        storeTimingLocally(timing)
    }
    
    func identify(userId: String?, properties: [String: Any]) {
        // Future: identify user with analytics service
    }
    
    func flush() {
        // Future: flush events to analytics service
    }
    
    private func storeEventLocally(_ event: AnalyticsEvent) {
        // Store in UserDefaults for local analytics dashboard
        var events = getStoredEvents()
        events.append(event)
        
        // Keep only last 1000 events to prevent storage bloat
        if events.count > 1000 {
            events = Array(events.suffix(1000))
        }
        
        if let data = try? JSONEncoder().encode(events.map { StoredEvent(from: $0) }) {
            UserDefaults.standard.set(data, forKey: "analytics_events")
        }
    }
    
    private func storeTimingLocally(_ timing: TimingEvent) {
        var timings = getStoredTimings()
        timings.append(timing)
        
        // Keep only last 500 timing events
        if timings.count > 500 {
            timings = Array(timings.suffix(500))
        }
        
        if let data = try? JSONEncoder().encode(timings.map { StoredTiming(from: $0) }) {
            UserDefaults.standard.set(data, forKey: "analytics_timings")
        }
    }
    
    func getStoredEvents() -> [AnalyticsEvent] {
        guard let data = UserDefaults.standard.data(forKey: "analytics_events"),
              let storedEvents = try? JSONDecoder().decode([StoredEvent].self, from: data) else {
            return []
        }
        return storedEvents.map { $0.toAnalyticsEvent() }
    }
    
    func getStoredTimings() -> [TimingEvent] {
        guard let data = UserDefaults.standard.data(forKey: "analytics_timings"),
              let storedTimings = try? JSONDecoder().decode([StoredTiming].self, from: data) else {
            return []
        }
        return storedTimings.map { $0.toTimingEvent() }
    }
}

// MARK: - Stored Event Models

private struct StoredEvent: Codable {
    let name: String
    let properties: [String: String] // Simplified for storage
    let timestamp: Date
    let sessionId: String
    
    init(from event: AnalyticsEvent) {
        self.name = event.name
        self.properties = event.properties.mapValues { String(describing: $0) }
        self.timestamp = event.timestamp
        self.sessionId = event.sessionId
    }
    
    func toAnalyticsEvent() -> AnalyticsEvent {
        // Return new AnalyticsEvent with stored values
        return AnalyticsEvent(name: name, properties: properties)
    }
}

private struct StoredTiming: Codable {
    let operation: String
    let duration: TimeInterval
    let properties: [String: String]
    let timestamp: Date
    
    init(from timing: TimingEvent) {
        self.operation = timing.operation
        self.duration = timing.duration
        self.properties = timing.properties.mapValues { String(describing: $0) }
        self.timestamp = Date()
    }
    
    func toTimingEvent() -> TimingEvent {
        // Create a fake start time based on duration
        let fakeStartTime = CFAbsoluteTimeGetCurrent() - duration
        let timing = TimingEvent(operation: operation, startTime: fakeStartTime, properties: properties)
        return timing
    }
}

// MARK: - Main Analytics Service

/// Main analytics service with privacy-conscious design
public final class Analytics: ObservableObject {
    public static let shared = Analytics()
    
    // MARK: - Public Properties
    
    @Published public private(set) var isEnabled: Bool = true
    public let sessionId: String
    
    // MARK: - Private Properties
    
    private let provider: AnalyticsProvider
    private let queue = DispatchQueue(label: "analytics", qos: .utility)
    
    // MARK: - Initialization
    
    private init() {
        self.sessionId = UUID().uuidString
        
        #if DEBUG
        self.provider = DebugAnalyticsProvider()
        #else
        self.provider = ProductionAnalyticsProvider()
        #endif
        
        // Track app launch
        trackAppLaunch()
    }
    
    // MARK: - Public Methods
    
    /// Track a custom event
    public func track(_ eventName: String, properties: [String: Any] = [:]) {
        guard isEnabled else { return }
        
        queue.async {
            let event = AnalyticsEvent(name: eventName, properties: properties)
            self.provider.track(event: event)
        }
    }
    
    /// Measure and track timing for an operation
    public func measureTime<T>(
        operation: String,
        properties: [String: Any] = [:],
        block: () throws -> T
    ) rethrows -> T {
        guard isEnabled else { return try block() }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try block()
        
        queue.async {
            let timing = TimingEvent(operation: operation, startTime: startTime, properties: properties)
            self.provider.track(timing: timing)
        }
        
        return result
    }
    
    /// Measure and track async timing
    public func measureTime<T>(
        operation: String,
        properties: [String: Any] = [:],
        block: () async throws -> T
    ) async rethrows -> T {
        guard isEnabled else { return try await block() }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await block()
        
        queue.async {
            let timing = TimingEvent(operation: operation, startTime: startTime, properties: properties)
            self.provider.track(timing: timing)
        }
        
        return result
    }
    
    /// Identify user (privacy-conscious - no PII)
    public func identify(anonymousId: String? = nil, properties: [String: Any] = [:]) {
        guard isEnabled else { return }
        
        queue.async {
            self.provider.identify(userId: anonymousId, properties: properties)
        }
    }
    
    /// Flush pending analytics
    public func flush() {
        queue.async {
            self.provider.flush()
        }
    }
    
    /// Toggle analytics collection
    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "analytics_enabled")
        
        track("analytics_toggled", properties: ["enabled": enabled])
    }
    
    // MARK: - Convenience Methods
    
    /// Track import completion
    public func trackImportCompleted(
        fileType: String,
        transactionCount: Int,
        success: Bool,
        processingTime: TimeInterval,
        categorizationRate: Double
    ) {
        track("import_completed", properties: [
            "file_type": fileType,
            "transaction_count": transactionCount,
            "success": success,
            "processing_time": processingTime,
            "categorization_rate": categorizationRate
        ])
    }
    
    /// Track transaction categorization
    public func trackTransactionCategorized(
        isAutomatic: Bool,
        category: String,
        confidence: Double? = nil
    ) {
        var properties: [String: Any] = [
            "method": isAutomatic ? "automatic" : "manual",
            "category": category
        ]
        
        if let confidence = confidence {
            properties["confidence"] = confidence
        }
        
        track("transaction_categorized", properties: properties)
    }
    
    /// Track rule creation
    public func trackRuleCreated(
        ruleType: String,
        source: String
    ) {
        track("rule_created", properties: [
            "rule_type": ruleType,
            "source": source
        ])
    }
    
    /// Track export
    public func trackExportPerformed(
        format: String,
        transactionCount: Int
    ) {
        track("export_performed", properties: [
            "format": format,
            "transaction_count": transactionCount
        ])
    }
    
    /// Track tab navigation
    public func trackTabNavigation(from: String, to: String) {
        track("tab_navigation", properties: [
            "from_tab": from,
            "to_tab": to
        ])
    }
    
    // MARK: - Analytics Data Access
    
    /// Get analytics data for dashboard (only in production provider)
    public func getAnalyticsData() -> AnalyticsData {
        if let productionProvider = provider as? ProductionAnalyticsProvider {
            let events = productionProvider.getStoredEvents()
            let timings = productionProvider.getStoredTimings()
            return AnalyticsData(events: events, timings: timings)
        }
        return AnalyticsData(events: [], timings: [])
    }
    
    // MARK: - Private Methods
    
    private func trackAppLaunch() {
        let lastLaunchDate = UserDefaults.standard.object(forKey: "last_launch_date") as? Date
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        
        var properties: [String: Any] = [
            "app_version": appVersion,
            "build_number": buildNumber,
            "is_first_launch": lastLaunchDate == nil
        ]
        
        if let lastLaunch = lastLaunchDate {
            properties["days_since_last_launch"] = Calendar.current.dateComponents([.day], from: lastLaunch, to: Date()).day ?? 0
        }
        
        track("app_launched", properties: properties)
        
        // Update last launch date
        UserDefaults.standard.set(Date(), forKey: "last_launch_date")
    }
}

// MARK: - Analytics Data Model

public struct AnalyticsData {
    public let events: [AnalyticsEvent]
    public let timings: [TimingEvent]
    
    // MARK: - Computed Properties for Dashboard
    
    public var importsThisMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        return events.filter { event in
            event.name == "import_completed" &&
            event.timestamp >= startOfMonth &&
            (event.properties["success"] as? Bool) == true
        }.count
    }
    
    public var averageCategorizationRate: Double {
        let importEvents = events.filter { $0.name == "import_completed" }
        guard !importEvents.isEmpty else { return 0.0 }
        
        let totalRate = importEvents.compactMap { event in
            event.properties["categorization_rate"] as? Double
        }.reduce(0.0, +)
        
        return importEvents.count > 0 ? totalRate / Double(importEvents.count) : 0.0
    }
    
    public var mostUsedCategories: [(category: String, count: Int)] {
        let categoryEvents = events.filter { $0.name == "transaction_categorized" }
        
        let categoryCounts = Dictionary(grouping: categoryEvents) { event in
            event.properties["category"] as? String ?? "unknown"
        }.mapValues { $0.count }
        
        return categoryCounts.sorted { $0.value > $1.value }.prefix(5).map { (category: $0.key, count: $0.value) }
    }
    
    public var averageImportTime: TimeInterval {
        let importTimings = timings.filter { $0.operation == "import_processing" }
        guard !importTimings.isEmpty else { return 0.0 }
        
        let totalTime = importTimings.reduce(0.0) { $0 + $1.duration }
        return totalTime / Double(importTimings.count)
    }
    
    public var averageCategorizationTime: TimeInterval {
        let categorizationTimings = timings.filter { $0.operation == "transaction_categorization" }
        guard !categorizationTimings.isEmpty else { return 0.0 }
        
        let totalTime = categorizationTimings.reduce(0.0) { $0 + $1.duration }
        return totalTime / Double(categorizationTimings.count)
    }
}
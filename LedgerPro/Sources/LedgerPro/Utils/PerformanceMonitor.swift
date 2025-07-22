import Foundation

/// Enhanced performance monitoring utility for LedgerPro
public class PerformanceMonitor {
    public static let shared = PerformanceMonitor()
    
    private var activeTimers: [String: CFAbsoluteTime] = [:]
    private var metrics: [String: [TimeInterval]] = [:]
    private let metricsQueue = DispatchQueue(label: "performance.metrics", qos: .utility)
    
    private init() {}
    
    /// Measure execution time of a synchronous operation
    public static func measure<T>(_ label: String, operation: () throws -> T) rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        defer {
            let elapsed = CFAbsoluteTimeGetCurrent() - start
            AppLogger.shared.debug("⏱️ \(label): \(String(format: "%.3f", elapsed))s", category: "Performance")
            shared.recordMetric(label, duration: elapsed)
        }
        return try operation()
    }
    
    /// Measure execution time of an async operation
    public static func measureAsync<T>(_ label: String, operation: () async throws -> T) async rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        defer {
            let elapsed = CFAbsoluteTimeGetCurrent() - start
            AppLogger.shared.debug("⏱️ \(label): \(String(format: "%.3f", elapsed))s", category: "Performance")
            shared.recordMetric(label, duration: elapsed)
        }
        return try await operation()
    }
    
    /// Start a named timer for long-running operations
    public func startTimer(_ name: String) {
        metricsQueue.async { [weak self] in
            self?.activeTimers[name] = CFAbsoluteTimeGetCurrent()
        }
        AppLogger.shared.debug("⏱️ Started timer: \(name)", category: "Performance")
    }
    
    /// Stop a named timer and record the result
    public func stopTimer(_ name: String) {
        metricsQueue.async { [weak self] in
            guard let self = self,
                  let startTime = self.activeTimers.removeValue(forKey: name) else {
                AppLogger.shared.warning("⏱️ Timer '\(name)' not found", category: "Performance")
                return
            }
            
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            self.recordMetric(name, duration: elapsed)
            
            DispatchQueue.main.async {
                AppLogger.shared.debug("⏱️ \(name): \(String(format: "%.3f", elapsed))s", category: "Performance")
            }
        }
    }
    
    /// Record a metric value for later analysis
    private func recordMetric(_ name: String, duration: TimeInterval) {
        metricsQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.metrics[name] == nil {
                self.metrics[name] = []
            }
            
            self.metrics[name]?.append(duration)
            
            // Keep only the last 100 measurements to prevent memory growth
            if let count = self.metrics[name]?.count, count > 100 {
                self.metrics[name]?.removeFirst(count - 100)
            }
        }
    }
    
    /// Get performance statistics for a metric
    public func getStats(for metricName: String) -> PerformanceStats? {
        return metricsQueue.sync { [weak self] in
            guard let measurements = self?.metrics[metricName], !measurements.isEmpty else {
                return nil
            }
            
            let sorted = measurements.sorted()
            let count = measurements.count
            let sum = measurements.reduce(0, +)
            
            return PerformanceStats(
                name: metricName,
                count: count,
                average: sum / Double(count),
                min: sorted.first ?? 0,
                max: sorted.last ?? 0,
                median: count % 2 == 0 ? 
                    (sorted[count/2 - 1] + sorted[count/2]) / 2 : 
                    sorted[count/2],
                p95: sorted[min(count - 1, Int(Double(count) * 0.95))]
            )
        }
    }
    
    /// Get all recorded performance metrics
    public func getAllStats() -> [PerformanceStats] {
        return metricsQueue.sync { [weak self] in
            guard let self = self else { return [] }
            
            return self.metrics.compactMap { key, _ in
                self.getStats(for: key)
            }.sorted { $0.name < $1.name }
        }
    }
    
    /// Generate a performance report
    public func generateReport() -> String {
        let stats = getAllStats()
        
        var report = "# LedgerPro Performance Report\n\n"
        report += "Generated: \(Date())\n\n"
        
        if stats.isEmpty {
            report += "No performance metrics recorded.\n"
            return report
        }
        
        report += "| Metric | Count | Avg (s) | Min (s) | Max (s) | P95 (s) |\n"
        report += "|--------|-------|---------|---------|---------|----------|\n"
        
        for stat in stats {
            report += "| \(stat.name) | \(stat.count) | \(String(format: "%.3f", stat.average)) | \(String(format: "%.3f", stat.min)) | \(String(format: "%.3f", stat.max)) | \(String(format: "%.3f", stat.p95)) |\n"
        }
        
        // Add performance insights
        report += "\n## Performance Insights\n\n"
        
        let slowOperations = stats.filter { $0.average > 1.0 }
        if !slowOperations.isEmpty {
            report += "### Slow Operations (>1s average):\n"
            for op in slowOperations {
                report += "- **\(op.name)**: \(String(format: "%.3f", op.average))s average\n"
            }
            report += "\n"
        }
        
        let inconsistentOperations = stats.filter { $0.max / $0.min > 5.0 && $0.count > 5 }
        if !inconsistentOperations.isEmpty {
            report += "### Inconsistent Operations (high variance):\n"
            for op in inconsistentOperations {
                report += "- **\(op.name)**: \(String(format: "%.1f", op.max / op.min))x variance\n"
            }
            report += "\n"
        }
        
        return report
    }
    
    /// Clear all recorded metrics
    public func clearMetrics() {
        metricsQueue.async { [weak self] in
            self?.metrics.removeAll()
            self?.activeTimers.removeAll()
        }
        AppLogger.shared.info("📊 Performance metrics cleared", category: "Performance")
    }
}

/// Performance statistics for a single metric
public struct PerformanceStats {
    public let name: String
    public let count: Int
    public let average: TimeInterval
    public let min: TimeInterval
    public let max: TimeInterval
    public let median: TimeInterval
    public let p95: TimeInterval
    
    /// Human readable summary
    public var summary: String {
        return "\(name): \(String(format: "%.3f", average))s avg (\(count) samples)"
    }
}

/// Convenience macros for common performance monitoring patterns
public extension PerformanceMonitor {
    
    /// Monitor filtering operations
    static func measureFiltering<T>(_ operation: () throws -> T) rethrows -> T {
        return try measure("Transaction Filtering", operation: operation)
    }
    
    /// Monitor categorization operations
    static func measureCategorization<T>(_ operation: () throws -> T) rethrows -> T {
        return try measure("Transaction Categorization", operation: operation)
    }
    
    /// Monitor UI rendering operations
    static func measureUIUpdate<T>(_ operation: () throws -> T) rethrows -> T {
        return try measure("UI Update", operation: operation)
    }
    
    /// Monitor async filtering operations
    static func measureFilteringAsync<T>(_ operation: () async throws -> T) async rethrows -> T {
        return try await measureAsync("Transaction Filtering (Async)", operation: operation)
    }
    
    /// Monitor async categorization operations
    static func measureCategorizationAsync<T>(_ operation: () async throws -> T) async rethrows -> T {
        return try await measureAsync("Transaction Categorization (Async)", operation: operation)
    }
}
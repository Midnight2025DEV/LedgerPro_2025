import Foundation
import os.signpost

/// Enhanced performance monitoring utility for LedgerPro
public class PerformanceMonitor {
    public static let shared = PerformanceMonitor()
    
    private var activeTimers: [String: CFAbsoluteTime] = [:]
    private var metrics: [String: [TimeInterval]] = [:]
    private var memoryMetrics: [String: [MemoryUsage]] = [:]
    private let metricsQueue = DispatchQueue(label: "performance.metrics", qos: .utility)
    
    // Enhanced logging with signposts
    private let log = OSLog(subsystem: "com.ledgerpro", category: "Performance")
    private let signposter = OSSignposter()
    
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
    
    /// Record memory usage for a specific context
    public func recordMemoryUsage(context: String, itemCount: Int? = nil) {
        metricsQueue.async { [weak self] in
            guard let self = self else { return }
            
            let memoryUsage = MemoryUsage(context: context, associatedItemCount: itemCount)
            
            if self.memoryMetrics[context] == nil {
                self.memoryMetrics[context] = []
            }
            
            self.memoryMetrics[context]?.append(memoryUsage)
            
            // Keep only the last 50 memory measurements per context
            if let count = self.memoryMetrics[context]?.count, count > 50 {
                self.memoryMetrics[context]?.removeFirst(count - 50)
            }
            
            // Log significant memory changes
            if let previous = self.memoryMetrics[context]?.dropLast().last {
                let memoryChange = Int64(memoryUsage.residentSizeMB) - Int64(previous.residentSizeMB)
                if abs(memoryChange) > 10 { // Log if >10MB change
                    let changeStr = memoryChange > 0 ? "+\(memoryChange)MB" : "\(memoryChange)MB"
                    AppLogger.shared.info("💾 Memory change in \(context): \(changeStr) (now \(memoryUsage.residentSizeMB)MB)", category: "Performance")
                }
            }
            
            // Integration with Analytics
            DispatchQueue.main.async {
                Analytics.shared.track("memory_usage", properties: [
                    "context": context,
                    "memory_mb": Int(memoryUsage.residentSizeMB),
                    "item_count": itemCount ?? 0,
                    "timestamp": memoryUsage.timestamp.timeIntervalSince1970
                ])
            }
        }
    }
    
    /// Get memory statistics for a context
    public func getMemoryStats(for context: String) -> MemoryStats? {
        return metricsQueue.sync { [weak self] in
            guard let measurements = self?.memoryMetrics[context], !measurements.isEmpty else {
                return nil
            }
            
            let residentSizes = measurements.map { $0.residentSizeMB }
            let count = measurements.count
            let sum = residentSizes.reduce(0, +)
            
            return MemoryStats(
                context: context,
                count: count,
                averageResidentMB: Double(sum) / Double(count),
                maxResidentMB: residentSizes.max() ?? 0,
                minResidentMB: residentSizes.min() ?? 0,
                currentResidentMB: residentSizes.last ?? 0
            )
        }
    }
    
    /// Get all memory statistics
    public func getAllMemoryStats() -> [MemoryStats] {
        return metricsQueue.sync { [weak self] in
            guard let self = self else { return [] }
            
            return self.memoryMetrics.compactMap { context, _ in
                self.getMemoryStats(for: context)
            }.sorted { $0.context < $1.context }
        }
    }
    
    /// Track filter operation with analytics integration
    public func trackFilterOperation<T>(
        filterType: String,
        itemCount: Int,
        operation: () async -> T
    ) async -> T {
        let signpostID = signposter.makeSignpostID()
        let state = signposter.beginInterval(
            "Filter",
            id: signpostID,
            "\(filterType) on \(itemCount) items"
        )
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Record memory before operation
        recordMemoryUsage(context: "before_\(filterType)", itemCount: itemCount)
        
        let result = await operation()
        
        // Record memory after operation
        recordMemoryUsage(context: "after_\(filterType)", itemCount: itemCount)
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        signposter.endInterval("Filter", state)
        
        // Send to analytics
        Analytics.shared.track("filter_performance", properties: [
            "filter_type": filterType,
            "item_count": itemCount,
            "duration_ms": Int(duration * 1000),
            "items_per_second": itemCount > 0 ? Int(Double(itemCount) / duration) : 0
        ])
        
        // Log if slow
        if duration > 0.5 {
            os_log(.error, log: log, 
                "Slow filter operation: %{public}@ took %.2fs for %d items",
                filterType, duration, itemCount
            )
        }
        
        // Record timing metric
        recordMetric(filterType, duration: duration)
        
        return result
    }
    
    /// Clear all recorded metrics
    public func clearMetrics() {
        metricsQueue.async { [weak self] in
            self?.metrics.removeAll()
            self?.memoryMetrics.removeAll()
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

/// Memory usage measurement
public struct MemoryUsage {
    public let timestamp: Date
    public let residentSizeMB: UInt64
    public let virtualSizeMB: UInt64
    public let context: String
    public let associatedItemCount: Int?
    
    init(context: String, associatedItemCount: Int? = nil) {
        self.timestamp = Date()
        self.context = context
        self.associatedItemCount = associatedItemCount
        
        // Get memory info from system
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if result == KERN_SUCCESS {
            self.residentSizeMB = info.resident_size / 1024 / 1024
            self.virtualSizeMB = info.virtual_size / 1024 / 1024
        } else {
            self.residentSizeMB = 0
            self.virtualSizeMB = 0
        }
    }
    
    public var summary: String {
        let itemInfo = associatedItemCount.map { " (\($0) items)" } ?? ""
        return "\(context): \(residentSizeMB)MB resident\(itemInfo)"
    }
}

/// Memory statistics for a context
public struct MemoryStats {
    public let context: String
    public let count: Int
    public let averageResidentMB: Double
    public let maxResidentMB: UInt64
    public let minResidentMB: UInt64
    public let currentResidentMB: UInt64
    
    public var summary: String {
        return "\(context): \(String(format: "%.1f", averageResidentMB))MB avg, \(maxResidentMB)MB peak (\(count) samples)"
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
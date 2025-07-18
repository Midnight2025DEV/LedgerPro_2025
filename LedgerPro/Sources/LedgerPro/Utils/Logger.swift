import Foundation
import os.log

/// Log levels with visual indicators and priority ordering
public enum LogLevel: Int, CaseIterable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    
    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
    
    var name: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARN"
        case .error: return "ERROR"
        }
    }
    
    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        }
    }
}

/// Production-safe logging system with conditional compilation
public final class Logger {
    public static let shared = Logger()
    
    private let osLog = OSLog(subsystem: "com.ledgerpro.app", category: "LedgerPro")
    
    #if DEBUG
    private let isDebugEnabled = true
    private let shouldPrintToConsole = true
    #else
    private let isDebugEnabled = false
    private let shouldPrintToConsole = false
    #endif
    
    private let minimumLogLevel: LogLevel
    private let dateFormatter: DateFormatter
    
    private init() {
        #if DEBUG
        self.minimumLogLevel = .debug
        #else
        self.minimumLogLevel = .warning
        #endif
        
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "HH:mm:ss.SSS"
    }
    
    /// Main logging function with file/function/line information
    public func log(
        _ message: String,
        level: LogLevel = .info,
        category: String? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        // Only log if level meets minimum threshold
        guard level.rawValue >= minimumLogLevel.rawValue else { return }
        
        let timestamp = dateFormatter.string(from: Date())
        let filename = URL(fileURLWithPath: file).deletingPathExtension().lastPathComponent
        let categoryPrefix = category.map { "[\($0)] " } ?? ""
        
        #if DEBUG
        if shouldPrintToConsole {
            let debugInfo = "[\(filename):\(line)] \(function)"
            print("\(level.emoji) \(timestamp) \(level.name) \(categoryPrefix)\(debugInfo) - \(message)")
        }
        #endif
        
        // Always log to os_log for crash reports and system logs
        os_log("%{public}@", log: osLog, type: level.osLogType, "\(categoryPrefix)\(message)")
    }
    
    /// Debug level logging - only in DEBUG builds
    public func debug(
        _ message: String,
        category: String? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }
    
    /// Info level logging
    public func info(
        _ message: String,
        category: String? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }
    
    /// Warning level logging
    public func warning(
        _ message: String,
        category: String? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }
    
    /// Error level logging
    public func error(
        _ message: String,
        category: String? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }
    
    /// Log with custom formatting for data structures
    public func logObject<T>(_ object: T, level: LogLevel = .debug, name: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let objectName = name ?? String(describing: type(of: object))
        log("[\(objectName)] \(String(describing: object))", level: level, file: file, function: function, line: line)
    }
    
    /// Performance timing utility
    public func measureTime<T>(
        operation: String,
        level: LogLevel = .debug,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        block: () throws -> T
    ) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try block()
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        log("⏱️ \(operation) completed in \(String(format: "%.3f", elapsed))s", level: level, file: file, function: function, line: line)
        return result
    }
    
    /// Network request logging helper
    public func logNetworkRequest(
        url: String,
        method: String = "GET",
        statusCode: Int? = nil,
        error: Error? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        if let error = error {
            self.error("🌐 \(method) \(url) failed: \(error.localizedDescription)", category: "Network", file: file, function: function, line: line)
        } else if let code = statusCode {
            let level: LogLevel = (200...299).contains(code) ? .info : .warning
            log("🌐 \(method) \(url) -> \(code)", level: level, category: "Network", file: file, function: function, line: line)
        } else {
            info("🌐 \(method) \(url)", category: "Network", file: file, function: function, line: line)
        }
    }
}

// MARK: - Global Logger Convenience
/// Global logger instance for easy access
public let logger = Logger.shared

// MARK: - Legacy AppLogger Support
/// Maintains compatibility with existing AppLogger usage
public typealias AppLogger = Logger

// MARK: - Debug-only print replacement
/// Development-only print function that's disabled in release builds
public func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    let message = items.map { String(describing: $0) }.joined(separator: separator)
    logger.debug(message)
    #endif
}
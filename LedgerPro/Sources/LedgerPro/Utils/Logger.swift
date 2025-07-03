import Foundation

enum LogLevel: String {
    case debug = "🔍"
    case info = "ℹ️"
    case warning = "⚠️"
    case error = "❌"
}

struct AppLogger {
    static let shared = AppLogger()
    
    #if DEBUG
    private let isEnabled = true
    #else
    private let isEnabled = false
    #endif
    
    func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        guard isEnabled else { return }
        let filename = URL(fileURLWithPath: file).lastPathComponent
        print("\(level.rawValue) [\(filename):\(line)] \(function) - \(message)")
    }
    
    func debug(_ message: String) {
        log(message, level: .debug)
    }
    
    func info(_ message: String) {
        log(message, level: .info)
    }
    
    func warning(_ message: String) {
        log(message, level: .warning)
    }
    
    func error(_ message: String) {
        log(message, level: .error)
    }
}
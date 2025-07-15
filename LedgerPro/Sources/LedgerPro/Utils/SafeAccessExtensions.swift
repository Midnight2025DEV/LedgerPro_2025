import Foundation
import SwiftUI

// MARK: - Safe Array Access
extension Array {
    /// Safely access array elements
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}

// MARK: - Safe Dictionary Access
extension Dictionary {
    /// Get value with default
    func value(for key: Key, default defaultValue: Value) -> Value {
        self[key] ?? defaultValue
    }
}

// MARK: - Safe URL Creation
extension URL {
    /// Create URL with fallback
    static func safe(_ string: String, fallback: URL? = nil) -> URL {
        URL(string: string) ?? fallback ?? URL(string: "https://example.com")!
    }
    
    /// Create URL or throw
    static func safeInit(_ string: String) throws -> URL {
        guard let url = URL(string: string) else {
            throw URLError(.badURL)
        }
        return url
    }
}

// MARK: - Safe Color Access
extension Color {
    /// Get color with fallback
    static func safe(named: String, fallback: Color = .gray) -> Color {
        // Platform-specific implementation
        #if os(macOS)
        if let nsColor = NSColor(named: named) {
            return Color(nsColor)
        }
        return fallback
        #else
        if let uiColor = UIColor(named: named) {
            return Color(uiColor)
        }
        return fallback
        #endif
    }
}

// MARK: - Safe Image Access
extension Image {
    /// Create image with fallback
    static func safe(systemName: String, fallback: String = "questionmark.circle") -> Image {
        // Check if system image exists
        #if os(macOS)
        if NSImage(systemSymbolName: systemName, accessibilityDescription: nil) != nil {
            return Image(systemName: systemName)
        }
        #endif
        return Image(systemName: fallback)
    }
}

// MARK: - Safe Casting
extension Optional {
    /// Cast with logging
    func safeCast<T>(to type: T.Type, file: String = #file, line: Int = #line) -> T? {
        guard let self = self else {
            print("⚠️ Attempted to cast nil value to \(type) at \(URL(fileURLWithPath: file).lastPathComponent):\(line)")
            return nil
        }
        
        guard let casted = self as? T else {
            print("⚠️ Failed to cast \(Swift.type(of: self)) to \(type) at \(URL(fileURLWithPath: file).lastPathComponent):\(line)")
            return nil
        }
        
        return casted
    }
}

// MARK: - Safe Numerical Operations
extension Optional where Wrapped: Numeric {
    /// Get value or zero
    var orZero: Wrapped {
        return self ?? .zero
    }
}

extension Optional where Wrapped == Double {
    /// Safe division with zero check
    func safeDivide(by divisor: Double?) -> Double? {
        guard let self = self, let divisor = divisor, divisor != 0 else {
            return nil
        }
        return self / divisor
    }
}

// MARK: - Safe View Geometry
extension View {
    /// Read geometry safely
    func safeGeometryReader<Content: View>(
        @ViewBuilder content: @escaping (GeometryProxy) -> Content
    ) -> some View {
        GeometryReader { geometry in
            content(geometry)
        }
    }
    
    /// Safe window access
    func withSafeWindow<Content: View>(
        @ViewBuilder content: @escaping (NSWindow?) -> Content
    ) -> some View {
        self.background(
            WindowAccessor { window in
                let _ = content(window) // Suppress unused warning
            }
        )
    }
}

// MARK: - Window Accessor Helper
private struct WindowAccessor: NSViewRepresentable {
    let callback: (NSWindow?) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            callback(view.window)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        callback(nsView.window)
    }
}

// MARK: - Safe String Conversion
extension Optional where Wrapped == String {
    /// Get string or empty
    var orEmpty: String {
        return self ?? ""
    }
    
    /// Get string or placeholder
    func or(_ placeholder: String) -> String {
        return self ?? placeholder
    }
}
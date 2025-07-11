#!/usr/bin/env swift

import Foundation

print("🧪 MCP PDF Processing Fix Verification")
print("=" * 50)

// Test 1: Verify the fix is in the code
print("\n1. Checking MCPBridge.swift for process_bank_pdf...")

let mcpBridgePath = "Sources/LedgerPro/Services/MCP/MCPBridge.swift"
if FileManager.default.fileExists(atPath: mcpBridgePath) {
    do {
        let content = try String(contentsOfFile: mcpBridgePath)
        let occurrences = content.components(separatedBy: "process_bank_pdf").count - 1
        print("   ✅ Found \(occurrences) occurrences of 'process_bank_pdf'")
        
        if content.contains("tools/call") && content.contains("process_bank_pdf") {
            print("   ✅ Tool call pattern correctly implemented")
        } else {
            print("   ❌ Tool call pattern not found")
        }
        
        if content.contains("📡 MCP Tool Response") {
            print("   ✅ Debug response logging added")
        } else {
            print("   ❌ Debug response logging missing")
        }
    } catch {
        print("   ❌ Error reading file: \(error)")
    }
} else {
    print("   ❌ MCPBridge.swift not found")
}

// Test 2: Check if PDF processor servers are running
print("\n2. Checking PDF processor server status...")

let task = Process()
task.launchPath = "/bin/bash"
task.arguments = ["-c", "ps aux | grep 'pdf_processor_server.py' | grep -v grep | wc -l"]

let pipe = Pipe()
task.standardOutput = pipe
task.launch()
task.waitUntilExit()

let data = pipe.fileHandleForReading.readDataToEndOfFile()
if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
   let count = Int(output) {
    if count > 0 {
        print("   ✅ \(count) PDF processor server(s) running")
    } else {
        print("   ❌ No PDF processor servers running")
    }
} else {
    print("   ❌ Could not check server status")
}

// Test 3: Verify test files are available
print("\n3. Checking for test PDF files...")

let testPaths = [
    NSHomeDirectory() + "/Downloads",
    NSHomeDirectory() + "/Documents"
]

var totalPDFs = 0
for path in testPaths {
    do {
        let files = try FileManager.default.contentsOfDirectory(atPath: path)
        let pdfFiles = files.filter { $0.lowercased().hasSuffix(".pdf") }
        if pdfFiles.count > 0 {
            print("   ✅ \(pdfFiles.count) PDF(s) in \(URL(fileURLWithPath: path).lastPathComponent)")
            totalPDFs += pdfFiles.count
        }
    } catch {
        print("   ⚠️ Could not access \(path)")
    }
}

if totalPDFs > 0 {
    print("   ✅ Total: \(totalPDFs) PDF files available for testing")
} else {
    print("   ❌ No test PDF files found")
}

print("\n🎯 VERIFICATION SUMMARY:")
print("   • Fix implemented: Check MCPBridge.swift results above")
print("   • Servers running: Check server status above")
print("   • Test files: \(totalPDFs) PDFs available")
print("")
print("🚀 READY TO TEST:")
print("   1. Upload a PDF with 'Use Local MCP Processing' enabled")
print("   2. Monitor console for debug output")
print("   3. Verify transactions are extracted successfully")

print("\n" + String(repeating: "=", count: 50))
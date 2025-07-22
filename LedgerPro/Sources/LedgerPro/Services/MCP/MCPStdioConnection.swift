import Foundation
import Combine
import OSLog

/// MCP Connection that communicates via stdio (standard input/output)
@MainActor
class MCPStdioConnection: ObservableObject {
    
    // Safe newline data constant to avoid force unwrapping
    private static let newlineData = "\n".data(using: .utf8) ?? Data([0x0A])
    
    private var process: Process?
    private var inputPipe: Pipe?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?
    
    private let logger = AppLogger.shared
    private var responseHandlers: [String: CheckedContinuation<MCPResponse, Error>] = [:]
    private let responseQueue = DispatchQueue(label: "mcp.response", qos: .userInitiated)
    
    @Published var isConnected: Bool = false
    @Published var lastError: Error?
    
    private let serverPath: String
    private let serverName: String
    private var outputBuffer = Data()
    private var isInitialized: Bool = false
    
    init(serverPath: String, serverName: String) {
        self.serverPath = serverPath
        self.serverName = serverName
    }
    
    func connect() async throws {
        guard !isConnected else { return }
        
        logger.info("🔌 Connecting to MCP server: \(self.serverName)")
        
        process = Process()
        guard let process = process else {
            throw MCPConnectionError.processCreationFailed
        }
        
        inputPipe = Pipe()
        outputPipe = Pipe()
        errorPipe = Pipe()
        
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        let serverURL = URL(fileURLWithPath: serverPath)
        process.currentDirectoryURL = serverURL.deletingLastPathComponent()
        
        // Use Python from venv if available
        let venvPython = serverURL.deletingLastPathComponent()
            .appendingPathComponent("venv/bin/python3").path
        let pythonPath = FileManager.default.fileExists(atPath: venvPython) ? venvPython : "/usr/bin/python3"
        
        process.executableURL = URL(fileURLWithPath: pythonPath)
        process.arguments = [serverPath]
        
        var environment = ProcessInfo.processInfo.environment
        environment["PYTHONUNBUFFERED"] = "1"
        process.environment = environment
        
        outputPipe?.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            Task { [weak self] in
                guard let self = self else { return }
                await self.handleOutputData(data)
            }
        }
        
        errorPipe?.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            if let error = String(data: data, encoding: .utf8) {
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.logger.error("⚠️ Server error: \(error)")
                }
            }
        }
        
        do {
            try process.run()
            isConnected = true
            logger.info("✅ Connected to \(self.serverName)")
        } catch {
            logger.error("❌ Failed to start MCP server process: \(error.localizedDescription)")
            throw MCPConnectionError.launchFailed(error.localizedDescription)
        }
        
        // Only initialize if not already initialized
        if !isInitialized {
            try await initialize()
            isInitialized = true
        } else {
            logger.info("ℹ️ Server \(self.serverName) already initialized, skipping initialization")
        }
    }
    
    func disconnect() async {
        logger.info("🔌 Disconnecting from \(self.serverName)")
        
        responseQueue.sync {
            for (_, continuation) in responseHandlers {
                continuation.resume(throwing: MCPConnectionError.connectionClosed)
            }
            responseHandlers.removeAll()
        }
        
        inputPipe?.fileHandleForWriting.closeFile()
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        errorPipe?.fileHandleForReading.readabilityHandler = nil
        
        process?.terminate()
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        if process?.isRunning == true {
            process?.interrupt()
        }
        
        process = nil
        inputPipe = nil
        outputPipe = nil
        errorPipe = nil
        isConnected = false
        isInitialized = false  // Reset initialization state
        
        logger.info("✅ Disconnected from \(self.serverName)")
    }
    
    func sendRequest(_ request: MCPRequest) async throws -> MCPResponse {
        return try await sendRequestWithTimeout(request, timeout: 120.0)
    }
    
    private func sendRequestWithTimeout(_ request: MCPRequest, timeout: TimeInterval) async throws -> MCPResponse {
        guard isConnected else {
            throw MCPConnectionError.notConnected
        }
        
        return try await withThrowingTaskGroup(of: MCPResponse.self) { group in
            // Add the main request task
            group.addTask { [weak self] in
                guard let self = self else { throw MCPConnectionError.notConnected }
                
                return try await withCheckedThrowingContinuation { continuation in
                    Task { @MainActor in
                        self.responseHandlers[request.id] = continuation
                        
                        do {
                            let encoder = JSONEncoder()
                            var requestData = try encoder.encode(request)
                            requestData.append(try "\n".safeUTF8Data())
                            
                            self.inputPipe?.fileHandleForWriting.write(requestData)
                            
                            self.logger.debug("📤 Sent request: \(request.method.rawValue) (id: \(request.id))")
                            
                        } catch {
                            self.logger.error("❌ Failed to encode/send MCP request: \(error.localizedDescription)")
                            self.responseHandlers.removeValue(forKey: request.id)
                            
                            // Provide more specific error for JSON encoding issues
                            if error is EncodingError {
                                continuation.resume(throwing: MCPConnectionError.invalidResponse)
                            } else {
                                continuation.resume(throwing: error)
                            }
                        }
                    }
                }
            }
            
            // Add timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw MCPConnectionError.timeout
            }
            
            // Return the first completed task (either response or timeout)
            guard let result = try await group.next() else {
                throw MCPConnectionError.timeout
            }
            
            // Cancel remaining tasks
            group.cancelAll()
            
            return result
        }
    }
    
    func sendNotification(_ notification: MCPNotification) async throws {
        guard isConnected else {
            throw MCPConnectionError.notConnected
        }
        
        do {
            let encoder = JSONEncoder()
            var notificationData = try encoder.encode(notification)
            notificationData.append(try "\n".safeUTF8Data())
            
            inputPipe?.fileHandleForWriting.write(notificationData)
            
            logger.debug("📤 Sent notification: \(notification.method)")
            
        } catch {
            logger.error("❌ Failed to encode/send MCP notification: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func initialize() async throws {
        let request = MCPRequest(
            method: .initialize,
            params: [
                "protocolVersion": AnyCodable("2024-11-05"),
                "capabilities": AnyCodable([
                    "roots": AnyCodable([
                        "listChanged": false
                    ]),
                    "sampling": AnyCodable([:] as [String: Any]),
                    "prompts": AnyCodable([
                        "listChanged": false
                    ]),
                    "resources": AnyCodable([
                        "subscribe": false,
                        "listChanged": false
                    ]),
                    "tools": AnyCodable([
                        "listChanged": false
                    ])
                ]),
                "clientInfo": AnyCodable([
                    "name": "LedgerPro",
                    "version": "1.0.0"
                ])
            ]
        )
        
        let response = try await sendRequest(request)
        guard response.isSuccess else {
            logger.error("❌ MCP initialization failed:")
            logger.error("   Server response: \(String(describing: response))")
            if let error = response.error {
                logger.error("   Error code: \(error.code)")
                logger.error("   Error message: \(error.message)")
                throw error
            } else {
                throw MCPConnectionError.initializationFailed
            }
        }
        
        // Send "initialized" notification to complete the MCP protocol handshake
        logger.debug("📤 Sending initialized notification...")
        try await sendNotification(MCPNotification(method: "notifications/initialized"))
        
        logger.info("✅ MCP server initialized successfully with protocol handshake complete")
        logger.debug("   Server response: \(String(describing: response))")
    }
    
    private func handleOutputData(_ data: Data) async {
        // APPEND new data to buffer
        outputBuffer.append(data)
        
        // Process all complete messages in buffer (delimited by newlines)
        while let newlineRange = outputBuffer.firstRange(of: Self.newlineData) {
            // Extract one complete message
            let messageData = outputBuffer[..<newlineRange.lowerBound]
            
            // Remove processed message + delimiter from buffer
            outputBuffer.removeSubrange(..<newlineRange.upperBound)
            
            // Skip empty messages
            if messageData.isEmpty {
                continue
            }
            
            // Validate JSON before processing
            do {
                // Quick validation that this is valid JSON
                _ = try JSONSerialization.jsonObject(with: messageData, options: [])
                
                // Debug the raw message data
                if let rawMessage = String(data: messageData, encoding: .utf8) {
                    logger.debug("🔍 RAW MCP MESSAGE: \(String(rawMessage.prefix(500)))...")
                }
                
                // Process the complete message
                processCompleteMessage(messageData)
            } catch {
                // This might be a partial message, keep accumulating
                logger.warning("⚠️ Received partial or invalid JSON, buffering: \(messageData.count) bytes")
                // Debug: Check if buffer ends with newline when we have a large buffer
                if outputBuffer.count > 100000 {
                    let last10Bytes = outputBuffer.suffix(10)
                    let last10String = String(data: last10Bytes, encoding: .utf8) ?? "non-utf8"
                    let bufferSize = outputBuffer.count
                    logger.warning("🔍 Large buffer (\(bufferSize) bytes) last 10 chars: \(last10String.debugDescription)")
                    // Check if we have a complete JSON object but missing newline
                    if (try? JSONSerialization.jsonObject(with: outputBuffer, options: [])) != nil {
                        logger.warning("⚡ Buffer contains valid JSON but no newline! Adding newline...")
                        outputBuffer.append(Self.newlineData)
                        continue  // Try processing again with the added newline
                    }
                }                // Give more time for large responses to complete
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                // Put the data back at the beginning of the buffer
                outputBuffer.insert(contentsOf: messageData, at: 0)
                outputBuffer.insert(contentsOf: Self.newlineData, at: messageData.count)
                break  // Wait for more data
            }
        }
        
        // Check buffer size to prevent memory issues with large messages
        if outputBuffer.count > 10_000_000 { // 10MB safety limit
            logger.error("❌ Buffer exceeded maximum size (\(self.outputBuffer.count) bytes), clearing buffer")
            outputBuffer.removeAll() // Reset to prevent memory issues
        }
    }
    
    private func processCompleteMessage(_ messageData: Data) {
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(MCPResponse.self, from: messageData)
            
            logger.debug("📥 Received response for id: \(response.id)")
            
            responseQueue.sync {
                if let continuation = responseHandlers.removeValue(forKey: response.id) {
                    continuation.resume(returning: response)
                } else {
                    logger.warning("⚠️ Received response with no matching request: \(response.id)")
                }
            }
            
        } catch {
            logger.error("❌ Failed to parse MCP response: \(error)")
            // Log detailed error information for debugging
            if let decodingError = error as? DecodingError {
                logger.error("🔍 DECODING ERROR DETAILS: \(decodingError.localizedDescription)")
            }
            if let rawMessage = String(data: messageData, encoding: .utf8) {
                logger.error("🔍 PROBLEMATIC MESSAGE (\(messageData.count) bytes): \(String(rawMessage.prefix(300)))...")
            }
        }
    }
}

enum MCPConnectionError: LocalizedError {
    case notConnected
    case connectionClosed
    case processCreationFailed
    case launchFailed(String)
    case initializationFailed
    case invalidResponse
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "MCP server is not connected"
        case .connectionClosed:
            return "MCP connection was closed"
        case .processCreationFailed:
            return "Failed to create MCP server process"
        case .launchFailed(let reason):
            return "Failed to launch MCP server: \(reason)"
        case .initializationFailed:
            return "Failed to initialize MCP server"
        case .invalidResponse:
            return "Received invalid response from MCP server"
        case .timeout:
            return "MCP request timed out"
        }
    }
}

extension MCPStdioConnection: MCPConnection {}

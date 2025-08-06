import Foundation

enum BackendError: LocalizedError {
    case executableNotFound
    case startupTimeout
    case unexpectedTermination
    
    var errorDescription: String? {
        switch self {
        case .executableNotFound:
            return "Backend executable not found in app bundle"
        case .startupTimeout:
            return "Backend failed to start within timeout period"
        case .unexpectedTermination:
            return "Backend process terminated unexpectedly"
        }
    }
}

@MainActor
class BackendManager: ObservableObject {
    @Published var isRunning = false
    @Published var lastError: String?
    @Published var startupProgress: String = ""
    
    private var backendProcess: Process?
    private let backendURL = "http://127.0.0.1:8000"
    private let logger = AppLogger.shared
    
    init() {
        setupTerminationHandler()
    }
    
    deinit {
        backendProcess?.terminate()
        backendProcess = nil
    }
    
    func start() async {
        guard !isRunning else { return }
        
        startupProgress = "Starting backend service..."
        
        do {
            guard let backendPath = Bundle.main.path(forResource: "ledgerpro-backend", ofType: nil, inDirectory: "Resources") else {
                #if DEBUG
                logger.log("Backend executable not found, falling back to development mode")
                startupProgress = "Using external backend (development mode)"
                isRunning = await checkHealth()
                return
                #else
                throw BackendError.executableNotFound
                #endif
            }
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: backendPath)
            process.environment = [
                "PYTHONUNBUFFERED": "1",
                "HOST": "127.0.0.1",
                "PORT": "8000",
                "LEDGERPRO_EMBEDDED": "1"
            ]
            
            setupProcessOutput(process)
            
            try process.run()
            backendProcess = process
            
            startupProgress = "Waiting for backend to initialize..."
            
            let started = await waitForBackend()
            if started {
                isRunning = true
                startupProgress = "Backend ready"
                lastError = nil
            } else {
                throw BackendError.startupTimeout
            }
            
        } catch {
            lastError = error.localizedDescription
            startupProgress = "Failed to start backend"
            logger.error("Backend startup failed: \(error)")
        }
    }
    
    func stop() {
        guard let process = backendProcess else { return }
        
        if process.isRunning {
            process.terminate()
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                if process.isRunning {
                    process.interrupt()
                }
            }
        }
        
        backendProcess = nil
        isRunning = false
        startupProgress = ""
    }
    
    func restart() async {
        stop()
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await start()
    }
    
    private func setupProcessOutput(_ process: Process) {
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                DispatchQueue.main.async {
                    self.logger.log("Backend: \(output.trimmingCharacters(in: .newlines))")
                }
            }
        }
        
        errorPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if let error = String(data: data, encoding: .utf8), !error.isEmpty {
                DispatchQueue.main.async {
                    self.logger.error("Backend Error: \(error.trimmingCharacters(in: .newlines))")
                }
            }
        }
    }
    
    private func setupTerminationHandler() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTermination),
            name: Process.didTerminateNotification,
            object: nil
        )
    }
    
    @objc private func handleTermination(_ notification: Notification) {
        guard let process = notification.object as? Process,
              process == backendProcess else { return }
        
        DispatchQueue.main.async {
            self.isRunning = false
            if process.terminationStatus != 0 {
                self.lastError = "Backend terminated with status: \(process.terminationStatus)"
                self.logger.error("Backend terminated unexpectedly with status: \(process.terminationStatus)")
            }
        }
    }
    
    private func waitForBackend() async -> Bool {
        for attempt in 0..<30 {
            if await checkHealth() {
                return true
            }
            
            startupProgress = "Waiting for backend... (\(attempt + 1)/30)"
            
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
        return false
    }
    
    private func checkHealth() async -> Bool {
        guard let url = URL(string: "\(backendURL)/api/health") else { return false }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
    
    var statusDescription: String {
        if isRunning {
            return "Backend running"
        } else if let error = lastError {
            return "Backend error: \(error)"
        } else if !startupProgress.isEmpty {
            return startupProgress
        } else {
            return "Backend not running"
        }
    }
}

#if DEBUG
extension BackendManager {
    func connectToExternalBackend() async {
        startupProgress = "Connecting to external backend..."
        isRunning = await checkHealth()
        if isRunning {
            startupProgress = "Connected to external backend"
        } else {
            lastError = "Could not connect to external backend at \(backendURL)"
            startupProgress = "Failed to connect"
        }
    }
}
#endif
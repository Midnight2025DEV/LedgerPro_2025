import Foundation

@MainActor
class APIService: ObservableObject {
    private let baseURL = "http://127.0.0.1:8000"
    
    @Published var isHealthy = false
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var lastError: String?
    
    private var authToken: String?
    
    init() {
        loadAuthToken()
    }
    
    // MARK: - Authentication
    private func loadAuthToken() {
        authToken = UserDefaults.standard.string(forKey: "auth_token")
    }
    
    private func saveAuthToken(_ token: String) {
        authToken = token
        UserDefaults.standard.set(token, forKey: "auth_token")
    }
    
    private func clearAuthToken() {
        authToken = nil
        UserDefaults.standard.removeObject(forKey: "auth_token")
    }
    
    var isAuthenticated: Bool {
        return authToken != nil
    }
    
    // MARK: - HTTP Helpers
    private func makeRequest<T: Codable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.networkError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        request.timeoutInterval = 30.0
        
        print("Making request: \(method) \(url)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError("Invalid response")
            }
            
            guard httpResponse.statusCode == 200 else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("API request failed: \(httpResponse.statusCode) - \(errorMessage)")
                
                if httpResponse.statusCode == 401 {
                    clearAuthToken()
                }
                
                throw APIError.httpError(httpResponse.statusCode, errorMessage)
            }
            
            let decoder = JSONDecoder()
            let result = try decoder.decode(responseType, from: data)
            
            print("Request successful for \(endpoint)")
            return result
            
        } catch let error as APIError {
            throw error
        } catch {
            print("Network error: \(error)")
            throw APIError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: - API Endpoints
    func healthCheck() async throws -> HealthStatus {
        do {
            let health = try await makeRequest(
                endpoint: "/api/health",
                responseType: HealthStatus.self
            )
            await MainActor.run {
                isHealthy = true
                lastError = nil
            }
            return health
        } catch {
            await MainActor.run {
                isHealthy = false
                lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    func uploadFile(_ fileURL: URL) async throws -> UploadResponse {
        guard let url = URL(string: "\(baseURL)/api/upload") else {
            throw APIError.networkError("Invalid upload URL")
        }
        
        print("🌐 Upload URL: \(url)")
        print("📁 File URL: \(fileURL)")
        print("🔒 Auth token present: \(authToken != nil)")
        
        await MainActor.run {
            isUploading = true
            uploadProgress = 0.0
        }
        
        defer {
            Task { @MainActor in
                isUploading = false
                uploadProgress = 0.0
            }
        }
        
        do {
            // First, verify file accessibility step by step
            print("🔍 Testing file accessibility...")
            print("🔍 File URL path: \(fileURL.path)")
            print("🔍 File URL absolute string: \(fileURL.absoluteString)")
            print("🔍 File exists at path: \(FileManager.default.fileExists(atPath: fileURL.path))")
            print("🔍 File is readable: \(FileManager.default.isReadableFile(atPath: fileURL.path))")
            
            // Try to get file attributes first
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                print("🔍 File attributes: \(attributes)")
                if let size = attributes[.size] as? NSNumber {
                    print("🔍 File size from attributes: \(size.intValue) bytes")
                }
            } catch {
                print("❌ Failed to get file attributes: \(error)")
            }
            
            // Now try to read the file data
            let fileData: Data
            do {
                fileData = try Data(contentsOf: fileURL)
                print("✅ Successfully read file data: \(fileData.count) bytes")
            } catch {
                print("❌ Failed to read file data: \(error)")
                throw APIError.uploadError("Cannot read file: \(error.localizedDescription)")
            }
            
            let filename = fileURL.lastPathComponent
            let boundary = "Boundary-\(UUID().uuidString)"
            
            print("📄 File name: \(filename)")
            print("📏 File size: \(fileData.count) bytes")
            
            var body = Data()
            
            // Add file data
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            if let token = authToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            request.httpBody = body
            request.timeoutInterval = 120.0
            
            print("📤 Uploading file: \(filename) (\(fileData.count) bytes)")
            print("🔍 Request headers: \(request.allHTTPHeaderFields ?? [:])")
            
            // Simulate upload progress
            Task {
                for i in 1...10 {
                    await MainActor.run {
                        uploadProgress = Double(i) * 0.1
                    }
                    try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                }
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                throw APIError.networkError("Invalid response")
            }
            
            print("📊 Response status: \(httpResponse.statusCode)")
            print("📊 Response headers: \(httpResponse.allHeaderFields)")
            
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            print("📄 Response body: \(responseString)")
            
            guard httpResponse.statusCode == 200 else {
                let errorMessage = responseString
                print("❌ Upload failed: \(httpResponse.statusCode) - \(errorMessage)")
                throw APIError.httpError(httpResponse.statusCode, errorMessage)
            }
            
            let decoder = JSONDecoder()
            do {
                let result = try decoder.decode(UploadResponse.self, from: data)
                
                await MainActor.run {
                    uploadProgress = 1.0
                }
                
                print("✅ Upload successful: \(result.jobId)")
                return result
            } catch {
                print("❌ Failed to decode response: \(error)")
                print("🔍 Raw response: \(responseString)")
                throw APIError.networkError("Failed to decode server response: \(error.localizedDescription)")
            }
            
        } catch let error as APIError {
            print("❌ API Error: \(error.errorDescription ?? "Unknown")")
            throw error
        } catch {
            print("❌ Unexpected error: \(error)")
            throw APIError.uploadError(error.localizedDescription)
        }
    }
    
    func getJobStatus(_ jobId: String) async throws -> JobStatus {
        return try await makeRequest(
            endpoint: "/api/jobs/\(jobId)",
            responseType: JobStatus.self
        )
    }
    
    func getTransactions(_ jobId: String) async throws -> TransactionResults {
        return try await makeRequest(
            endpoint: "/api/transactions/\(jobId)",
            responseType: TransactionResults.self
        )
    }
    
    func pollJobUntilComplete(
        _ jobId: String,
        maxRetries: Int = 30,
        intervalSeconds: UInt64 = 2
    ) async throws -> JobStatus {
        var retries = 0
        
        while retries < maxRetries {
            let status = try await getJobStatus(jobId)
            
            if status.status == "completed" || status.status == "error" {
                return status
            }
            
            try await Task.sleep(nanoseconds: intervalSeconds * 1_000_000_000)
            retries += 1
        }
        
        throw APIError.timeout("Job processing timeout")
    }
}

// MARK: - API Models
struct HealthStatus: Codable {
    let status: String
    let timestamp: String
    let version: String
    let message: String
    let processor: String?
}

struct UploadResponse: Codable {
    let jobId: String
    let status: String
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case jobId = "job_id"
        case status, message
    }
}

struct JobStatus: Codable {
    let jobId: String
    let status: String
    let progress: Double
    let filename: String?
    let createdAt: String?
    let completedAt: String?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case jobId = "job_id"
        case status, progress, filename, error
        case createdAt = "created_at"
        case completedAt = "completed_at"
    }
}

struct APIAccount: Codable {
    let id: String
    let name: String
    let institution: String
    let accountType: String
    let identifier: String?
    let isNew: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, institution, identifier
        case accountType = "account_type"
        case isNew = "is_new"
    }
}

struct TransactionResults: Codable {
    let jobId: String
    let status: String
    let transactions: [Transaction]
    let account: APIAccount?
    let metadata: Metadata
    let summary: Summary
    
    struct Metadata: Codable {
        let filename: String
        let totalTransactions: Int
        let processingTime: String
        
        enum CodingKeys: String, CodingKey {
            case filename
            case totalTransactions = "total_transactions"
            case processingTime = "processing_time"
        }
    }
    
    struct Summary: Codable {
        let totalIncome: Double
        let totalExpenses: Double
        let netAmount: Double
        let transactionCount: Int
        
        enum CodingKeys: String, CodingKey {
            case totalIncome = "total_income"
            case totalExpenses = "total_expenses"
            case netAmount = "net_amount"
            case transactionCount = "transaction_count"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case jobId = "job_id"
        case status, transactions, account, metadata, summary
    }
}

// MARK: - Error Types
enum APIError: LocalizedError {
    case networkError(String)
    case httpError(Int, String)
    case uploadError(String)
    case timeout(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network Error: \(message)"
        case .httpError(let code, let message):
            return "HTTP \(code): \(message)"
        case .uploadError(let message):
            return "Upload Error: \(message)"
        case .timeout(let message):
            return "Timeout: \(message)"
        }
    }
}
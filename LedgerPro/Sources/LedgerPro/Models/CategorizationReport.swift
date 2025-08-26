import Foundation

/// Structured report for transaction categorization results
@MainActor
class CategorizationReport {
    // MARK: - Report Data
    private var startTime: Date
    private var endTime: Date?
    
    var totalTransactions = 0
    var successfulCategorizations = 0
    var failedCategorizations = 0
    
    // Category breakdown
    private var categoryCounts: [String: Int] = [:]
    
    // Confidence distribution
    var highConfidenceCount = 0    // > 0.8
    var mediumConfidenceCount = 0  // 0.5 - 0.8
    var lowConfidenceCount = 0     // < 0.5
    
    // Failed patterns tracking
    private var failedPatterns: [String: Int] = [:]
    private var failureReasons: [String: Int] = [:]
    
    // Detailed transaction samples
    private var sampleSuccesses: [(Transaction, Category, Double)] = []
    private var sampleFailures: [Transaction] = []
    
    // MARK: - Log Level
    enum LogLevel {
        case summary    // Just the report
        case detailed   // Report + sample transactions
        case verbose    // Everything (current behavior)
    }
    
    var logLevel: LogLevel = .summary
    
    // MARK: - Initialization
    init() {
        self.startTime = Date()
    }
    
    // MARK: - Data Collection
    
    func recordTransaction(_ transaction: Transaction) {
        totalTransactions += 1
    }
    
    func recordSuccess(transaction: Transaction, category: Category, confidence: Double) {
        successfulCategorizations += 1
        
        // Track category
        categoryCounts[category.name, default: 0] += 1
        
        // Track confidence distribution
        if confidence > 0.8 {
            highConfidenceCount += 1
        } else if confidence >= 0.5 {
            mediumConfidenceCount += 1
        } else {
            lowConfidenceCount += 1
        }
        
        // Keep samples for detailed logging
        if sampleSuccesses.count < 10 {
            sampleSuccesses.append((transaction, category, confidence))
        }
    }
    
    func recordFailure(transaction: Transaction, reason: String, suggestedCategory: Category? = nil, confidence: Double = 0.0) {
        failedCategorizations += 1
        
        // Track failed patterns
        let pattern = extractPattern(from: transaction.description)
        failedPatterns[pattern, default: 0] += 1
        
        // Track failure reasons
        failureReasons[reason, default: 0] += 1
        
        // Track low confidence as separate category
        if confidence < 0.5 && confidence > 0 {
            lowConfidenceCount += 1
        }
        
        // Keep samples for detailed logging
        if sampleFailures.count < 10 {
            sampleFailures.append(transaction)
        }
    }
    
    private func extractPattern(from description: String) -> String {
        // Extract common patterns from transaction descriptions
        let upperDescription = description.uppercased()
        
        // Common patterns
        if upperDescription.contains("ATM") || upperDescription.contains("CASH") {
            return "ATM/Cash Withdrawal"
        } else if upperDescription.contains("FEE") || upperDescription.contains("CHARGE") {
            return "Fees/Charges"
        } else if upperDescription.contains("TRANSFER") {
            return "Transfers"
        } else if upperDescription.contains("PAYMENT") || upperDescription.contains("PMT") {
            return "Payments"
        } else if upperDescription.contains("INTEREST") {
            return "Interest"
        } else if upperDescription.contains("DEPOSIT") {
            return "Deposits"
        }
        
        // Try to extract merchant name
        let words = description.split(separator: " ").prefix(3)
        return words.joined(separator: " ")
    }
    
    // MARK: - Report Generation
    
    func finalizeReport() {
        endTime = Date()
    }
    
    var processingTime: TimeInterval {
        guard let endTime = endTime else { return 0 }
        return endTime.timeIntervalSince(startTime)
    }
    
    var successRate: Double {
        guard totalTransactions > 0 else { return 0 }
        return Double(successfulCategorizations) / Double(totalTransactions)
    }
    
    func generateReport() -> String {
        var report = """
        
        ===== CATEGORIZATION REPORT =====
        Total Transactions: \(totalTransactions)
        Successfully Categorized: \(successfulCategorizations) (\(String(format: "%.1f", successRate * 100))%)
        Failed: \(failedCategorizations)
        
        """
        
        // Category breakdown
        if !categoryCounts.isEmpty {
            report += "By Category:\n"
            let sortedCategories = categoryCounts.sorted { $0.value > $1.value }
            for (category, count) in sortedCategories.prefix(10) {
                report += "  - \(category): \(count) transactions\n"
            }
            if sortedCategories.count > 10 {
                report += "  ... and \(sortedCategories.count - 10) more categories\n"
            }
            report += "\n"
        }
        
        // Confidence distribution
        report += """
        Confidence Distribution:
          - High (>0.8): \(highConfidenceCount) transactions
          - Medium (0.5-0.8): \(mediumConfidenceCount) transactions
          - Low (<0.5): \(lowConfidenceCount) transactions
        
        """
        
        // Failed patterns
        if !failedPatterns.isEmpty {
            report += "Top Failed Patterns:\n"
            let sortedPatterns = failedPatterns.sorted { $0.value > $1.value }
            for (pattern, count) in sortedPatterns.prefix(5) {
                let reason = getMostCommonReason(for: pattern)
                report += "  - \"\(pattern)\": \(count) instances (\(reason))\n"
            }
            report += "\n"
        }
        
        // Processing time
        report += "Processing Time: \(String(format: "%.2f", processingTime))s\n"
        report += "=================================\n"
        
        // Add detailed samples if requested
        if logLevel == .detailed || logLevel == .verbose {
            report += generateDetailedSection()
        }
        
        return report
    }
    
    private func generateDetailedSection() -> String {
        var detailed = "\n===== DETAILED SAMPLES =====\n"
        
        if !sampleSuccesses.isEmpty {
            detailed += "\nSUCCESSFUL CATEGORIZATIONS:\n"
            for (index, (transaction, category, confidence)) in sampleSuccesses.enumerated() {
                detailed += "\(index + 1). \"\(transaction.description)\" → \(category.name) (confidence: \(String(format: "%.2f", confidence)))\n"
            }
        }
        
        if !sampleFailures.isEmpty {
            detailed += "\nFAILED CATEGORIZATIONS:\n"
            for (index, transaction) in sampleFailures.enumerated() {
                detailed += "\(index + 1). \"\(transaction.description)\" (amount: \(transaction.amount))\n"
            }
        }
        
        detailed += "============================\n"
        return detailed
    }
    
    private func getMostCommonReason(for pattern: String) -> String {
        // In a real implementation, we'd track reasons per pattern
        // For now, return the most common overall reason
        return failureReasons.max { $0.value < $1.value }?.key ?? "unknown"
    }
    
    // MARK: - Export Functions
    
    func exportToFile() throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = formatter.string(from: Date())
        
        let fileName = "categorization_report_\(timestamp).txt"
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        let fullReport = generateVerboseReport()
        try fullReport.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return fileURL
    }
    
    private func generateVerboseReport() -> String {
        let previousLevel = logLevel
        logLevel = .verbose
        let report = generateReport()
        logLevel = previousLevel
        return report
    }
}

// MARK: - Diagnostic Log Level Manager

@MainActor
class DiagnosticLogManager {
    static let shared = DiagnosticLogManager()
    
    private(set) var currentLevel: CategorizationReport.LogLevel = .summary
    
    func setLogLevel(_ level: CategorizationReport.LogLevel) {
        currentLevel = level
        AppLogger.shared.info("📊 Diagnostic log level set to: \(level)")
    }
    
    func toggleLogLevel() {
        switch currentLevel {
        case .summary:
            currentLevel = .detailed
        case .detailed:
            currentLevel = .verbose
        case .verbose:
            currentLevel = .summary
        }
        AppLogger.shared.info("📊 Diagnostic log level toggled to: \(currentLevel)")
    }
}
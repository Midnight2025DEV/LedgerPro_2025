import Foundation

struct TestDataHelper {
    static let testCSVPath: String = {
        Bundle(for: LedgerProUITestsBase.self)
            .path(forResource: "test_transactions", ofType: "csv") ?? ""
    }()
    
    static let testPDFPath: String = {
        Bundle(for: LedgerProUITestsBase.self)
            .path(forResource: "test_statement", ofType: "pdf") ?? ""
    }()
    
    static func createTestCSVFile() -> String {
        let csvContent = """
        Date,Description,Amount,Category
        2024-01-01,STARBUCKS COFFEE #12345,-5.50,Food & Dining
        2024-01-02,SALARY DEPOSIT EMPLOYER,3000.00,Income
        2024-01-03,UBER TRIP DOWNTOWN,-25.00,Transportation
        2024-01-04,AMAZON.COM PURCHASE,-99.99,Shopping
        2024-01-05,WHOLE FOODS MARKET,-156.32,Groceries
        2024-01-06,NETFLIX.COM,-15.99,Entertainment
        2024-01-07,CHEVRON GAS STATION,-45.00,Transportation
        2024-01-08,TARGET STORE #1234,-87.43,Shopping
        2024-01-09,CAPITAL ONE PAYMENT,250.00,Credit Card Payment
        2024-01-10,PAYPAL TRANSFER,50.00,Transfers
        """
        
        let tempPath = NSTemporaryDirectory() + "test_transactions_\(UUID().uuidString).csv"
        do {
            try csvContent.write(toFile: tempPath, atomically: true, encoding: .utf8)
            return tempPath
        } catch {
            print("Failed to create test CSV: \(error)")
            return ""
        }
    }
    
    static func createLargeTestCSV(transactionCount: Int = 1000) -> String {
        var csvContent = "Date,Description,Amount,Category\n"
        
        let merchants = [
            "STARBUCKS", "AMAZON", "WALMART", "TARGET", "UBER",
            "LYFT", "NETFLIX", "SPOTIFY", "APPLE", "GOOGLE",
            "WHOLE FOODS", "TRADER JOES", "CHEVRON", "SHELL"
        ]
        
        let categories = [
            "Food & Dining", "Shopping", "Transportation", "Entertainment",
            "Groceries", "Utilities", "Healthcare", "Other"
        ]
        
        for i in 1...transactionCount {
            let date = "2024-01-\(String(format: "%02d", (i % 28) + 1))"
            let merchant = merchants.randomElement()!
            let amount = Double.random(in: -200...200)
            let category = categories.randomElement()!
            
            csvContent += "\(date),\(merchant) #\(i),\(amount),\(category)\n"
        }
        
        let tempPath = NSTemporaryDirectory() + "large_test_\(transactionCount)_\(UUID().uuidString).csv"
        do {
            try csvContent.write(toFile: tempPath, atomically: true, encoding: .utf8)
            return tempPath
        } catch {
            print("Failed to create large test CSV: \(error)")
            return ""
        }
    }
    
    static func cleanupTestFiles() {
        let fileManager = FileManager.default
        let tempDir = NSTemporaryDirectory()
        
        do {
            let files = try fileManager.contentsOfDirectory(atPath: tempDir)
            let testFiles = files.filter { $0.hasPrefix("test_transactions_") || $0.hasPrefix("large_test_") }
            
            for file in testFiles {
                let filePath = tempDir + file
                try fileManager.removeItem(atPath: filePath)
            }
        } catch {
            print("Failed to cleanup test files: \(error)")
        }
    }
}

// Extension to generate random elements
extension Array {
    func randomElement() -> Element? {
        guard !isEmpty else { return nil }
        let index = Int.random(in: 0..<count)
        return self[index]
    }
}

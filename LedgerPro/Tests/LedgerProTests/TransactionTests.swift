import XCTest
@testable import LedgerPro

final class TransactionTests: XCTestCase {
    
    // MARK: - Transaction Creation Tests
    
    func testBasicTransactionCreation() {
        let transaction = Transaction(
            date: "2024-01-15",
            description: "Amazon Purchase",
            amount: -49.99,
            category: "Shopping"
        )
        
        XCTAssertEqual(transaction.description, "Amazon Purchase")
        XCTAssertEqual(transaction.amount, -49.99)
        XCTAssertEqual(transaction.category, "Shopping")
        XCTAssertFalse(transaction.wasAutoCategorized ?? false)
        XCTAssertNotNil(transaction.id)
    }
    
    func testTransactionWithForexData() {
        var transaction = Transaction(
            date: "2024-01-15",
            description: "International Purchase",
            amount: -41.70,
            category: "Shopping"
        )
        
        // Set foreign currency data
        transaction.originalAmount = 750.00
        transaction.originalCurrency = "MXN"
        transaction.exchangeRate = 0.0556
        
        XCTAssertEqual(transaction.originalAmount, 750.00)
        XCTAssertEqual(transaction.originalCurrency, "MXN")
        XCTAssertEqual(transaction.exchangeRate, 0.0556)
        XCTAssertTrue(transaction.hasForex ?? false)
    }
    
    // MARK: - Foreign Currency Tests
    
    func testHasForexProperty() {
        var transaction = Transaction(
            date: "2024-01-15",
            description: "Test Transaction",
            amount: -100.0,
            category: "Test"
        )
        
        // Initially no forex
        XCTAssertFalse(transaction.hasForex ?? false)
        
        // Add forex data
        transaction.originalAmount = 1000.0
        transaction.originalCurrency = "EUR"
        transaction.exchangeRate = 1.1
        
        // Should now have forex
        XCTAssertTrue(transaction.hasForex ?? false)
        
        // Remove forex data
        transaction.originalAmount = nil
        transaction.originalCurrency = nil
        transaction.exchangeRate = nil
        
        // Should no longer have forex
        XCTAssertFalse(transaction.hasForex ?? false)
    }
    
    func testForexCalculationAccuracy() {
        let transaction = Transaction(
            date: "2024-01-15",
            description: "Forex Test",
            amount: -111.20,
            category: "Test",
            originalAmount: 100.0,
            originalCurrency: "EUR",
            exchangeRate: 1.112
        )
        
        // Verify the calculation: 100 EUR * 1.112 = 111.20 USD
        if let originalAmount = transaction.originalAmount,
           let exchangeRate = transaction.exchangeRate {
            let calculatedUSD = originalAmount * exchangeRate
            XCTAssertEqual(calculatedUSD, abs(transaction.amount), accuracy: 0.01)
        } else {
            XCTFail("Forex data should be present")
        }
    }
    
    // MARK: - Date Formatting Tests
    
    func testDateFormatting() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let testDate = dateFormatter.date(from: "2024-01-15")!
        
        let transaction = Transaction(
            date: "2024-01-15",
            description: "Date Test",
            amount: -50.0,
            category: "Test"
        )
        
        XCTAssertEqual(transaction.formattedDate, testDate)
        
        // Test formatted date string
        let formattedString = dateFormatter.string(from: transaction.formattedDate)
        XCTAssertEqual(formattedString, "2024-01-15")
    }
    
    // MARK: - Merchant Name Extraction Tests
    
    func testMerchantNameExtraction() {
        let transaction1 = Transaction(
            date: "2024-01-15",
            description: "AMAZON.COM*2K3L45 AMZN.COM/BILL WA",
            amount: -29.99,
            category: "Shopping"
        )
        
        // The display merchant name should extract clean merchant name
        XCTAssertTrue(transaction1.displayMerchantName.contains("AMAZON"))
        
        let transaction2 = Transaction(
            date: "2024-01-15",
            description: "STARBUCKS #1234 NEW YORK NY",
            amount: -5.95,
            category: "Food & Dining"
        )
        
        XCTAssertTrue(transaction2.displayMerchantName.contains("STARBUCKS"))
    }
    
    // MARK: - Amount Formatting Tests
    
    func testAmountFormatting() {
        let expenseTransaction = Transaction(
            date: "2024-01-15",
            description: "Expense",
            amount: -123.45,
            category: "Test"
        )
        
        let incomeTransaction = Transaction(
            date: "2024-01-15",
            description: "Income",
            amount: 1000.00,
            category: "Salary"
        )
        
        // Test that amounts maintain proper precision
        XCTAssertEqual(expenseTransaction.amount, -123.45)
        XCTAssertEqual(incomeTransaction.amount, 1000.00)
        
        // Test sign preservation
        XCTAssertTrue(expenseTransaction.amount < 0)
        XCTAssertTrue(incomeTransaction.amount > 0)
    }
    
    // MARK: - Categorization Tests
    
    func testAutoCategorization() {
        var transaction = Transaction(
            date: "2024-01-15",
            description: "Auto Categorized Transaction",
            amount: -50.0,
            category: "Shopping"
        )
        
        transaction.wasAutoCategorized = true
        transaction.confidence = 0.95
        
        XCTAssertTrue(transaction.wasAutoCategorized ?? false)
        XCTAssertEqual(transaction.confidence, 0.95)
    }
    
    func testCategoryChanges() {
        var transaction = Transaction(
            date: "2024-01-15",
            description: "Category Change Test",
            amount: -25.0,
            category: "Other"
        )
        
        // Change category
        transaction.category = "Food & Dining"
        XCTAssertEqual(transaction.category, "Food & Dining")
        
        // Test that wasAutoCategorized can be updated
        transaction.wasAutoCategorized = false
        XCTAssertFalse(transaction.wasAutoCategorized ?? false)
    }
    
    // MARK: - Duplicate Detection Tests
    
    func testTransactionEquality() {
        let date = Date()
        
        let transaction1 = Transaction(
            date: "2024-01-15",
            description: "Duplicate Test",
            amount: -50.0,
            category: "Test"
        )
        
        let transaction2 = Transaction(
            date: "2024-01-15",
            description: "Duplicate Test",
            amount: -50.0,
            category: "Test"
        )
        
        // Transactions with same content should be considered duplicates
        // Note: This assumes there's a duplicate detection method
        // We're testing that the core fields match
        XCTAssertEqual(transaction1.description, transaction2.description)
        XCTAssertEqual(transaction1.amount, transaction2.amount)
        XCTAssertEqual(transaction1.formattedDate, transaction2.formattedDate)
    }
    
    // MARK: - Edge Cases Tests
    
    func testZeroAmountTransaction() {
        let transaction = Transaction(
            date: "2024-01-15",
            description: "Zero Amount",
            amount: 0.0,
            category: "Test"
        )
        
        XCTAssertEqual(transaction.amount, 0.0)
        XCTAssertNotNil(transaction.id)
    }
    
    func testEmptyDescriptionHandling() {
        let transaction = Transaction(
            date: "2024-01-15",
            description: "",
            amount: -10.0,
            category: "Test"
        )
        
        XCTAssertEqual(transaction.description, "")
        // Should still create valid transaction
        XCTAssertNotNil(transaction.id)
    }
    
    func testLargeAmountHandling() {
        let transaction = Transaction(
            date: "2024-01-15",
            description: "Large Amount",
            amount: -999999.99,
            category: "Test"
        )
        
        XCTAssertEqual(transaction.amount, -999999.99)
    }
    
    // MARK: - Performance Tests
    
    func testTransactionCreationPerformance() {
        measure {
            for i in 0..<1000 {
                let _ = Transaction(
                    date: "2024-01-15",
                    description: "Performance Test \(i)",
                    amount: Double(i) * -1.0,
                    category: "Test"
                )
            }
        }
    }
}
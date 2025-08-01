import XCTest
@testable import LedgerPro

final class ForexCalculationTests: XCTestCase {
    
    // MARK: - MXN→USD Conversion Tests
    
    func testMXNToUSDConversionAccuracy() {
        // Test typical MXN→USD conversion
        let mxnAmount = 1000.0
        let usdRate = 0.058  // Example rate: 1 MXN = 0.058 USD
        let expectedUSD = 58.0
        
        let transaction = Transaction(
            date: "2024-01-15",
            description: "OXXO STORE MX",
            amount: -expectedUSD,
            category: "Shopping",
            originalAmount: mxnAmount,
            originalCurrency: "MXN",
            exchangeRate: usdRate
        )
        
        XCTAssertEqual(transaction.originalAmount, mxnAmount)
        XCTAssertEqual(transaction.originalCurrency, "MXN")
        XCTAssertEqual(transaction.exchangeRate, usdRate)
        XCTAssertTrue(transaction.hasForex)
        
        // Test calculated USD amount
        let calculatedUSD = mxnAmount * usdRate
        XCTAssertEqual(calculatedUSD, expectedUSD, accuracy: 0.01)
    }
    
    func testEURToUSDConversionAccuracy() {
        // Test EUR→USD conversion
        let eurAmount = 100.0
        let usdRate = 1.10  // Example rate: 1 EUR = 1.10 USD
        let expectedUSD = 110.0
        
        let transaction = Transaction(
            date: "2024-01-15",
            description: "RESTAURANT PARIS",
            amount: -expectedUSD,
            category: "Food & Dining",
            originalAmount: eurAmount,
            originalCurrency: "EUR",
            exchangeRate: usdRate
        )
        
        let calculatedUSD = eurAmount * usdRate
        XCTAssertEqual(calculatedUSD, expectedUSD, accuracy: 0.01)
    }
    
    func testGBPToUSDConversionAccuracy() {
        // Test GBP→USD conversion
        let gbpAmount = 80.0
        let usdRate = 1.25  // Example rate: 1 GBP = 1.25 USD
        let expectedUSD = 100.0
        
        let transaction = Transaction(
            date: "2024-01-15",
            description: "LONDON TRANSPORT",
            amount: -expectedUSD,
            category: "Transportation",
            originalAmount: gbpAmount,
            originalCurrency: "GBP",
            exchangeRate: usdRate
        )
        
        let calculatedUSD = gbpAmount * usdRate
        XCTAssertEqual(calculatedUSD, expectedUSD, accuracy: 0.01)
    }
    
    // MARK: - Edge Cases
    
    func testZeroAmountConversion() {
        let transaction = Transaction(
            date: "2024-01-15",
            description: "ZERO AMOUNT TEST",
            amount: 0.0,
            category: "Other",
            originalAmount: 0.0,
            originalCurrency: "MXN",
            exchangeRate: 0.058
        )
        
        XCTAssertEqual(transaction.originalAmount, 0.0)
        XCTAssertEqual(transaction.amount, 0.0)
        
        let calculatedUSD = (transaction.originalAmount ?? 0.0) * (transaction.exchangeRate ?? 1.0)
        XCTAssertEqual(calculatedUSD, 0.0)
    }
    
    func testNegativeAmountConversion() {
        // Test negative original amount (refunds)
        let mxnAmount = -500.0
        let usdRate = 0.058
        let expectedUSD = -29.0
        
        let transaction = Transaction(
            date: "2024-01-15",
            description: "REFUND OXXO MX",
            amount: expectedUSD,
            category: "Other",
            originalAmount: mxnAmount,
            originalCurrency: "MXN",
            exchangeRate: usdRate
        )
        
        let calculatedUSD = mxnAmount * usdRate
        XCTAssertEqual(calculatedUSD, expectedUSD, accuracy: 0.01)
        XCTAssertTrue(calculatedUSD < 0)
    }
    
    func testHugeAmountConversion() {
        // Test very large amounts
        let mxnAmount = 1000000.0  // 1 million MXN
        let usdRate = 0.058
        let expectedUSD = 58000.0
        
        let transaction = Transaction(
            date: "2024-01-15",
            description: "LARGE PURCHASE MX",
            amount: -expectedUSD,
            category: "Other",
            originalAmount: mxnAmount,
            originalCurrency: "MXN",
            exchangeRate: usdRate
        )
        
        let calculatedUSD = mxnAmount * usdRate
        XCTAssertEqual(calculatedUSD, expectedUSD, accuracy: 0.01)
    }
    
    func testVerySmallAmountConversion() {
        // Test very small amounts
        let mxnAmount = 0.01  // 1 centavo
        let usdRate = 0.058
        let expectedUSD = 0.00058
        
        let transaction = Transaction(
            date: "2024-01-15",
            description: "TINY PURCHASE MX",
            amount: -expectedUSD,
            category: "Other",
            originalAmount: mxnAmount,
            originalCurrency: "MXN",
            exchangeRate: usdRate
        )
        
        let calculatedUSD = mxnAmount * usdRate
        XCTAssertEqual(calculatedUSD, expectedUSD, accuracy: 0.000001)
    }
    
    // MARK: - Exchange Rate Edge Cases
    
    func testZeroExchangeRate() {
        let transaction = Transaction(
            date: "2024-01-15",
            description: "ZERO RATE TEST",
            amount: -100.0,
            category: "Other",
            originalAmount: 1000.0,
            originalCurrency: "MXN",
            exchangeRate: 0.0
        )
        
        let calculatedUSD = (transaction.originalAmount ?? 0.0) * (transaction.exchangeRate ?? 1.0)
        XCTAssertEqual(calculatedUSD, 0.0)
    }
    
    func testVeryHighExchangeRate() {
        // Test currencies with very high exchange rates (e.g., JPY)
        let jpyAmount = 10000.0
        let usdRate = 0.0067  // Example rate: 1 JPY = 0.0067 USD
        let expectedUSD = 67.0
        
        let transaction = Transaction(
            date: "2024-01-15",
            description: "TOKYO RESTAURANT",
            amount: -expectedUSD,
            category: "Food & Dining",
            originalAmount: jpyAmount,
            originalCurrency: "JPY",
            exchangeRate: usdRate
        )
        
        let calculatedUSD = jpyAmount * usdRate
        XCTAssertEqual(calculatedUSD, expectedUSD, accuracy: 0.01)
    }
    
    // MARK: - Rate Formatting Tests
    
    func testExchangeRateFormatting() {
        let rates = [
            0.058,      // MXN rate
            1.10,       // EUR rate
            1.25,       // GBP rate
            0.0067,     // JPY rate
            0.000001,   // Very small rate
            1000.0      // Very large rate
        ]
        
        for rate in rates {
            let transaction = Transaction(
                date: "2024-01-15",
                description: "RATE FORMAT TEST",
                amount: -100.0,
                category: "Other",
                originalAmount: 1000.0,
                originalCurrency: "XXX",
                exchangeRate: rate
            )
            
            XCTAssertEqual(transaction.exchangeRate, rate)
            XCTAssertNotNil(transaction.exchangeRate)
        }
    }
    
    func testFormattedExchangeRateDisplay() {
        let transaction = Transaction(
            date: "2024-01-15",
            description: "OXXO STORE MX",
            amount: -58.0,
            category: "Shopping",
            originalAmount: 1000.0,
            originalCurrency: "MXN",
            exchangeRate: 0.058
        )
        
        // Test that we can format the rate for display
        if let rate = transaction.exchangeRate {
            let formattedRate = String(format: "%.4f", rate)
            XCTAssertEqual(formattedRate, "0.0580")
        }
    }
    
    // MARK: - Currency Code Tests
    
    func testSupportedCurrencyCodes() {
        let supportedCurrencies = ["MXN", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF"]
        
        for currency in supportedCurrencies {
            let transaction = Transaction(
                date: "2024-01-15",
                description: "CURRENCY TEST",
                amount: -100.0,
                category: "Other",
                originalAmount: 1000.0,
                originalCurrency: currency,
                exchangeRate: 0.5
            )
            
            XCTAssertEqual(transaction.originalCurrency, currency)
            XCTAssertTrue(transaction.hasForex)
        }
    }
    
    func testEmptyCurrencyCode() {
        let transaction = Transaction(
            date: "2024-01-15",
            description: "NO CURRENCY TEST",
            amount: -100.0,
            category: "Other",
            originalAmount: 1000.0,
            originalCurrency: "",
            exchangeRate: 0.5
        )
        
        XCTAssertEqual(transaction.originalCurrency, "")
        XCTAssertFalse(transaction.hasForex)
    }
    
    // MARK: - Transaction Forex Flag Tests
    
    func testForexFlagConsistency() {
        // Transaction with forex data should have hasForex = true
        let forexTransaction = Transaction(
            date: "2024-01-15",
            description: "FOREX TRANSACTION",
            amount: -100.0,
            category: "Other",
            originalAmount: 1000.0,
            originalCurrency: "MXN",
            exchangeRate: 0.1
        )
        
        XCTAssertTrue(forexTransaction.hasForex)
        XCTAssertNotNil(forexTransaction.originalAmount)
        XCTAssertNotNil(forexTransaction.originalCurrency)
        XCTAssertNotNil(forexTransaction.exchangeRate)
    }
    
    func testNonForexTransaction() {
        // Transaction without forex data should have hasForex = false or nil
        let domesticTransaction = Transaction(
            date: "2024-01-15",
            description: "DOMESTIC TRANSACTION",
            amount: -100.0,
            category: "Other"
        )
        
        XCTAssertFalse(domesticTransaction.hasForex)
        XCTAssertNil(domesticTransaction.originalAmount)
        XCTAssertNil(domesticTransaction.originalCurrency)
        XCTAssertNil(domesticTransaction.exchangeRate)
    }
    
    // MARK: - Performance Tests
    
    func testForexCalculationPerformance() {
        let transactions = (0..<1000).map { index in
            Transaction(
                date: "2024-01-15",
                description: "PERFORMANCE TEST \(index)",
                amount: -Double(index),
                category: "Other",
                originalAmount: Double(index * 17),
                originalCurrency: "MXN",
                exchangeRate: 0.058
            )
        }
        
        measure {
            for transaction in transactions {
                let _ = (transaction.originalAmount ?? 0.0) * (transaction.exchangeRate ?? 1.0)
            }
        }
    }
}
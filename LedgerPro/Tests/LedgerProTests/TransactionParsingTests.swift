import XCTest
@testable import LedgerPro

final class TransactionParsingTests: XCTestCase {
    
    // MARK: - Date Parsing Tests
    
    func testDateParsingVariants() {
        // Test ISO8601 format
        let iso8601Date = "2024-01-15"
        let parsedISO = parseDate(from: iso8601Date)
        XCTAssertNotNil(parsedISO)
        
        // Test US format MM/DD/YYYY
        let usDate = "01/15/2024"
        let parsedUS = parseDate(from: usDate, format: "MM/dd/yyyy")
        XCTAssertNotNil(parsedUS)
        
        // Test EU format DD/MM/YYYY
        let euDate = "15/01/2024"
        let parsedEU = parseDate(from: euDate, format: "dd/MM/yyyy")
        XCTAssertNotNil(parsedEU)
        
        // Test with time component
        let dateTime = "2024-01-15 14:30:00"
        let parsedDateTime = parseDate(from: dateTime, format: "yyyy-MM-dd HH:mm:ss")
        XCTAssertNotNil(parsedDateTime)
        
        // Test abbreviated month format
        let abbrevDate = "15-Jan-2024"
        let parsedAbbrev = parseDate(from: abbrevDate, format: "dd-MMM-yyyy")
        XCTAssertNotNil(parsedAbbrev)
        
        // Test full month format
        let fullMonthDate = "January 15, 2024"
        let parsedFullMonth = parseDate(from: fullMonthDate, format: "MMMM dd, yyyy")
        XCTAssertNotNil(parsedFullMonth)
    }
    
    func testDateParsingEdgeCases() {
        // Test empty string
        let emptyDate = ""
        let parsedEmpty = parseDate(from: emptyDate)
        XCTAssertNil(parsedEmpty)
        
        // Test invalid format
        let invalidDate = "not-a-date"
        let parsedInvalid = parseDate(from: invalidDate)
        XCTAssertNil(parsedInvalid)
        
        // Test leap year date
        let leapDate = "2024-02-29"
        let parsedLeap = parseDate(from: leapDate)
        XCTAssertNotNil(parsedLeap)
        
        // Test invalid leap year date
        let invalidLeapDate = "2023-02-29"
        let parsedInvalidLeap = parseDate(from: invalidLeapDate)
        XCTAssertNil(parsedInvalidLeap)
    }
    
    // MARK: - Amount Parsing Tests
    
    func testAmountParsingWithCommas() {
        // Test standard comma-separated thousands
        let amount1 = "1,234.56"
        XCTAssertEqual(parseAmount(from: amount1), 1234.56, accuracy: 0.01)
        
        // Test multiple commas
        let amount2 = "1,234,567.89"
        XCTAssertEqual(parseAmount(from: amount2), 1234567.89, accuracy: 0.01)
        
        // Test without decimal
        let amount3 = "1,000"
        XCTAssertEqual(parseAmount(from: amount3), 1000.0, accuracy: 0.01)
        
        // Test no commas
        let amount4 = "500.25"
        XCTAssertEqual(parseAmount(from: amount4), 500.25, accuracy: 0.01)
    }
    
    func testAmountParsingWithDecimals() {
        // Test standard two decimal places
        let amount1 = "123.45"
        XCTAssertEqual(parseAmount(from: amount1), 123.45, accuracy: 0.01)
        
        // Test one decimal place
        let amount2 = "100.5"
        XCTAssertEqual(parseAmount(from: amount2), 100.5, accuracy: 0.01)
        
        // Test many decimal places (should handle gracefully)
        let amount3 = "99.999999"
        XCTAssertEqual(parseAmount(from: amount3), 99.999999, accuracy: 0.000001)
        
        // Test no decimal
        let amount4 = "1000"
        XCTAssertEqual(parseAmount(from: amount4), 1000.0, accuracy: 0.01)
    }
    
    func testAmountParsingWithCurrencySymbols() {
        // Test USD symbol
        let usdAmount = "$1,234.56"
        XCTAssertEqual(parseAmount(from: usdAmount), 1234.56, accuracy: 0.01)
        
        // Test MXN symbol
        let mxnAmount = "MXN 2,500.00"
        XCTAssertEqual(parseAmount(from: mxnAmount), 2500.00, accuracy: 0.01)
        
        // Test currency code prefix
        let prefixAmount = "USD 999.99"
        XCTAssertEqual(parseAmount(from: prefixAmount), 999.99, accuracy: 0.01)
        
        // Test currency code suffix
        let suffixAmount = "500.00 USD"
        XCTAssertEqual(parseAmount(from: suffixAmount), 500.00, accuracy: 0.01)
    }
    
    func testAmountParsingEdgeCases() {
        // Test zero
        let zero = "0.00"
        XCTAssertEqual(parseAmount(from: zero), 0.0, accuracy: 0.01)
        
        // Test negative amounts
        let negative1 = "-100.50"
        XCTAssertEqual(parseAmount(from: negative1), -100.50, accuracy: 0.01)
        
        let negative2 = "($1,234.56)"  // Accounting format
        XCTAssertEqual(parseAmount(from: negative2), -1234.56, accuracy: 0.01)
        
        // Test very large amounts
        let largeAmount = "999,999,999.99"
        XCTAssertEqual(parseAmount(from: largeAmount), 999999999.99, accuracy: 0.01)
        
        // Test empty string
        let empty = ""
        XCTAssertEqual(parseAmount(from: empty), 0.0, accuracy: 0.01)
        
        // Test invalid format
        let invalid = "not-a-number"
        XCTAssertEqual(parseAmount(from: invalid), 0.0, accuracy: 0.01)
    }
    
    // MARK: - Description Cleaning Tests
    
    func testDescriptionCleaning() {
        // Test removing extra spaces
        let desc1 = "PURCHASE   AT   STORE    NAME"
        let cleaned1 = cleanDescription(desc1)
        XCTAssertEqual(cleaned1, "PURCHASE AT STORE NAME")
        
        // Test trimming whitespace
        let desc2 = "  COFFEE SHOP  "
        let cleaned2 = cleanDescription(desc2)
        XCTAssertEqual(cleaned2, "COFFEE SHOP")
        
        // Test removing special characters
        let desc3 = "STORE*NAME#123"
        let cleaned3 = cleanDescription(desc3)
        XCTAssertEqual(cleaned3, "STORE NAME 123")
        
        // Test preserving important punctuation
        let desc4 = "SMITH'S GROCERY - MAIN ST."
        let cleaned4 = cleanDescription(desc4)
        XCTAssertEqual(cleaned4, "SMITH'S GROCERY - MAIN ST.")
    }
    
    func testDescriptionCleaningWithBankCodes() {
        // Test removing transaction codes
        let desc1 = "POS 12345 MERCHANT NAME"
        let cleaned1 = cleanDescription(desc1)
        XCTAssertEqual(cleaned1, "MERCHANT NAME")
        
        // Test removing reference numbers
        let desc2 = "REF#98765 PAYMENT TO VENDOR"
        let cleaned2 = cleanDescription(desc2)
        XCTAssertEqual(cleaned2, "PAYMENT TO VENDOR")
        
        // Test removing dates from descriptions
        let desc3 = "01/15/24 PURCHASE AT STORE"
        let cleaned3 = cleanDescription(desc3)
        XCTAssertEqual(cleaned3, "PURCHASE AT STORE")
        
        // Test removing transaction IDs
        let desc4 = "TXN-ABC123XYZ COFFEE PURCHASE"
        let cleaned4 = cleanDescription(desc4)
        XCTAssertEqual(cleaned4, "COFFEE PURCHASE")
    }
    
    func testDescriptionCleaningEdgeCases() {
        // Test empty string
        let empty = ""
        let cleanedEmpty = cleanDescription(empty)
        XCTAssertEqual(cleanedEmpty, "")
        
        // Test only whitespace
        let whitespace = "   "
        let cleanedWhitespace = cleanDescription(whitespace)
        XCTAssertEqual(cleanedWhitespace, "")
        
        // Test very long description
        let longDesc = String(repeating: "WORD ", count: 50)
        let cleanedLong = cleanDescription(longDesc)
        XCTAssertTrue(cleanedLong.count <= 255) // Assuming max length
        
        // Test mixed case preservation
        let mixedCase = "McDonald's Restaurant"
        let cleanedMixed = cleanDescription(mixedCase)
        XCTAssertEqual(cleanedMixed, "McDonald's Restaurant")
    }
    
    // MARK: - Helper Functions
    
    private func parseDate(from string: String, format: String = "yyyy-MM-dd") -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: string)
    }
    
    private func parseAmount(from string: String) -> Double {
        // Remove currency symbols and whitespace
        var cleanedString = string
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "MXN", with: "")
            .replacingOccurrences(of: "USD", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle accounting format negative numbers
        if cleanedString.hasPrefix("(") && cleanedString.hasSuffix(")") {
            cleanedString = "-" + cleanedString
                .replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: ")", with: "")
        }
        
        // Remove commas
        cleanedString = cleanedString.replacingOccurrences(of: ",", with: "")
        
        // Parse to double
        return Double(cleanedString) ?? 0.0
    }
    
    private func cleanDescription(_ description: String) -> String {
        var cleaned = description
        
        // Remove extra spaces
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Remove common bank codes and prefixes
        let prefixPatterns = [
            "POS \\d+ ",
            "REF#\\d+ ",
            "TXN-[A-Z0-9]+ ",
            "\\d{2}/\\d{2}/\\d{2,4} "
        ]
        
        for pattern in prefixPatterns {
            cleaned = cleaned.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }
        
        // Remove special characters except essential punctuation
        let allowedCharacters = CharacterSet.alphanumerics
            .union(CharacterSet.whitespaces)
            .union(CharacterSet(charactersIn: "'-.,"))
        
        cleaned = cleaned.components(separatedBy: allowedCharacters.inverted).joined(separator: " ")
        
        // Clean up extra spaces again and trim
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Limit length
        if cleaned.count > 255 {
            cleaned = String(cleaned.prefix(255))
        }
        
        return cleaned
    }
}
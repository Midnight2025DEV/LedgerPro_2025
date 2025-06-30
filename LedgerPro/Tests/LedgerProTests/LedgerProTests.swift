import XCTest
@testable import LedgerPro

final class LedgerProTests: XCTestCase {
    
    func testTransactionInitialization() {
        let transaction = Transaction(
            id: "test-123",
            date: "2023-12-01",
            description: "Test Transaction",
            amount: 100.0,
            category: "Testing",
            accountId: "test-account"
        )
        
        XCTAssertEqual(transaction.id, "test-123")
        XCTAssertEqual(transaction.description, "Test Transaction")
        XCTAssertEqual(transaction.amount, 100.0)
        XCTAssertEqual(transaction.category, "Testing")
        XCTAssertEqual(transaction.accountId, "test-account")
    }
    
    func testTransactionAmountFormatting() {
        let transaction = Transaction(
            date: "2023-12-01",
            description: "Test Transaction",
            amount: 1234.56,
            category: "Testing"
        )
        
        let formattedAmount = transaction.formattedAmount
        XCTAssertTrue(formattedAmount.contains("1,234.56"))
    }
    
    func testTransactionIncomeExpenseDetection() {
        let income = Transaction(
            date: "2023-12-01",
            description: "Salary",
            amount: 1000.0,
            category: "Income"
        )
        
        let expense = Transaction(
            date: "2023-12-01", 
            description: "Groceries",
            amount: -50.0,
            category: "Food"
        )
        
        XCTAssertTrue(income.isIncome)
        XCTAssertFalse(income.isExpense)
        XCTAssertTrue(expense.isExpense)
        XCTAssertFalse(expense.isIncome)
    }
    
    @MainActor
    func testAPIServiceInitialization() {
        let apiService = APIService()
        XCTAssertFalse(apiService.isHealthy)
        XCTAssertFalse(apiService.isUploading)
        XCTAssertEqual(apiService.uploadProgress, 0.0)
    }
}
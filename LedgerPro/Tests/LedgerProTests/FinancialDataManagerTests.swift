import XCTest
@testable import LedgerPro

@MainActor
final class FinancialDataManagerTests: XCTestCase {
    var sut: FinancialDataManager!
    var testTransactions: [Transaction]!
    var testBankAccount: BankAccount!
    
    override func setUp() async throws {
        try await super.setUp()
        sut = FinancialDataManager()
        
        // Clear any existing data
        sut.clearAllData()
        
        // Setup test data
        testBankAccount = BankAccount(
            id: "test_account_1234",
            name: "Test Checking Account",
            institution: "Test Bank",
            accountType: .checking,
            lastFourDigits: "1234",
            currency: "USD",
            isActive: true,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        
        // Add the test bank account to the manager so it can be found during addTransactions
        sut.bankAccounts.append(testBankAccount)
        
        testTransactions = [
            Transaction(
                id: "test_1",
                date: "2024-01-01",
                description: "STARBUCKS COFFEE SHOP",
                amount: -5.50,
                category: "Food & Dining",
                confidence: 0.9,
                jobId: "test_job_1",
                accountId: testBankAccount.id
            ),
            Transaction(
                id: "test_2",
                date: "2024-01-02",
                description: "MONTHLY SALARY DEPOSIT",
                amount: 3000.00,
                category: "Income",
                confidence: 1.0,
                jobId: "test_job_1",
                accountId: testBankAccount.id
            ),
            Transaction(
                id: "test_3",
                date: "2024-01-03",
                description: "UBER RIDE DOWNTOWN",
                amount: -25.00,
                category: "Transportation",
                confidence: 0.85,
                jobId: "test_job_1",
                accountId: testBankAccount.id
            )
        ]
    }
    
    override func tearDown() async throws {
        sut.clearAllData()
        sut = nil
        testTransactions = nil
        testBankAccount = nil
        try await super.tearDown()
    }
    
    // MARK: - Transaction Management Tests
    
    func testAddTransactions_updatesTransactionsList() async {
        // Given
        let initialCount = sut.transactions.count
        
        // When
        sut.addTransactions(testTransactions, jobId: "test_job_1", filename: "test_statement.csv")
        
        // Then
        XCTAssertEqual(sut.transactions.count, initialCount + testTransactions.count)
        XCTAssertEqual(sut.transactions.last?.description, "UBER RIDE DOWNTOWN")
    }
    
    func testAddTransactions_preventsDuplicateJobs() async {
        // Given
        sut.addTransactions(testTransactions, jobId: "test_job_1", filename: "test_statement.csv")
        let countAfterFirst = sut.transactions.count
        
        // When - Add same job ID again
        sut.addTransactions(testTransactions, jobId: "test_job_1", filename: "test_statement_duplicate.csv")
        
        // Then - Count should not increase
        XCTAssertEqual(sut.transactions.count, countAfterFirst)
    }
    
    func testUpdateTransactionCategory_persistsChange() async {
        // Given
        sut.addTransactions(testTransactions, jobId: "test_job_1", filename: "test_statement.csv")
        let transaction = sut.transactions.first!
        let newCategory = "Groceries"
        
        // When
        sut.updateTransactionCategory(transactionId: transaction.id, newCategory: newCategory)
        
        // Then
        let updated = sut.transactions.first { $0.id == transaction.id }
        XCTAssertEqual(updated?.category, newCategory)
    }
    
    func testRemoveDuplicates_cleansTransactionsList() async {
        // Given - Add duplicate transactions
        let duplicateTransaction = Transaction(
            id: "duplicate_1",
            date: "2024-01-01",
            description: "STARBUCKS COFFEE SHOP",
            amount: -5.50,
            category: "Food & Dining"
        )
        
        sut.addTransactions(testTransactions, jobId: "test_job_1", filename: "test_statement.csv")
        sut.transactions.append(duplicateTransaction)
        let countWithDuplicate = sut.transactions.count
        
        // When
        sut.removeDuplicates()
        
        // Then
        XCTAssertLessThan(sut.transactions.count, countWithDuplicate)
    }
    
    // MARK: - Summary Calculation Tests
    
    func testCalculateSummary_computesCorrectTotals() async {
        // Given
        sut.addTransactions(testTransactions, jobId: "test_job_1", filename: "test_statement.csv")
        
        // When
        let summary = sut.summary
        
        // Then
        XCTAssertEqual(summary.totalIncome, 3000.00, accuracy: 0.01)
        XCTAssertEqual(summary.totalExpenses, 30.50, accuracy: 0.01) // 5.50 + 25.00
        XCTAssertEqual(summary.netSavings, 2969.50, accuracy: 0.01)
        XCTAssertEqual(summary.transactionCount, testTransactions.count)
    }
    
    func testGetTransactionsForAccount_filtersCorrectly() async {
        // Given
        let anotherAccount = "different_account"
        let otherTransaction = Transaction(
            date: "2024-01-04",
            description: "OTHER ACCOUNT TRANSACTION",
            amount: -100.00,
            category: "Other",
            accountId: anotherAccount
        )
        
        sut.addTransactions(testTransactions, jobId: "test_job_1", filename: "test_statement.csv")
        sut.transactions.append(otherTransaction)
        
        // When
        let accountTransactions = sut.getTransactions(for: testBankAccount.id)
        
        // Then
        XCTAssertEqual(accountTransactions.count, testTransactions.count)
        XCTAssertTrue(accountTransactions.allSatisfy { $0.accountId == testBankAccount.id })
    }
    
    func testGetSummaryForAccount_calculatesCorrectly() async {
        // Given
        sut.addTransactions(testTransactions, jobId: "test_job_1", filename: "test_statement.csv")
        
        // When
        let accountSummary = sut.getSummary(for: testBankAccount.id)
        
        // Then
        XCTAssertEqual(accountSummary.totalIncome, 3000.00, accuracy: 0.01)
        XCTAssertEqual(accountSummary.totalExpenses, 30.50, accuracy: 0.01)
        XCTAssertEqual(accountSummary.transactionCount, testTransactions.count)
    }
    
    // MARK: - Bank Account Detection Tests
    
    func testDetectBankAccountFromFilename_capitalOne() async {
        // Given - Clear existing accounts to test filename detection
        sut.bankAccounts.removeAll()
        
        let capitalOneTransactions = [
            Transaction(
                date: "2024-01-01",
                description: "TEST TRANSACTION",
                amount: -10.00,
                category: "Test"
            )
        ]
        
        // When
        sut.addTransactions(capitalOneTransactions, jobId: "capital_one_job", filename: "Capital_One_Credit_1234.csv")
        
        // Then
        XCTAssertFalse(sut.bankAccounts.isEmpty)
        let account = sut.bankAccounts.first!
        XCTAssertEqual(account.institution, "Capital One")
        XCTAssertEqual(account.accountType, .credit)
        XCTAssertEqual(account.lastFourDigits, "1234")
    }
    
    func testDetectBankAccountFromFilename_chase() async {
        // Given - Clear existing accounts to test filename detection
        sut.bankAccounts.removeAll()
        
        let chaseTransactions = [
            Transaction(
                date: "2024-01-01",
                description: "TEST TRANSACTION",
                amount: -10.00,
                category: "Test"
            )
        ]
        
        // When
        sut.addTransactions(chaseTransactions, jobId: "chase_job", filename: "Chase_Checking_5678.csv")
        
        // Then
        let account = sut.bankAccounts.first!
        XCTAssertEqual(account.institution, "Chase Bank")
        XCTAssertEqual(account.accountType, .checking)
        XCTAssertEqual(account.lastFourDigits, "5678")
    }
    
    // MARK: - Data Persistence Tests
    
    func testClearAllData_removesAllData() async {
        // Given
        sut.addTransactions(testTransactions, jobId: "test_job_1", filename: "test_statement.csv")
        XCTAssertFalse(sut.transactions.isEmpty)
        XCTAssertFalse(sut.bankAccounts.isEmpty)
        
        // When
        sut.clearAllData()
        
        // Then
        XCTAssertTrue(sut.transactions.isEmpty)
        XCTAssertTrue(sut.bankAccounts.isEmpty)
        XCTAssertTrue(sut.uploadedStatements.isEmpty)
        XCTAssertEqual(sut.summary.transactionCount, 0)
    }
    
    func testLoadStoredData_handlesEmptyData() async {
        // Given - Fresh manager with no stored data
        let newManager = FinancialDataManager()
        
        // When - Load is called automatically in init
        // Then - Should not crash and have empty data
        XCTAssertTrue(newManager.transactions.isEmpty)
        XCTAssertTrue(newManager.bankAccounts.isEmpty)
        XCTAssertFalse(newManager.isLoading)
    }
    
    // MARK: - Foreign Currency Tests
    
    func testAddTransactions_withForexData_preservesForexFields() async {
        // Given
        let forexTransaction = Transaction(
            date: "2024-01-01",
            description: "LONDON HOTEL EUR",
            amount: -120.50,
            category: "Travel",
            originalAmount: -100.00,
            originalCurrency: "EUR",
            exchangeRate: 1.205,
            hasForex: true
        )
        
        // When
        sut.addTransactions([forexTransaction], jobId: "forex_job", filename: "capital_one_travel.csv")
        
        // Then
        let storedTransaction = sut.transactions.first!
        XCTAssertEqual(storedTransaction.originalAmount, -100.00)
        XCTAssertEqual(storedTransaction.originalCurrency, "EUR")
        XCTAssertEqual(storedTransaction.exchangeRate, 1.205)
        XCTAssertEqual(storedTransaction.hasForex, true)
    }
    
    // MARK: - Error Handling Tests
    
    func testAddTransactions_withEmptyArray_handlesGracefully() async {
        // Given
        let emptyTransactions: [Transaction] = []
        let initialCount = sut.transactions.count
        
        // When
        sut.addTransactions(emptyTransactions, jobId: "empty_job", filename: "empty.csv")
        
        // Then - Should not crash
        XCTAssertEqual(sut.transactions.count, initialCount)
    }
    
    func testUpdateTransactionCategory_withInvalidId_handlesGracefully() async {
        // Given
        let invalidId = "non_existent_transaction"
        let initialTransactions = sut.transactions
        
        // When
        sut.updateTransactionCategory(transactionId: invalidId, newCategory: "New Category")
        
        // Then - Should not crash or modify data
        XCTAssertEqual(sut.transactions.count, initialTransactions.count)
    }
    
    func testGetAccount_withNilId_returnsNil() async {
        // Given/When
        let result = sut.getAccount(for: nil)
        
        // Then
        XCTAssertNil(result)
    }
    
    func testGetAccount_withInvalidId_returnsNil() async {
        // Given
        sut.addTransactions(testTransactions, jobId: "test_job", filename: "test.csv")
        
        // When
        let result = sut.getAccount(for: "invalid_account_id")
        
        // Then
        XCTAssertNil(result)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteWorkflow_importCategorizeClearData() async {
        // Given - Start with empty state
        XCTAssertTrue(sut.transactions.isEmpty)
        
        // When - Import transactions
        sut.addTransactions(testTransactions, jobId: "workflow_test", filename: "test_statement.csv")
        
        // Then - Verify import
        XCTAssertEqual(sut.transactions.count, testTransactions.count)
        XCTAssertFalse(sut.bankAccounts.isEmpty)
        XCTAssertFalse(sut.uploadedStatements.isEmpty)
        
        // When - Update category
        let firstTransaction = sut.transactions.first!
        sut.updateTransactionCategory(transactionId: firstTransaction.id, newCategory: "Updated Category")
        
        // Then - Verify update
        let updatedTransaction = sut.transactions.first { $0.id == firstTransaction.id }
        XCTAssertEqual(updatedTransaction?.category, "Updated Category")
        
        // When - Clear all data
        sut.clearAllData()
        
        // Then - Verify clean state
        XCTAssertTrue(sut.transactions.isEmpty)
        XCTAssertTrue(sut.bankAccounts.isEmpty)
        XCTAssertTrue(sut.uploadedStatements.isEmpty)
    }
    
    // MARK: - Performance Tests
    
    func testLargeDatasetPerformance_1000Transactions() async {
        // Measure performance with 1000 transactions
        let largeDataset = (0..<1000).map { index in
            Transaction(
                date: "2024-01-01",
                description: "Transaction \(index)",
                amount: Double.random(in: -500...500),
                category: "Test Category",
                accountId: testBankAccount.id
            )
        }
        
        let startTime = Date()
        sut.addTransactions(largeDataset, jobId: "performance_test", filename: "large_dataset.csv")
        let duration = Date().timeIntervalSince(startTime)
        
        XCTAssertLessThan(duration, 2.0, "Adding 1000 transactions should take less than 2 seconds")
        XCTAssertEqual(sut.transactions.count, 1000)
        
        // Test summary calculation performance
        let summaryStartTime = Date()
        let summary = sut.summary
        let summaryDuration = Date().timeIntervalSince(summaryStartTime)
        
        XCTAssertLessThan(summaryDuration, 0.1, "Summary calculation should take less than 100ms")
        XCTAssertEqual(summary.transactionCount, 1000)
    }
    
    func testPerformance_duplicateDetection() async {
        // Test duplicate detection performance
        let baseTransactions = testTransactions!
        
        // Add original transactions
        sut.addTransactions(baseTransactions, jobId: "original_job", filename: "original.csv")
        
        // Create duplicates with slight variations
        let duplicateTransactions = baseTransactions.map { transaction in
            Transaction(
                date: transaction.date,
                description: transaction.description,
                amount: transaction.amount,
                category: transaction.category,
                accountId: transaction.accountId
            )
        }
        
        let startTime = Date()
        sut.addTransactions(duplicateTransactions, jobId: "duplicate_job", filename: "duplicate.csv")
        sut.removeDuplicates()
        let duration = Date().timeIntervalSince(startTime)
        
        XCTAssertLessThan(duration, 1.0, "Duplicate detection should be fast")
        XCTAssertEqual(sut.transactions.count, baseTransactions.count) // Should remain same count
    }
    
    // MARK: - Demo Data Tests
    
    func testLoadDemoData_createsExpectedData() async {
        // Given - Empty state
        XCTAssertTrue(sut.transactions.isEmpty)
        
        // When
        sut.loadDemoData()
        
        // Then
        XCTAssertFalse(sut.transactions.isEmpty)
        XCTAssertTrue(sut.transactions.contains { $0.description.contains("Whole Foods") })
        XCTAssertTrue(sut.transactions.contains { $0.description.contains("Salary") })
        XCTAssertTrue(sut.transactions.contains { $0.description.contains("Starbucks") })
    }
}
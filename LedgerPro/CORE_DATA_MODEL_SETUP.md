# Core Data Model Setup Instructions

## Overview
This document provides instructions for creating the Core Data model file (LedgerPro.xcdatamodeld) that supports the Core Data migration implementation.

## Creating the Core Data Model File

### 1. Add Core Data Model File
In Xcode, add a new Core Data Model file:
1. Right-click on `Sources/LedgerPro/`
2. Select "New File..."
3. Choose "Core Data" → "Data Model"
4. Name it "LedgerPro" (this will create LedgerPro.xcdatamodeld)

### 2. Create Entities

#### CDTransaction Entity
**Attributes:**
- `id` (String, required)
- `date` (String, required)
- `transactionDescription` (String, required) - Note: 'description' is reserved
- `amount` (Double, required)
- `category` (String, required)
- `confidence` (Double, default: 0.0)
- `jobId` (String, optional)
- `rawDataJSON` (String, optional)
- `originalAmount` (Double, default: 0.0)
- `originalCurrency` (String, optional)
- `exchangeRate` (Double, default: 0.0)
- `wasAutoCategorized` (Boolean, default: NO)
- `categorizationMethod` (String, optional)
- `createdAt` (Date, required)
- `updatedAt` (Date, required)

**Relationships:**
- `account` (To One → CDAccount, optional, delete rule: Nullify)
- `statement` (To One → CDUploadedStatement, optional, delete rule: Nullify)

**Configurations:**
- Class: CDTransaction
- Codegen: Manual/None (we have custom classes)

#### CDAccount Entity
**Attributes:**
- `id` (String, required)
- `name` (String, required)
- `institution` (String, required)
- `accountTypeRaw` (String, required, default: "checking")
- `lastFourDigits` (String, optional)
- `currency` (String, required, default: "USD")
- `isActive` (Boolean, required, default: YES)
- `createdAt` (Date, required)
- `updatedAt` (Date, required)

**Relationships:**
- `transactions` (To Many → CDTransaction, delete rule: Cascade)
- `statements` (To Many → CDUploadedStatement, delete rule: Cascade)

**Configurations:**
- Class: CDAccount
- Codegen: Manual/None

#### CDUploadedStatement Entity
**Attributes:**
- `id` (String, required)
- `jobId` (String, required)
- `filename` (String, required)
- `uploadDate` (Date, required)
- `transactionCount` (Integer 32, required, default: 0)
- `totalIncome` (Double, required, default: 0.0)
- `totalExpenses` (Double, required, default: 0.0)
- `netAmount` (Double, required, default: 0.0)
- `createdAt` (Date, required)
- `updatedAt` (Date, required)

**Relationships:**
- `account` (To One → CDAccount, optional, delete rule: Nullify)
- `transactions` (To Many → CDTransaction, delete rule: Cascade)

**Configurations:**
- Class: CDUploadedStatement
- Codegen: Manual/None

### 3. Configure Indexes (Performance Optimization)

#### CDTransaction Indexes
1. Compound Index: `account.id + date` (for account transaction queries)
2. Single Index: `category` (for category filtering)
3. Single Index: `date` (for date range queries)
4. Single Index: `id` (for lookups)

#### CDAccount Indexes
1. Single Index: `id` (for lookups)
2. Single Index: `institution` (for institution queries)
3. Compound Index: `isActive + institution` (for active account queries)

#### CDUploadedStatement Indexes
1. Single Index: `id` (for lookups)
2. Single Index: `jobId` (for job-based queries)
3. Compound Index: `account.id + uploadDate` (for account statement queries)

### 4. Configuration Settings

#### Entity Inspector Settings
For each entity:
- **Abstract Entity**: NO
- **Used with Core Data**: YES
- **Codegen**: Manual/None (since we have custom classes)

#### Attribute Inspector Settings
For string attributes that are required:
- **Optional**: NO
- **Default Value**: (set appropriate defaults)

For relationship attributes:
- **Delete Rule**: 
  - CDAccount → CDTransaction: Cascade
  - CDAccount → CDUploadedStatement: Cascade
  - CDTransaction → CDAccount: Nullify
  - CDUploadedStatement → CDAccount: Nullify

### 5. Validation Rules

#### CDTransaction Validations
- `id`: Minimum length = 1
- `date`: Minimum length = 8 (YYYY-MM-DD format)
- `transactionDescription`: Minimum length = 1
- `category`: Minimum length = 1

#### CDAccount Validations
- `id`: Minimum length = 1
- `name`: Minimum length = 1
- `institution`: Minimum length = 1
- `accountTypeRaw`: Must be one of: "checking", "savings", "credit", "investment", "loan"

#### CDUploadedStatement Validations
- `id`: Minimum length = 1
- `jobId`: Minimum length = 1
- `filename`: Minimum length = 1
- `transactionCount`: Minimum value = 0

## Migration Strategy

### Version Control
1. Start with Version 1.0 of the data model
2. For future schema changes, create new model versions
3. Use lightweight migration when possible
4. Implement heavyweight migration for complex changes

### Performance Considerations
1. Enable WAL mode (configured in CoreDataManager)
2. Use batch operations for large datasets
3. Implement proper indexing
4. Use background contexts for heavy operations

## Testing the Model

### Model Validation
1. Build the project to ensure no compilation errors
2. Run Core Data model validation in Xcode
3. Test entity creation and relationships
4. Verify index performance with large datasets

### Migration Testing
1. Create test data in UserDefaults format
2. Run migration service
3. Verify data integrity
4. Test performance with large datasets

## Troubleshooting

### Common Issues
1. **Entity not found**: Ensure entity names match class names exactly
2. **Relationship issues**: Check delete rules and inverse relationships
3. **Performance issues**: Verify indexes are properly configured
4. **Migration failures**: Check attribute types and constraints

### Debug Tips
1. Enable Core Data debug logging: `-com.apple.CoreData.SQLDebug 1`
2. Use Core Data instruments for performance analysis
3. Check relationship consistency with validation
4. Monitor memory usage during large operations

## Next Steps

After creating the model file:
1. Update Package.swift to include CoreData framework
2. Initialize CoreDataManager in LedgerProApp.swift
3. Run migration service on first launch
4. Update FinancialDataManager to use CoreDataRepository
5. Test with existing data and verify performance improvements
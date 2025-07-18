# Changelog

All notable changes to LedgerPro will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Foreign currency detection and conversion for Capital One transactions
- Enhanced categorization system with 90+ built-in rules
- Support for AI services categorization (Claude, OpenAI, Anthropic)
- Mexican merchant categorization (OXXO, Carniceria, Fruteria)
- Entertainment service rules (Netflix, YouTube, Crunchyroll)
- Smart learning from user corrections
- Pattern-based rule matching
- Git workflow documentation (GIT_WORKFLOW.md)

### Fixed
- Swift 6.0 async/await compilation errors
- Actor isolation issues in test suites
- Categorization test failures (improved from 61% to 89%+ success rate)
- FinancialDataManager test account detection
- Range errors in merchant database operations

### Changed
- Improved CSV processor with forex support
- Enhanced ImportCategorizationService with direct CategoryService integration
- Updated test suites with @MainActor annotations
- Refactored categorization system for better accuracy

### Security
- All processing remains local-only
- No external data transmission

## [1.0.0] - Previous Release

### Added
- Initial macOS SwiftUI application
- PDF/CSV file processing
- Multi-bank support
- Basic transaction categorization
- MCP server integration
- Financial insights and charts
- Account management

### Known Issues
- MCP servers require manual configuration
- Limited categorization rules
- No foreign currency support
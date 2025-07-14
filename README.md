# LedgerPro 📊

<div align="center">

[![Tests](https://github.com/Jihp760/LedgerPro/actions/workflows/test.yml/badge.svg)](https://github.com/Jihp760/LedgerPro/actions/workflows/test.yml)
[![Security](https://github.com/Jihp760/LedgerPro/actions/workflows/security.yml/badge.svg)](https://github.com/Jihp760/LedgerPro/actions/workflows/security.yml)
[![codecov](https://codecov.io/gh/Jihp760/LedgerPro/branch/main/graph/badge.svg)](https://codecov.io/gh/Jihp760/LedgerPro)
[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Python 3.12](https://img.shields.io/badge/Python-3.12-blue.svg)](https://python.org)

**Privacy-focused financial management for Mac with AI-powered categorization**

[Features](#features) • [Installation](#installation) • [Architecture](#architecture) • [Contributing](#contributing)

</div>

## 🚀 Features

- 🔒 **100% Local Processing** - Your financial data never leaves your device
- 🤖 **Smart Categorization** - AI learns from your corrections
- 📈 **Pattern Learning** - Automatically improves over time
- 🏦 **Multi-Bank Support** - Works with major bank formats
- 💱 **Foreign Currency** - Automatic forex detection and conversion

## 📊 Project Health

| Metric | Status | Target |
|--------|--------|--------|
| Test Coverage | 70%+ | 80% |
| Unit Tests | 115+ | 150 |
| Build Time | <2min | <3min |
| Force Unwraps (Services) | 0 | 0 |
| Security Issues | 0 | 0 |
| Performance (500 tx) | 13.7s | <20s |

## 🏗️ Architecture

```
LedgerPro/
├── SwiftUI App (Mac)         # Native Mac application
├── MCP Bridge                # JSON-RPC communication
├── MCP Servers               # Local processing servers
│   ├── PDF Processor         # Bank statement parsing
│   ├── Financial Analyzer    # Insights & trends
│   └── OpenAI Service        # Optional categorization
└── Core Services             # Business logic
    ├── FinancialDataManager  # Transaction management
    ├── CategoryService       # Categorization engine
    ├── PatternLearningService # AI learning
    └── ImportCategorization  # Import workflows
```

## 🧪 Testing

We maintain comprehensive test coverage:

```bash
# Run all tests
./Scripts/run_all_tests.sh

# Run specific test suites
swift test --filter FinancialDataManagerTests
swift test --filter PatternLearningServiceTests
swift test --filter CriticalWorkflowTests

# Check coverage
swift test --enable-code-coverage
open .build/debug/codecov/index.html
```

### Test Categories

- **Unit Tests**: Individual service testing
- **Integration Tests**: End-to-end workflows
- **Performance Tests**: Large dataset handling
- **Security Tests**: Memory safety, force unwrap detection

## 🔒 Security

- No force unwraps in critical services
- Memory-safe string operations
- Automated security scanning
- No hardcoded secrets

## 🚀 Getting Started

### Prerequisites

- macOS 14.0+
- Xcode 15.0+
- Python 3.11+ (for MCP servers)
- Swift 6.0

### Installation

```bash
# Clone the repository
git clone https://github.com/Jihp760/LedgerPro.git
cd LedgerPro

# Install Python dependencies
cd MCP-Servers
pip install -r requirements.txt
cd ..

# Build and run
swift build
swift run
```

## 📈 Performance

Benchmarked on MacBook Pro M2:

- Import 500 transactions: 13.7s
- Categorization accuracy: 95%+
- Memory usage (1000 tx): <200MB
- Pattern learning: <5s per batch

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Ensure tests pass (`./Scripts/run_all_tests.sh`)
4. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
5. Push to the branch (`git push origin feature/AmazingFeature`)
6. Open a Pull Request

### Code Quality Standards

- ✅ All tests must pass
- ✅ No force unwraps in Services/
- ✅ Test coverage must not decrease
- ✅ Performance benchmarks must pass
- ✅ SwiftLint warnings resolved

## 📚 Documentation

Full documentation available at: https://jihp760.github.io/LedgerPro

## 🎯 Roadmap

- [ ] Multi-account sync
- [ ] Receipt scanning
- [ ] Budget planning
- [ ] Investment tracking
- [x] Pattern learning from corrections
- [x] Foreign currency support
- [x] Comprehensive test coverage
- [x] CI/CD pipeline

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with Swift 6.0 and SwiftUI
- MCP (Model Context Protocol) for AI integration
- Community contributors

---

<div align="center">
Made with ❤️ for privacy-conscious Mac users
</div>
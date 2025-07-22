// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LedgerPro",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "LedgerPro", targets: ["LedgerPro"])
    ],
    dependencies: [
        // Using Foundation's URLSession instead of AsyncHTTPClient for simplicity
    ],
    targets: [
        .executableTarget(
            name: "LedgerPro",
            dependencies: [],
            path: "Sources/LedgerPro",
            exclude: [
                "Services/FinancialDataManager.swift.backup3",
                "Views/OverviewView.swift.backup",
                "Debug/APIMonitor.swift.disabled"
            ]
        ),
        .testTarget(
            name: "LedgerProTests",
            dependencies: ["LedgerPro"],
            path: "Tests/LedgerProTests"
        )
    ]
)

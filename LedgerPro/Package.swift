// swift-tools-version: 5.9
// LedgerPro - Complete Financial Management Application 
// FIXED: Full Package.swift configuration to resolve build errors
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
        // Using Foundation's URLSession for HTTP requests - no external deps needed
    ],
    targets: [
        .executableTarget(
            name: "LedgerPro",
            dependencies: [],
            path: "Sources/LedgerPro",
            exclude: [
                "Debug/APIMonitor.swift.disabled",
                "Views/RulesManagementView.swift"
            ]
        ),
        .testTarget(
            name: "LedgerProTests",
            dependencies: ["LedgerPro"],
            path: "Tests/LedgerProTests"
        ),
        .testTarget(
            name: "LedgerProUITests",
            dependencies: ["LedgerPro"],
            path: "Tests/LedgerProUITests",
            resources: [
                .process("TestResources")
            ]
        )
    ]
)

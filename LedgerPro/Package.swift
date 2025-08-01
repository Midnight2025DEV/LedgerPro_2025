// swift-tools-version: 5.9
// LedgerPro - Complete Financial Management Application
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
        // Using Foundation's URLSession for HTTP requests
    ],
    targets: [
        .executableTarget(
            name: "LedgerPro",
            dependencies: [],
            path: "Sources/LedgerPro"
        ),
        .testTarget(
            name: "LedgerProTests",
            dependencies: ["LedgerPro"],
            path: "Tests/LedgerProTests"
        )
    ]
)
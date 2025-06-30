// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LedgerPro",
    platforms: [
        .macOS(.v13)
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
            path: "Sources/LedgerPro"
        ),
        .testTarget(
            name: "LedgerProTests",
            dependencies: ["LedgerPro"],
            path: "Tests/LedgerProTests"
        )
    ]
)
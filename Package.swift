// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MFA",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "MFA",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
            ],
            path: "Sources/MFA"
        ),
        .testTarget(
            name: "MFATests",
            dependencies: ["MFA"],
            path: "Tests/MFATests"
        ),
    ]
)

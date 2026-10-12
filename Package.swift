// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ApproachableConcurrency"),
]

let package = Package(
    name: "oxus",
    platforms: [.macOS(.v27)],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.12.1"),
    ],
    targets: [
        .target(
            name: "OxusServer",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk"),
            ],
            swiftSettings: swiftSettings,
        ),
        .executableTarget(
            name: "oxus",
            dependencies: [
                "OxusServer",
                .product(name: "MCP", package: "swift-sdk"),
            ],
            swiftSettings: swiftSettings,
        ),
        .testTarget(
            name: "OxusServerTests",
            dependencies: [
                "OxusServer",
                .product(name: "MCP", package: "swift-sdk"),
            ],
            swiftSettings: swiftSettings,
        ),
    ]
)

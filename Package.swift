// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PaymentProcessingFramework",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        // Main framework with all StoreKit 2 features
        .library(
            name: "PaymentProcessingFramework",
            targets: ["PaymentProcessingFramework"]
        ),
        // UI components including PaywallView
        .library(
            name: "PaymentProcessingUI",
            targets: ["PaymentProcessingUI"]
        ),
        // Analytics module
        .library(
            name: "PaymentProcessingAnalytics",
            targets: ["PaymentProcessingAnalytics"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
        .package(url: "https://github.com/apple/swift-async-algorithms.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0")
    ],
    targets: [
        // Core Framework
        .target(
            name: "PaymentProcessingFramework",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "Collections", package: "swift-collections")
            ],
            path: "Sources/Core",
            exclude: [],
            sources: nil,
            resources: nil,
            publicHeadersPath: nil,
            cSettings: nil,
            cxxSettings: nil,
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .define("RELEASE", .when(configuration: .release)),
                .enableUpcomingFeature("StrictConcurrency")
            ],
            linkerSettings: nil
        ),
        // UI Components
        .target(
            name: "PaymentProcessingUI",
            dependencies: ["PaymentProcessingFramework"],
            path: "Sources/UI",
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        ),
        // Analytics
        .target(
            name: "PaymentProcessingAnalytics",
            dependencies: ["PaymentProcessingFramework"],
            path: "Sources/Analytics"
        ),
        // Tests
        .testTarget(
            name: "PaymentProcessingFrameworkTests",
            dependencies: ["PaymentProcessingFramework"],
            path: "Tests/Core"
        ),
        .testTarget(
            name: "PaymentProcessingUITests",
            dependencies: ["PaymentProcessingUI"],
            path: "Tests/UI"
        ),
        .testTarget(
            name: "PaymentProcessingAnalyticsTests",
            dependencies: ["PaymentProcessingAnalytics"],
            path: "Tests/Analytics"
        )
    ],
    swiftLanguageVersions: [.v5]
)

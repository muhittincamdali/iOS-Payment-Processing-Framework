// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "iOSPaymentProcessingFramework",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "PaymentProcessingFramework",
            targets: ["PaymentProcessingFramework"]
        ),
        .library(
            name: "PaymentProcessingUI",
            targets: ["PaymentProcessingUI"]
        ),
        .library(
            name: "PaymentProcessingAnalytics",
            targets: ["PaymentProcessingAnalytics"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-async-algorithms.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "PaymentProcessingFramework",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "Collections", package: "swift-collections")
            ],
            path: "Sources/Core",
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .define("RELEASE", .when(configuration: .release))
            ]
        ),
        .target(
            name: "PaymentProcessingUI",
            dependencies: ["PaymentProcessingFramework"],
            path: "Sources/UI",
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "PaymentProcessingAnalytics",
            dependencies: ["PaymentProcessingFramework"],
            path: "Sources/Analytics"
        ),
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
    ]
) 
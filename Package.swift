// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "PaymentKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "PaymentKit", targets: ["PaymentKit"])
    ],
    targets: [
        .target(
            name: "PaymentKit",
            path: "Sources/PaymentKit"
        ),
        .testTarget(
            name: "PaymentKitTests",
            dependencies: ["PaymentKit"]
        )
    ]
)

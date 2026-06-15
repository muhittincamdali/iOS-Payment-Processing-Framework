// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "iOSPaymentProcessing",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [.library(name: "iOSPaymentProcessing", targets: ["iOSPaymentProcessing"])],
    targets: [.target(name: "iOSPaymentProcessing", path: "Sources/iOSPaymentProcessing")]
)

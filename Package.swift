// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "InopaySDK",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(name: "InopaySDK", targets: ["InopaySDK"]),
    ],
    targets: [
        .target(
            name: "InopaySDK",
            path: "Sources/InopaySDK"
        ),
        .testTarget(
            name: "InopaySDKTests",
            dependencies: ["InopaySDK"],
            path: "Tests/InopaySDKTests"
        ),
    ]
)

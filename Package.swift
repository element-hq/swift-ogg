// swift-tools-version:5.5.0
import PackageDescription

let package = Package(
    name: "SwiftOGG",
    platforms: [
        .iOS(.v12), .macOS(.v10_12), .watchOS(.v6), .tvOS(.v12)
    ],
    products: [
        .library(name: "SwiftOGG", targets: ["SwiftOGG"]),
    ],
    dependencies: [
        .package(url: "https://github.com/alta/swift-opus", branch: "main"),
        .package(url: "https://github.com/vincentneo/SwiftOgg", from: "1.3.5")
    ],
    targets: [
        // To debug with a local framework
//        .binaryTarget(name: "YbridOpus", path: "YbridOpus.xcframework"),
        .target(name: "Copustools", path: "Sources/SupportingFiles/Dependencies/Copustools"),
        .target(name: "SwiftOGG",
                dependencies: [
                    .product(name: "Opus", package: "swift-opus"),
                    .product(name: "COgg", package: "SwiftOgg"),
                    "Copustools"
                ],
                path: "Sources/SwiftOGG"),
        .testTarget(name: "EncoderDecoderTests", dependencies: ["SwiftOGG"], resources: [.process("Resources")]),
    ]
)

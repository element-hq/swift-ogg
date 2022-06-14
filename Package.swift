// swift-tools-version:5.5.0
import PackageDescription

let package = Package(
    name: "SwiftOGG",
    platforms: [
        .iOS(.v10), .macOS(.v10_15),
    ],
    products: [
        .library(name: "SwiftOGG", targets: ["SwiftOGG"]),
    ],
    dependencies: [
        .package(
            name: "YbridOpus",
            url: "https://github.com/ybrid/opus-swift.git",
            from: "0.8.0"),
        .package(
            name: "YbridOgg",
            url: "https://github.com/ybrid/ogg-swift.git",
            from: "0.8.0")
    ],
    targets: [
        .target(name: "Copustools", path: "Sources/SupportingFiles/Dependencies/Copustools"),
        .target(name: "SwiftOGG", dependencies: ["YbridOpus", "YbridOgg", "Copustools"], path: "Sources/SwiftOGG"),
        .testTarget(name: "EncoderDecoderTests", dependencies: ["SwiftOGG"], resources: [.process("Resources")]),
    ]
)

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
    targets: [
        .systemLibrary(name: "Clibogg", path: "Sources/SupportingFiles/Dependencies/Clibogg", pkgConfig: "ogg", providers: [.brew(["libogg"])]),
        .systemLibrary(name: "Clibopus", path: "Sources/SupportingFiles/Dependencies/Clibopus", pkgConfig: "opus", providers: [.brew(["opus"])]),
        .target(name: "Copustools", path: "Sources/SupportingFiles/Dependencies/Copustools"),
        .target(name: "SwiftOGG", dependencies: ["Clibogg", "Clibopus", "Copustools"], path: "Sources/SwiftOGG"),
        .testTarget(name: "EncoderDecoderTests", dependencies: ["SwiftOGG"], resources: [.process("Resources")]),
    ]
)

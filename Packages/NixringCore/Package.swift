// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "NixringCore",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "NixringCore", targets: ["NixringCore"]),
    ],
    targets: [
        .target(name: "NixringCore"),
        .testTarget(name: "NixringCoreTests", dependencies: ["NixringCore"]),
    ]
)

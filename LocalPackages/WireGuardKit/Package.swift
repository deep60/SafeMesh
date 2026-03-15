// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WireGuardKit",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(name: "WireGuardKit", targets: ["WireGuardKit"])
    ],
    targets: [
        .target(name: "WireGuardKit")
    ]
)

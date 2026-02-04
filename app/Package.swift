// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Grit",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Grit", targets: ["GritApp"])
    ],
    targets: [
        .executableTarget(
            name: "GritApp",
            path: "Sources"
        )
    ]
)

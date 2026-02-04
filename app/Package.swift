// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Grit",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Grit", targets: ["GritApp"])
    ],
    targets: [
        .target(
            name: "GritCoreFFI",
            path: "Sources/Services/Generated",
            exclude: ["GritCore.swift"],
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath(".")
            ]
        ),
        .executableTarget(
            name: "GritApp",
            dependencies: ["GritCoreFFI"],
            path: "Sources",
            exclude: [
                "Services/Generated/GritCoreFFI.h",
                "Services/Generated/GritCoreFFI.modulemap",
                "Services/Generated/interface.modulemap",
                "Services/Generated/module.modulemap"
            ],
            resources: [
                .process("../Config.json")
            ],
            linkerSettings: [
                .unsafeFlags(["-L", "../crates/core/target/debug", "-lgrit_core"])
            ]
        )
    ]
)

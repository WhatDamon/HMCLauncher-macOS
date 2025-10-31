// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HMCLauncher",
    platforms: [
        .macOS(.v10_13)
    ],
    targets: [
        .executableTarget(
            name: "HMCLauncher",
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .unsafeFlags([
                    "-whole-module-optimization",
                    "-cross-module-optimization",
                    "-enable-library-evolution",
                ], .when(configuration: .release))
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-flto"
                ], .when(configuration: .release))
            ]
        )
    ]
)

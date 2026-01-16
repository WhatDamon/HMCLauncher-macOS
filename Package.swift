// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HMCLauncher",
    platforms: [
        .macOS(.v10_15)
    ],
    targets: [
        .executableTarget(
            name: "HMCLauncher",
            swiftSettings: [
                .unsafeFlags(
                    [
                        "-Osize",
                        "-whole-module-optimization",
                    ],
                    .when(configuration: .release)
                )
            ],
        ),
        .testTarget(
            name: "HMCLauncherTests",
            dependencies: ["HMCLauncher"]
        ),
    ]
)

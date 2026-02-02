// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "L2RR2L",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "L2RR2LCore",
            targets: ["L2RR2LCore"]
        )
    ],
    dependencies: [
        // UI - Confetti animations for celebrations
        .package(url: "https://github.com/simibac/ConfettiSwiftUI.git", from: "1.1.0"),

        // Testing - SwiftUI view inspection
        .package(url: "https://github.com/nalexn/ViewInspector.git", from: "0.9.0"),

        // DI Framework (optional but recommended for testability)
        .package(url: "https://github.com/pointfreeco/swift-dependencies.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "L2RR2LCore",
            dependencies: [
                "ConfettiSwiftUI",
                .product(name: "Dependencies", package: "swift-dependencies")
            ],
            path: "L2RR2L/Core"
        ),
        .testTarget(
            name: "L2RR2LTests",
            dependencies: [
                "L2RR2LCore",
                "ViewInspector"
            ],
            path: "L2RR2LTests"
        )
    ]
)

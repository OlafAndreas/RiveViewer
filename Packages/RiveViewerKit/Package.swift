// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RiveViewerKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "RiveViewerKit", targets: ["RiveViewerKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/rive-app/rive-ios", exact: "6.28.1"),
    ],
    targets: [
        .target(
            name: "RiveViewerKit",
            dependencies: [.product(name: "RiveRuntime", package: "rive-ios")]
        ),
        .testTarget(
            name: "RiveViewerKitTests",
            dependencies: ["RiveViewerKit"],
            resources: [.copy("Fixtures")]
        ),
    ]
)

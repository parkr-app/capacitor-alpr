// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CapacitorAlpr",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "CapacitorAlpr",
            targets: ["AlprPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0")
    ],
    targets: [
        .target(
            name: "AlprPlugin",
            dependencies: [
                "AlprKit",
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios/Sources/AlprPlugin"),
        // Fetched by scripts/fetch-binaries.sh and shipped in the npm package.
        .binaryTarget(name: "AlprKit", path: "ios/Frameworks/AlprKit.xcframework")
    ]
)

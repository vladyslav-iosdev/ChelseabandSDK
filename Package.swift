// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ChelseabandSDK",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "ChelseabandSDK",
            targets: ["ChelseabandSDK"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vladyslav-iosdev/RxBluetoothKit.git", from: "6.0.0")
        //,
//        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "ChelseabandSDK",
            dependencies: ["RxBluetoothKit"/*, "RxSwift"*/]),
        .testTarget(
            name: "ChelseabandSDKTests",
            dependencies: ["ChelseabandSDK"]),
    ]
)

// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PocketBase",
    platforms: [.iOS(.v13), .macOS(.v10_15), .tvOS(.v13), .watchOS(.v6)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "PocketBase",
            targets: ["PocketBase"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.0.0"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.6.1")),
//        .package(path: "~/dev/EventSource"),
        .package(url: "https://github.com/briannadoubt/AlamofireEventSource.git", branch: "master")
//        .package(url: "https://github.com/briannadoubt/EventSource.git", branch: "master")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "PocketBase",
            dependencies: ["Alamofire", "KeychainAccess", "AlamofireEventSource"]),
        .testTarget(
            name: "PocketBaseTests",
            dependencies: ["PocketBase"]),
    ]
)

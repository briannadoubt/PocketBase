// swift-tools-version: 6.0

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "PocketBase",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11),
        .macCatalyst(.v18),
        .visionOS(.v2),
    ],
    products: [
        .library(name: "PocketBase", targets: ["PocketBase"]),
        .library(name: "PocketBaseUI", targets: ["PocketBaseUI"]),
        // MARK: WIP
//        .library(name: "DataBase", targets: ["DataBase"]),
    ],
    dependencies: [
//        .package(path: "../EventSource" url: "https://github.com/briannadoubt/EventSource.git", .upToNextMinor(from: "0.1.0")),
        .package(url: "https://github.com/apple/swift-http-types.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", .upToNextMajor(from: "4.0.0")),
        .package(url: "https://github.com/swiftlang/swift-syntax", "509.0.0"..<"602.0.0"),
        .package(url: "https://github.com/apple/swift-async-algorithms.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/apple/swift-collections.git", .upToNextMajor(from: "1.1.2")),
        .package(url: "https://github.com/briannadoubt/multipart-kit.git", revision: "760ca93"),
    ],
    targets: [
        .target(
            name: "DataBase",
            dependencies: ["PocketBase"]
        ),
        .target(
            name: "PocketBase",
            dependencies: [
                "PocketBaseMacros",
//                .product(name: "EventSource", package: "EventSource"),
                .product(name: "KeychainAccess", package: "KeychainAccess"),
                .product(name: "HTTPTypes", package: "swift-http-types"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "MultipartKit", package: "multipart-kit"),
            ]
        ),
        .macro(
            name: "PocketBaseMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(
            name: "PocketBaseUI",
            dependencies: ["PocketBase"]
        ),
        .target(
            name: "TestUtilities",
            dependencies: ["PocketBase"]
        ),
        .testTarget(
            name: "PocketBaseIntegrationTests",
            dependencies: ["PocketBase", "TestUtilities"]
        ),
        .testTarget(
            name: "PocketBaseMacrosTests",
            dependencies: [
                "PocketBase",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "PocketBaseTests",
            dependencies: ["PocketBase", "TestUtilities"]
        ),
    ],
    swiftLanguageModes: [.v6]
)

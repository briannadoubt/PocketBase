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
        .library(
            name: "PocketBase",
            targets: ["PocketBase"]
        ),
        .library(
            name: "PocketBaseUI",
            targets: ["PocketBaseUI"]
        ),
        .library(
            name: "DataBase",
            targets: ["DataBase"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-http-types.git",
            .upToNextMajor(from: "1.0.0")
        ),
        .package(
            url: "https://github.com/kishikawakatsumi/KeychainAccess.git",
            .upToNextMajor(from: "4.0.0")
        ),
        .package(
            url: "https://github.com/apple/swift-syntax",
            "509.0.0"..<"601.0.0-prerelease"
        ),
        .package(
            url: "https://github.com/apple/swift-async-algorithms.git",
            .upToNextMajor(from: "1.0.0")
        ),
        .package(
            url: "https://github.com/apple/swift-collections.git",
            .upToNextMajor(from: "1.1.2")
        ),
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
                .product(name: "KeychainAccess", package: "KeychainAccess"),
                .product(name: "HTTPTypes", package: "swift-http-types"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "Collections", package: "swift-collections")
            ]
        ),
        .macro(
            name: "PocketBaseMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .testTarget(
            name: "PocketBaseMacrosTests",
            dependencies: [
                "PocketBase",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
        .target(
            name: "PocketBaseUI",
            dependencies: ["PocketBase"]
        ),
        .testTarget(
            name: "PocketBaseTests",
            dependencies: ["PocketBase"]
        ),
        .testTarget(
            name: "PocketBaseIntegrationTests",
            dependencies: ["PocketBase"]
        ),
    ]
)

// swift-tools-version: 6.0

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "PocketBase",
    platforms: [
        .macOS(.v15),
        .iOS(.v17),
        .tvOS(.v17),
        .watchOS(.v10),
        .macCatalyst(.v17),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "PocketBase", targets: ["PocketBase"]),
        .library(name: "PocketBaseAdmin", targets: ["PocketBaseAdmin"]),
        .library(name: "PocketBaseUI", targets: ["PocketBaseUI"]),
        .plugin(name: "PocketBasePlugin", targets: ["PocketBasePlugin"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-http-types.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", .upToNextMajor(from: "4.0.0")),
        .package(url: "https://github.com/swiftlang/swift-syntax", "509.0.0"..<"603.0.0"),
        .package(url: "https://github.com/apple/swift-async-algorithms.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/apple/swift-collections.git", .upToNextMajor(from: "1.1.2")),
        .package(url: "https://github.com/vapor/multipart-kit.git", .upToNextMajor(from: "4.0.0")),
    ],
    targets: [
        .target(
            name: "PocketBase",
            dependencies: [
                "PocketBaseMacros",
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
            name: "PocketBaseAdmin",
            dependencies: ["PocketBase"]
        ),
        .target(
            name: "TestUtilities",
            dependencies: ["PocketBase"]
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
        .plugin(
            name: "PocketBasePlugin",
            capability: .command(
                intent: .custom(
                    verb: "pocketbase",
                    description: "PocketBase development tools: build, run, container, and db commands"
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "Needs to sign binaries, manage backups, and create configuration files")
                ]
            )
        ),
    ],
    swiftLanguageModes: [.v6]
)

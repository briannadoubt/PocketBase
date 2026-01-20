// swift-tools-version: 6.2

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
        .library(name: "PocketBaseServerLib", targets: ["PocketBaseServerLib"]),
        .executable(name: "PocketBaseServer", targets: ["PocketBaseServer"]),
        .plugin(name: "PocketBasePlugin", targets: ["PocketBasePlugin"]),
        // MARK: WIP
//        .library(name: "DataBase", targets: ["DataBase"]),
    ],
    dependencies: [
//        .package(path: "../EventSource" url: "https://github.com/briannadoubt/EventSource.git", .upToNextMinor(from: "0.1.0")),
        .package(url: "https://github.com/apple/swift-http-types.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", .upToNextMajor(from: "4.0.0")),
        .package(url: "https://github.com/swiftlang/swift-syntax", "509.0.0"..<"603.0.0"),
        .package(url: "https://github.com/apple/swift-async-algorithms.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/apple/swift-collections.git", .upToNextMajor(from: "1.1.2")),
        .package(url: "https://github.com/apple/containerization.git", exact: "0.21.1"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "1.3.0")),
        .package(url: "https://github.com/vapor/multipart-kit.git", .upToNextMajor(from: "4.0.0")),
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
            name: "PocketBaseAdmin",
            dependencies: ["PocketBase"]
        ),
        .target(
            name: "TestUtilities",
            dependencies: ["PocketBase"]
        ),
        .testTarget(
            name: "PocketBaseIntegrationTests",
            dependencies: ["PocketBase", "TestUtilities", "PocketBaseServerLib"]
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
        .testTarget(
            name: "PocketBaseAdminTests",
            dependencies: ["PocketBase", "PocketBaseAdmin", "TestUtilities"]
        ),
        .target(
            name: "PocketBaseServerLib",
            dependencies: [
                "PocketBase",
                .product(name: "Containerization", package: "containerization"),
                .product(name: "ContainerizationOCI", package: "containerization"),
            ]
        ),
        .executableTarget(
            name: "PocketBaseServer",
            dependencies: [
                "PocketBaseServerLib",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
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

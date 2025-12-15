//
//  BuildServerPlugin.swift
//  PocketBase
//
//  A SwiftPM command plugin that builds and signs PocketBaseServer with the required entitlements.
//

import Foundation
import PackagePlugin

@main
struct BuildServerPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let tool = try context.tool(named: "swift")

        // Parse arguments
        var release = false
        var run = false
        var remainingArgs: [String] = []

        var i = 0
        while i < arguments.count {
            switch arguments[i] {
            case "--release":
                release = true
            case "--run":
                run = true
            default:
                remainingArgs.append(arguments[i])
            }
            i += 1
        }

        let configuration = release ? "release" : "debug"

        // Build the product
        print("Building PocketBaseServer (\(configuration))...")

        let buildProcess = Process()
        buildProcess.executableURL = URL(
            fileURLWithPath: tool.url.absoluteString
        )
        buildProcess.arguments = ["build", "--product", "PocketBaseServer", "-c", configuration]
        buildProcess.currentDirectoryURL = URL(
            fileURLWithPath: context.package.directoryURL.absoluteString
        )

        try buildProcess.run()
        buildProcess.waitUntilExit()

        guard buildProcess.terminationStatus == 0 else {
            print("Build failed with exit code \(buildProcess.terminationStatus)")
            return
        }

        // Find the built binary
        let buildDir = context.package.directoryURL.appending(path: ".build").appending(path: configuration)
        let binaryPath = buildDir.appending(path: "PocketBaseServer")

        // Find the entitlements file - look in the PocketBase package, not the root project
        // When run from a dependent project, we need to find the actual package location
        let possiblePaths = [
            // Direct path (when run from PocketBase package itself)
            context.package.directoryURL.appending(path: "Sources/PocketBaseServer/PocketBaseServer.entitlements"
            ),
            // Checkouts path (when PocketBase is a remote dependency)
            context.package.directoryURL.appending(path:
                ".build/checkouts/PocketBase/Sources/PocketBaseServer/PocketBaseServer.entitlements"
            ),
            // Local package path (when PocketBase is referenced as ../PocketBase)
            context.package.directoryURL.appending(path:
                "../PocketBase/Sources/PocketBaseServer/PocketBaseServer.entitlements"
            ),
        ]

        guard let entitlementsPath = possiblePaths.first(where: { FileManager.default.fileExists(atPath: $0.absoluteString) }) else {
            print("❌ Could not find PocketBaseServer.entitlements")
            print("Searched paths:")
            for path in possiblePaths {
                print("  - \(path.absoluteString)")
            }
            return
        }

        // Sign the binary
        print(
            "Signing with entitlements at: \(entitlementsPath.absoluteString)"
        )

        let codesignProcess = Process()
        codesignProcess.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        codesignProcess.arguments = [
            "--force",
            "--sign", "-",
            "--entitlements", entitlementsPath.absoluteString,
            binaryPath.absoluteString
        ]

        try codesignProcess.run()
        codesignProcess.waitUntilExit()

        guard codesignProcess.terminationStatus == 0 else {
            print("Code signing failed with exit code \(codesignProcess.terminationStatus)")
            return
        }

        print("✅ Build complete: \(binaryPath.absoluteString)")

        // Run if requested
        if run {
            print("\nStarting PocketBaseServer...")

            let runProcess = Process()
            runProcess.executableURL = URL(
                fileURLWithPath: binaryPath.absoluteString
            )
            runProcess.arguments = remainingArgs
            runProcess.currentDirectoryURL = URL(
                fileURLWithPath: context.package.directoryURL
                    .absoluteString)

            // Forward stdout/stderr
            runProcess.standardOutput = FileHandle.standardOutput
            runProcess.standardError = FileHandle.standardError

            try runProcess.run()
            runProcess.waitUntilExit()
        }
    }
}

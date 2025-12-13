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
        buildProcess.executableURL = URL(fileURLWithPath: tool.path.string)
        buildProcess.arguments = ["build", "--product", "PocketBaseServer", "-c", configuration]
        buildProcess.currentDirectoryURL = URL(fileURLWithPath: context.package.directory.string)

        try buildProcess.run()
        buildProcess.waitUntilExit()

        guard buildProcess.terminationStatus == 0 else {
            print("Build failed with exit code \(buildProcess.terminationStatus)")
            return
        }

        // Find the built binary
        let buildDir = context.package.directory.appending([".build", configuration])
        let binaryPath = buildDir.appending(["PocketBaseServer"])

        // Find the entitlements file
        let entitlementsPath = context.package.directory.appending([
            "Sources", "PocketBaseServer", "PocketBaseServer.entitlements"
        ])

        // Sign the binary
        print("Signing with entitlements...")

        let codesignProcess = Process()
        codesignProcess.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        codesignProcess.arguments = [
            "--force",
            "--sign", "-",
            "--entitlements", entitlementsPath.string,
            binaryPath.string
        ]

        try codesignProcess.run()
        codesignProcess.waitUntilExit()

        guard codesignProcess.terminationStatus == 0 else {
            print("Code signing failed with exit code \(codesignProcess.terminationStatus)")
            return
        }

        print("✅ Build complete: \(binaryPath.string)")

        // Run if requested
        if run {
            print("\nStarting PocketBaseServer...")

            let runProcess = Process()
            runProcess.executableURL = URL(fileURLWithPath: binaryPath.string)
            runProcess.arguments = remainingArgs
            runProcess.currentDirectoryURL = URL(fileURLWithPath: context.package.directory.string)

            // Forward stdout/stderr
            runProcess.standardOutput = FileHandle.standardOutput
            runProcess.standardError = FileHandle.standardError

            try runProcess.run()
            runProcess.waitUntilExit()
        }
    }
}

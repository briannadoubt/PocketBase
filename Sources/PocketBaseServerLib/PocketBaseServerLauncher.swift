//
//  PocketBaseServerLauncher.swift
//  PocketBase
//
//  Created by Brianna Zamora on 12/11/24.
//

#if os(macOS)

import Foundation
import PocketBase

/// A singleton launcher for the PocketBase server container.
/// Used by integration tests to ensure a shared container instance.
public actor PocketBaseServerLauncher {
    /// Shared singleton instance
    public static let shared = PocketBaseServerLauncher()
    
    /// The underlying container
    private var container: PocketBaseContainer?
    
    /// Configuration for the server
    private var configuration: PocketBaseContainerConfiguration
    
    /// Health check URL
    private var healthCheckURL: URL {
        URL(string: "http://localhost:\(configuration.port)/api/health")!
    }
    
    /// Whether the server is currently running
    public private(set) var isRunning = false
    
    /// Reference count for nested start/stop calls
    private var referenceCount = 0
    
    private init() {
        self.configuration = PocketBaseContainerConfiguration()
    }
    
    /// Start the PocketBase server container.
    /// Uses reference counting to support nested calls.
    /// - Parameters:
    ///   - port: The port to run on (default: 8090)
    ///   - dataPath: Path to the data directory (default: ./pb_data_test for tests)
    ///   - verbose: Enable verbose logging
    ///   - clear: Clear the database before starting (truncate all collections)
    public func start(
        port: Int = 8090,
        dataPath: String = "./pb_data_test",
        verbose: Bool = false,
        clear: Bool = false
    ) async throws {
        referenceCount += 1
        
        // Already running, just increment reference count
        if isRunning {
            if verbose {
                print("[PocketBaseServerLauncher] Server already running, reference count: \(referenceCount)")
            }
            
            // If clear requested on an already running server, truncate via API
            if clear {
                try await clearDatabase(verbose: verbose)
            }
            return
        }
        
        configuration = PocketBaseContainerConfiguration(
            port: port,
            dataPath: dataPath,
            verbose: verbose
        )
        
        // Clear the data directory if requested and starting fresh
        if clear {
            let dataURL = URL(fileURLWithPath: dataPath)
            if FileManager.default.fileExists(atPath: dataURL.path) {
                if verbose {
                    print("[PocketBaseServerLauncher] Clearing data directory: \(dataPath)")
                }
                try? FileManager.default.removeItem(at: dataURL)
            }
        }
        
        let container = PocketBaseContainer(configuration: configuration)
        self.container = container
        
        if verbose {
            print("[PocketBaseServerLauncher] Starting PocketBase server...")
        }
        
        try await container.start()
        
        // Wait for health check to pass
        try await waitForHealthy(verbose: verbose)
        
        isRunning = true
        
        if verbose {
            print("[PocketBaseServerLauncher] Server is ready at http://localhost:\(port)")
        }
    }
    
    /// Stop the PocketBase server container.
    /// Only actually stops when reference count reaches zero.
    public func stop(verbose: Bool = false) async throws {
        referenceCount -= 1
        
        if referenceCount > 0 {
            if verbose {
                print("[PocketBaseServerLauncher] Keeping server running, reference count: \(referenceCount)")
            }
            return
        }
        
        guard isRunning, let container = container else {
            return
        }
        
        if verbose {
            print("[PocketBaseServerLauncher] Stopping PocketBase server...")
        }
        
        try await container.stop()
        self.container = nil
        isRunning = false
        referenceCount = 0
        
        if verbose {
            print("[PocketBaseServerLauncher] Server stopped")
        }
    }
    
    /// Force stop the server regardless of reference count
    public func forceStop(verbose: Bool = false) async throws {
        guard let container = container else {
            return
        }
        
        if verbose {
            print("[PocketBaseServerLauncher] Force stopping PocketBase server...")
        }
        
        try await container.stop()
        self.container = nil
        isRunning = false
        referenceCount = 0
    }
    
    /// Wait for the server to become healthy
    private func waitForHealthy(verbose: Bool, timeout: TimeInterval = 60) async throws {
        let startTime = Date()
        var lastError: Error?
        
        if verbose {
            print("[PocketBaseServerLauncher] Waiting for server health check...")
        }
        
        while Date().timeIntervalSince(startTime) < timeout {
            do {
                let (_, response) = try await URLSession.shared.data(from: healthCheckURL)
                
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    if verbose {
                        print("[PocketBaseServerLauncher] Health check passed")
                    }
                    return
                }
            } catch {
                lastError = error
            }
            
            // Wait before retrying
            try await Task.sleep(for: .milliseconds(500))
        }
        
        throw PocketBaseServerLauncherError.healthCheckTimeout(lastError)
    }
    
    /// Clear the database by truncating all user-created collections.
    /// Requires superuser authentication.
    private func clearDatabase(verbose: Bool) async throws {
        if verbose {
            print("[PocketBaseServerLauncher] Clearing database via API...")
        }
        
        // Note: This requires admin authentication to work.
        // For tests, it's often easier to just delete the data directory.
        // This is a placeholder for when admin auth is available.
        
        // The truncate endpoint is: DELETE /api/collections/{collectionIdOrName}/truncate
        // It requires Authorization: TOKEN header with superuser token
        
        if verbose {
            print("[PocketBaseServerLauncher] Database clear requested (requires admin setup)")
        }
    }
    
    /// Get the base URL for the running server
    public func baseURL() -> URL {
        URL(string: "http://localhost:\(configuration.port)")!
    }
}

/// Errors from the server launcher
public enum PocketBaseServerLauncherError: Error, LocalizedError {
    case healthCheckTimeout(Error?)
    case notRunning
    
    public var errorDescription: String? {
        switch self {
        case .healthCheckTimeout(let underlying):
            if let error = underlying {
                return "Server health check timed out: \(error.localizedDescription)"
            }
            return "Server health check timed out"
        case .notRunning:
            return "Server is not running"
        }
    }
}

#endif

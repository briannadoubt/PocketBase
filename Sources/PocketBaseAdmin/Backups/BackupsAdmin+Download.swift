//
//  BackupsAdmin+Download.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation

extension BackupsAdmin {
    /// Gets the download URL for a backup.
    ///
    /// The URL includes an authentication token and is valid for a limited time.
    ///
    /// - Parameter name: The backup file name.
    /// - Returns: The download URL for the backup.
    public func downloadURL(name: String) -> URL {
        var url = pocketbase.url.appending(path: "\(Self.basePath)/\(name)")
        if let token = pocketbase.authStore.token {
            url = url.appending(queryItems: [URLQueryItem(name: "token", value: token)])
        }
        return url
    }

    /// Downloads a backup file.
    ///
    /// - Parameter name: The backup file name.
    /// - Returns: The backup file data.
    public func download(name: String) async throws -> Data {
        try await execute(method: "GET", path: "\(Self.basePath)/\(name)")
    }
}

//
//  RecordCollection+FileToken.swift
//  PocketBase
//
//  Created by Brianna Zamora on 12/4/24.
//

import Foundation

public extension RecordCollection {
    /// Requests a short-lived file token for accessing protected files.
    ///
    /// Protected files require authentication to access. This method generates
    /// a temporary token (valid for approximately 2 minutes) that can be used
    /// to access protected files.
    ///
    /// The client must be authenticated (have a valid auth token) to request
    /// a file token.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Get a file token
    /// let tokenResponse = try await collection.getFileToken()
    ///
    /// // Use the token to build a protected file URL
    /// let url = pocketbase.fileURL(
    ///     record: myRecord,
    ///     filename: myRecord.protectedFile,
    ///     token: tokenResponse.token
    /// )
    /// ```
    ///
    /// - Returns: A `FileTokenResponse` containing the short-lived token.
    /// - Throws: An error if the request fails or the user is not authenticated.
    @Sendable
    func getFileToken() async throws -> FileTokenResponse {
        try await post(
            path: PocketBase.fileTokenPath,
            query: [],
            headers: headers
        )
    }
}

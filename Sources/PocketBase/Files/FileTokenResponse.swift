//
//  FileTokenResponse.swift
//  PocketBase
//
//  Created by Brianna Zamora on 12/4/24.
//

import Foundation

/// The response from requesting a protected file token.
///
/// File tokens are short-lived (approximately 2 minutes) and are used to access
/// protected files that require authentication.
public struct FileTokenResponse: Codable, Sendable, Hashable {
    /// The short-lived file access token.
    ///
    /// This token should be appended to file URLs as a query parameter
    /// to access protected files.
    public let token: String
}

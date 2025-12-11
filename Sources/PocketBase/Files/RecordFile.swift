//
//  RecordFile.swift
//  PocketBase
//
//  Created by Brianna Zamora on 12/4/24.
//

import Foundation

/// Represents a file attached to a PocketBase record.
///
/// `RecordFile` provides a rich interface for working with files stored in PocketBase.
/// It contains the filename along with the context needed to generate URLs, including
/// a ready-to-use `url` property.
///
/// ## Usage with @FileField
///
/// Use the `@FileField` macro to declare file properties on your records:
///
/// ```swift
/// @BaseCollection("posts")
/// struct Post {
///     var title: String = ""
///     @FileField var coverImage: RecordFile?        // Single file
///     @FileField var attachments: [RecordFile]? // Multiple files
/// }
/// ```
///
/// The macro automatically hydrates file fields when decoding records from PocketBase,
/// including the base URL for direct access.
///
/// ## Accessing Files
///
/// ```swift
/// if let cover = post.coverImage {
///     // Direct URL access - ready to use!
///     let url = cover.url
///     // "http://localhost:8090/api/files/posts/abc123/cover_xyz.png"
///
///     // With thumbnail
///     let thumbUrl = cover.url(thumb: .crop(width: 100, height: 100))
///
///     // Force download
///     let downloadUrl = cover.url(download: true)
///
///     // Protected file with token
///     let token = try await collection.getFileToken()
///     let protectedUrl = cover.url(token: token.token)
/// }
/// ```
public struct RecordFile: Sendable, Hashable {
    /// The filename as stored in PocketBase.
    ///
    /// PocketBase stores files with the original filename plus a random suffix,
    /// e.g., `avatar_Ab24ZjL.png`.
    public let filename: String

    /// The collection name or ID this file belongs to.
    public let collectionName: String

    /// The record ID this file belongs to.
    public let recordId: String

    /// The base URL of the PocketBase server.
    public let baseURL: URL

    /// The direct URL to access this file.
    ///
    /// This is a ready-to-use URL that can be used directly in image views,
    /// download tasks, etc.
    ///
    /// ```swift
    /// if let cover = post.coverImage {
    ///     let url = cover.url  // Ready to use!
    /// }
    /// ```
    public var url: URL {
        baseURL
            .appending(path: PocketBase.filePath(collectionName, recordId, filename))
    }

    /// Creates a new RecordFile.
    ///
    /// - Parameters:
    ///   - filename: The filename as stored in PocketBase.
    ///   - collectionName: The collection name or ID.
    ///   - recordId: The record ID.
    ///   - baseURL: The PocketBase server base URL.
    public init(filename: String, collectionName: String, recordId: String, baseURL: URL) {
        self.filename = filename
        self.collectionName = collectionName
        self.recordId = recordId
        self.baseURL = baseURL
    }

    /// Generates a URL for accessing this file with options.
    ///
    /// Use this method when you need thumbnails, tokens, or download mode.
    /// For basic access, use the `url` property directly.
    ///
    /// - Parameters:
    ///   - thumb: Optional thumbnail size for image files.
    ///   - token: Optional file token for protected files.
    ///   - download: If `true`, forces browser download instead of preview.
    /// - Returns: The complete URL for the file with query parameters.
    public func url(
        thumb: ThumbSize? = nil,
        token: String? = nil,
        download: Bool = false
    ) -> URL {
        var queryItems: [URLQueryItem] = []

        if let thumb = thumb {
            queryItems.append(URLQueryItem(name: "thumb", value: thumb.queryValue))
        }

        if let token = token {
            queryItems.append(URLQueryItem(name: "token", value: token))
        }

        if download {
            queryItems.append(URLQueryItem(name: "download", value: "1"))
        }

        if queryItems.isEmpty {
            return url
        }

        return url.appending(queryItems: queryItems)
    }
}

// MARK: - Decoder UserInfo Key

extension RecordFile {
    /// The key used to pass the PocketBase base URL through decoder's userInfo.
    public static let baseURLUserInfoKey = CodingUserInfoKey(rawValue: "io.pocketbase.baseURL")!
}

// MARK: - Codable Support

extension RecordFile: Codable {
    /// RecordFile encodes to just the filename string for simplicity.
    /// The full context is reconstructed during decoding via the macro.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(filename)
    }

    /// RecordFile cannot be decoded directly - it requires record context.
    /// The @FileField macro handles decoding with proper context.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.filename = try container.decode(String.self)
        // These will be empty/localhost when decoded directly - the macro fills them in
        self.collectionName = ""
        self.recordId = ""
        self.baseURL = (decoder.userInfo[Self.baseURLUserInfoKey] as? URL) ?? .localhost
    }
}

// MARK: - CustomStringConvertible

extension RecordFile: CustomStringConvertible {
    public var description: String {
        "RecordFile(\(filename))"
    }
}

// MARK: - ExpressibleByStringLiteral

extension RecordFile: ExpressibleByStringLiteral {
    /// Allows creating a RecordFile from a string literal (for testing/convenience).
    ///
    /// Note: Files created this way will use localhost as the base URL.
    public init(stringLiteral value: String) {
        self.filename = value
        self.collectionName = ""
        self.recordId = ""
        self.baseURL = .localhost
    }
}

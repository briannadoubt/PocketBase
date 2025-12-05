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
/// It contains the filename along with the context needed to generate URLs.
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
///     @FileField var attachments: [RecordFile] = [] // Multiple files
/// }
/// ```
///
/// The macro automatically hydrates file fields when decoding records from PocketBase.
///
/// ## Generating URLs
///
/// Use the `url(from:)` method to generate file URLs:
///
/// ```swift
/// if let cover = post.coverImage {
///     // Basic URL
///     let url = cover.url(from: pocketbase)
///
///     // With thumbnail
///     let thumbUrl = cover.url(from: pocketbase, thumb: .crop(width: 100, height: 100))
///
///     // Force download
///     let downloadUrl = cover.url(from: pocketbase, download: true)
///
///     // Protected file with token
///     let token = try await collection.getFileToken()
///     let protectedUrl = cover.url(from: pocketbase, token: token.token)
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

    /// Creates a new RecordFile.
    ///
    /// - Parameters:
    ///   - filename: The filename as stored in PocketBase.
    ///   - collectionName: The collection name or ID.
    ///   - recordId: The record ID.
    public init(filename: String, collectionName: String, recordId: String) {
        self.filename = filename
        self.collectionName = collectionName
        self.recordId = recordId
    }

    /// Generates a URL for accessing this file.
    ///
    /// - Parameters:
    ///   - pocketbase: The PocketBase instance to generate the URL from.
    ///   - thumb: Optional thumbnail size for image files.
    ///   - token: Optional file token for protected files.
    ///   - download: If `true`, forces browser download instead of preview.
    /// - Returns: The complete URL for the file.
    public func url(
        from pocketbase: PocketBase,
        thumb: ThumbSize? = nil,
        token: String? = nil,
        download: Bool = false
    ) -> URL {
        pocketbase.fileURL(
            collectionIdOrName: collectionName,
            recordId: recordId,
            filename: filename,
            thumb: thumb,
            token: token,
            download: download
        )
    }
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
        // These will be empty when decoded directly - the macro fills them in
        self.collectionName = ""
        self.recordId = ""
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
    /// Note: Files created this way won't have collection/record context for URL generation.
    public init(stringLiteral value: String) {
        self.filename = value
        self.collectionName = ""
        self.recordId = ""
    }
}

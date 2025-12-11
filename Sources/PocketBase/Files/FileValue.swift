//
//  FileValue.swift
//  PocketBase
//
//  Created by Brianna Zamora on 12/10/24.
//

import Foundation

/// A file value that can represent either an existing file on the server or a pending upload.
///
/// `FileValue` provides a unified type for working with files in `@FileField` properties,
/// allowing you to seamlessly handle both existing files and new uploads with the same API.
///
/// ## Usage
///
/// ```swift
/// @BaseCollection("posts")
/// struct Post {
///     var title: String = ""
///     @FileField var coverImage: FileValue?
///     @FileField var attachments: [FileValue]?
/// }
///
/// // Create a post with a file to upload
/// var post = Post(title: "My Post")
/// post.coverImage = .pending(UploadFile(filename: "cover.png", data: imageData))
/// let created = try await collection.create(post)  // Auto-detects, uses multipart
///
/// // Later, access the uploaded file
/// if let cover = created.coverImage?.existingFile {
///     let url = cover.url
/// }
///
/// // Update with mixed files (keep existing, add new)
/// created.attachments = [
///     .existing(existingFile),  // Keep this one
///     .pending(newUpload)       // Upload this one
/// ]
/// let updated = try await collection.update(created)
/// ```
public enum FileValue: Sendable, Hashable {
    /// An existing file already stored on the PocketBase server.
    case existing(RecordFile)

    /// A file pending upload to the server.
    case pending(UploadFile)

    /// The filename for this file value.
    public var filename: String {
        switch self {
        case .existing(let file):
            return file.filename
        case .pending(let file):
            return file.filename
        }
    }

    /// Returns the `UploadFile` if this is a pending upload, `nil` otherwise.
    public var pendingUpload: UploadFile? {
        if case .pending(let file) = self {
            return file
        }
        return nil
    }

    /// Returns the `RecordFile` if this is an existing file, `nil` otherwise.
    public var existingFile: RecordFile? {
        if case .existing(let file) = self {
            return file
        }
        return nil
    }

    /// Returns `true` if this is a pending upload.
    public var isPending: Bool {
        if case .pending = self {
            return true
        }
        return false
    }

    /// Returns `true` if this is an existing file.
    public var isExisting: Bool {
        if case .existing = self {
            return true
        }
        return false
    }
}

// MARK: - Convenience Initializers

extension FileValue {
    /// Creates a `FileValue` from an existing `RecordFile`.
    ///
    /// - Parameter file: The existing file reference.
    public init(_ file: RecordFile) {
        self = .existing(file)
    }

    /// Creates a `FileValue` from an `UploadFile` pending upload.
    ///
    /// - Parameter file: The file to upload.
    public init(_ file: UploadFile) {
        self = .pending(file)
    }
}

// MARK: - Codable Support

extension FileValue: Codable {
    /// Encodes the file value as just the filename string.
    ///
    /// For existing files, this encodes the filename.
    /// For pending uploads, this also encodes the filename (the actual data goes in multipart body).
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(filename)
    }

    /// Decodes a file value from a filename string.
    ///
    /// Files decoded this way are treated as existing files. The macro fills in
    /// the full context (collection, record ID, base URL) during record decoding.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let filename = try container.decode(String.self)
        let baseURL = (decoder.userInfo[RecordFile.baseURLUserInfoKey] as? URL) ?? .localhost
        // When decoded directly, treat as existing file (context filled in by macro)
        self = .existing(RecordFile(
            filename: filename,
            collectionName: "",
            recordId: "",
            baseURL: baseURL
        ))
    }
}

// MARK: - CustomStringConvertible

extension FileValue: CustomStringConvertible {
    public var description: String {
        switch self {
        case .existing(let file):
            return "FileValue.existing(\(file.filename))"
        case .pending(let file):
            return "FileValue.pending(\(file.filename))"
        }
    }
}

// MARK: - ExpressibleByStringLiteral

extension FileValue: ExpressibleByStringLiteral {
    /// Creates a `FileValue` from a string literal.
    ///
    /// This creates an existing file reference with the given filename.
    /// Useful for testing and simple initialization.
    ///
    /// Note: Files created this way will use localhost as the base URL
    /// and empty collection/record context.
    public init(stringLiteral value: String) {
        self = .existing(RecordFile(
            filename: value,
            collectionName: "",
            recordId: "",
            baseURL: .localhost
        ))
    }
}

// MARK: - URL Access

extension FileValue {
    /// The direct URL to access this file, if it's an existing file.
    ///
    /// Returns `nil` for pending uploads since they haven't been uploaded yet.
    public var url: URL? {
        existingFile?.url
    }

    /// Generates a URL for accessing this file with options.
    ///
    /// Returns `nil` for pending uploads.
    ///
    /// - Parameters:
    ///   - thumb: Optional thumbnail size for image files.
    ///   - token: Optional file token for protected files.
    ///   - download: If `true`, forces browser download instead of preview.
    /// - Returns: The complete URL for the file with query parameters, or `nil` if pending.
    public func url(
        thumb: ThumbSize? = nil,
        token: String? = nil,
        download: Bool = false
    ) -> URL? {
        existingFile?.url(thumb: thumb, token: token, download: download)
    }
}

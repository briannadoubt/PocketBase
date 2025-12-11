//
//  UploadFile.swift
//  PocketBase
//
//  Created by Brianna Zamora on 12/4/24.
//

import Foundation

/// Represents a file to be uploaded to PocketBase.
///
/// Use this struct when creating or updating records with file fields.
///
/// ## Usage
///
/// ```swift
/// // Create from raw data
/// let file = UploadFile(
///     filename: "document.pdf",
///     data: pdfData,
///     mimeType: "application/pdf"
/// )
///
/// // Create from a file URL
/// let imageFile = try UploadFile(url: imageURL)
///
/// // Upload with a record
/// try await collection.create(record, files: [
///     "avatar": [file]
/// ])
/// ```
public struct UploadFile: Sendable, Hashable {
    /// The filename to use when uploading.
    ///
    /// PocketBase will sanitize this filename and append a random suffix.
    public let filename: String

    /// The raw file data to upload.
    public let data: Data

    /// The MIME type of the file.
    ///
    /// Common examples:
    /// - `image/png`
    /// - `image/jpeg`
    /// - `application/pdf`
    /// - `text/plain`
    public let mimeType: String

    /// Creates a new file for upload.
    ///
    /// - Parameters:
    ///   - filename: The filename to use when uploading.
    ///   - data: The raw file data.
    ///   - mimeType: The MIME type of the file. Defaults to `application/octet-stream`.
    public init(
        filename: String,
        data: Data,
        mimeType: String = "application/octet-stream"
    ) {
        self.filename = filename
        self.data = data
        self.mimeType = mimeType
    }

    /// Creates a new file for upload from a file URL.
    ///
    /// - Parameter url: The file URL to read from.
    /// - Throws: An error if the file cannot be read.
    public init(url: URL) throws {
        self.filename = url.lastPathComponent
        self.data = try Data(contentsOf: url)
        self.mimeType = Self.mimeType(for: url)
    }

    /// Infers the MIME type from a file URL based on its extension.
    ///
    /// - Parameter url: The file URL.
    /// - Returns: The inferred MIME type, or `application/octet-stream` if unknown.
    public static func mimeType(for url: URL) -> String {
        mimeType(forExtension: url.pathExtension)
    }

    /// Returns the MIME type for a given file extension.
    ///
    /// - Parameter extension: The file extension (without the dot).
    /// - Returns: The MIME type, or `application/octet-stream` if unknown.
    public static func mimeType(forExtension ext: String) -> String {
        switch ext.lowercased() {
        // Images
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "webp":
            return "image/webp"
        case "svg":
            return "image/svg+xml"
        case "ico":
            return "image/x-icon"
        case "bmp":
            return "image/bmp"
        case "tiff", "tif":
            return "image/tiff"
        case "heic":
            return "image/heic"
        case "heif":
            return "image/heif"

        // Documents
        case "pdf":
            return "application/pdf"
        case "doc":
            return "application/msword"
        case "docx":
            return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "xls":
            return "application/vnd.ms-excel"
        case "xlsx":
            return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case "ppt":
            return "application/vnd.ms-powerpoint"
        case "pptx":
            return "application/vnd.openxmlformats-officedocument.presentationml.presentation"

        // Text
        case "txt":
            return "text/plain"
        case "html", "htm":
            return "text/html"
        case "css":
            return "text/css"
        case "js":
            return "text/javascript"
        case "json":
            return "application/json"
        case "xml":
            return "application/xml"
        case "csv":
            return "text/csv"
        case "md":
            return "text/markdown"

        // Audio
        case "mp3":
            return "audio/mpeg"
        case "wav":
            return "audio/wav"
        case "ogg":
            return "audio/ogg"
        case "m4a":
            return "audio/mp4"
        case "flac":
            return "audio/flac"
        case "aac":
            return "audio/aac"

        // Video
        case "mp4":
            return "video/mp4"
        case "mpeg", "mpg":
            return "video/mpeg"
        case "webm":
            return "video/webm"
        case "mov":
            return "video/quicktime"
        case "avi":
            return "video/x-msvideo"
        case "mkv":
            return "video/x-matroska"

        // Archives
        case "zip":
            return "application/zip"
        case "tar":
            return "application/x-tar"
        case "gz", "gzip":
            return "application/gzip"
        case "rar":
            return "application/vnd.rar"
        case "7z":
            return "application/x-7z-compressed"

        // Other
        case "wasm":
            return "application/wasm"

        default:
            return "application/octet-stream"
        }
    }
}

/// A collection of files to upload, organized by field name.
///
/// The dictionary keys are the field names in your PocketBase collection,
/// and the values are arrays of files to upload for that field.
///
/// ## Field Name Modifiers
///
/// When updating records, you can use special prefixes/suffixes on field names:
///
/// - `fieldName+` - Append files to existing ones
/// - `+fieldName` - Prepend files to existing ones
/// - `fieldName-` - Delete specific files (use empty `UploadFile` with just the filename)
///
/// ## Example
///
/// ```swift
/// // Upload new files
/// let files: FileUploadPayload = [
///     "avatar": [avatarFile],
///     "documents": [doc1, doc2, doc3]
/// ]
///
/// // Append to existing files
/// let appendFiles: FileUploadPayload = [
///     "documents+": [newDoc]
/// ]
/// ```
public typealias FileUploadPayload = [String: [UploadFile]]

/// Represents files to be deleted from a record.
///
/// Use this when updating a record to remove specific files from a multi-file field.
public struct FileDeletePayload: Sendable {
    /// The field name and filenames to delete.
    public let deletions: [String: [String]]

    /// Creates a new file deletion payload.
    ///
    /// - Parameter deletions: A dictionary mapping field names to arrays of filenames to delete.
    public init(_ deletions: [String: [String]]) {
        self.deletions = deletions
    }

    /// Creates a payload to delete files from a single field.
    ///
    /// - Parameters:
    ///   - fieldName: The field name.
    ///   - filenames: The filenames to delete.
    public init(fieldName: String, filenames: [String]) {
        self.deletions = [fieldName: filenames]
    }
}

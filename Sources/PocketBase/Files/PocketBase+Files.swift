//
//  PocketBase+Files.swift
//  PocketBase
//
//  Created by Brianna Zamora on 12/4/24.
//

import Foundation

extension PocketBase {
    /// Generates a URL for accessing a file stored in PocketBase.
    ///
    /// This method constructs the complete URL for downloading or displaying a file
    /// from a PocketBase record.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Basic file URL
    /// let url = pocketbase.fileURL(
    ///     collectionIdOrName: "posts",
    ///     recordId: "abc123",
    ///     filename: "image.png"
    /// )
    ///
    /// // With thumbnail
    /// let thumbUrl = pocketbase.fileURL(
    ///     collectionIdOrName: "posts",
    ///     recordId: "abc123",
    ///     filename: "image.png",
    ///     thumb: .crop(width: 100, height: 100)
    /// )
    ///
    /// // Force download
    /// let downloadUrl = pocketbase.fileURL(
    ///     collectionIdOrName: "posts",
    ///     recordId: "abc123",
    ///     filename: "document.pdf",
    ///     download: true
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - collectionIdOrName: The collection ID or name.
    ///   - recordId: The record ID.
    ///   - filename: The filename as stored in PocketBase.
    ///   - thumb: Optional thumbnail size for image files.
    ///   - token: Optional file token for protected files.
    ///   - download: If `true`, adds `?download=1` to force browser download instead of preview.
    /// - Returns: The complete URL for the file.
    public func fileURL(
        collectionIdOrName: String,
        recordId: String,
        filename: String,
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

        let path = Self.filePath(collectionIdOrName, recordId, filename)
        var url = self.url.appending(path: path)

        if !queryItems.isEmpty {
            url = url.appending(queryItems: queryItems)
        }

        return url
    }

    /// Generates a URL for accessing a file from a record.
    ///
    /// This is a convenience method that extracts the collection and record ID from a record.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let url = pocketbase.fileURL(
    ///     record: myPost,
    ///     filename: myPost.coverImage
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - record: The record containing the file.
    ///   - filename: The filename as stored in the record.
    ///   - thumb: Optional thumbnail size for image files.
    ///   - token: Optional file token for protected files.
    ///   - download: If `true`, forces browser download instead of preview.
    /// - Returns: The complete URL for the file.
    public func fileURL<T: Record>(
        record: T,
        filename: String,
        thumb: ThumbSize? = nil,
        token: String? = nil,
        download: Bool = false
    ) -> URL {
        fileURL(
            collectionIdOrName: T.collection,
            recordId: record.id,
            filename: filename,
            thumb: thumb,
            token: token,
            download: download
        )
    }
}

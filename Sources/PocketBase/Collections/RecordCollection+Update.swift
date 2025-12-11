//
//  RecordCollection+Update.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

import Foundation

public extension RecordCollection {
    /// Update a given record by passing in an updated record.
    ///
    /// This method automatically detects pending file uploads in `@FileField` properties
    /// that use `FileValue` type. If any pending uploads are found, it uses multipart/form-data
    /// encoding; otherwise, it uses JSON encoding.
    ///
    /// ## Usage with FileValue (auto-detection)
    ///
    /// ```swift
    /// var post = try await collection.view("some-id")
    /// post.title = "Updated Title"
    /// post.coverImage = .pending(UploadFile(filename: "new-cover.png", data: imageData))
    /// let updated = try await collection.update(post)  // Auto-detects, uses multipart
    /// ```
    ///
    /// ## Usage without files
    ///
    /// ```swift
    /// var post = try await collection.view("some-id")
    /// post.title = "Updated Title"
    /// let updated = try await collection.update(post)  // Uses JSON
    /// ```
    ///
    /// - note: Depending on the collection's `updateRule` value, the access to this action may or may not have been restricted.
    /// - Parameters:
    ///   - record: The record to be updated, with the updates pre-applied locally.
    /// - Returns: Returns the updated record.
    @Sendable
    @discardableResult
    func update(_ record: T) async throws -> T {
        let pendingFiles = record.pendingFileUploads()

        if pendingFiles.isEmpty {
            // No pending uploads - use JSON encoding
            return try await patch(
                path: PocketBase.recordPath(collection, record.id, trailingSlash: false),
                query: {
                    var query: [URLQueryItem] = []
                    if !T.relations.isEmpty {
                        query.append(URLQueryItem(name: "expand", value: T.relations.keys.joined(separator: ",")))
                    }
                    return query
                }(),
                headers: headers,
                body: record
            )
        } else {
            // Has pending uploads - use multipart encoding
            let body = try buildMultipartBody(record: record, files: pendingFiles)
            return try await patchMultipart(
                path: PocketBase.recordPath(collection, record.id, trailingSlash: false),
                query: {
                    var query: [URLQueryItem] = []
                    if !T.relations.isEmpty {
                        query.append(URLQueryItem(name: "expand", value: T.relations.keys.joined(separator: ",")))
                    }
                    return query
                }(),
                body: body
            )
        }
    }
}

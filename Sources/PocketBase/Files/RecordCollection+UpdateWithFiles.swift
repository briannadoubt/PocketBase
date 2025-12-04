//
//  RecordCollection+UpdateWithFiles.swift
//  PocketBase
//
//  Created by Brianna Zamora on 12/4/24.
//

import Foundation
internal import HTTPTypes

public extension RecordCollection {
    /// Updates a record with file uploads.
    ///
    /// This method uses multipart/form-data encoding to upload new files
    /// alongside the record data updates.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let newAvatar = UploadFile(
    ///     filename: "new-avatar.png",
    ///     data: imageData,
    ///     mimeType: "image/png"
    /// )
    ///
    /// let updated = try await collection.update(
    ///     myRecord,
    ///     files: ["avatar": [newAvatar]]
    /// )
    /// ```
    ///
    /// ## File Field Modifiers
    ///
    /// When updating records with multi-file fields, you can use special
    /// field name modifiers:
    ///
    /// - `fieldName+` - Append files to existing ones
    /// - `+fieldName` - Prepend files to existing ones
    ///
    /// ```swift
    /// // Append a new document to existing documents
    /// let updated = try await collection.update(
    ///     myRecord,
    ///     files: ["documents+": [newDocument]]
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - record: The record to update.
    ///   - files: A dictionary mapping field names to arrays of files to upload.
    /// - Returns: The updated record with new file names.
    /// - Throws: An error if the request fails.
    @Sendable
    @discardableResult
    func update(
        _ record: T,
        files: FileUploadPayload
    ) async throws -> T {
        let body = try buildMultipartBody(record: record, files: files)
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

    /// Updates a record with file uploads and file deletions.
    ///
    /// This method uses multipart/form-data encoding to upload new files
    /// and delete existing files from the record.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Upload new files and delete old ones
    /// let updated = try await collection.update(
    ///     myRecord,
    ///     files: ["documents+": [newDocument]],
    ///     deleteFiles: FileDeletePayload(["documents": ["old_file_abc123.pdf"]])
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - record: The record to update.
    ///   - files: A dictionary mapping field names to arrays of files to upload.
    ///   - deleteFiles: A payload specifying which files to delete from which fields.
    /// - Returns: The updated record.
    /// - Throws: An error if the request fails.
    @Sendable
    @discardableResult
    func update(
        _ record: T,
        files: FileUploadPayload = [:],
        deleteFiles: FileDeletePayload
    ) async throws -> T {
        var multipart = try buildMultipartBody(record: record, files: files)

        // Add file deletions using the fieldName- modifier
        for (fieldName, filenames) in deleteFiles.deletions {
            for filename in filenames {
                multipart.append(name: "\(fieldName)-", value: filename)
            }
        }

        return try await patchMultipart(
            path: PocketBase.recordPath(collection, record.id, trailingSlash: false),
            query: {
                var query: [URLQueryItem] = []
                if !T.relations.isEmpty {
                    query.append(URLQueryItem(name: "expand", value: T.relations.keys.joined(separator: ",")))
                }
                return query
            }(),
            body: multipart
        )
    }

    /// Deletes files from a record without uploading new ones.
    ///
    /// This is a convenience method for removing files from a record's file fields.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Delete specific files from a record
    /// let updated = try await collection.deleteFiles(
    ///     from: myRecord,
    ///     files: FileDeletePayload([
    ///         "documents": ["file1_abc123.pdf", "file2_def456.pdf"]
    ///     ])
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - record: The record to update.
    ///   - files: A payload specifying which files to delete from which fields.
    /// - Returns: The updated record.
    /// - Throws: An error if the request fails.
    @Sendable
    @discardableResult
    func deleteFiles(
        from record: T,
        files: FileDeletePayload
    ) async throws -> T {
        try await update(record, files: [:], deleteFiles: files)
    }

    /// Clears all files from a specific field on a record.
    ///
    /// This sets the file field to an empty value, removing all associated files.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Remove all files from the "documents" field
    /// let updated = try await collection.clearFileField(
    ///     on: myRecord,
    ///     fieldName: "documents"
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - record: The record to update.
    ///   - fieldName: The name of the file field to clear.
    /// - Returns: The updated record.
    /// - Throws: An error if the request fails.
    @Sendable
    @discardableResult
    func clearFileField(
        on record: T,
        fieldName: String
    ) async throws -> T {
        var multipart = MultipartFormData()

        // Set the file field to empty string to clear it
        multipart.append(name: fieldName, value: "")

        return try await patchMultipart(
            path: PocketBase.recordPath(collection, record.id, trailingSlash: false),
            query: {
                var query: [URLQueryItem] = []
                if !T.relations.isEmpty {
                    query.append(URLQueryItem(name: "expand", value: T.relations.keys.joined(separator: ",")))
                }
                return query
            }(),
            body: multipart
        )
    }
}

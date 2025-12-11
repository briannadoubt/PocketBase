//
//  RecordCollection+UpdateWithFiles.swift
//  PocketBase
//
//  Created by Brianna Zamora on 12/4/24.
//

import Foundation
internal import HTTPTypes

public extension RecordCollection {
    /// Updates a record while deleting specific files.
    ///
    /// Use this method when you need to delete specific files from a record's file fields.
    /// For uploading new files, use the unified API by assigning `.pending(UploadFile(...))`
    /// to `@FileField` properties and calling `update(record)`.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Delete specific files from a record
    /// let updated = try await collection.update(
    ///     myRecord,
    ///     deleteFiles: FileDeletePayload(["documents": ["old_file_abc123.pdf"]])
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - record: The record to update.
    ///   - deleteFiles: A payload specifying which files to delete from which fields.
    /// - Returns: The updated record.
    /// - Throws: An error if the request fails.
    @Sendable
    @discardableResult
    func update(
        _ record: T,
        deleteFiles: FileDeletePayload
    ) async throws -> T {
        var multipart = MultipartFormData()

        // Encode the record as JSON and add fields to multipart
        let jsonData = try encoder.encode(record, configuration: .remoteBody)
        try multipart.appendJSON(jsonData)

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

    /// Deletes files from a record.
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
        try await update(record, deleteFiles: files)
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

//
//  RecordCollection+CreateWithFiles.swift
//  PocketBase
//
//  Created by Brianna Zamora on 12/4/24.
//

import Foundation
internal import HTTPTypes

public extension RecordCollection where T: BaseRecord {
    /// Creates a new record with file uploads.
    ///
    /// This method uses multipart/form-data encoding to upload files alongside
    /// the record data. File uploads are only supported through multipart/form-data.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let imageFile = UploadFile(
    ///     filename: "avatar.png",
    ///     data: imageData,
    ///     mimeType: "image/png"
    /// )
    ///
    /// let record = try await collection.create(
    ///     myRecord,
    ///     files: ["avatar": [imageFile]]
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - record: The record to create.
    ///   - files: A dictionary mapping field names to arrays of files to upload.
    /// - Returns: The created record with server-assigned ID and file names.
    /// - Throws: An error if the request fails.
    @Sendable
    @discardableResult
    func create(
        _ record: T,
        files: FileUploadPayload
    ) async throws -> T {
        let body = try buildMultipartBody(record: record, files: files)
        return try await postMultipart(
            path: PocketBase.recordsPath(collection, trailingSlash: false),
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

public extension RecordCollection where T: AuthRecord {
    /// Creates a new auth record with file uploads.
    ///
    /// This method uses multipart/form-data encoding to upload files alongside
    /// the record data and password fields.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let avatarFile = try UploadFile(url: avatarURL)
    ///
    /// let user = try await usersCollection.create(
    ///     newUser,
    ///     password: "securePassword123",
    ///     passwordConfirm: "securePassword123",
    ///     files: ["avatar": [avatarFile]]
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - record: The auth record to create.
    ///   - password: The password for the new account.
    ///   - passwordConfirm: The password confirmation (must match password).
    ///   - files: A dictionary mapping field names to arrays of files to upload.
    /// - Returns: The created record with server-assigned ID and file names.
    /// - Throws: An error if the request fails.
    @Sendable
    @discardableResult
    func create(
        _ record: T,
        password: String,
        passwordConfirm: String,
        files: FileUploadPayload
    ) async throws -> T {
        let body = try buildMultipartBody(
            record: record,
            files: files,
            additionalFields: [
                "password": password,
                "passwordConfirm": passwordConfirm
            ]
        )
        return try await postMultipart(
            path: PocketBase.recordsPath(collection, trailingSlash: false),
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

// MARK: - Internal Helpers

extension RecordCollection {
    /// Builds a multipart/form-data body for a record with files.
    func buildMultipartBody<R: Record>(
        record: R,
        files: FileUploadPayload,
        additionalFields: [String: String] = [:]
    ) throws -> MultipartFormData where R.EncodingConfiguration == PocketBase.EncodingConfiguration {
        var multipart = MultipartFormData()

        // Encode the record as JSON and add fields to multipart
        let jsonData = try encoder.encode(record, configuration: .remoteBody)
        try multipart.appendJSON(jsonData)

        // Add additional fields (like password)
        for (name, value) in additionalFields {
            multipart.append(name: name, value: value)
        }

        // Add files
        for (fieldName, fieldFiles) in files {
            multipart.append(name: fieldName, files: fieldFiles)
        }

        return multipart
    }

    /// Builds a multipart/form-data body for updating a record with mixed existing and pending files.
    ///
    /// This method properly handles preserving existing files while adding new uploads,
    /// maintaining the original array order for mixed existing/pending file arrays.
    ///
    /// For each file field, entries are processed in order:
    /// - Existing files: sent as `fieldName` with the filename value
    /// - Pending files: sent as `fieldName` with the file data
    ///
    /// This preserves the array order so `[.existing(A), .pending(B), .existing(C)]`
    /// results in the order `[A, B, C]` on the server.
    ///
    /// - Parameters:
    ///   - record: The record being updated.
    ///   - fileFieldValues: File field entries preserving order, keyed by field name.
    /// - Returns: A MultipartFormData body ready to send.
    func buildMultipartBodyForUpdate<R: Record>(
        record: R,
        fileFieldValues: [String: [FileFieldEntry]]
    ) throws -> MultipartFormData where R.EncodingConfiguration == PocketBase.EncodingConfiguration {
        var multipart = MultipartFormData()

        // Encode the record as JSON and add fields to multipart
        let jsonData = try encoder.encode(record, configuration: .remoteBody)
        try multipart.appendJSON(jsonData)

        // Process each file field in order to preserve array ordering
        for (fieldName, entries) in fileFieldValues {
            for entry in entries {
                switch entry {
                case .existing(let filename):
                    // Send existing filename to preserve this file
                    multipart.append(name: fieldName, value: filename)
                case .pending(let upload):
                    // Send pending file data
                    multipart.append(name: fieldName, file: upload)
                }
            }
        }

        return multipart
    }

    /// Performs a POST request with multipart/form-data body.
    func postMultipart<Response: Decodable & Sendable>(
        path: String,
        query: [URLQueryItem],
        body: MultipartFormData
    ) async throws -> Response {
        var headers = headers
        headers[.contentType] = body.contentType

        var mutableBody = body
        let data = mutableBody.finalize()

        return try await post(
            path: path,
            query: query,
            headers: headers,
            body: data
        )
    }

    /// Performs a PATCH request with multipart/form-data body.
    func patchMultipart<Response: Decodable & Sendable>(
        path: String,
        query: [URLQueryItem],
        body: MultipartFormData
    ) async throws -> Response {
        var headers = headers
        headers[.contentType] = body.contentType

        var mutableBody = body
        let data = mutableBody.finalize()

        let response = try await execute(
            method: .patch,
            path: path,
            query: query,
            headers: headers,
            body: data
        )
        return try decoder.decode(Response.self, from: response)
    }
}

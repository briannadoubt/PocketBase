//
//  RecordCollection+Create.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/3/24.
//

import Foundation

public extension RecordCollection where T: BaseRecord {
    /// Creates a new collection Record.
    ///
    /// This method automatically detects pending file uploads in `@File` properties
    /// that use `FileValue` type. If any pending uploads are found, it uses multipart/form-data
    /// encoding; otherwise, it uses JSON encoding.
    ///
    /// ## Usage with FileValue (auto-detection)
    ///
    /// ```swift
    /// var post = Post(title: "My Post")
    /// post.coverImage = .pending(UploadFile(filename: "cover.png", data: imageData))
    /// let created = try await collection.create(post)  // Auto-detects, uses multipart
    /// ```
    ///
    /// ## Usage without files
    ///
    /// ```swift
    /// let post = Post(title: "Simple Post")
    /// let created = try await collection.create(post)  // Uses JSON
    /// ```
    ///
    /// - note: Depending on the collection's `createRule` value, the access to this action may or may not have been restricted.
    /// - Parameters:
    ///   - record: The collection's related schema object.
    /// - Returns: The created Record
    @Sendable
    @discardableResult
    func create(
        _ record: T
    ) async throws -> T {
        let pendingFiles = record.pendingFileUploads()

        if pendingFiles.isEmpty {
            // No pending uploads - use JSON encoding
            return try await post(
                path: PocketBase.recordsPath(collection, trailingSlash: false),
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
}

public extension RecordCollection where T: AuthRecord {
    /// Creates a new auth collection Record.
    ///
    /// This method automatically detects pending file uploads in `@File` properties
    /// that use `FileValue` type. If any pending uploads are found, it uses multipart/form-data
    /// encoding; otherwise, it uses JSON encoding.
    ///
    /// - note: Depending on the collection's `createRule` value, the access to this action may or may not have been restricted.
    /// - Parameters:
    ///   - record: The collection's related schema object.
    ///   - password: The password for the new account.
    ///   - passwordConfirm: The password confirmation (must match password).
    /// - Returns: The created Record
    @Sendable
    @discardableResult
    func create(
        _ record: T,
        password: String,
        passwordConfirm: String
    ) async throws -> T {
        let pendingFiles = record.pendingFileUploads()

        if pendingFiles.isEmpty {
            // No pending uploads - use JSON encoding
            let body = try record.createBody(
                password: password,
                passwordConfirm: passwordConfirm,
                encoder: encoder
            )
            let newAuthRecord: T = try await post(
                path: PocketBase.recordsPath(collection, trailingSlash: false),
                query: {
                    var query: [URLQueryItem] = []
                    if !T.relations.isEmpty {
                        query.append(URLQueryItem(name: "expand", value: T.relations.keys.joined(separator: ",")))
                    }
                    return query
                }(),
                headers: headers,
                body: body
            )
            return newAuthRecord
        } else {
            // Has pending uploads - use multipart encoding
            let body = try buildMultipartBody(
                record: record,
                files: pendingFiles,
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
}

extension AuthRecord {
    func createBody(
        password: String,
        passwordConfirm: String,
        encoder: JSONEncoder
    ) throws -> Data {
        let data = try encoder.encode(self, configuration: .remoteBody)
        var record = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        record["password"] = password
        record["passwordConfirm"] = passwordConfirm
        let body = try JSONSerialization.data(withJSONObject: record)
        return body
    }
}

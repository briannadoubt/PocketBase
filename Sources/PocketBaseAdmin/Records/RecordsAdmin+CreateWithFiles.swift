//
//  RecordsAdmin+CreateWithFiles.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation
import PocketBase

extension RecordsAdmin {
    /// Creates a new record with file uploads.
    ///
    /// - Parameters:
    ///   - data: The record field values.
    ///   - files: Dictionary of field names to file data arrays.
    /// - Returns: The created record.
    public func create(
        _ data: [String: JSONValue],
        files: [String: [UploadFile]]
    ) async throws -> RecordModel {
        var multipart = MultipartFormData()

        // Add regular fields
        for (key, value) in data {
            appendJSONValue(value, name: key, to: &multipart)
        }

        // Add files
        for (fieldName, fieldFiles) in files {
            for file in fieldFiles {
                multipart.append(name: fieldName, file: file)
            }
        }

        return try await postMultipart(
            path: Self.basePath(collection),
            body: multipart
        )
    }

    /// Updates a record with file uploads.
    ///
    /// - Parameters:
    ///   - id: The record ID.
    ///   - data: The record field values.
    ///   - files: Dictionary of field names to file data arrays.
    /// - Returns: The updated record.
    public func update(
        id: String,
        _ data: [String: JSONValue],
        files: [String: [UploadFile]]
    ) async throws -> RecordModel {
        var multipart = MultipartFormData()

        // Add regular fields
        for (key, value) in data {
            appendJSONValue(value, name: key, to: &multipart)
        }

        // Add files
        for (fieldName, fieldFiles) in files {
            for file in fieldFiles {
                multipart.append(name: fieldName, file: file)
            }
        }

        return try await patchMultipart(
            path: "\(Self.basePath(collection))/\(id)",
            body: multipart
        )
    }

    // MARK: - Private Helpers

    private func appendJSONValue(_ value: JSONValue, name: String, to multipart: inout MultipartFormData) {
        switch value {
        case .string(let s):
            multipart.append(name: name, value: s)
        case .int(let i):
            multipart.append(name: name, value: "\(i)")
        case .double(let d):
            multipart.append(name: name, value: "\(d)")
        case .decimal(let d):
            multipart.append(name: name, value: "\(d)")
        case .bool(let b):
            multipart.append(name: name, value: b ? "true" : "false")
        case .null:
            // Skip null values
            break
        case .url(let url):
            multipart.append(name: name, value: url.absoluteString)
        case .date(let date):
            multipart.append(name: name, value: ISO8601DateFormatter().string(from: date))
        case .array(let arr):
            for (index, item) in arr.enumerated() {
                appendJSONValue(item, name: "\(name)[\(index)]", to: &multipart)
            }
        case .dictionary(let dict):
            for (key, item) in dict {
                appendJSONValue(item, name: "\(name)[\(key)]", to: &multipart)
            }
        }
    }

    private func postMultipart<Response: Decodable & Sendable>(
        path: String,
        body: MultipartFormData
    ) async throws -> Response {
        var mutableBody = body
        let data = mutableBody.finalize()

        // Build headers with multipart content type
        var multipartHeaders: [String: String] = [
            "Content-Type": body.contentType
        ]
        if let token = pocketbase.authStore.token {
            multipartHeaders["Authorization"] = "Bearer \(token)"
        }

        let responseData = try await execute(
            method: "POST",
            path: path,
            headers: multipartHeaders,
            body: data
        )

        return try decoder.decode(Response.self, from: responseData)
    }

    private func patchMultipart<Response: Decodable & Sendable>(
        path: String,
        body: MultipartFormData
    ) async throws -> Response {
        var mutableBody = body
        let data = mutableBody.finalize()

        // Build headers with multipart content type
        var multipartHeaders: [String: String] = [
            "Content-Type": body.contentType
        ]
        if let token = pocketbase.authStore.token {
            multipartHeaders["Authorization"] = "Bearer \(token)"
        }

        let responseData = try await execute(
            method: "PATCH",
            path: path,
            headers: multipartHeaders,
            body: data
        )

        return try decoder.decode(Response.self, from: responseData)
    }
}

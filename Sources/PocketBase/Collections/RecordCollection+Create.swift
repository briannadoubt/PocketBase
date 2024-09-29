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
    /// Depending on the collection's createRule value, the access to this action may or may not have been restricted.
    ///
    /// You could find individual generated records API documentation from the admin UI.
    /// - Parameters:
    ///   - record: The collection's related schema object.
    /// - Returns: The created Record with
    @Sendable
    @discardableResult
    func create(
        _ record: T
    ) async throws -> T {
        try await post(
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
    }
}

public extension RecordCollection where T: AuthRecord {
    /// Creates a new collection Record.
    ///
    /// Depending on the collection's createRule value, the access to this action may or may not have been restricted.
    ///
    /// You could find individual generated records API documentation from the admin UI.
    /// - Parameters:
    ///   - record: The collection's related schema object.
    /// - Returns: The created Record with
    @Sendable
    @discardableResult
    func create(
        _ record: T,
        password: String,
        passwordConfirm: String
    ) async throws -> T {
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
        if let token = pocketbase.authStore.token {
            try pocketbase.authStore.set(token: token, record: newAuthRecord)
        }
        return newAuthRecord
    }
}

extension AuthRecord {
    func createBody(
        password: String,
        passwordConfirm: String,
        encoder: JSONEncoder
    ) throws -> Data {
        guard var recordData = try JSONSerialization.jsonObject(
            with: encoder.encode(self, configuration: .remoteBody)
        ) as? [String: Any] else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "The record must be serializable into a dictionary."
                )
            )
        }
        recordData["password"] = password
        recordData["passwordConfirm"] = passwordConfirm
        let body = try JSONSerialization.data(withJSONObject: recordData)
        return body
    }
}

//
//  RecordCollection+Create.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/3/24.
//

import Foundation

public extension RecordCollection {
    /// Creates a new collection Record.
    ///
    /// Depending on the collection's createRule value, the access to this action may or may not have been restricted.
    ///
    /// You could find individual generated records API documentation from the admin UI.
    /// - Parameters:
    ///   - record: The collection's related schema object.
    ///   - expand: Auto expand record relations. Ex.: `?expand=relField1,relField2.subRelField`
    ///             Supports up to 6-levels depth nested relations expansion.
    ///             The expanded relations will be appended to the record under the expand property (eg. `"expand": {"relField1": {...}, ...}`).
    ///             Only the relations to which the request user has permissions to view will be expanded.
    ///   - fields: Comma separated string of the fields to return in the JSON response (by default returns all fields). Ex.:
    ///             `?fields=*,expand.relField.name`
    ///             * targets all keys from the specific depth level.
    ///             In addition, the following field modifiers are also supported: `:excerpt(maxLength, withEllipsis?)`
    ///             Returns a short plain text version of the field string value.
    ///             Ex.: `?fields=*,description:excerpt(200,true)`
    /// - Returns: The created Record with
    @Sendable
    @discardableResult
    func create(
        _ record: T,
        expand: [String] = [],
        fields: [String] = []
    ) async throws -> T where T.EncodingConfiguration == RecordCollectionEncodingConfiguration {
        try await post(
            path: PocketBase.recordsPath(collection),
            query: {
                var query: [URLQueryItem] = []
                if !expand.isEmpty {
                    query.append(URLQueryItem(name: "expand", value: expand.joined(separator: ",")))
                }
                if !fields.isEmpty {
                    query.append(URLQueryItem(name: "fields", value: fields.joined(separator: ",")))
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
    ///   - expand: Auto expand record relations. Ex.: `?expand=relField1,relField2.subRelField`
    ///             Supports up to 6-levels depth nested relations expansion.
    ///             The expanded relations will be appended to the record under the expand property (eg. `"expand": {"relField1": {...}, ...}`).
    ///             Only the relations to which the request user has permissions to view will be expanded.
    ///   - fields: Comma separated string of the fields to return in the JSON response (by default returns all fields). Ex.:
    ///             `?fields=*,expand.relField.name`
    ///             * targets all keys from the specific depth level.
    ///             In addition, the following field modifiers are also supported: `:excerpt(maxLength, withEllipsis?)`
    ///             Returns a short plain text version of the field string value.
    ///             Ex.: `?fields=*,description:excerpt(200,true)`
    /// - Returns: The created Record with
    @Sendable
    @discardableResult
    func create(
        _ record: T,
        password: String,
        passwordConfirm: String,
        expand: [String] = [],
        fields: [String] = []
    ) async throws -> T where T.EncodingConfiguration == RecordCollectionEncodingConfiguration {
        let body = try record.createBody(
            password: password,
            passwordConfirm: passwordConfirm,
            encoder: encoder
        )
        let newAuthRecord: T = try await post(
            path: PocketBase.recordsPath(collection),
            query: {
                var query: [URLQueryItem] = []
                if !expand.isEmpty {
                    query.append(URLQueryItem(name: "expand", value: expand.joined(separator: ",")))
                }
                if !fields.isEmpty {
                    query.append(URLQueryItem(name: "fields", value: fields.joined(separator: ",")))
                }
                return query
            }(),
            headers: headers,
            body: body
        )
        if let token = pocketbase.authStore.token {
            try pocketbase.authStore.set(AuthResponse(token: token, record: newAuthRecord))
        }
        return newAuthRecord
    }
}

extension AuthRecord where EncodingConfiguration == RecordCollectionEncodingConfiguration {
    func createBody(
        password: String,
        passwordConfirm: String,
        encoder: JSONEncoder
    ) throws -> Data {
        guard var recordData = try JSONSerialization.jsonObject(
            with: encoder.encode(self, configuration: .remote)
        ) as? [String: Any] else {
            fatalError("The record must be serializable into a dictionary.")
        }
        recordData["password"] = password
        recordData["passwordConfirm"] = passwordConfirm
        let body = try JSONSerialization.data(withJSONObject: recordData)
        return body
    }
}

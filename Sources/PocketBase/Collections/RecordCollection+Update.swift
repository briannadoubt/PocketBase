//
//  RecordCollection+Update.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

import Foundation

public extension RecordCollection {
    /// Returns a single collection record by its ID.
    ///
    /// Depending on the collection's viewRule value, the access to this action may or may not have been restricted.
    ///
    /// *You could find individual generated records API documentation in the "Admin UI > Collections > API Preview".*
    /// - Parameters:
    ///   - record: The record to be updated, with the updates pre-applied.
    ///   - fields: Comma separated string of the fields to return in the JSON response (by default returns all fields). Ex.:
    ///             `?fields=*,expand.relField.name`
    ///             * targets all keys from the specific depth level.
    ///             In addition, the following field modifiers are also supported: `:excerpt(maxLength, withEllipsis?)`
    ///             Returns a short plain text version of the field string value.
    ///             Ex.: `?fields=*,description:excerpt(200,true)`
    /// - Returns: Returns a single collection record by its ID.
    @Sendable
    @discardableResult
    func update(
        _ record: T,
        fields: [String] = []
    ) async throws -> T where T.EncodingConfiguration == RecordCollectionEncodingConfiguration {
        try await patch(
            path: PocketBase.recordPath(collection, record.id),
            query: {
                var query: [URLQueryItem] = []
                if !T.relations.isEmpty {
                    query.append(URLQueryItem(name: "expand", value: T.relations.keys.joined(separator: ",")))
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

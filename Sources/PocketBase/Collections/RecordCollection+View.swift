//
//  RecordCollection+View.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/3/24.
//

import Foundation

public extension RecordCollection {
    /// Returns a single collection record by its ID.
    ///
    /// Depending on the collection's viewRule value, the access to this action may or may not have been restricted.
    ///
    /// *You could find individual generated records API documentation in the "Admin UI > Collections > API Preview".*
    /// - Parameters:
    ///   - id: ID of the record to view.
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
    /// - Returns: Returns a single collection record by its ID.
    @Sendable
    func view(
        id recordId: String,
        expand: [String] = [],
        fields: [String] = []
    ) async throws -> T {
        try await get(
            path: PocketBase.recordPath(collection, recordId),
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
            headers: headers
        )
    }
}

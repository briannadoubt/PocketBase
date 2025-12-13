//
//  RecordsAdmin+Update.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation

extension RecordsAdmin {
    /// Updates an existing record.
    ///
    /// - Parameters:
    ///   - id: The record ID.
    ///   - data: Dictionary of field values to update.
    /// - Returns: The updated record.
    @discardableResult
    public func update(id: String, _ data: [String: JSONValue]) async throws -> RecordModel {
        let body = try encoder.encode(data)
        return try await patch(path: "\(Self.basePath(collection))/\(id)", body: body)
    }

    /// Updates an existing record from an encodable object.
    ///
    /// - Parameters:
    ///   - id: The record ID.
    ///   - record: The record data to update.
    /// - Returns: The updated record.
    @discardableResult
    public func update<T: Encodable>(id: String, _ record: T) async throws -> RecordModel {
        let body = try encoder.encode(record)
        return try await patch(path: "\(Self.basePath(collection))/\(id)", body: body)
    }
}

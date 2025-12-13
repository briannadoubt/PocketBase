//
//  RecordsAdmin+Create.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation

extension RecordsAdmin {
    /// Creates a new record in the collection.
    ///
    /// - Parameter data: Dictionary of field values for the new record.
    /// - Returns: The created record.
    @discardableResult
    public func create(_ data: [String: JSONValue]) async throws -> RecordModel {
        let body = try encoder.encode(data)
        return try await post(path: Self.basePath(collection), body: body)
    }

    /// Creates a new record from an encodable object.
    ///
    /// - Parameter record: The record data to create.
    /// - Returns: The created record.
    @discardableResult
    public func create<T: Encodable>(_ record: T) async throws -> RecordModel {
        let body = try encoder.encode(record)
        return try await post(path: Self.basePath(collection), body: body)
    }
}

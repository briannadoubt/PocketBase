//
//  CollectionsAdmin+Update.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation

extension CollectionsAdmin {
    /// Updates an existing collection.
    ///
    /// - Parameters:
    ///   - id: The collection ID or name.
    ///   - collection: The updated collection schema.
    /// - Returns: The updated collection schema.
    @discardableResult
    public func update(id: String, _ collection: CollectionModel) async throws -> CollectionModel {
        let body = try encoder.encode(collection)
        return try await patch(path: "\(Self.basePath)/\(id)", body: body)
    }

    /// Updates an existing collection with partial data.
    ///
    /// - Parameters:
    ///   - id: The collection ID or name.
    ///   - request: The collection update request with fields to update.
    /// - Returns: The updated collection schema.
    @discardableResult
    public func update(id: String, _ request: CollectionUpdateRequest) async throws -> CollectionModel {
        let body = try encoder.encode(request)
        return try await patch(path: "\(Self.basePath)/\(id)", body: body)
    }
}

/// Request body for updating a collection.
public struct CollectionUpdateRequest: Codable, Sendable {
    public let name: String?
    public let schema: [Field]?
    public let listRule: String?
    public let viewRule: String?
    public let createRule: String?
    public let updateRule: String?
    public let deleteRule: String?
    public let indexes: [String]?

    public init(
        name: String? = nil,
        schema: [Field]? = nil,
        listRule: String? = nil,
        viewRule: String? = nil,
        createRule: String? = nil,
        updateRule: String? = nil,
        deleteRule: String? = nil,
        indexes: [String]? = nil
    ) {
        self.name = name
        self.schema = schema
        self.listRule = listRule
        self.viewRule = viewRule
        self.createRule = createRule
        self.updateRule = updateRule
        self.deleteRule = deleteRule
        self.indexes = indexes
    }
}

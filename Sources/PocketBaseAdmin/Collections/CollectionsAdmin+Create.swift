//
//  CollectionsAdmin+Create.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation

extension CollectionsAdmin {
    /// Creates a new collection.
    ///
    /// - Parameter collection: The collection schema to create.
    /// - Returns: The created collection schema.
    @discardableResult
    public func create(_ collection: CollectionModel) async throws -> CollectionModel {
        let body = try encoder.encode(collection)
        return try await post(path: Self.basePath, body: body)
    }

    /// Creates a new collection from a create request.
    ///
    /// - Parameter request: The collection create request.
    /// - Returns: The created collection schema.
    @discardableResult
    public func create(_ request: CollectionCreateRequest) async throws -> CollectionModel {
        let body = try encoder.encode(request)
        return try await post(path: Self.basePath, body: body)
    }
}

/// Request body for creating a new collection.
public struct CollectionCreateRequest: Codable, Sendable {
    public let name: String
    public let type: CollectionModelType
    public let schema: [Field]?
    public let listRule: String?
    public let viewRule: String?
    public let createRule: String?
    public let updateRule: String?
    public let deleteRule: String?
    public let indexes: [String]?

    public init(
        name: String,
        type: CollectionModelType = .base,
        schema: [Field]? = nil,
        listRule: String? = nil,
        viewRule: String? = nil,
        createRule: String? = nil,
        updateRule: String? = nil,
        deleteRule: String? = nil,
        indexes: [String]? = nil
    ) {
        self.name = name
        self.type = type
        self.schema = schema
        self.listRule = listRule
        self.viewRule = viewRule
        self.createRule = createRule
        self.updateRule = updateRule
        self.deleteRule = deleteRule
        self.indexes = indexes
    }
}

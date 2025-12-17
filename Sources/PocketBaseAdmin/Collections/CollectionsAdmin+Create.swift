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
    /// The collection fields. Encoded as `fields` for PocketBase 0.23+.
    public let schema: [Field]?
    public let listRule: String?
    public let viewRule: String?
    public let createRule: String?
    public let updateRule: String?
    public let deleteRule: String?
    public let indexes: [String]?

    // Auth collection specific options
    public let verificationTemplate: EmailTemplate?
    public let resetPasswordTemplate: EmailTemplate?
    public let confirmEmailChangeTemplate: EmailTemplate?
    public let authAlert: AuthAlertConfig?

    enum CodingKeys: String, CodingKey {
        case name, type
        case schema = "fields"  // PocketBase 0.23+ uses `fields`
        case listRule, viewRule, createRule, updateRule, deleteRule
        case indexes
        case verificationTemplate, resetPasswordTemplate, confirmEmailChangeTemplate, authAlert
    }

    public init(
        name: String,
        type: CollectionModelType = .base,
        schema: [Field]? = nil,
        listRule: String? = nil,
        viewRule: String? = nil,
        createRule: String? = nil,
        updateRule: String? = nil,
        deleteRule: String? = nil,
        indexes: [String]? = nil,
        verificationTemplate: EmailTemplate? = nil,
        resetPasswordTemplate: EmailTemplate? = nil,
        confirmEmailChangeTemplate: EmailTemplate? = nil,
        authAlert: AuthAlertConfig? = nil
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
        self.verificationTemplate = verificationTemplate
        self.resetPasswordTemplate = resetPasswordTemplate
        self.confirmEmailChangeTemplate = confirmEmailChangeTemplate
        self.authAlert = authAlert
    }
}

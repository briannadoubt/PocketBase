//
//  CollectionModel.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation

/// Represents a PocketBase collection schema.
public struct CollectionModel: Codable, Identifiable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let type: CollectionModelType
    public let system: Bool
    public let schema: [Field]?
    public let listRule: String?
    public let viewRule: String?
    public let createRule: String?
    public let updateRule: String?
    public let deleteRule: String?
    public let indexes: [String]?
    public let created: Date?
    public let updated: Date?

    public init(
        id: String,
        name: String,
        type: CollectionModelType,
        system: Bool = false,
        schema: [Field]? = nil,
        listRule: String? = nil,
        viewRule: String? = nil,
        createRule: String? = nil,
        updateRule: String? = nil,
        deleteRule: String? = nil,
        indexes: [String]? = nil,
        created: Date? = nil,
        updated: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.system = system
        self.schema = schema
        self.listRule = listRule
        self.viewRule = viewRule
        self.createRule = createRule
        self.updateRule = updateRule
        self.deleteRule = deleteRule
        self.indexes = indexes
        self.created = created
        self.updated = updated
    }
}

/// The type of a PocketBase collection.
public enum CollectionModelType: String, Codable, Sendable, Hashable {
    case base
    case auth
    case view
}

/// Represents a field in a collection schema.
public struct Field: Codable, Identifiable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let type: FieldType
    public let system: Bool
    public let required: Bool?
    public let presentable: Bool?
    public let options: FieldOptions?

    public init(
        id: String,
        name: String,
        type: FieldType,
        system: Bool = false,
        required: Bool? = nil,
        presentable: Bool? = nil,
        options: FieldOptions? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.system = system
        self.required = required
        self.presentable = presentable
        self.options = options
    }

    /// Convenience initializer for simpler field creation.
    public init(
        id: String,
        name: String,
        presentable: Bool,
        system: Bool,
        type: FieldType
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.system = system
        self.required = nil
        self.presentable = presentable
        self.options = nil
    }
}

/// Field type enumeration covering all PocketBase field types.
public enum FieldType: String, Codable, Sendable, Hashable {
    case text
    case editor
    case number
    case bool
    case email
    case url
    case date
    case dateTime
    case autodate
    case select
    case json
    case file
    case relation
    case password
    case customEmail = "custom_email"
}

/// Options for field configuration.
public struct FieldOptions: Codable, Sendable, Hashable {
    public let min: Int?
    public let max: Int?
    public let maxSelect: Int?
    public let maxSize: Int?
    public let values: [String]?
    public let collectionId: String?
    public let cascadeDelete: Bool?
    public let minSelect: Int?
    public let displayFields: [String]?
    public let mimeTypes: [String]?
    public let thumbs: [String]?

    public init(
        min: Int? = nil,
        max: Int? = nil,
        maxSelect: Int? = nil,
        maxSize: Int? = nil,
        values: [String]? = nil,
        collectionId: String? = nil,
        cascadeDelete: Bool? = nil,
        minSelect: Int? = nil,
        displayFields: [String]? = nil,
        mimeTypes: [String]? = nil,
        thumbs: [String]? = nil
    ) {
        self.min = min
        self.max = max
        self.maxSelect = maxSelect
        self.maxSize = maxSize
        self.values = values
        self.collectionId = collectionId
        self.cascadeDelete = cascadeDelete
        self.minSelect = minSelect
        self.displayFields = displayFields
        self.mimeTypes = mimeTypes
        self.thumbs = thumbs
    }
}

/// Response wrapper for paginated collections.
public struct CollectionsResponse: Codable, Sendable {
    public let page: Int
    public let perPage: Int
    public let totalItems: Int
    public let totalPages: Int
    public let items: [CollectionModel]

    public init(
        page: Int = 1,
        perPage: Int = 30,
        totalItems: Int = 0,
        totalPages: Int = 0,
        items: [CollectionModel] = []
    ) {
        self.page = page
        self.perPage = perPage
        self.totalItems = totalItems
        self.totalPages = totalPages
        self.items = items
    }
}

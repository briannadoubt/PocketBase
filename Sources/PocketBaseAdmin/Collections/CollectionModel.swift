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
    /// The collection fields. Named `fields` in PocketBase 0.23+, `schema` in older versions.
    public let fields: [Field]?
    public let listRule: String?
    public let viewRule: String?
    public let createRule: String?
    public let updateRule: String?
    public let deleteRule: String?
    public let indexes: [String]?
    public let created: Date?
    public let updated: Date?

    // Auth collection specific options
    public let verificationTemplate: EmailTemplate?
    public let resetPasswordTemplate: EmailTemplate?
    public let confirmEmailChangeTemplate: EmailTemplate?
    public let authAlert: AuthAlertConfig?

    /// Backwards compatibility alias for `fields`
    public var schema: [Field]? { fields }

    public init(
        id: String,
        name: String,
        type: CollectionModelType,
        system: Bool = false,
        fields: [Field]? = nil,
        listRule: String? = nil,
        viewRule: String? = nil,
        createRule: String? = nil,
        updateRule: String? = nil,
        deleteRule: String? = nil,
        indexes: [String]? = nil,
        created: Date? = nil,
        updated: Date? = nil,
        verificationTemplate: EmailTemplate? = nil,
        resetPasswordTemplate: EmailTemplate? = nil,
        confirmEmailChangeTemplate: EmailTemplate? = nil,
        authAlert: AuthAlertConfig? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.system = system
        self.fields = fields
        self.listRule = listRule
        self.viewRule = viewRule
        self.createRule = createRule
        self.updateRule = updateRule
        self.deleteRule = deleteRule
        self.indexes = indexes
        self.created = created
        self.updated = updated
        self.verificationTemplate = verificationTemplate
        self.resetPasswordTemplate = resetPasswordTemplate
        self.confirmEmailChangeTemplate = confirmEmailChangeTemplate
        self.authAlert = authAlert
    }

    enum CodingKeys: String, CodingKey {
        case id, name, type, system, fields, schema
        case listRule, viewRule, createRule, updateRule, deleteRule
        case indexes, created, updated
        case verificationTemplate, resetPasswordTemplate, confirmEmailChangeTemplate, authAlert
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(CollectionModelType.self, forKey: .type)
        system = try container.decodeIfPresent(Bool.self, forKey: .system) ?? false
        // Try `fields` first (PocketBase 0.23+), fallback to `schema` (older versions)
        fields = try container.decodeIfPresent([Field].self, forKey: .fields)
            ?? container.decodeIfPresent([Field].self, forKey: .schema)
        listRule = try container.decodeIfPresent(String.self, forKey: .listRule)
        viewRule = try container.decodeIfPresent(String.self, forKey: .viewRule)
        createRule = try container.decodeIfPresent(String.self, forKey: .createRule)
        updateRule = try container.decodeIfPresent(String.self, forKey: .updateRule)
        deleteRule = try container.decodeIfPresent(String.self, forKey: .deleteRule)
        indexes = try container.decodeIfPresent([String].self, forKey: .indexes)
        created = try container.decodeIfPresent(Date.self, forKey: .created)
        updated = try container.decodeIfPresent(Date.self, forKey: .updated)
        verificationTemplate = try container.decodeIfPresent(EmailTemplate.self, forKey: .verificationTemplate)
        resetPasswordTemplate = try container.decodeIfPresent(EmailTemplate.self, forKey: .resetPasswordTemplate)
        confirmEmailChangeTemplate = try container.decodeIfPresent(EmailTemplate.self, forKey: .confirmEmailChangeTemplate)
        authAlert = try container.decodeIfPresent(AuthAlertConfig.self, forKey: .authAlert)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(system, forKey: .system)
        try container.encodeIfPresent(fields, forKey: .fields)
        try container.encodeIfPresent(listRule, forKey: .listRule)
        try container.encodeIfPresent(viewRule, forKey: .viewRule)
        try container.encodeIfPresent(createRule, forKey: .createRule)
        try container.encodeIfPresent(updateRule, forKey: .updateRule)
        try container.encodeIfPresent(deleteRule, forKey: .deleteRule)
        try container.encodeIfPresent(indexes, forKey: .indexes)
        try container.encodeIfPresent(created, forKey: .created)
        try container.encodeIfPresent(updated, forKey: .updated)
        try container.encodeIfPresent(verificationTemplate, forKey: .verificationTemplate)
        try container.encodeIfPresent(resetPasswordTemplate, forKey: .resetPasswordTemplate)
        try container.encodeIfPresent(confirmEmailChangeTemplate, forKey: .confirmEmailChangeTemplate)
        try container.encodeIfPresent(authAlert, forKey: .authAlert)
    }
}

/// Email template configuration for auth collections.
public struct EmailTemplate: Codable, Sendable, Hashable {
    public var subject: String
    public var body: String

    public init(subject: String = "", body: String = "") {
        self.subject = subject
        self.body = body
    }
}

/// Auth alert configuration for notifying users of new logins.
public struct AuthAlertConfig: Codable, Sendable, Hashable {
    public var enabled: Bool?
    public var emailTemplate: EmailTemplate?

    public init(enabled: Bool? = nil, emailTemplate: EmailTemplate? = nil) {
        self.enabled = enabled
        self.emailTemplate = emailTemplate
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(FieldType.self, forKey: .type)
        system = try container.decodeIfPresent(Bool.self, forKey: .system) ?? false
        required = try container.decodeIfPresent(Bool.self, forKey: .required)
        presentable = try container.decodeIfPresent(Bool.self, forKey: .presentable)
        options = try container.decodeIfPresent(FieldOptions.self, forKey: .options)
    }

    enum CodingKeys: String, CodingKey {
        case id, name, type, system, required, presentable, options
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

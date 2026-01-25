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

    // View collection specific options
    /// The SQL query for view collections. Only applicable when type is .view.
    public let viewQuery: String?

    // Auth collection specific options
    public let verificationTemplate: EmailTemplate?
    public let resetPasswordTemplate: EmailTemplate?
    public let confirmEmailChangeTemplate: EmailTemplate?
    public let authAlert: AuthAlertConfig?

    // Auth-specific configuration
    public let oauth2: OAuth2Config?
    public let passwordAuth: PasswordAuthConfig?
    public let mfa: MFAConfig?
    public let otp: OTPConfig?

    // Auth rules
    public let manageRule: String?
    public let authRule: String?

    // Token configurations
    public let authToken: TokenConfig?
    public let passwordResetToken: TokenConfig?
    public let emailChangeToken: TokenConfig?
    public let verificationToken: TokenConfig?
    public let fileToken: TokenConfig?

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
        viewQuery: String? = nil,
        verificationTemplate: EmailTemplate? = nil,
        resetPasswordTemplate: EmailTemplate? = nil,
        confirmEmailChangeTemplate: EmailTemplate? = nil,
        authAlert: AuthAlertConfig? = nil,
        oauth2: OAuth2Config? = nil,
        passwordAuth: PasswordAuthConfig? = nil,
        mfa: MFAConfig? = nil,
        otp: OTPConfig? = nil,
        manageRule: String? = nil,
        authRule: String? = nil,
        authToken: TokenConfig? = nil,
        passwordResetToken: TokenConfig? = nil,
        emailChangeToken: TokenConfig? = nil,
        verificationToken: TokenConfig? = nil,
        fileToken: TokenConfig? = nil
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
        self.viewQuery = viewQuery
        self.verificationTemplate = verificationTemplate
        self.resetPasswordTemplate = resetPasswordTemplate
        self.confirmEmailChangeTemplate = confirmEmailChangeTemplate
        self.authAlert = authAlert
        self.oauth2 = oauth2
        self.passwordAuth = passwordAuth
        self.mfa = mfa
        self.otp = otp
        self.manageRule = manageRule
        self.authRule = authRule
        self.authToken = authToken
        self.passwordResetToken = passwordResetToken
        self.emailChangeToken = emailChangeToken
        self.verificationToken = verificationToken
        self.fileToken = fileToken
    }

    enum CodingKeys: String, CodingKey {
        case id, name, type, system, fields, schema
        case listRule, viewRule, createRule, updateRule, deleteRule
        case indexes, created, updated, viewQuery
        case verificationTemplate, resetPasswordTemplate, confirmEmailChangeTemplate, authAlert
        case oauth2, passwordAuth, mfa, otp
        case manageRule, authRule
        case authToken, passwordResetToken, emailChangeToken, verificationToken, fileToken
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
        viewQuery = try container.decodeIfPresent(String.self, forKey: .viewQuery)
        verificationTemplate = try container.decodeIfPresent(EmailTemplate.self, forKey: .verificationTemplate)
        resetPasswordTemplate = try container.decodeIfPresent(EmailTemplate.self, forKey: .resetPasswordTemplate)
        confirmEmailChangeTemplate = try container.decodeIfPresent(EmailTemplate.self, forKey: .confirmEmailChangeTemplate)
        authAlert = try container.decodeIfPresent(AuthAlertConfig.self, forKey: .authAlert)

        // Auth configuration
        oauth2 = try container.decodeIfPresent(OAuth2Config.self, forKey: .oauth2)
        passwordAuth = try container.decodeIfPresent(PasswordAuthConfig.self, forKey: .passwordAuth)
        mfa = try container.decodeIfPresent(MFAConfig.self, forKey: .mfa)
        otp = try container.decodeIfPresent(OTPConfig.self, forKey: .otp)

        // Auth rules
        manageRule = try container.decodeIfPresent(String.self, forKey: .manageRule)
        authRule = try container.decodeIfPresent(String.self, forKey: .authRule)

        // Token configs
        authToken = try container.decodeIfPresent(TokenConfig.self, forKey: .authToken)
        passwordResetToken = try container.decodeIfPresent(TokenConfig.self, forKey: .passwordResetToken)
        emailChangeToken = try container.decodeIfPresent(TokenConfig.self, forKey: .emailChangeToken)
        verificationToken = try container.decodeIfPresent(TokenConfig.self, forKey: .verificationToken)
        fileToken = try container.decodeIfPresent(TokenConfig.self, forKey: .fileToken)
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
        try container.encodeIfPresent(viewQuery, forKey: .viewQuery)
        try container.encodeIfPresent(verificationTemplate, forKey: .verificationTemplate)
        try container.encodeIfPresent(resetPasswordTemplate, forKey: .resetPasswordTemplate)
        try container.encodeIfPresent(confirmEmailChangeTemplate, forKey: .confirmEmailChangeTemplate)
        try container.encodeIfPresent(authAlert, forKey: .authAlert)

        // Auth configuration
        try container.encodeIfPresent(oauth2, forKey: .oauth2)
        try container.encodeIfPresent(passwordAuth, forKey: .passwordAuth)
        try container.encodeIfPresent(mfa, forKey: .mfa)
        try container.encodeIfPresent(otp, forKey: .otp)

        // Auth rules
        try container.encodeIfPresent(manageRule, forKey: .manageRule)
        try container.encodeIfPresent(authRule, forKey: .authRule)

        // Token configs
        try container.encodeIfPresent(authToken, forKey: .authToken)
        try container.encodeIfPresent(passwordResetToken, forKey: .passwordResetToken)
        try container.encodeIfPresent(emailChangeToken, forKey: .emailChangeToken)
        try container.encodeIfPresent(verificationToken, forKey: .verificationToken)
        try container.encodeIfPresent(fileToken, forKey: .fileToken)
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
/// PocketBase 0.23+ uses flat field options instead of nested `options` object.
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

    enum CodingKeys: String, CodingKey {
        case id, name, type, system, required, presentable
        // Legacy nested options (for reading older format)
        case options
        // Flat options for PocketBase 0.23+
        case min, max, maxSelect, maxSize, values, collectionId
        case cascadeDelete, minSelect, displayFields, mimeTypes, thumbs
        // Autodate options
        case onCreate, onUpdate
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(FieldType.self, forKey: .type)
        system = try container.decodeIfPresent(Bool.self, forKey: .system) ?? false
        required = try container.decodeIfPresent(Bool.self, forKey: .required)
        presentable = try container.decodeIfPresent(Bool.self, forKey: .presentable)

        // Try legacy nested options first, then flat options (PocketBase 0.23+)
        if let nestedOptions = try container.decodeIfPresent(FieldOptions.self, forKey: .options) {
            options = nestedOptions
        } else {
            // Read flat options (PocketBase 0.23+)
            let min = try container.decodeIfPresent(Int.self, forKey: .min)
            let max = try container.decodeIfPresent(Int.self, forKey: .max)
            let maxSelect = try container.decodeIfPresent(Int.self, forKey: .maxSelect)
            let maxSize = try container.decodeIfPresent(Int.self, forKey: .maxSize)
            let values = try container.decodeIfPresent([String].self, forKey: .values)
            let collectionId = try container.decodeIfPresent(String.self, forKey: .collectionId)
            let cascadeDelete = try container.decodeIfPresent(Bool.self, forKey: .cascadeDelete)
            let minSelect = try container.decodeIfPresent(Int.self, forKey: .minSelect)
            let displayFields = try container.decodeIfPresent([String].self, forKey: .displayFields)
            let mimeTypes = try container.decodeIfPresent([String].self, forKey: .mimeTypes)
            let thumbs = try container.decodeIfPresent([String].self, forKey: .thumbs)
            let onCreate = try container.decodeIfPresent(Bool.self, forKey: .onCreate)
            let onUpdate = try container.decodeIfPresent(Bool.self, forKey: .onUpdate)

            // Only create options if at least one property is set
            if min != nil || max != nil || maxSelect != nil || maxSize != nil ||
               values != nil || collectionId != nil || cascadeDelete != nil ||
               minSelect != nil || displayFields != nil || mimeTypes != nil || thumbs != nil ||
               onCreate != nil || onUpdate != nil {
                options = FieldOptions(
                    min: min, max: max, maxSelect: maxSelect, maxSize: maxSize,
                    values: values, collectionId: collectionId, cascadeDelete: cascadeDelete,
                    minSelect: minSelect, displayFields: displayFields, mimeTypes: mimeTypes, thumbs: thumbs,
                    onCreate: onCreate, onUpdate: onUpdate
                )
            } else {
                options = nil
            }
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(system, forKey: .system)
        try container.encodeIfPresent(required, forKey: .required)
        try container.encodeIfPresent(presentable, forKey: .presentable)

        // Encode options as flat properties (PocketBase 0.23+)
        if let options = options {
            try container.encodeIfPresent(options.min, forKey: .min)
            try container.encodeIfPresent(options.max, forKey: .max)
            try container.encodeIfPresent(options.maxSelect, forKey: .maxSelect)
            try container.encodeIfPresent(options.maxSize, forKey: .maxSize)
            try container.encodeIfPresent(options.values, forKey: .values)
            try container.encodeIfPresent(options.collectionId, forKey: .collectionId)
            try container.encodeIfPresent(options.cascadeDelete, forKey: .cascadeDelete)
            try container.encodeIfPresent(options.minSelect, forKey: .minSelect)
            try container.encodeIfPresent(options.displayFields, forKey: .displayFields)
            try container.encodeIfPresent(options.mimeTypes, forKey: .mimeTypes)
            try container.encodeIfPresent(options.thumbs, forKey: .thumbs)
            try container.encodeIfPresent(options.onCreate, forKey: .onCreate)
            try container.encodeIfPresent(options.onUpdate, forKey: .onUpdate)
        }
    }
}

/// Field type enumeration covering all PocketBase field types.
public enum FieldType: Codable, Sendable, Hashable {
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
    case customEmail
    case primaryKey
    case geoPoint
    case unknown(String)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        switch rawValue {
        case "text": self = .text
        case "editor": self = .editor
        case "number": self = .number
        case "bool": self = .bool
        case "email": self = .email
        case "url": self = .url
        case "date": self = .date
        case "dateTime": self = .dateTime
        case "autodate": self = .autodate
        case "select": self = .select
        case "json": self = .json
        case "file": self = .file
        case "relation": self = .relation
        case "password": self = .password
        case "custom_email": self = .customEmail
        case "primaryKey": self = .primaryKey
        case "geoPoint": self = .geoPoint
        default: self = .unknown(rawValue)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text: try container.encode("text")
        case .editor: try container.encode("editor")
        case .number: try container.encode("number")
        case .bool: try container.encode("bool")
        case .email: try container.encode("email")
        case .url: try container.encode("url")
        case .date: try container.encode("date")
        case .dateTime: try container.encode("dateTime")
        case .autodate: try container.encode("autodate")
        case .select: try container.encode("select")
        case .json: try container.encode("json")
        case .file: try container.encode("file")
        case .relation: try container.encode("relation")
        case .password: try container.encode("password")
        case .customEmail: try container.encode("custom_email")
        case .primaryKey: try container.encode("primaryKey")
        case .geoPoint: try container.encode("geoPoint")
        case .unknown(let value): try container.encode(value)
        }
    }

    /// String representation for display purposes
    public var rawValue: String {
        switch self {
        case .text: return "text"
        case .editor: return "editor"
        case .number: return "number"
        case .bool: return "bool"
        case .email: return "email"
        case .url: return "url"
        case .date: return "date"
        case .dateTime: return "dateTime"
        case .autodate: return "autodate"
        case .select: return "select"
        case .json: return "json"
        case .file: return "file"
        case .relation: return "relation"
        case .password: return "password"
        case .customEmail: return "custom_email"
        case .primaryKey: return "primaryKey"
        case .geoPoint: return "geoPoint"
        case .unknown(let value): return value
        }
    }
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
    /// For autodate fields: set date on record creation
    public let onCreate: Bool?
    /// For autodate fields: set date on record update
    public let onUpdate: Bool?

    enum CodingKeys: String, CodingKey {
        case min, max, maxSelect, maxSize, values, collectionId, cascadeDelete
        case minSelect, displayFields, mimeTypes, thumbs, onCreate, onUpdate
    }

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
        thumbs: [String]? = nil,
        onCreate: Bool? = nil,
        onUpdate: Bool? = nil
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
        self.onCreate = onCreate
        self.onUpdate = onUpdate
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Helper to decode Int from either Int or String
        func decodeFlexibleInt(forKey key: CodingKeys) throws -> Int? {
            if let intValue = try? container.decodeIfPresent(Int.self, forKey: key) {
                return intValue
            }
            if let stringValue = try? container.decodeIfPresent(String.self, forKey: key),
               let intValue = Int(stringValue) {
                return intValue
            }
            return nil
        }

        self.min = try decodeFlexibleInt(forKey: .min)
        self.max = try decodeFlexibleInt(forKey: .max)
        self.maxSelect = try decodeFlexibleInt(forKey: .maxSelect)
        self.maxSize = try decodeFlexibleInt(forKey: .maxSize)
        self.minSelect = try decodeFlexibleInt(forKey: .minSelect)

        self.values = try container.decodeIfPresent([String].self, forKey: .values)
        self.collectionId = try container.decodeIfPresent(String.self, forKey: .collectionId)
        self.cascadeDelete = try container.decodeIfPresent(Bool.self, forKey: .cascadeDelete)
        self.displayFields = try container.decodeIfPresent([String].self, forKey: .displayFields)
        self.mimeTypes = try container.decodeIfPresent([String].self, forKey: .mimeTypes)
        self.thumbs = try container.decodeIfPresent([String].self, forKey: .thumbs)
        self.onCreate = try container.decodeIfPresent(Bool.self, forKey: .onCreate)
        self.onUpdate = try container.decodeIfPresent(Bool.self, forKey: .onUpdate)
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

// MARK: - OAuth2 Configuration

/// OAuth2 provider configuration
public struct OAuth2ProviderConfig: Codable, Sendable, Hashable {
    public var name: String
    public var clientId: String
    public var clientSecret: String
    public var authURL: String?
    public var tokenURL: String?
    public var userInfoURL: String?
    public var displayName: String?
    public var pkce: Bool?
    public var extra: [String: String]?

    enum CodingKeys: String, CodingKey {
        case name, clientId, clientSecret, displayName, pkce, extra
        case authURL = "authUrl"
        case tokenURL = "tokenUrl"
        case userInfoURL = "userInfoUrl"
    }

    public init(
        name: String,
        clientId: String,
        clientSecret: String,
        authURL: String? = nil,
        tokenURL: String? = nil,
        userInfoURL: String? = nil,
        displayName: String? = nil,
        pkce: Bool? = nil,
        extra: [String: String]? = nil
    ) {
        self.name = name
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.authURL = authURL
        self.tokenURL = tokenURL
        self.userInfoURL = userInfoURL
        self.displayName = displayName
        self.pkce = pkce
        self.extra = extra
    }
}

/// OAuth2 field mapping configuration
public struct OAuth2MappedFields: Codable, Sendable, Hashable {
    public var id: String?
    public var name: String?
    public var username: String?
    public var avatarURL: String?

    enum CodingKeys: String, CodingKey {
        case id, name, username
        case avatarURL = "avatarUrl"
    }

    public init(
        id: String? = nil,
        name: String? = nil,
        username: String? = nil,
        avatarURL: String? = nil
    ) {
        self.id = id
        self.name = name
        self.username = username
        self.avatarURL = avatarURL
    }
}

/// OAuth2 authentication configuration
public struct OAuth2Config: Codable, Sendable, Hashable {
    public var enabled: Bool?
    public var mappedFields: OAuth2MappedFields?
    public var providers: [OAuth2ProviderConfig]?

    public init(
        enabled: Bool? = nil,
        mappedFields: OAuth2MappedFields? = nil,
        providers: [OAuth2ProviderConfig]? = nil
    ) {
        self.enabled = enabled
        self.mappedFields = mappedFields
        self.providers = providers
    }
}

// MARK: - Other Auth Options

/// Password authentication configuration
public struct PasswordAuthConfig: Codable, Sendable, Hashable {
    public var enabled: Bool?
    public var identityFields: [String]?

    public init(
        enabled: Bool? = nil,
        identityFields: [String]? = nil
    ) {
        self.enabled = enabled
        self.identityFields = identityFields
    }
}

/// MFA configuration
public struct MFAConfig: Codable, Sendable, Hashable {
    public var enabled: Bool?
    public var duration: Int?
    public var rule: String?

    public init(
        enabled: Bool? = nil,
        duration: Int? = nil,
        rule: String? = nil
    ) {
        self.enabled = enabled
        self.duration = duration
        self.rule = rule
    }
}

/// OTP configuration
public struct OTPConfig: Codable, Sendable, Hashable {
    public var enabled: Bool?
    public var duration: Int?
    public var length: Int?
    public var emailTemplate: EmailTemplate?

    public init(
        enabled: Bool? = nil,
        duration: Int? = nil,
        length: Int? = nil,
        emailTemplate: EmailTemplate? = nil
    ) {
        self.enabled = enabled
        self.duration = duration
        self.length = length
        self.emailTemplate = emailTemplate
    }
}

/// Token configuration with duration and secret
public struct TokenConfig: Codable, Sendable, Hashable {
    public var duration: Int?
    public var secret: String?

    public init(
        duration: Int? = nil,
        secret: String? = nil
    ) {
        self.duration = duration
        self.secret = secret
    }
}

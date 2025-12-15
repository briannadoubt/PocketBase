//
//  RecordModel.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation

/// A generic record model for admin API access.
///
/// Unlike typed Record models, RecordModel provides dynamic field access
/// through JSONValue, suitable for admin interfaces that display arbitrary collections.
public struct RecordModel: Codable, Identifiable, Sendable, Hashable {
    public let id: String
    public let collectionId: String
    public let collectionName: String
    public let created: Date?
    public let updated: Date?
    public let content: [String: JSONValue]
    public let expand: [String: JSONValue]?

    public init(
        id: String,
        collectionId: String,
        collectionName: String,
        created: Date? = nil,
        updated: Date? = nil,
        content: [String: JSONValue] = [:],
        expand: [String: JSONValue]? = nil
    ) {
        self.id = id
        self.collectionId = collectionId
        self.collectionName = collectionName
        self.created = created
        self.updated = updated
        self.content = content
        self.expand = expand
    }

    enum CodingKeys: String, CodingKey {
        case id
        case collectionId
        case collectionName
        case created
        case updated
        case expand
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(String.self, forKey: .id)
        self.collectionId = try container.decode(String.self, forKey: .collectionId)
        self.collectionName = try container.decode(String.self, forKey: .collectionName)
        self.created = try container.decodeIfPresent(Date.self, forKey: .created)
        self.updated = try container.decodeIfPresent(Date.self, forKey: .updated)
        self.expand = try container.decodeIfPresent([String: JSONValue].self, forKey: .expand)

        // Decode all other fields into content
        let allContainer = try decoder.container(keyedBy: DynamicCodingKey.self)
        var content: [String: JSONValue] = [:]

        let reservedKeys = Set(CodingKeys.allCases.map(\.stringValue))
        for key in allContainer.allKeys {
            guard !reservedKeys.contains(key.stringValue) else { continue }
            if let value = try? allContainer.decode(JSONValue.self, forKey: key) {
                content[key.stringValue] = value
            }
        }

        self.content = content
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(collectionId, forKey: .collectionId)
        try container.encode(collectionName, forKey: .collectionName)
        try container.encodeIfPresent(created, forKey: .created)
        try container.encodeIfPresent(updated, forKey: .updated)
        try container.encodeIfPresent(expand, forKey: .expand)

        var dynamicContainer = encoder.container(keyedBy: DynamicCodingKey.self)
        for (key, value) in content {
            try dynamicContainer.encode(value, forKey: DynamicCodingKey(stringValue: key)!)
        }
    }
}

extension RecordModel.CodingKeys: CaseIterable {}

/// Dynamic coding key for arbitrary field access.
struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

/// A JSON value that can represent any JSON type.
public enum JSONValue: Codable, Sendable, Hashable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case decimal(Decimal)
    case string(String)
    case url(URL)
    case date(Date)
    case array([JSONValue])
    case dictionary([String: JSONValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let string = try? container.decode(String.self) {
            // Try to parse as date
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS'Z'"
            formatter.timeZone = TimeZone(identifier: "UTC")
            formatter.locale = Locale(identifier: "en_US_POSIX")
            if let date = formatter.date(from: string) {
                self = .date(date)
            } else if let url = URL(string: string), url.scheme != nil {
                self = .url(url)
            } else {
                self = .string(string)
            }
        } else if let array = try? container.decode([JSONValue].self) {
            self = .array(array)
        } else if let dictionary = try? container.decode([String: JSONValue].self) {
            self = .dictionary(dictionary)
        } else {
            throw DecodingError.typeMismatch(
                JSONValue.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unable to decode JSONValue"
                )
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .decimal(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .url(let value):
            try container.encode(value.absoluteString)
        case .date(let value):
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS'Z'"
            try container.encode(formatter.string(from: value))
        case .array(let value):
            try container.encode(value)
        case .dictionary(let value):
            try container.encode(value)
        }
    }
}

// MARK: - Convenience Accessors

public extension RecordModel {
    /// Convenience accessor for email field (common in auth collections).
    var email: JSONValue? {
        content["email"]
    }

    /// Convenience accessor for username field (common in auth collections).
    var username: JSONValue? {
        content["username"]
    }

    /// Convenience accessor for verified field (common in auth collections).
    var verified: JSONValue? {
        content["verified"]
    }

    /// Convenience accessor for emailVisibility field (common in auth collections).
    var emailVisibility: JSONValue? {
        content["emailVisibility"]
    }

    /// Subscript for dynamic field access via JSONValue.
    subscript(field: String) -> JSONValue? {
        content[field]
    }
}

/// Response wrapper for paginated records.
public struct RecordsResponse: Codable, Sendable {
    public let page: Int
    public let perPage: Int
    public let totalItems: Int
    public let totalPages: Int
    public let items: [RecordModel]

    public init(
        page: Int = 1,
        perPage: Int = 30,
        totalItems: Int = 0,
        totalPages: Int = 0,
        items: [RecordModel] = []
    ) {
        self.page = page
        self.perPage = perPage
        self.totalItems = totalItems
        self.totalPages = totalPages
        self.items = items
    }
}

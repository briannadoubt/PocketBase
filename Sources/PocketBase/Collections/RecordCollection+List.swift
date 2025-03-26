//
//  RecordCollection+List.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/3/24.
//

import Foundation
import Collections

public extension RecordCollection {
    /// Returns a paginated records list, supporting sorting and filtering.
    ///
    /// - note: Depending on the collection's `listRule` value, the access to this action may or may not have been restricted.
    /// - Parameters:
    ///   - page: The page (aka. offset) of the paginated list _(default to 1 on the server)_.
    ///   - perPage: The max returned records per page _(default to 30 on the server)_.
    ///   - sort: Specify the ORDER BY fields.
    ///   - filter: Filter expression to filter/search the returned records list (in addition to the collection's listRule), eg.: `?filter=(title~'abc' && created>'2022-01-01')`
    ///             Supported record filter fields:
    ///             `id`, `created`, `updated`, + any field from the collection schema.
    ///             The syntax basically follows the format `OPERAND OPERATOR OPERAND`, where:
    ///             `OPERAND` - could be any of the above field literal, `string` (single or double quoted), `number`, `null`, `true`, `false`
    ///             `OPERATOR` - is one of:
    ///             `=` Equal
    ///             `!=` NOT equal
    ///             `>` Greater than
    ///             `>=` Greater than or equal
    ///             `<` Less than
    ///             `<=` Less than or equal
    ///             `~` Like/Contains (if not specified auto wraps the right string OPERAND in a "%" for wildcard match)
    ///             `!~` NOT Like/Contains (if not specified auto wraps the right string OPERAND in a "%" for wildcard match)
    ///             `?=` Any/At least one of Equal
    ///             `?!=` Any/At least one of NOT equal
    ///             `?>` Any/At least one of Greater than
    ///             `?>=` Any/At least one of Greater than or equal
    ///             `?<` Any/At least one of Less than
    ///             `?<=` Any/At least one of Less than or equal
    ///             `?~` Any/At least one of Like/Contains (if not specified auto wraps the right string OPERAND in a "%" for wildcard match)
    ///             `?!~` Any/At least one of NOT Like/Contains (if not specified auto wraps the right string OPERAND in a "%" for wildcard match)
    ///             To group and combine several expressions you could use parenthesis `(...)`, `&&` (AND) and `||` (OR) tokens.
    ///             Single line comments are also supported: `// Example comment`.
    /// - Returns: An array of records.
    func list(
        page: Int? = nil,
        perPage: Int? = nil,
        sort: [SortDescriptor<T>] = [],
        filter: Filter? = nil
    ) async throws -> ListResponse {
        try await client.get(
            path: PocketBase.recordsPath(collection, trailingSlash: false),
            query: {
                var query: [URLQueryItem] = []
                if let page {
                    query.append(URLQueryItem(name: "page", value: "\(page)"))
                }
                if let perPage {
                    query.append(URLQueryItem(name: "perPage", value: "\(perPage)"))
                }
                if !sort.isEmpty {
                    query.append(URLQueryItem(name: "sort", value: sort.sortParameter()))
                }
                if let filter {
                    query.append(URLQueryItem(name: "filter", value: filter.rawValue))
                }
                if !T.relations.isEmpty {
                    query.append(URLQueryItem(name: "expand", value: T.relations.keys.joined(separator: ",")))
                }
                return query
            }(),
            headers: client.headers
        )
    }
    
    struct ListResponse: Decodable, EncodableWithConfiguration, Sendable, Equatable {
        public typealias EncodingConfiguration = PocketBase.EncodingConfiguration
        
        public var page: Int
        public var perPage: Int
        public var totalItems: Int
        public var totalPages: Int
        public var items: [T]
        
        public init(
            page: Int = 0,
            perPage: Int = 30,
            totalItems: Int = 0,
            totalPages: Int = 0,
            items: [T] = []
        ) {
            self.page = page
            self.perPage = perPage
            self.totalItems = totalItems
            self.totalPages = totalPages
            self.items = items
        }
        
        enum CodingKeys: String, CodingKey {
            case page
            case perPage
            case totalItems
            case totalPages
            case items
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.page = try container.decode(Int.self, forKey: .page)
            self.perPage = try container.decode(Int.self, forKey: .perPage)
            self.totalItems = try container.decode(Int.self, forKey: .totalItems)
            self.totalPages = Int(ceil(Double(totalItems) / Double(perPage)))
            self.items = try container.decode([T].self, forKey: .items)
        }
        
        public func encode(to encoder: any Encoder, configuration: PocketBase.EncodingConfiguration) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.page, forKey: .page)
            try container.encode(self.perPage, forKey: .perPage)
            try container.encode(self.totalItems, forKey: .totalItems)
            try container.encode(self.totalPages, forKey: .totalPages)
            try container.encode(self.items, forKey: .items, configuration: configuration)
        }
    }
}

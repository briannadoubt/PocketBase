//
//  Sort.swift
//  PocketBase
//
//  Created by Bri on 9/18/22.
//

import Foundation

public struct Sort {
    var order: SortOrder = .ascending
    var key: String
    var queryValue: String {
        switch order {
        case .ascending:
            return key
        case .descending:
            return "-" + key
        }
    }
}

public enum SortOrder {
    case ascending
    case descending
}

public enum SortKey {
    case id
    case created
    case updated
    case custom(key: String)
    
    var string: String {
        switch self {
        case .id:
            return "id"
        case .created:
            return "created"
        case .updated:
            return "updated"
        case .custom(let key):
            return key
        }
    }
}

@resultBuilder public struct SortQuery {
    static func buildBlock(_ sort: Sort...) -> [Sort] {
        sort
    }
}

public extension Array where Element == Sort {
    var query: String {
        "sort=" + self.map(\.queryValue).joined(separator: ",")
    }
}

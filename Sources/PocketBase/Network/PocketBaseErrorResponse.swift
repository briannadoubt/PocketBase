//
//  PocketBaseErrorResponse.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

import Foundation

public struct PocketBaseErrorResponse: Decodable, Sendable, Equatable {
    public var code: Int
    public var message: String
    public var errorDetails: String?
    /// Field-specific validation errors
    public var data: [String: FieldError]?

    /// Formatted string of all validation errors
    public var formattedErrors: String {
        var parts: [String] = [message]
        if let details = errorDetails, !details.isEmpty {
            parts.append(details)
        }
        if let data = data {
            let fieldErrors = data.map { "\($0.key): \($0.value.message)" }
            if !fieldErrors.isEmpty {
                parts.append(contentsOf: fieldErrors)
            }
        }
        return parts.joined(separator: "; ")
    }

    public struct FieldError: Decodable, Sendable, Equatable {
        public var code: String
        public var message: String
    }
}

//
//  Identifier.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/11/24.
//

import Foundation

@propertyWrapper
public struct Identifier: Codable, Hashable, Sendable, Identifiable, RawRepresentable {
    static let id = UUID().uuidString
    
    public var id: String = Self.id
    
    public var wrappedValue: String { id }
    
    public init?(rawValue: String) {
        self.id = rawValue
    }
    
    public var rawValue: String { id }
    
    public init() {}
}

//
//  AuthSetting.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/11/24.
//

import Foundation

@propertyWrapper
public struct AuthSetting: Codable, Hashable, Sendable, RawRepresentable {
    public typealias BooleanLiteralType = Bool
    
    public var bool: Bool = false
    
    public var wrappedValue: Bool { bool }
    
    public init() {}
    
    public init?(rawValue: Bool) {
        self.bool = rawValue
    }
    
    public var rawValue: Bool { bool }
}

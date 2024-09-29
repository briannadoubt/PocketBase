//
//  MockKeychain.swift
//  PocketBase
//
//  Created by Brianna Zamora on 9/20/24.
//

import PocketBase

public final class MockKeychain: KeychainProtocol {
    public let service: String
    
    public init(service: String) {
        self.service = service
    }
    
    public nonisolated(unsafe) var values: [String: String] = [:]
    
    public subscript(key: String) -> String? {
        get {
            values[key]
        }
        set(newValue) {
            values[key] = newValue
        }
    }
}

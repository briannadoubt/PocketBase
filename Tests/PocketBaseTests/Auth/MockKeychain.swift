//
//  MockKeychain.swift
//  PocketBase
//
//  Created by Brianna Zamora on 9/20/24.
//

import PocketBase

final class MockKeychain: KeychainProtocol {
    let service: String
    
    init(service: String) {
        self.service = service
    }
    
    nonisolated(unsafe) var values: [String: String] = [:]
    
    subscript(key: String) -> String? {
        get {
            values[key]
        }
        set(newValue) {
            values[key] = newValue
        }
    }
}

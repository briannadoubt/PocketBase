//
//  AuthStore.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/10/24.
//

import Foundation
internal import KeychainAccess

public struct AuthStore: Sendable {
    
    public init() {}
    
    public var isValid: Bool {
        token != nil
    }
    
    public var token: String? {
        Keychain()["token"]
    }
    
    func set(token: String) {
        Keychain()["token"] = token
    }
    
    public func record<T: AuthRecord>() throws -> T? {
        guard let data = UserDefaults.pocketbase?.value(forKey: "record") as? Data else {
            return nil
        }
        let record = try JSONDecoder().decode(AuthResponse<T>.self, from: data).record
        return record
    }
    
    func set<T: AuthRecord>(_ response: AuthResponse<T>) throws {
        // Don't use the internal PocketBase encoder becuase this will skip keys that are intended to be set by the server.
        let data = try JSONEncoder().encode(response)
        UserDefaults.pocketbase?.setValue(data, forKey: "record")
    }
    
    func set<T: AuthRecord>(response: AuthResponse<T>) throws {
        set(token: response.token)
        try set(response)
    }
    
    public func clear() {
        Keychain()["token"] = nil
        UserDefaults.pocketbase?.removeObject(forKey: "record")
    }
}

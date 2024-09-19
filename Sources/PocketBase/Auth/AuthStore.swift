//
//  AuthStore.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/10/24.
//

import Foundation
@preconcurrency internal import KeychainAccess

public struct AuthStore: Sendable {
    
    public init() {}
    
    let keychain = Keychain(service: "io.pocketbase.auth")
    
    public var isValid: Bool {
        token != nil
    }
    
    public var token: String? {
        keychain["token"]
    }
    
    func set(token: String) {
        keychain["token"] = token
    }
    
    public func record<T: AuthRecord>() throws -> T? {
        guard let data = UserDefaults.pocketbase?.value(forKey: "record") as? Data else {
            return nil
        }
        let record = try JSONDecoder().decode(AuthResponse<T>.self, from: data).record
        return record
    }
    
    func set<T: AuthRecord>(_ response: AuthResponse<T>) throws {
        let data = try JSONEncoder().encode(response, configuration: .cache)
        UserDefaults.pocketbase?.setValue(data, forKey: "record")
    }
    
    func set<T: AuthRecord>(response: AuthResponse<T>) throws {
        set(token: response.token)
        try set(response)
    }
    
    public func clear() {
        keychain["token"] = nil
        UserDefaults.pocketbase?.removeObject(forKey: "record")
    }
}

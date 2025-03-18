//
//  AuthStore.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/10/24.
//

import Foundation

public struct AuthStore: Sendable {
    
    public static var service: String {
        "io.pocketbase.auth"
    }
    
    nonisolated(unsafe) let defaults: UserDefaults?
    
    public init(
        keychain: KeychainProtocol.Type = DefaultKeychain.self,
        service: String = AuthStore.service,
        defaults: UserDefaults? = UserDefaults.pocketbase
    ) {
        self.init(
            keychain: keychain.init(service: service),
            defaults: defaults
        )
    }
    
    init(
        keychain: KeychainProtocol,
        defaults: UserDefaults? = UserDefaults.pocketbase
    ) {
        self.keychain = keychain
        self.defaults = defaults
    }
    
    let keychain: KeychainProtocol
    
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
        guard let data = defaults?.value(forKey: "record") as? Data else {
            return nil
        }
        let record = try JSONDecoder().decode(AuthResponse<T>.self, from: data).record
        return record
    }
    
    package func set<T: AuthRecord>(_ response: AuthResponse<T>) throws {
        try set(token: response.token, record: response.record)
    }
    
    package func set<T: AuthRecord>(token: String, record: T) throws {
        set(token: token)
        let data = try JSONEncoder().encode(AuthResponse(token: token, record: record), configuration: .none)
        defaults?.setValue(data, forKey: "record")
    }
    
    public func clear() {
        keychain["token"] = nil
        defaults?.removeObject(forKey: "record")
    }
}

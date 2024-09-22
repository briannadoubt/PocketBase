//
//  AuthStore.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/10/24.
//

import Foundation
@preconcurrency import KeychainAccess

public protocol KeychainProtocol: AnyObject, Sendable {
    init(service: String)
    subscript(_ key: String) -> String? { get set }
    var service: String { get }
}

extension Keychain: KeychainProtocol, @unchecked @retroactive Sendable {}

public struct AuthStore: Sendable {
    
    public static var service: String {
        "io.pocketbase.auth"
    }
    
    public init(
        keychain: KeychainProtocol.Type = Keychain.self,
        service: String = AuthStore.service
    ) {
        self.init(
            keychain: keychain.init(
                service: service
            )
        )
    }
    
    init(keychain: KeychainProtocol) {
        self.keychain = keychain
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
        guard let data = UserDefaults.pocketbase?.value(forKey: "record") as? Data else {
            return nil
        }
        let record = try JSONDecoder().decode(AuthResponse<T>.self, from: data).record
        return record
    }
    
    func set<T: AuthRecord>(_ response: AuthResponse<T>) throws {
        set(token: response.token)
        let data = try JSONEncoder().encode(response, configuration: .cache)
        UserDefaults.pocketbase?.setValue(data, forKey: "record")
    }
    
    public func clear() {
        keychain["token"] = nil
        UserDefaults.pocketbase?.removeObject(forKey: "record")
    }
}

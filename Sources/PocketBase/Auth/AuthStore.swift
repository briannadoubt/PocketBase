//
//  AuthStore.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/10/24.
//

import Foundation

public struct AuthStore: Sendable, HasLogger {

    public static var service: String {
        "io.pocketbase.auth"
    }
    
    static let legacyRecordKey = "record"

    // UserDefaults is thread-safe per Apple's documentation, but isn't marked as Sendable.
    // nonisolated(unsafe) silences the compiler warning while maintaining correct behavior.
    nonisolated(unsafe) let defaults: UserDefaults?

    // Connection-specific key for storing auth records
    // Derived from the service name to ensure isolation between connections
    private let recordKey: String

    public init(
        keychain: KeychainProtocol.Type = DefaultKeychain.self,
        service: String = AuthStore.service,
        defaults: UserDefaults? = UserDefaults.pocketbase
    ) {
        self.init(
            keychain: keychain.init(service: service),
            defaults: defaults,
            recordKey: "record.\(service)"
        )
    }

    init(
        keychain: KeychainProtocol,
        defaults: UserDefaults? = UserDefaults.pocketbase,
        recordKey: String = "record.\(AuthStore.service)"
    ) {
        self.keychain = keychain
        self.defaults = defaults
        self.recordKey = recordKey
    }

    let keychain: KeychainProtocol
    
    public var isValid: Bool {
        token != nil
    }
    
    public var token: String? {
        keychain["token"]
    }
    
    public func set(token: String) {
        keychain["token"] = token
    }
    
    public func record<T: AuthRecord>() throws -> T? {
        if let data = defaults?.value(forKey: recordKey) as? Data {
            let record = try JSONDecoder().decode(AuthResponse<T>.self, from: data).record
            return record
        }
        
        // Backward-compatibility: fallback to legacy key and migrate on successful decode.
        guard
            recordKey != Self.legacyRecordKey,
            let legacyData = defaults?.value(forKey: Self.legacyRecordKey) as? Data
        else {
            return nil
        }
        let record = try JSONDecoder().decode(AuthResponse<T>.self, from: legacyData).record
        defaults?.setValue(legacyData, forKey: recordKey)
        defaults?.removeObject(forKey: Self.legacyRecordKey)
        return record
    }
    
    func set<T: AuthRecord>(_ response: AuthResponse<T>) throws {
        try set(token: response.token, record: response.record)
    }
    
    func set<T: AuthRecord>(token: String, record: T) throws {
        set(token: token)
        let data = try JSONEncoder().encode(AuthResponse(token: token, record: record), configuration: .none)
        #if DEBUG
        Self.logger.debug("AuthStore.set recordKey=\(self.recordKey)")
        #endif
        defaults?.setValue(data, forKey: recordKey)
    }
    
    public func clear() {
        #if DEBUG
        Self.logger.debug("AuthStore.clear recordKey=\(self.recordKey)")
        #endif
        keychain["token"] = nil
        defaults?.removeObject(forKey: recordKey)
        if recordKey != Self.legacyRecordKey {
            defaults?.removeObject(forKey: Self.legacyRecordKey)
        }
    }
}

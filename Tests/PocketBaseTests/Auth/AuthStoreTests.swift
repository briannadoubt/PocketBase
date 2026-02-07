//
//  AuthStoreTests.swift
//  PocketBase
//
//  Created by Brianna Zamora on 9/20/24.
//

import Testing
@testable import PocketBase
import TestUtilities

@Suite("AuthStore Tests")
struct AuthStoreTests {
    @Test("Keychain Service String")
    func service() {
        #expect(AuthStore.service == "io.pocketbase.auth")
    }
    
    @Test("Initialize AuthStore")
    func initialization() {
        let uuid = UUID().uuidString
        let store = AuthStore(
            keychain: MockKeychain.self,
            service: uuid
        )
        #expect(store.keychain.service == uuid)
        #expect(store.token == nil)
        #expect(store.isValid == false)
    }
    
    @Test("Set Token")
    func setToken() {
        let uuid = UUID().uuidString
        let store = AuthStore(
            keychain: MockKeychain.self,
            service: uuid
        )
        #expect(store.token == nil)
        #expect(store.isValid == false)
        store.set(token: "meow")
        #expect(store.token == "meow")
        #expect(store.isValid)
    }
    
    @Test("Create/Update/Delete")
    func createUpdateDelete() throws {
        let uuid = UUID().uuidString
        let mockKeychain = MockKeychain(service: uuid)
        let fake = "fake"
        let tester = Tester()
        let store = AuthStore(
            keychain: mockKeychain
        )
        try store.set(
            AuthResponse(
                token: fake,
                record: tester
            )
        )
        #expect(store.token == fake)
        #expect(store.isValid)
        let record: Tester? = try store.record()
        #expect(record == tester)
        store.clear()
        #expect(store.token == nil)
        #expect(store.isValid == false)
        #expect(try store.record() as Tester? == nil)
    }

    @Test("Reads legacy record key and migrates to namespaced key")
    func migratesLegacyRecordKey() throws {
        let service = UUID().uuidString
        let defaults = UserDefaultsSpy(suiteName: service)
        let record = Tester()
        let token = "legacy-token"
        let payload = try JSONEncoder().encode(
            AuthResponse(
                token: token,
                record: record
            ),
            configuration: .none
        )
        defaults?.setValue(payload, forKey: "record")

        let store = AuthStore(
            keychain: MockKeychain.self,
            service: service,
            defaults: defaults
        )

        let loaded: Tester? = try store.record()
        #expect(loaded == record)
        #expect(defaults?.data(forKey: "record.\(service)") == payload)
        #expect(defaults?.data(forKey: "record") == nil)
    }
}

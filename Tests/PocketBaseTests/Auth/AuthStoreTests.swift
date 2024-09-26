//
//  AuthStoreTests.swift
//  PocketBase
//
//  Created by Brianna Zamora on 9/20/24.
//

import Testing
@testable import PocketBase

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
}

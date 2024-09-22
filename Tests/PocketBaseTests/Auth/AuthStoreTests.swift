//
//  AuthStoreTests.swift
//  PocketBase
//
//  Created by Brianna Zamora on 9/20/24.
//

import Testing
@testable import PocketBase

struct AuthStoreTests {
    @Test func service() {
        #expect(AuthStore.service == "io.pocketbase.auth")
    }
    
    @Test func initialization() {
        let uuid = UUID().uuidString
        let store = AuthStore(
            keychain: MockKeychain.self,
            service: uuid
        )
        #expect(store.keychain.service == uuid)
        #expect(store.token == nil)
        #expect(store.isValid == false)
    }
    
    @Test func setToken() {
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
    
    @Test func createUpdateDelete() throws {
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

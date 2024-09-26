//
//  RecordCollectionTests.swift
//  PocketBase
//
//  Created by Brianna Zamora on 9/21/24.
//

import Testing
@testable import PocketBase

@Suite("RecordCollection Tests")
struct RecordCollectionTests: AuthTestSuite {
    @Test("Initialize")
    func initialize() async throws {
        let userDefaults = UserDefaultsSpy(suiteName: #function)
        let session = MockNetworkSession(
            data: try PocketBase.encoder.encode(Self.tester, configuration: .cache)
        )
        
        let collection = RecordCollection<Rawr>(
            Tester.collection,
            PocketBase(
                url: URL(string: #function + ".com")!,
                defaults: userDefaults,
                session: session,
                authStore: AuthStore(
                    keychain: MockKeychain(service: #function),
                    defaults: userDefaults
                )
            )
        )
        
        await #expect(collection.baseURL == URL(string: #function + ".com")!)
        await #expect(collection.collection == Tester.collection)
        await #expect(collection.session as? MockNetworkSession == session)
    }
    
    @Test("Headers", arguments: [true, false])
    func headers(isAuthenticated: Bool) async throws {
        let userDefaults = UserDefaultsSpy(suiteName: #function)
        
        let response = isAuthenticated ? try PocketBase.encoder.encode(Self.authResponse, configuration: .cache) : Data()
        let session = MockNetworkSession(
            data: response
        )
        
        let pocketbase = PocketBase(
            url: URL(string: UUID().uuidString + ".com")!,
            defaults: userDefaults,
            session: session,
            authStore: AuthStore(
                keychain: MockKeychain(service: #function),
                defaults: userDefaults
            )
        )
        
        let collection = pocketbase.collection(Tester.self)
        
        if isAuthenticated {
            let testers = pocketbase.collection(Tester.self)
            try await testers.login(
                with: .identity(
                    Self.username,
                    password: Self.password
                )
            )
        }
        
        let headers = await collection.headers
        let expectedHeader = isAuthenticated ? "Bearer \(Self.token)" : nil
        
        #expect(headers[.authorization] == expectedHeader)
    }
}

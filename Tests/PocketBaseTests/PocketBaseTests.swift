//
//  PocketBaseTests.swift
//  PocketBase
//
//  Created by Brianna Zamora on 9/19/24.
//

import Testing
@testable import PocketBase
import Foundation

@Suite("Test PocketBase")
struct PocketBaseTests {
    @Test("Initialize from stored URL")
    func initFromStoredURL() async {
        let userDefaults = UserDefaultsSpy(suiteName: #function)
        userDefaults?.set(URL.localhost, forKey: PocketBase.urlKey)
        #expect(userDefaults?.url(forKey: PocketBase.urlKey) == .localhost)
        let session = MockNetworkSession()
        let pocketbase = PocketBase(
            fromStoredURL: userDefaults,
            session: session,
            authStore: AuthStore(
                keychain: MockKeychain(service: "meow"),
                defaults: userDefaults
            )
        )
        #expect(pocketbase.url == .localhost)
        await #expect(pocketbase.realtime.baseUrl == .localhost)
        #expect(pocketbase.session as? MockNetworkSession == session)
        #expect(userDefaults?.url(forKey: PocketBase.urlKey) == .localhost)
        userDefaults?.removeObject(forKey: PocketBase.urlKey)
        #expect(userDefaults?.url(forKey: PocketBase.urlKey) == nil)
    }
    
    @Test("Create Collection")
    func collection() async {
        let defaults = UserDefaultsSpy(suiteName: #function)
        let session = MockNetworkSession()
        let pb = PocketBase(
            url: .localhost,
            defaults: defaults,
            session: session,
            authStore: AuthStore(
                keychain: MockKeychain(service: "fake"),
                defaults: defaults
            )
        )
        let collection = pb.collection(Rawr.self)
        await #expect(collection.baseURL == pb.url)
        await #expect(collection.session as? MockNetworkSession == session)
        await #expect(collection
            .collection == Rawr.collection)
    }
    
    @Test("PocketBase Localhost Definition")
    func localhost() {
        let pocketbase: PocketBase = .localhost
        #expect(pocketbase.url == .localhost)
    }
    
    @Test("PocketBase URL Key")
    func urlKey() {
        #expect(PocketBase.urlKey == "io.pocketbase.url")
    }
    
    @Test("PocketBase Last Event Key")
    func lastEventKey() {
        #expect(PocketBase.lastEventKey == "io.pocketbase.lastEvent")
    }
    
    struct Localhost {
        @Test("Localhost URL Definition")
        func localhostURL() {
            #expect(URL.localhost.absoluteString == "http://localhost:8090")
        }
    }
}

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
    @Test func initFromStoredURL() async {
        UserDefaults.pocketbase?.set(URL.localhost, forKey: PocketBase.urlKey)
        #expect(UserDefaults.pocketbase?.url(forKey: PocketBase.urlKey) == .localhost)
        let session = MockNetworkSession()
        let pocketbase = PocketBase(session: session)
        #expect(pocketbase.url == .localhost)
        await #expect(pocketbase.realtime.baseUrl == .localhost)
        #expect(pocketbase.session as? MockNetworkSession == session)
        #expect(UserDefaults.pocketbase?.url(forKey: PocketBase.urlKey) == .localhost)
        UserDefaults.pocketbase?.removeObject(forKey: PocketBase.urlKey)
        #expect(UserDefaults.pocketbase?.url(forKey: PocketBase.urlKey) == nil)
    }
    
    @Test("Create Collection")
    func collection() async {
        let session = MockNetworkSession()
        let pb = PocketBase(url: .localhost, session: session)
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

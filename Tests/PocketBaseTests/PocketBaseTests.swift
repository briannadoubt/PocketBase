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
}

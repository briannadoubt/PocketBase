//
//  MetaOAuth2ResponseTests.swift
//  PocketBase
//
//  Created by Brianna Zamora on 9/20/24.
//

import Testing
@testable import PocketBase

@Suite("MetaOAuth2Response Tests")
struct MetaOAuth2ResponseTests {
    @Test("\"Did Sign Out\" Notification Name")
    func pocketbaseDidSignOutNotificationName() {
        #expect(Notification.Name.pocketbaseDidSignOut.rawValue == "pocketbaseDidSignOut")
    }

    @Test("Initializer")
    func initialize() async throws {
        let fake = "fake"
        let date = Date()
        let url = URL(string: "fake.com")!
        let data = fake.data(using: .utf8)!
        let response = MetaOAuth2Response(
            id: fake,
            name: fake,
            username: fake,
            email: fake,
            isNew: true,
            avatarUrl: url,
            rawUser: data,
            accessToken: fake,
            refreshToken: fake,
            expiry: date
        )
        #expect(response.id == fake)
        #expect(response.name == fake)
        #expect(response.username == fake)
        #expect(response.email == fake)
        #expect(response.isNew)
        #expect(response.avatarUrl == url)
        #expect(response.rawUser == data)
        #expect(response.accessToken == fake)
        #expect(response.refreshToken == fake)
        #expect(response.expiry == date)
    }

}

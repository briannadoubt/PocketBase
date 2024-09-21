//
//  LinkedAuthProviderTests.swift
//  PocketBase
//
//  Created by Brianna Zamora on 9/20/24.
//

import Testing
@testable import PocketBase

struct LinkedAuthProviderTests {

    @Test func initilize() async throws {
        let date = Date()
        let provider = LinkedAuthProvider(
            id: "fake",
            created: date,
            updated: date,
            recordId: "fake",
            collectionId: "fake",
            provider: "fake",
            providerId: "fake"
        )
        #expect(provider.id == "fake")
        #expect(provider.created == date)
        #expect(provider.updated == date)
        #expect(provider.recordId == "fake")
        #expect(provider.collectionId == "fake")
        #expect(provider.provider == "fake")
        #expect(provider.providerId == "fake")
    }

}

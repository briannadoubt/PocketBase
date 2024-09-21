//
//  OAuthProviderTests.swift
//  PocketBase
//
//  Created by Brianna Zamora on 9/20/24.
//

import Testing
@testable import PocketBase

struct OAuthProviderTests {
    @Test
    func initializer() {
        let name = "meowface"
        let fake = "fake"
        let url = URL(string: "fake.com")!
        let provider = OAuthProvider(
            name: name,
            state: fake,
            codeVerifier: fake,
            codeChallenge: fake,
            codeChallengeMethod: fake,
            authUrl: url
        )
        #expect(provider.name == name)
        #expect(provider.state == fake)
        #expect(provider.codeVerifier == fake)
        #expect(provider.codeChallenge == fake)
        #expect(provider.codeChallengeMethod == fake)
        #expect(provider.authUrl == url)
    }
}

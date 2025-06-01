//
//  AuthMethodsTests.swift
//  PocketBase
//
//  Created by Brianna Zamora on 9/20/24.
//

import Testing
@testable import PocketBase

@Suite("AuthMethods Tests")
struct AuthMethodsTests {

    @Test("AuthMethods Initializer")
    func initializer() async throws {
        let methods = AuthMethods(
            usernamePassword: true,
            emailPassword: true,
            oauth2: Oauth2Methods(providers: [], enabled: false)
        )
        #expect(methods.usernamePassword)
        #expect(methods.emailPassword)
        #expect(methods.oauth2.providers.isEmpty)
    }

}

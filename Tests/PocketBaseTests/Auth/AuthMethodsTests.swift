//
//  AuthMethodsTests.swift
//  PocketBase
//
//  Created by Brianna Zamora on 9/20/24.
//

import Testing
@testable import PocketBase

struct AuthMethodsTests {

    @Test func initializer() async throws {
        let methods = AuthMethods(
            usernamePassword: true,
            emailPassword: true,
            authProviders: []
        )
        #expect(methods.usernamePassword)
        #expect(methods.emailPassword)
        #expect(methods.authProviders.isEmpty)
    }

}

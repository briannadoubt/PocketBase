//
//  NetworkResponseTestSuite.swift
//  PocketBase
//
//  Created by Brianna Zamora on 9/22/24.
//

import Testing
@testable import PocketBase

protocol NetworkResponseTestSuite {}

extension NetworkResponseTestSuite {
    static var baseURL: URL {
        URL(string: UUID().uuidString + ".com")!
    }
    
    static var email: String {
        "meow@meow.com"
    }
    
    static var newEmail: String {
        "meow2@meow.com"
    }
    
    static var identityLogin: RecordCollection<Tester>.AuthMethod {
        .identity(
            username,
            password: password
        )
    }
    
    static var oauthLogin: RecordCollection<Tester>.AuthMethod {
        .oauth(
            OAuthProvider(
                name: "fake",
                state: "fake",
                codeVerifier: "fake",
                codeChallenge: "fake",
                codeChallengeMethod: "fake",
                authUrl: URL(string: "fake.com")!
            )
        )
    }
    
    static var token: String {
        "meowmeow1234"
    }
    
    static var id: String {
        "meow1234"
    }
    
    static var username: String {
        "meowface"
    }
    
    static var password: String {
        "Test1234"
    }
    
    static var keychainService: String {
        "PocketBase.AuthTests"
    }
    
    static var authResponse: AuthResponse<Tester> {
        AuthResponse(token: token, record: tester)
    }
    
    static var tester: Tester {
        Tester(id: id, username: username)
    }
    
    static var field: String {
        "meow"
    }
    
    static var rawr: Rawr {
        Rawr(id: id, field: field)
    }
}

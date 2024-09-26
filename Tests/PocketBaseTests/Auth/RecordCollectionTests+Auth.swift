//
//  RecordCollectionTests+Auth.swift
//  PocketBase
//
//  Created by Brianna Zamora on 9/24/24.
//

import Testing
@testable import PocketBase

extension RecordCollectionTests {
    @Suite("Authentication Tests")
    struct AuthTests: AuthTestSuite {
        
        @Test(
            "Login",
            arguments: zip(
                [
                    Self.identityLogin,
                    Self.oauthLogin,
                ],
                [
                    Self.authResponse,
                    Self.authResponse
                ]
            )
        )
        func login(
            method: RecordCollection<Tester>.AuthMethod,
            response: AuthResponse<Tester>
        ) async throws {
            let defaults = UserDefaultsSpy(suiteName: #function)
            let mockSession = MockNetworkSession(
                data: try PocketBase.encoder.encode(response, configuration: .cache)
            )
            let pocketbase = PocketBase(
                url: .localhost,
                defaults: defaults,
                session: mockSession,
                authStore: AuthStore(
                    keychain: MockKeychain(
                        service: Self.keychainService
                    ),
                    defaults: defaults
                )
            )
            let collection = pocketbase.collection(Tester.self)
            switch method {
            case .identity:
                let tester = try await collection.login(with: method)
                #expect(response.record.id == tester.id)
                #expect(response.record.username == tester.username)
                
                // Test cache
                #expect(pocketbase.authStore.token == response.token)
                let cachedTester: Tester? = try pocketbase.authStore.record()
                #expect(cachedTester?.id == response.record.id)
                
                #expect(mockSession.lastRequest?.url?.absoluteString == "http://localhost:8090/api/collections/testers/auth-with-password?expand=rawrs")
                guard let body = mockSession.lastRequest?.httpBody else {
                    #expect(mockSession.lastRequest?.httpBody != nil)
                    return
                }
                let decodedBody = try JSONDecoder().decode(AuthWithPasswordBody.self, from: body)
                #expect(decodedBody == AuthWithPasswordBody(
                    identity: Self.username,
                    password: Self.password
                ))
                #expect(mockSession.lastRequest?.httpMethod == "POST")
                #expect(mockSession.lastRequest?.allHTTPHeaderFields == ["Content-Type": "application/json"])
            case .oauth:
                await #expect(
                    throws: PocketBaseError.notImplemented,
                    performing: {
                        try await collection.login(with: method)
                    }
                )
            }
        }
        
        @Test("Logout")
        func logout() async throws {
            let defaults = UserDefaultsSpy(suiteName: #function)
            // MARK: GIVEN a logged in user
            let mockSession = MockNetworkSession(
                data: try PocketBase.encoder.encode(
                    Self.authResponse,
                    configuration: .cache
                )
            )
            let pocketbase = PocketBase(
                url: .localhost,
                defaults: defaults,
                session: mockSession,
                authStore: AuthStore(
                    keychain: MockKeychain(
                        service: Self.keychainService
                    ),
                    defaults: defaults
                )
            )
            let collection = pocketbase.collection(Tester.self)
            
            let tester = try await collection.login(with: Self.identityLogin)
            #expect(Self.authResponse.record.id == tester.id)
            #expect(Self.authResponse.record.username == tester.username)
            
            // MARK: THEN Cache should have values
            #expect(pocketbase.authStore.token == Self.authResponse.token)
            #expect((try pocketbase.authStore.record() as Tester?)?.id == Self.authResponse.record.id)
            
            #expect(mockSession.lastRequest?.url?.absoluteString == "http://localhost:8090/api/collections/testers/auth-with-password?expand=rawrs")
            guard let body = mockSession.lastRequest?.httpBody else {
                #expect(mockSession.lastRequest?.httpBody != nil)
                return
            }
            let decodedBody = try JSONDecoder().decode(AuthWithPasswordBody.self, from: body)
            #expect(decodedBody == AuthWithPasswordBody(
                identity: Self.username,
                password: Self.password
            ))
            #expect(mockSession.lastRequest?.httpMethod == "POST")
            #expect(mockSession.lastRequest?.allHTTPHeaderFields == ["Content-Type": "application/json"])
            
            // MARK: WHEN Logged out
            await collection.logout()
            
            // MARK: THEN Cache should NOT have values
            #expect(pocketbase.authStore.token == nil)
            #expect(try pocketbase.authStore.record() as Tester? == nil)
            
            // MARK: No requests should be made, thus the last request should match the prior one!
            #expect(mockSession.lastRequest?.url?.absoluteString == "http://localhost:8090/api/collections/testers/auth-with-password?expand=rawrs")
        }
        
        @Test("Refresh")
        func refresh() async throws {
            let defaults = UserDefaultsSpy(suiteName: #function)
            // MARK: GIVEN a logged in user
            let mockSession = MockNetworkSession(
                data: try PocketBase.encoder.encode(
                    Self.authResponse,
                    configuration: .cache
                )
            )
            let pocketbase = PocketBase(
                url: .localhost,
                defaults: defaults,
                session: mockSession,
                authStore: AuthStore(
                    keychain: MockKeychain.self,
                    service: Self.keychainService,
                    defaults: defaults
                )
            )
            let collection = pocketbase.collection(Tester.self)
            
            #expect(pocketbase.authStore.token == nil)
            let username = (try pocketbase.authStore.record() as Tester?)?.username
            #expect(username == nil || username == "")
            
            try await collection.authRefresh()
            
            #expect(pocketbase.authStore.token == Self.token)
            let usernameAgain = (try pocketbase.authStore.record() as Tester?)?.username
            #expect(usernameAgain == Self.username)
            
            #expect(mockSession.lastRequest?.url?.absoluteString == "http://localhost:8090/api/collections/testers/auth-refresh?expand=rawrs")
            #expect(mockSession.lastRequest?.httpBody == nil)
            #expect(mockSession.lastRequest?.httpMethod == "POST")
            #expect(mockSession.lastRequest?.allHTTPHeaderFields == ["Content-Type": "application/json"])
            
            await collection.logout()
        }
        
        @Test("Refresh, Error clears auth state")
        func refreshErrorClearsAuthState() async throws {
            let defaults = UserDefaultsSpy(suiteName: #function)
            // MARK: GIVEN a logged in user
            let mockSession = MockNetworkSession(
                data: try PocketBase.encoder.encode(
                    Self.authResponse,
                    configuration: .cache
                )
            )
            let pocketbase = PocketBase(
                url: .localhost,
                defaults: defaults,
                session: mockSession,
                authStore: AuthStore(
                    keychain: MockKeychain.self,
                    service: Self.keychainService,
                    defaults: defaults
                )
            )
            let collection = pocketbase.collection(Tester.self)
            
            #expect(pocketbase.authStore.token == nil)
            let username = (try pocketbase.authStore.record() as Tester?)?.username
            #expect(username == nil || username == "")
            
            try await collection.authRefresh()
            
            #expect(pocketbase.authStore.token == Self.token)
            let usernameAgain = (try pocketbase.authStore.record() as Tester?)?.username
            #expect(usernameAgain == Self.username)
            
            #expect(mockSession.lastRequest?.url?.absoluteString == "http://localhost:8090/api/collections/testers/auth-refresh?expand=rawrs")
            #expect(mockSession.lastRequest?.httpBody == nil)
            #expect(mockSession.lastRequest?.httpMethod == "POST")
            #expect(mockSession.lastRequest?.allHTTPHeaderFields == ["Content-Type": "application/json"])
            
            // MARK: Network layer throws here to mock a network error
            mockSession.shouldThrow = true
            
            await #expect(throws: MockNetworkError.youToldMeTo) {
                try await collection.authRefresh()
            }
            
            #expect(pocketbase.authStore.token == nil)
            let anotherUsername = (try pocketbase.authStore.record() as Tester?)?.username
            #expect(anotherUsername == nil || anotherUsername == "")
        }
        
        @Test("Request Email Change")
        func requestEmailChange() async throws {
            let defaults = UserDefaultsSpy(suiteName: #function)
            let mockSession = MockNetworkSession()
            let pocketbase = PocketBase(
                url: .localhost,
                defaults: defaults,
                session: mockSession,
                authStore: AuthStore(
                    keychain: MockKeychain.self,
                    service: Self.keychainService,
                    defaults: defaults
                )
            )
            let collection = pocketbase.collection(Tester.self)
            
            try await collection.requestEmailChange(newEmail: "meow@meow.com")
            
            #expect(mockSession.lastRequest?.url?.absoluteString == "http://localhost:8090/api/collections/testers/request-email-change")
            guard let body = mockSession.lastRequest?.httpBody else {
                #expect(mockSession.lastRequest?.httpBody != nil)
                return
            }
            guard let decodedBody = try JSONSerialization.jsonObject(with: body) as? [String: String] else {
                Issue.record("No JSON object in body")
                return
            }
            #expect(decodedBody == ["newEmail": "meow@meow.com"])
            #expect(mockSession.lastRequest?.httpMethod == "POST")
            #expect(mockSession.lastRequest?.allHTTPHeaderFields == ["Content-Type": "application/json"])
        }
        
        @Test("Confirm Email Change")
        func confirmEmailChange() async throws {
            let defaults = UserDefaultsSpy(suiteName: #function)
            let mockSession = MockNetworkSession()
            let pocketbase = PocketBase(
                url: .localhost,
                defaults: defaults,
                session: mockSession,
                authStore: AuthStore(
                    keychain: MockKeychain.self,
                    service: Self.keychainService,
                    defaults: defaults
                )
            )
            let collection = pocketbase.collection(Tester.self)
            
            try await collection.confirmEmailChange(
                token: Self.token,
                password: Self.password
            )
            
            #expect(mockSession.lastRequest?.url?.absoluteString == "http://localhost:8090/api/collections/testers/confirm-email-change")
            guard let body = mockSession.lastRequest?.httpBody else {
                #expect(mockSession.lastRequest?.httpBody != nil)
                return
            }
            guard let decodedBody = try JSONSerialization.jsonObject(with: body) as? [String: String] else {
                Issue.record("No JSON object in body")
                return
            }
            #expect(decodedBody == ["password": Self.password, "token": Self.token])
            #expect(mockSession.lastRequest?.httpMethod == "POST")
            #expect(mockSession.lastRequest?.allHTTPHeaderFields == ["Content-Type": "application/json"])
        }
        
        @Test("Change Password")
        func changePassword() async throws {
            let defaults = UserDefaultsSpy(suiteName: #function)
            let mockSession = MockNetworkSession()
            let pocketbase = PocketBase(
                url: .localhost,
                defaults: defaults,
                session: mockSession,
                authStore: AuthStore(
                    keychain: MockKeychain.self,
                    service: Self.keychainService,
                    defaults: defaults
                )
            )
            let collection = pocketbase.collection(Tester.self)
            
            try await collection.requestPasswordReset(email: "meow@meow.com")
            
            #expect(mockSession.lastRequest?.url?.absoluteString == "http://localhost:8090/api/collections/testers/request-password-reset")
            guard let body = mockSession.lastRequest?.httpBody else {
                #expect(mockSession.lastRequest?.httpBody != nil)
                return
            }
            guard let decodedBody = try JSONSerialization.jsonObject(with: body) as? [String: String] else {
                Issue.record("No JSON object in body")
                return
            }
            #expect(decodedBody == ["email": "meow@meow.com"])
            #expect(mockSession.lastRequest?.httpMethod == "POST")
            #expect(mockSession.lastRequest?.allHTTPHeaderFields == ["Content-Type": "application/json"])
        }
        
        @Test("Confirm Password Reset")
        func confirmPasswordReset() async throws {
            let defaults = UserDefaultsSpy(suiteName: #function)
            let mockSession = MockNetworkSession()
            let pocketbase = PocketBase(
                url: .localhost,
                defaults: defaults,
                session: mockSession,
                authStore: AuthStore(
                    keychain: MockKeychain.self,
                    service: Self.keychainService,
                    defaults: defaults
                )
            )
            let collection = pocketbase.collection(Tester.self)
            
            try await collection.confirmPasswordReset(
                token: Self.token,
                password: Self.password,
                passwordConfirm: Self.password
            )
            
            #expect(mockSession.lastRequest?.url?.absoluteString == "http://localhost:8090/api/collections/testers/confirm-password-reset")
            #expect(mockSession.lastRequest?.httpMethod == "POST")
            #expect(mockSession.lastRequest?.allHTTPHeaderFields == ["Content-Type": "application/json"])
            guard let body = mockSession.lastRequest?.httpBody else {
                #expect(mockSession.lastRequest?.httpBody != nil)
                return
            }
            guard let decodedBody = try JSONSerialization.jsonObject(with: body) as? [String: String] else {
                Issue.record("No JSON object in body")
                return
            }
            let expectedBody = [
                "passwordConfirm": Self.password,
                "token": Self.token,
                "password": Self.password
            ]
            #expect(decodedBody == expectedBody)
        }
        
        @Test("List Linked Auth Providers")
        func listLinkedAuthProviders() async throws {
            let defaults = UserDefaultsSpy(suiteName: #function)
            let expectedProvider = LinkedAuthProvider(
                id: Self.id,
                created: .init(timeIntervalSince1970: 0),
                updated: .init(timeIntervalSince1970: 0),
                recordId: Self.id,
                collectionId: Self.id,
                provider: "meow",
                providerId: "meowmeow"
            )
            // MARK: GIVEN a logged in user
            let mockSession = MockNetworkSession(
                data: try PocketBase.encoder.encode([expectedProvider])
            )
            let pocketbase = PocketBase(
                url: .localhost,
                defaults: defaults,
                session: mockSession,
                authStore: AuthStore(
                    keychain: MockKeychain.self,
                    service: Self.keychainService,
                    defaults: defaults
                )
            )
            let collection = pocketbase.collection(Tester.self)
            
            let providers = try await collection.listLinkedAuthProviders(id: Self.id)
            
            #expect(providers == [expectedProvider])
            
            #expect(mockSession.lastRequest?.url?.absoluteString == "http://localhost:8090/api/collections/testers/records/external-auths")
            #expect(mockSession.lastRequest?.httpBody == nil)
            #expect(mockSession.lastRequest?.httpMethod == "GET")
            #expect(mockSession.lastRequest?.allHTTPHeaderFields == ["Content-Type": "application/json"])
        }
        
        @Test("Unlink External Auth Provider")
        func unlinkExternalAuthProvider() async throws {
            let defaults = UserDefaultsSpy(suiteName: #function)
            // MARK: GIVEN a logged in user
            let mockSession = MockNetworkSession()
            let pocketbase = PocketBase(
                url: .localhost,
                defaults: defaults,
                session: mockSession,
                authStore: AuthStore(
                    keychain: MockKeychain.self,
                    service: Self.keychainService,
                    defaults: defaults
                )
            )
            let collection = pocketbase.collection(Tester.self)
            
            try await collection.unlinkExternalAuthProvider(id: Self.id, provider: "meow")
            
            #expect(mockSession.lastRequest?.url?.absoluteString == "http://localhost:8090/api/collections/testers/records/external-auths/meow")
            #expect(mockSession.lastRequest?.httpBody == nil)
            #expect(mockSession.lastRequest?.httpMethod == "DELETE")
            #expect(mockSession.lastRequest?.allHTTPHeaderFields == ["Content-Type": "application/json"])
        }
        
        @Test("List Auth Methods")
        func listAuthMethods() async throws {
            let defaults = UserDefaultsSpy(suiteName: #function)
            // MARK: GIVEN a logged in user
            let methods = AuthMethods(
                usernamePassword: true,
                emailPassword: true,
                authProviders: []
            )
            let mockSession = MockNetworkSession(
                data: try PocketBase.encoder.encode(methods)
            )
            let pocketbase = PocketBase(
                url: .localhost,
                defaults: defaults,
                session: mockSession,
                authStore: AuthStore(
                    keychain: MockKeychain.self,
                    service: Self.keychainService,
                    defaults: defaults
                )
            )
            let collection = pocketbase.collection(Tester.self)
            
            let authMethods = try await collection.listAuthMethods()
            #expect(authMethods == methods)
            
            #expect(mockSession.lastRequest?.url?.absoluteString == "http://localhost:8090/api/collections/testers/auth-methods")
            #expect(mockSession.lastRequest?.httpBody == nil)
            #expect(mockSession.lastRequest?.httpMethod == "GET")
            #expect(mockSession.lastRequest?.allHTTPHeaderFields == ["Content-Type": "application/json"])
        }
        
        @Test("Request Verification")
        func requestVerification() async throws {
            let defaults = UserDefaultsSpy(suiteName: #function)
            let mockSession = MockNetworkSession()
            let pocketbase = PocketBase(
                url: .localhost,
                defaults: defaults,
                session: mockSession,
                authStore: AuthStore(
                    keychain: MockKeychain.self,
                    service: Self.keychainService,
                    defaults: defaults
                )
            )
            let collection = pocketbase.collection(Tester.self)
            
            try await collection.requestVerification(email: Self.email)
            
            #expect(mockSession.lastRequest?.url?.absoluteString == "http://localhost:8090/api/collections/testers/request-verification")
            guard let body = mockSession.lastRequest?.httpBody else {
                #expect(mockSession.lastRequest?.httpBody != nil)
                return
            }
            guard let decodedBody = try JSONSerialization.jsonObject(with: body) as? [String: String] else {
                Issue.record("No JSON object in body")
                return
            }
            #expect(decodedBody == ["email": "meow@meow.com"])
            #expect(mockSession.lastRequest?.httpMethod == "POST")
            #expect(mockSession.lastRequest?.allHTTPHeaderFields == ["Content-Type": "application/json"])
        }
        
        @Test("Confirm Verification")
        func confirmVerification() async throws {
            let defaults = UserDefaultsSpy(suiteName: #function)
            let mockSession = MockNetworkSession()
            let pocketbase = PocketBase(
                url: .localhost,
                defaults: defaults,
                session: mockSession,
                authStore: AuthStore(
                    keychain: MockKeychain.self,
                    service: Self.keychainService,
                    defaults: defaults
                )
            )
            let collection = pocketbase.collection(Tester.self)
            
            try await collection.confirmVerification(
                token: Self.token,
                password: Self.password,
                passwordConfirm: Self.password
            )
            
            #expect(mockSession.lastRequest?.url?.absoluteString == "http://localhost:8090/api/collections/testers/confirm-verification")
            guard let body = mockSession.lastRequest?.httpBody else {
                #expect(mockSession.lastRequest?.httpBody != nil)
                return
            }
            guard let decodedBody = try JSONSerialization.jsonObject(with: body) as? [String: String] else {
                Issue.record("No JSON object in body")
                return
            }
            #expect(decodedBody == ["passwordConfirm": Self.password, "password": Self.password, "token": Self.token])
            #expect(mockSession.lastRequest?.httpMethod == "POST")
            #expect(mockSession.lastRequest?.allHTTPHeaderFields == ["Content-Type": "application/json"])
        }
    }
}

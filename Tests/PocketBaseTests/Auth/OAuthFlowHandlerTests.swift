//
//  OAuthFlowHandlerTests.swift
//  PocketBase
//

import Foundation
import Testing
@testable import PocketBase
import TestUtilities

#if canImport(AuthenticationServices)
@Suite("OAuth Flow Handler")
struct OAuthFlowHandlerTests {
    @Test("Valid callback returns authorization code")
    func validCallback() throws {
        let callbackURL = URL(string: "myapp://callback?code=abc123&state=s1")!
        let code = try OAuthFlowHandler.parseAuthorizationCode(
            from: callbackURL,
            expectedState: "s1"
        )
        #expect(code == "abc123")
    }

    @Test("Callback error returns oauthFailed")
    func callbackError() {
        let callbackURL = URL(string: "myapp://callback?error=access_denied&error_description=Denied")!
        do {
            _ = try OAuthFlowHandler.parseAuthorizationCode(
                from: callbackURL,
                expectedState: "s1"
            )
            Issue.record("Expected oauthFailed error")
        } catch PocketBaseError.oauthFailed(let underlyingError) {
            #expect(underlyingError.localizedDescription == "Denied")
        } catch {
            Issue.record("Expected oauthFailed, got \(error)")
        }
    }

    @Test("Missing code returns oauthFailed")
    func missingCode() {
        let callbackURL = URL(string: "myapp://callback?state=s1")!
        do {
            _ = try OAuthFlowHandler.parseAuthorizationCode(
                from: callbackURL,
                expectedState: "s1"
            )
            Issue.record("Expected oauthFailed error")
        } catch PocketBaseError.oauthFailed(let underlyingError) {
            #expect(underlyingError.localizedDescription.contains("authorization code"))
        } catch {
            Issue.record("Expected oauthFailed, got \(error)")
        }
    }

    @Test("Missing state when expected returns oauthFailed")
    func missingStateWhenExpected() {
        let callbackURL = URL(string: "myapp://callback?code=abc123")!
        do {
            _ = try OAuthFlowHandler.parseAuthorizationCode(
                from: callbackURL,
                expectedState: "s1"
            )
            Issue.record("Expected oauthFailed error")
        } catch PocketBaseError.oauthFailed(let underlyingError) {
            #expect(underlyingError.localizedDescription.contains("State mismatch"))
        } catch {
            Issue.record("Expected oauthFailed, got \(error)")
        }
    }

    @Test("Mismatched state returns oauthFailed")
    func mismatchedState() {
        let callbackURL = URL(string: "myapp://callback?code=abc123&state=s2")!
        do {
            _ = try OAuthFlowHandler.parseAuthorizationCode(
                from: callbackURL,
                expectedState: "s1"
            )
            Issue.record("Expected oauthFailed error")
        } catch PocketBaseError.oauthFailed(let underlyingError) {
            #expect(underlyingError.localizedDescription.contains("State mismatch"))
        } catch {
            Issue.record("Expected oauthFailed, got \(error)")
        }
    }
}

@Suite("OAuth Flow Orchestration")
struct OAuthFlowOrchestrationTests {
    enum TestError: Error {
        case stopAfterCapture
    }

    @MainActor
    final class CapturingAuthenticator: OAuthAuthenticating {
        var capturedState: String?

        func authenticate(
            authUrl: URL,
            redirectScheme: String,
            expectedState: String?,
            preferEphemeralSession: Bool
        ) async throws -> String {
            capturedState = expectedState
            throw TestError.stopAfterCapture
        }
    }

    @MainActor
    @Test("Provider not found returns oauthFailed")
    func providerNotFound() async throws {
        let response = AuthMethods(
            usernamePassword: true,
            emailPassword: true,
            oauth2: Oauth2Methods(
                providers: [],
                enabled: true
            )
        )
        let responseData = try JSONEncoder().encode(response)
        let environment = PocketBase.TestEnvironment(
            baseURL: URL(string: "http://localhost:8090")!,
            response: responseData
        )
        let collection = environment.pocketbase.collection(Tester.self)

        do {
            _ = try await collection.loginWithOAuth(
                provider: OAuthProviderName.google,
                redirectScheme: "myapp"
            )
            Issue.record("Expected oauthFailed error")
        } catch PocketBaseError.oauthFailed(let underlyingError) {
            #expect(underlyingError.localizedDescription.contains("not found"))
        } catch {
            Issue.record("Expected oauthFailed, got \(error)")
        }
    }

    @MainActor
    @Test("loginWithOAuth passes provider state to authenticator")
    func passesProviderStateToAuthenticator() async throws {
        let provider = OAuthProvider(
            name: "google",
            state: "state-123",
            codeVerifier: "verifier",
            codeChallenge: "challenge",
            codeChallengeMethod: "S256",
            authUrl: URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        )
        let authMethods = AuthMethods(
            usernamePassword: true,
            emailPassword: true,
            oauth2: Oauth2Methods(providers: [provider], enabled: true)
        )
        let responseData = try JSONEncoder().encode(authMethods)
        let environment = PocketBase.TestEnvironment(
            baseURL: URL(string: "http://localhost:8090")!,
            response: responseData
        )
        let collection = environment.pocketbase.collection(Tester.self)
        let authenticator = CapturingAuthenticator()

        do {
            _ = try await collection.loginWithOAuth(
                provider: OAuthProviderName.google,
                redirectScheme: "myapp",
                authenticator: authenticator
            )
            Issue.record("Expected test sentinel error")
        } catch TestError.stopAfterCapture {
            #expect(authenticator.capturedState == "state-123")
        } catch {
            Issue.record("Expected test sentinel error, got \(error)")
        }
    }
}
#endif

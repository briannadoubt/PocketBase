//
//  OAuthTests.swift
//  PocketBaseTests
//
//  Unit tests for OAuth2 functionality
//

import Foundation
import Testing
@testable import PocketBase

@Suite("OAuth2 Authentication Tests")
struct OAuthTests {

    @Suite("OAuthProviderName")
    struct ProviderNameTests {

        @Test("Well-known provider names")
        func testWellKnownProviders() {
            #expect(OAuthProviderName.google.rawValue == "google")
            #expect(OAuthProviderName.github.rawValue == "github")
            #expect(OAuthProviderName.discord.rawValue == "discord")
            #expect(OAuthProviderName.microsoft.rawValue == "microsoft")
            #expect(OAuthProviderName.apple.rawValue == "apple")
        }

        @Test("Custom provider creation")
        func testCustomProvider() {
            let custom = OAuthProviderName.custom("okta")
            #expect(custom.rawValue == "okta")
        }

        @Test("String literal initialization")
        func testStringLiteral() {
            let provider: OAuthProviderName = "gitlab"
            #expect(provider.rawValue == "gitlab")
        }

        @Test("Equality comparison")
        func testEquality() {
            let provider1 = OAuthProviderName.google
            let provider2 = OAuthProviderName(rawValue: "google")
            let provider3: OAuthProviderName = "google"

            #expect(provider1 == provider2)
            #expect(provider2 == provider3)
            #expect(provider1 == provider3)
        }

        @Test("Hash consistency")
        func testHashable() {
            let provider1 = OAuthProviderName.github
            let provider2: OAuthProviderName = "github"

            var set = Set<OAuthProviderName>()
            set.insert(provider1)
            set.insert(provider2)

            #expect(set.count == 1)
        }

        @Test("Description format")
        func testDescription() {
            let provider = OAuthProviderName.google
            #expect(provider.description == "google")
        }
    }

    @Suite("OAuth Body Types")
    struct BodyTypeTests {

        @Test("AuthWithOAuth2Body conforms to Sendable")
        func testBodyWithCreateDataSendable() {
            struct TestData: EncodableWithConfiguration, Sendable {
                typealias EncodingConfiguration = PocketBase.EncodingConfiguration
                var value: String
                func encode(to encoder: any Encoder, configuration: PocketBase.EncodingConfiguration) throws {}
            }

            let body = AuthWithOAuth2Body(
                provider: "google",
                code: "code",
                codeVerifier: "verifier",
                redirectUrl: URL(string: "app://callback")!,
                createData: TestData(value: "test")
            )

            // If this compiles, the Sendable conformance is correct
            let _: any Sendable = body
        }

        @Test("AuthWithOAuth2BodyNoCreateData conforms to Sendable")
        func testBodyNoCreateDataSendable() {
            let body = AuthWithOAuth2BodyNoCreateData(
                provider: "github",
                code: "code",
                codeVerifier: "verifier",
                redirectUrl: URL(string: "app://callback")!
            )

            // If this compiles, the Sendable conformance is correct
            let _: any Sendable = body
        }
    }

    @Suite("OAuth Error Handling")
    struct ErrorHandlingTests {

        @Test("OAuth cancelled error")
        func testOAuthCancelledError() {
            let error = PocketBaseError.oauthCancelled

            switch error {
            case .oauthCancelled:
                // Expected
                break
            default:
                Issue.record("Expected oauthCancelled error")
            }
        }

        @Test("OAuth failed error")
        func testOAuthFailedError() {
            let underlyingError = NSError(domain: "Test", code: 123)
            let error = PocketBaseError.oauthFailed(underlyingError)

            switch error {
            case .oauthFailed(let err):
                #expect((err as NSError).code == 123)
            default:
                Issue.record("Expected oauthFailed error")
            }
        }

        @Test("OAuth flow required error")
        func testOAuthFlowRequiredError() {
            let provider = OAuthProvider(
                name: "google",
                state: "state123",
                codeVerifier: "verifier",
                codeChallenge: "challenge",
                codeChallengeMethod: "S256",
                authUrl: URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!
            )

            let error = PocketBaseError.oauthFlowRequired(provider)

            switch error {
            case .oauthFlowRequired(let p):
                #expect(p.name == "google")
            default:
                Issue.record("Expected oauthFlowRequired error")
            }
        }
    }

    @Suite("URL Code Extraction")
    struct URLCodeExtractionTests {

        @Test("Extract code from valid callback URL")
        func testValidCodeExtraction() throws {
            let url = URL(string: "myapp://callback?code=authorization_code_123&state=abc")!
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let code = components?.queryItems?.first(where: { $0.name == "code" })?.value

            #expect(code == "authorization_code_123")
        }

        @Test("Handle callback URL without code")
        func testMissingCode() {
            let url = URL(string: "myapp://callback?state=abc")!
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let code = components?.queryItems?.first(where: { $0.name == "code" })?.value

            #expect(code == nil)
        }

        @Test("Handle callback URL with error")
        func testCallbackWithError() {
            let url = URL(string: "myapp://callback?error=access_denied&error_description=User+denied+access")!
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let error = components?.queryItems?.first(where: { $0.name == "error" })?.value

            #expect(error == "access_denied")
        }
    }
}
